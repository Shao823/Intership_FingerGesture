`timescale 1ns / 1ps

// LightCNN1D classifier compute core:
//   GAP(sum/174) -> FC0(96->96) -> ReLU -> FC1(96->5) -> argmax
//
// This module has no weight storage. It requests one packed 16-lane weight
// word at a time from fc_weight_controller.
//
// Weight request convention:
//   layer=0, oc_base=0,16,...,80, k=0..95 weight, k=96 bias
//   layer=1, oc_base=0,            k=0..95 weight, k=96 bias
// For FC1 only lanes 0..4 of weight_vec are used.

module fc_classifier_96_5_compute #(
    parameter integer DATA_W        = 16,
    parameter integer GAP_ACC_W     = 48,
    parameter integer ACC_W         = 48,
    parameter integer FC0_IN        = 96,
    parameter integer FC0_OUT       = 96,
    parameter integer FC1_OUT       = 5,
    parameter integer FC0_OUT_LANES = 16,
    parameter integer AVG_LANES     = 12,
    parameter integer GAP_LEN       = 174,
    parameter integer FRAC_BITS     = 8
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire [8:0] gap_count,
    input  wire signed [FC0_IN*GAP_ACC_W-1:0] gap_sum_vec,

    output wire weight_req_valid,
    output wire weight_req_layer,
    output wire [6:0] weight_req_oc_base,
    output wire [6:0] weight_req_k,
    input  wire weight_req_ready,

    input  wire weight_vec_valid,
    output wire weight_vec_ready,
    input  wire signed [FC0_OUT_LANES*DATA_W-1:0] weight_vec,

    input  wire result_ready,
    output reg busy,
    output reg done,
    output reg result_valid,
    output reg [2:0] class_idx,
    output reg input_count_error,
    output reg signed [FC1_OUT*DATA_W-1:0] logits_vec
);

    localparam integer AVG_GROUPS = (FC0_IN + AVG_LANES - 1) / AVG_LANES;
    localparam integer AVG_GROUP_W = (AVG_GROUPS <= 1)
        ? 1 : $clog2(AVG_GROUPS);
    localparam integer FC0_K_W    = (FC0_IN <= 1) ? 1 : $clog2(FC0_IN + 1);
    localparam integer FC0_BASE_W = (FC0_OUT <= 1) ? 1 : $clog2(FC0_OUT + 1);
    localparam integer FC1_K_W    = (FC0_OUT <= 1) ? 1 : $clog2(FC0_OUT + 1);

    localparam [8:0] GAP_TARGET = GAP_LEN[8:0];
    localparam integer AVG_MAG_W = 23;
    localparam integer AVG_RECIP_SHIFT = 30;
    localparam [AVG_MAG_W-1:0] AVG_RECIP_MUL = 23'd6170931;
    localparam integer AVG_PROD_W = AVG_MAG_W + AVG_MAG_W;

    localparam [4:0] STATE_IDLE          = 5'd0;
    localparam [4:0] STATE_AVG_LOAD      = 5'd1;
    localparam [4:0] STATE_AVG_ABS       = 5'd2;
    localparam [4:0] STATE_AVG_MUL       = 5'd3;
    localparam [4:0] STATE_AVG_SHIFT     = 5'd4;
    localparam [4:0] STATE_AVG_SIGN      = 5'd5;
    localparam [4:0] STATE_AVG_STORE     = 5'd6;
    localparam [4:0] STATE_FC0_BIAS_REQ  = 5'd7;
    localparam [4:0] STATE_FC0_BIAS_WAIT = 5'd8;
    localparam [4:0] STATE_FC0_MAC_REQ   = 5'd9;
    localparam [4:0] STATE_FC0_MAC_WAIT  = 5'd10;
    localparam [4:0] STATE_FC0_STORE     = 5'd11;
    localparam [4:0] STATE_FC1_BIAS_REQ  = 5'd12;
    localparam [4:0] STATE_FC1_BIAS_WAIT = 5'd13;
    localparam [4:0] STATE_FC1_MAC_REQ   = 5'd14;
    localparam [4:0] STATE_FC1_MAC_WAIT  = 5'd15;
    localparam [4:0] STATE_FC1_STORE     = 5'd16;
    localparam [4:0] STATE_ARGMAX        = 5'd17;
    localparam [4:0] STATE_OUT           = 5'd18;

    reg [4:0] state;
    reg [AVG_GROUP_W-1:0] avg_group;
    reg [FC0_BASE_W-1:0] fc0_base_reg;
    reg [FC0_K_W-1:0] fc0_k;
    reg [FC1_K_W-1:0] fc1_k;

    reg signed [GAP_ACC_W-1:0] gap_latched_mem [0:FC0_IN-1];
    reg signed [GAP_ACC_W-1:0] avg_gap_group [0:AVG_LANES-1];
    reg avg_neg_group [0:AVG_LANES-1];
    reg [AVG_MAG_W-1:0] avg_abs_group [0:AVG_LANES-1];
    reg [AVG_PROD_W-1:0] avg_mul_group [0:AVG_LANES-1];
    reg [GAP_ACC_W-1:0] avg_quot_group [0:AVG_LANES-1];
    reg signed [GAP_ACC_W-1:0] avg_div_group [0:AVG_LANES-1];
    reg signed [DATA_W-1:0] avg_mem [0:FC0_IN-1];
    reg signed [DATA_W-1:0] hidden_mem [0:FC0_OUT-1];
    reg signed [DATA_W-1:0] logit_mem [0:FC1_OUT-1];

    reg signed [ACC_W-1:0] fc0_acc [0:FC0_OUT_LANES-1];
    reg signed [ACC_W-1:0] fc1_acc [0:FC1_OUT-1];

    reg signed [DATA_W-1:0] best_val;
    reg [2:0] best_idx;

    integer i;
    integer j;
    integer avg_ch;

    assign weight_req_valid = (state == STATE_FC0_BIAS_REQ)
        || (state == STATE_FC0_MAC_REQ)
        || (state == STATE_FC1_BIAS_REQ)
        || (state == STATE_FC1_MAC_REQ);
    assign weight_req_layer = (state == STATE_FC1_BIAS_REQ)
        || (state == STATE_FC1_MAC_REQ);
    assign weight_req_oc_base = weight_req_layer
        ? 7'd0
        : fc0_base_reg[6:0];
    assign weight_req_k =
        ((state == STATE_FC0_BIAS_REQ) || (state == STATE_FC1_BIAS_REQ))
            ? FC0_IN[6:0]
            : (weight_req_layer ? fc1_k[6:0] : fc0_k[6:0]);
    assign weight_vec_ready = (state == STATE_FC0_BIAS_WAIT)
        || (state == STATE_FC0_MAC_WAIT)
        || (state == STATE_FC1_BIAS_WAIT)
        || (state == STATE_FC1_MAC_WAIT);

    initial begin
        if (FC0_OUT_LANES != 16) begin
            $error("fc_classifier_96_5_compute: FC0_OUT_LANES must match the 16-lane FC ROM word");
        end
        if (FC0_IN != FC0_OUT) begin
            $error("fc_classifier_96_5_compute: this implementation assumes FC0_IN == FC0_OUT");
        end
        if (FC1_OUT > FC0_OUT_LANES) begin
            $error("fc_classifier_96_5_compute: FC1_OUT must fit in one packed ROM word");
        end
        if (AVG_LANES < 1) begin
            $error("fc_classifier_96_5_compute: AVG_LANES must be >= 1");
        end
        if (AVG_LANES > FC0_IN) begin
            $error("fc_classifier_96_5_compute: AVG_LANES must be <= FC0_IN");
        end
        if (GAP_LEN != 174) begin
            $error("fc_classifier_96_5_compute: reciprocal average constants assume GAP_LEN == 174");
        end
        if (AVG_MAG_W > GAP_ACC_W) begin
            $error("fc_classifier_96_5_compute: AVG_MAG_W must be <= GAP_ACC_W");
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            avg_group <= {AVG_GROUP_W{1'b0}};
            fc0_base_reg <= {FC0_BASE_W{1'b0}};
            fc0_k <= {FC0_K_W{1'b0}};
            fc1_k <= {FC1_K_W{1'b0}};
            busy <= 1'b0;
            done <= 1'b0;
            result_valid <= 1'b0;
            class_idx <= 3'd0;
            input_count_error <= 1'b0;
            logits_vec <= {(FC1_OUT*DATA_W){1'b0}};

            for (i = 0; i < FC0_IN; i = i + 1) begin
                gap_latched_mem[i] <= {GAP_ACC_W{1'b0}};
                avg_mem[i] <= {DATA_W{1'b0}};
            end
            for (i = 0; i < AVG_LANES; i = i + 1) begin
                avg_gap_group[i] <= {GAP_ACC_W{1'b0}};
                avg_neg_group[i] <= 1'b0;
                avg_abs_group[i] <= {AVG_MAG_W{1'b0}};
                avg_mul_group[i] <= {AVG_PROD_W{1'b0}};
                avg_quot_group[i] <= {GAP_ACC_W{1'b0}};
                avg_div_group[i] <= {GAP_ACC_W{1'b0}};
            end
            for (i = 0; i < FC0_OUT; i = i + 1) begin
                hidden_mem[i] <= {DATA_W{1'b0}};
            end
            for (i = 0; i < FC1_OUT; i = i + 1) begin
                logit_mem[i] <= {DATA_W{1'b0}};
                fc1_acc[i] <= {ACC_W{1'b0}};
            end
            for (i = 0; i < FC0_OUT_LANES; i = i + 1) begin
                fc0_acc[i] <= {ACC_W{1'b0}};
            end
        end else begin
            done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    result_valid <= 1'b0;
                    avg_group <= {AVG_GROUP_W{1'b0}};
                    fc0_base_reg <= {FC0_BASE_W{1'b0}};
                    fc0_k <= {FC0_K_W{1'b0}};
                    fc1_k <= {FC1_K_W{1'b0}};

                    if (start) begin
                        busy <= 1'b1;
                        input_count_error <= (gap_count != GAP_TARGET);
                        for (i = 0; i < FC0_IN; i = i + 1) begin
                            gap_latched_mem[i] <= $signed(
                                gap_sum_vec[i*GAP_ACC_W +: GAP_ACC_W]
                            );
                        end
                        state <= STATE_AVG_LOAD;
                    end
                end

                STATE_AVG_LOAD: begin
                    busy <= 1'b1;
                    for (j = 0; j < AVG_LANES; j = j + 1) begin
                        avg_ch = avg_group * AVG_LANES + j;
                        if (avg_ch < FC0_IN) begin
                            avg_gap_group[j] <= gap_latched_mem[avg_ch];
                        end else begin
                            avg_gap_group[j] <= {GAP_ACC_W{1'b0}};
                        end
                    end
                    state <= STATE_AVG_ABS;
                end

                STATE_AVG_ABS: begin
                    busy <= 1'b1;
                    for (j = 0; j < AVG_LANES; j = j + 1) begin
                        avg_neg_group[j] <= avg_gap_group[j][GAP_ACC_W-1];
                        avg_abs_group[j] <= abs_to_avg_mag(avg_gap_group[j]);
                    end
                    state <= STATE_AVG_MUL;
                end

                STATE_AVG_MUL: begin
                    busy <= 1'b1;
                    for (j = 0; j < AVG_LANES; j = j + 1) begin
                        avg_mul_group[j] <= {{AVG_MAG_W{1'b0}}, avg_abs_group[j]}
                            * {{AVG_MAG_W{1'b0}}, AVG_RECIP_MUL};
                    end
                    state <= STATE_AVG_SHIFT;
                end

                STATE_AVG_SHIFT: begin
                    busy <= 1'b1;
                    for (j = 0; j < AVG_LANES; j = j + 1) begin
                        avg_quot_group[j] <= avg_mul_group[j] >> AVG_RECIP_SHIFT;
                    end
                    state <= STATE_AVG_SIGN;
                end

                STATE_AVG_SIGN: begin
                    busy <= 1'b1;
                    for (j = 0; j < AVG_LANES; j = j + 1) begin
                        avg_div_group[j] <= avg_neg_group[j]
                            ? -$signed(avg_quot_group[j])
                            : $signed(avg_quot_group[j]);
                    end
                    state <= STATE_AVG_STORE;
                end

                STATE_AVG_STORE: begin
                    busy <= 1'b1;
                    for (j = 0; j < AVG_LANES; j = j + 1) begin
                        avg_ch = avg_group * AVG_LANES + j;
                        if (avg_ch < FC0_IN) begin
                            avg_mem[avg_ch] <= sat_q8_8_from_gap_avg(
                                avg_div_group[j]
                            );
                        end
                    end

                    if (avg_group == AVG_GROUPS-1) begin
                        avg_group <= {AVG_GROUP_W{1'b0}};
                        fc0_base_reg <= {FC0_BASE_W{1'b0}};
                        state <= STATE_FC0_BIAS_REQ;
                    end else begin
                        avg_group <= avg_group + 1'b1;
                        state <= STATE_AVG_LOAD;
                    end
                end

                STATE_FC0_BIAS_REQ: begin
                    busy <= 1'b1;
                    fc0_k <= {FC0_K_W{1'b0}};
                    if (weight_req_ready) begin
                        state <= STATE_FC0_BIAS_WAIT;
                    end
                end

                STATE_FC0_BIAS_WAIT: begin
                    busy <= 1'b1;
                    if (weight_vec_valid) begin
                        for (j = 0; j < FC0_OUT_LANES; j = j + 1) begin
                            if ((fc0_base_reg + j) < FC0_OUT) begin
                                fc0_acc[j] <= bias_to_acc(weight_lane(weight_vec, j));
                            end else begin
                                fc0_acc[j] <= {ACC_W{1'b0}};
                            end
                        end
                        state <= STATE_FC0_MAC_REQ;
                    end
                end

                STATE_FC0_MAC_REQ: begin
                    busy <= 1'b1;
                    if (weight_req_ready) begin
                        state <= STATE_FC0_MAC_WAIT;
                    end
                end

                STATE_FC0_MAC_WAIT: begin
                    busy <= 1'b1;
                    if (weight_vec_valid) begin
                        for (j = 0; j < FC0_OUT_LANES; j = j + 1) begin
                            if ((fc0_base_reg + j) < FC0_OUT) begin
                                fc0_acc[j] <= fc0_acc[j] + mul_to_acc(
                                    avg_mem[fc0_k],
                                    weight_lane(weight_vec, j)
                                );
                            end
                        end

                        if (fc0_k == FC0_IN-1) begin
                            fc0_k <= {FC0_K_W{1'b0}};
                            state <= STATE_FC0_STORE;
                        end else begin
                            fc0_k <= fc0_k + 1'b1;
                            state <= STATE_FC0_MAC_REQ;
                        end
                    end
                end

                STATE_FC0_STORE: begin
                    busy <= 1'b1;
                    for (j = 0; j < FC0_OUT_LANES; j = j + 1) begin
                        if ((fc0_base_reg + j) < FC0_OUT) begin
                            hidden_mem[fc0_base_reg + j] <= relu_q8_8(
                                sat_q8_8_from_acc_shift(fc0_acc[j])
                            );
                        end
                    end

                    if ((fc0_base_reg + FC0_OUT_LANES) >= FC0_OUT) begin
                        fc0_base_reg <= {FC0_BASE_W{1'b0}};
                        state <= STATE_FC1_BIAS_REQ;
                    end else begin
                        fc0_base_reg <= fc0_base_reg + FC0_OUT_LANES;
                        state <= STATE_FC0_BIAS_REQ;
                    end
                end

                STATE_FC1_BIAS_REQ: begin
                    busy <= 1'b1;
                    fc1_k <= {FC1_K_W{1'b0}};
                    if (weight_req_ready) begin
                        state <= STATE_FC1_BIAS_WAIT;
                    end
                end

                STATE_FC1_BIAS_WAIT: begin
                    busy <= 1'b1;
                    if (weight_vec_valid) begin
                        for (j = 0; j < FC1_OUT; j = j + 1) begin
                            fc1_acc[j] <= bias_to_acc(weight_lane(weight_vec, j));
                        end
                        state <= STATE_FC1_MAC_REQ;
                    end
                end

                STATE_FC1_MAC_REQ: begin
                    busy <= 1'b1;
                    if (weight_req_ready) begin
                        state <= STATE_FC1_MAC_WAIT;
                    end
                end

                STATE_FC1_MAC_WAIT: begin
                    busy <= 1'b1;
                    if (weight_vec_valid) begin
                        for (j = 0; j < FC1_OUT; j = j + 1) begin
                            fc1_acc[j] <= fc1_acc[j] + mul_to_acc(
                                hidden_mem[fc1_k],
                                weight_lane(weight_vec, j)
                            );
                        end

                        if (fc1_k == FC0_OUT-1) begin
                            fc1_k <= {FC1_K_W{1'b0}};
                            state <= STATE_FC1_STORE;
                        end else begin
                            fc1_k <= fc1_k + 1'b1;
                            state <= STATE_FC1_MAC_REQ;
                        end
                    end
                end

                STATE_FC1_STORE: begin
                    busy <= 1'b1;
                    for (j = 0; j < FC1_OUT; j = j + 1) begin
                        logit_mem[j] <= sat_q8_8_from_acc_shift(fc1_acc[j]);
                    end
                    state <= STATE_ARGMAX;
                end

                STATE_ARGMAX: begin
                    busy <= 1'b1;
                    best_val = logit_mem[0];
                    best_idx = 3'd0;
                    for (j = 1; j < FC1_OUT; j = j + 1) begin
                        if (logit_mem[j] > best_val) begin
                            best_val = logit_mem[j];
                            best_idx = j[2:0];
                        end
                    end

                    for (j = 0; j < FC1_OUT; j = j + 1) begin
                        logits_vec[j*DATA_W +: DATA_W] <= logit_mem[j];
                    end
                    class_idx <= best_idx;
                    result_valid <= 1'b1;
                    state <= STATE_OUT;
                end

                STATE_OUT: begin
                    busy <= 1'b1;
                    if (result_valid && result_ready) begin
                        result_valid <= 1'b0;
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= STATE_IDLE;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                    busy <= 1'b0;
                    result_valid <= 1'b0;
                end
            endcase
        end
    end

    function signed [DATA_W-1:0] weight_lane;
        input [FC0_OUT_LANES*DATA_W-1:0] word;
        input integer lane;
        begin
            weight_lane = word[lane*DATA_W +: DATA_W];
        end
    endfunction

    function [AVG_MAG_W-1:0] abs_to_avg_mag;
        input signed [GAP_ACC_W-1:0] value;
        reg [GAP_ACC_W-1:0] magnitude;
        begin
            if (value[GAP_ACC_W-1]) begin
                magnitude = (~value) + {{(GAP_ACC_W-1){1'b0}}, 1'b1};
            end else begin
                magnitude = value[GAP_ACC_W-1:0];
            end

            if (|magnitude[GAP_ACC_W-1:AVG_MAG_W]) begin
                abs_to_avg_mag = {AVG_MAG_W{1'b1}};
            end else begin
                abs_to_avg_mag = magnitude[AVG_MAG_W-1:0];
            end
        end
    endfunction

    function signed [ACC_W-1:0] bias_to_acc;
        input signed [DATA_W-1:0] value;
        reg signed [ACC_W-1:0] extended;
        begin
            extended = $signed({{(ACC_W-DATA_W){value[DATA_W-1]}}, value});
            bias_to_acc = extended <<< FRAC_BITS;
        end
    endfunction

    function signed [ACC_W-1:0] mul_to_acc;
        input signed [DATA_W-1:0] a;
        input signed [DATA_W-1:0] b;
        reg signed [31:0] product;
        begin
            product = a * b;
            mul_to_acc = $signed({{(ACC_W-32){product[31]}}, product});
        end
    endfunction

    function signed [DATA_W-1:0] relu_q8_8;
        input signed [DATA_W-1:0] value;
        begin
            relu_q8_8 = value[DATA_W-1] ? {DATA_W{1'b0}} : value;
        end
    endfunction

    function signed [DATA_W-1:0] sat_q8_8_from_gap_avg;
        input signed [GAP_ACC_W-1:0] value;
        begin
            if (value > $signed({1'b0, {(DATA_W-1){1'b1}}})) begin
                sat_q8_8_from_gap_avg = {1'b0, {(DATA_W-1){1'b1}}};
            end else if (value < $signed({1'b1, {(DATA_W-1){1'b0}}})) begin
                sat_q8_8_from_gap_avg = {1'b1, {(DATA_W-1){1'b0}}};
            end else begin
                sat_q8_8_from_gap_avg = value[DATA_W-1:0];
            end
        end
    endfunction

    function signed [DATA_W-1:0] sat_q8_8_from_acc_shift;
        input signed [ACC_W-1:0] value;
        reg signed [ACC_W-1:0] shifted;
        begin
            shifted = value >>> FRAC_BITS;
            if (shifted > $signed({1'b0, {(DATA_W-1){1'b1}}})) begin
                sat_q8_8_from_acc_shift = {1'b0, {(DATA_W-1){1'b1}}};
            end else if (shifted < $signed({1'b1, {(DATA_W-1){1'b0}}})) begin
                sat_q8_8_from_acc_shift = {1'b1, {(DATA_W-1){1'b0}}};
            end else begin
                sat_q8_8_from_acc_shift = shifted[DATA_W-1:0];
            end
        end
    endfunction

endmodule
