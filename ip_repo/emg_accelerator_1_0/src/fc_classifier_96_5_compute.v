`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

// LightCNN1D classifier compute core:
//   GAP Q15 requant -> embedding(96->96) -> ReLU
//   -> classifier(96->5) -> argmax
//
// This module has no weight storage. It requests one packed 16-lane weight
// word at a time from fc_weight_controller.
//
// Weight request convention:
//   layer=0, oc_base=0,16,...,80, k=0..95 embedding weight
//   layer=1, oc_base=0,            k=0..95 classifier weight
// Bias and requantization parameters are local ROM arrays initialized from
// weight_data/fc0, weight_data/fc1, and weight_data/gap.

module fc_classifier_96_5_compute #(
    parameter integer DATA_W        =  8,
    parameter integer MULT_W        = 16,
    parameter integer GAP_ACC_W     = 48,
    parameter integer ACC_W         = 48,
    parameter integer FC0_IN        = 96,
    parameter integer FC0_OUT       = 96,
    parameter integer FC1_OUT       = 5,
    parameter integer FC0_OUT_LANES = 16,
    parameter integer AVG_LANES     = 12,
    parameter integer GAP_LEN       = 174,
    parameter integer FRAC_BITS     = 8,
    parameter GAP_MULT_INIT_FILE    = {`PROJECT_ROOT, "/weight_data/gap/multiplier_q15.mem"},
    parameter GAP_SHIFT_INIT_FILE   = {`PROJECT_ROOT, "/weight_data/gap/right_shift.mem"},
    parameter FC0_BIAS_INIT_FILE    = {`PROJECT_ROOT, "/weight_data/fc0/bias_int32.mem"},
    parameter FC0_MULT_INIT_FILE    = {`PROJECT_ROOT, "/weight_data/fc0/multiplier_q15.mem"},
    parameter FC0_SHIFT_INIT_FILE   = {`PROJECT_ROOT, "/weight_data/fc0/right_shift.mem"},
    parameter FC1_BIAS_INIT_FILE    = {`PROJECT_ROOT, "/weight_data/fc1/bias_int32.mem"},
    parameter FC1_MULT_INIT_FILE    = {`PROJECT_ROOT, "/weight_data/fc1/multiplier_q15.mem"},
    parameter FC1_SHIFT_INIT_FILE   = {`PROJECT_ROOT, "/weight_data/fc1/right_shift.mem"}
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
    localparam integer FC1_K_W    = (FC0_OUT <= 1) ? 1 : $clog2(FC0_OUT + 1);
    localparam integer FC0_GROUPS = (FC0_OUT + FC0_OUT_LANES - 1) / FC0_OUT_LANES;
    localparam integer FC0_GROUP_W = (FC0_GROUPS <= 1) ? 1 : $clog2(FC0_GROUPS);

    localparam [8:0] GAP_TARGET = GAP_LEN[8:0];
    localparam [4:0] STATE_IDLE          = 5'd0;
    localparam [4:0] STATE_AVG_LOAD      = 5'd1;
    localparam [4:0] STATE_AVG_STORE     = 5'd6;
    localparam [4:0] STATE_FC0_BIAS_REQ  = 5'd7;
    localparam [4:0] STATE_FC0_ADVANCE   = 5'd8;
    localparam [4:0] STATE_FC0_MAC_REQ   = 5'd9;
    localparam [4:0] STATE_FC0_MAC_WAIT  = 5'd10;
    localparam [4:0] STATE_FC0_STORE     = 5'd11;
    localparam [4:0] STATE_FC1_BIAS_REQ  = 5'd12;
    localparam [4:0] STATE_FC1_MAC_REQ   = 5'd14;
    localparam [4:0] STATE_FC1_MAC_WAIT  = 5'd15;
    localparam [4:0] STATE_FC1_STORE     = 5'd16;
    localparam [4:0] STATE_ARGMAX        = 5'd17;
    localparam [4:0] STATE_OUT           = 5'd18;
    localparam [4:0] STATE_FC0_REQUANT   = 5'd20;
    localparam [4:0] STATE_FC1_REQUANT   = 5'd21;
    localparam [4:0] STATE_FC0_PREP      = 5'd22;

    reg [4:0] state;
    reg [AVG_GROUP_W-1:0] avg_group;
    reg [FC0_GROUP_W-1:0] fc0_group;
    reg [6:0] fc0_oc_base_reg;
    reg [6:0] fc0_oc_index [0:FC0_OUT_LANES-1];
    reg [FC0_K_W-1:0] fc0_k;
    reg [FC1_K_W-1:0] fc1_k;

    reg signed [63:0] avg_requant_product_group [0:AVG_LANES-1];
    reg [7:0] avg_requant_shift_group [0:AVG_LANES-1];
    reg signed [DATA_W-1:0] avg_mem [0:FC0_IN-1];
    reg signed [DATA_W-1:0] hidden_mem [0:FC0_OUT-1];
    reg signed [DATA_W-1:0] logit_mem [0:FC1_OUT-1];

    reg signed [ACC_W-1:0] fc0_acc [0:FC0_OUT_LANES-1];
    reg signed [ACC_W-1:0] fc1_acc [0:FC1_OUT-1];
    reg signed [63:0] fc0_requant_product [0:FC0_OUT_LANES-1];
    reg [7:0] fc0_requant_shift [0:FC0_OUT_LANES-1];
    reg signed [63:0] fc1_requant_product [0:FC1_OUT-1];
    reg [7:0] fc1_requant_shift [0:FC1_OUT-1];
    reg signed [MULT_W-1:0] gap_multiplier_q15_mem [0:0];
    reg [7:0] gap_right_shift_mem [0:0];
    reg signed [31:0] fc0_bias_int32_mem [0:FC0_OUT-1];
    reg signed [MULT_W-1:0] fc0_multiplier_q15_mem [0:FC0_OUT-1];
    reg [7:0] fc0_right_shift_mem [0:FC0_OUT-1];
    reg signed [31:0] fc1_bias_int32_mem [0:FC1_OUT-1];
    reg signed [MULT_W-1:0] fc1_multiplier_q15_mem [0:FC1_OUT-1];
    reg [7:0] fc1_right_shift_mem [0:FC1_OUT-1];

    reg signed [DATA_W-1:0] best_val;
    reg [2:0] best_idx;

    integer i;
    integer j;
    integer avg_ch;

    assign weight_req_valid = (state == STATE_FC0_MAC_REQ)
        || (state == STATE_FC1_MAC_REQ);
    assign weight_req_layer = (state == STATE_FC1_MAC_REQ)
        || (state == STATE_FC1_MAC_WAIT);
    assign weight_req_oc_base = weight_req_layer
        ? 7'd0
        : fc0_oc_base_reg;
    assign weight_req_k = weight_req_layer ? fc1_k[6:0] : fc0_k[6:0];
    assign weight_vec_ready = (state == STATE_FC0_MAC_WAIT)
        || (state == STATE_FC1_MAC_WAIT);

    initial begin
        $readmemh(GAP_MULT_INIT_FILE, gap_multiplier_q15_mem);
        $readmemh(GAP_SHIFT_INIT_FILE, gap_right_shift_mem);
        $readmemh(FC0_BIAS_INIT_FILE, fc0_bias_int32_mem);
        $readmemh(FC0_MULT_INIT_FILE, fc0_multiplier_q15_mem);
        $readmemh(FC0_SHIFT_INIT_FILE, fc0_right_shift_mem);
        $readmemh(FC1_BIAS_INIT_FILE, fc1_bias_int32_mem);
        $readmemh(FC1_MULT_INIT_FILE, fc1_multiplier_q15_mem);
        $readmemh(FC1_SHIFT_INIT_FILE, fc1_right_shift_mem);
        if (FC0_OUT_LANES != 16) begin
            $error("fc_classifier_96_5_compute: FC0_OUT_LANES must match the 16-lane FC ROM word");
        end
        if (FC0_IN != FC0_OUT) begin
            $error("fc_classifier_96_5_compute: this implementation assumes FC0_IN == FC0_OUT");
        end
        if ((FC0_OUT % FC0_OUT_LANES) != 0) begin
            $error("fc_classifier_96_5_compute: FC0_OUT must be divisible by FC0_OUT_LANES");
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
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            avg_group <= {AVG_GROUP_W{1'b0}};
            fc0_group <= {FC0_GROUP_W{1'b0}};
            fc0_oc_base_reg <= 7'd0;
            fc0_k <= {FC0_K_W{1'b0}};
            fc1_k <= {FC1_K_W{1'b0}};
            busy <= 1'b0;
            done <= 1'b0;
            result_valid <= 1'b0;
            class_idx <= 3'd0;
            input_count_error <= 1'b0;
            logits_vec <= {(FC1_OUT*DATA_W){1'b0}};

            for (i = 0; i < FC0_IN; i = i + 1) begin
                avg_mem[i] <= {DATA_W{1'b0}};
            end
            for (i = 0; i < AVG_LANES; i = i + 1) begin
                avg_requant_product_group[i] <= 64'sd0;
                avg_requant_shift_group[i] <= 8'd0;
            end
            for (i = 0; i < FC0_OUT; i = i + 1) begin
                hidden_mem[i] <= {DATA_W{1'b0}};
            end
            for (i = 0; i < FC1_OUT; i = i + 1) begin
                logit_mem[i] <= {DATA_W{1'b0}};
                fc1_acc[i] <= {ACC_W{1'b0}};
                fc1_requant_product[i] <= 64'sd0;
                fc1_requant_shift[i] <= 8'd0;
            end
            for (i = 0; i < FC0_OUT_LANES; i = i + 1) begin
                fc0_oc_index[i] <= 7'd0;
                fc0_acc[i] <= {ACC_W{1'b0}};
                fc0_requant_product[i] <= 64'sd0;
                fc0_requant_shift[i] <= 8'd0;
            end
        end else begin
            done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    result_valid <= 1'b0;
                    avg_group <= {AVG_GROUP_W{1'b0}};
                    fc0_group <= {FC0_GROUP_W{1'b0}};
                    fc0_oc_base_reg <= 7'd0;
                    fc0_k <= {FC0_K_W{1'b0}};
                    fc1_k <= {FC1_K_W{1'b0}};

                    if (start) begin
                        busy <= 1'b1;
                        input_count_error <= (gap_count != GAP_TARGET);
                        state <= STATE_AVG_LOAD;
                    end
                end

                STATE_AVG_LOAD: begin
                    busy <= 1'b1;
                    for (j = 0; j < AVG_LANES; j = j + 1) begin
                        avg_ch = avg_group * AVG_LANES + j;
                        if (avg_ch < FC0_IN) begin
                            avg_requant_product_group[j]
                                <= $signed(gap_sum_vec[avg_ch*GAP_ACC_W +: GAP_ACC_W])
                                 * $signed(gap_multiplier_q15_mem[0]);
                        end else begin
                            avg_requant_product_group[j] <= 64'sd0;
                        end
                        avg_requant_shift_group[j] <= gap_right_shift_mem[0];
                    end
                    state <= STATE_AVG_STORE;
                end

                STATE_AVG_STORE: begin
                    busy <= 1'b1;
                    for (j = 0; j < AVG_LANES; j = j + 1) begin
                        avg_ch = avg_group * AVG_LANES + j;
                        if (avg_ch < FC0_IN) begin
                            avg_mem[avg_ch] <= saturate_int8(
                                requant_product_q15(
                                    avg_requant_product_group[j],
                                    avg_requant_shift_group[j]
                                )
                            );
                        end
                    end

                    if (avg_group == AVG_GROUPS-1) begin
                        avg_group <= {AVG_GROUP_W{1'b0}};
                        fc0_group <= {FC0_GROUP_W{1'b0}};
                        state <= STATE_FC0_PREP;
                    end else begin
                        avg_group <= avg_group + 1'b1;
                        state <= STATE_AVG_LOAD;
                    end
                end

                STATE_FC0_PREP: begin
                    busy <= 1'b1;
                    fc0_oc_base_reg <= fc0_group_base(fc0_group);
                    for (j = 0; j < FC0_OUT_LANES; j = j + 1) begin
                        fc0_oc_index[j] <= fc0_group_base(fc0_group) + j[6:0];
                    end
                    state <= STATE_FC0_BIAS_REQ;
                end

                STATE_FC0_BIAS_REQ: begin
                    busy <= 1'b1;
                    fc0_k <= {FC0_K_W{1'b0}};
                    for (j = 0; j < FC0_OUT_LANES; j = j + 1) begin
                        fc0_acc[j] <= $signed({
                            {(ACC_W-32){fc0_bias_int32_mem[fc0_oc_index[j]][31]}},
                            fc0_bias_int32_mem[fc0_oc_index[j]]
                        });
                    end
                    state <= STATE_FC0_MAC_REQ;
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
                            fc0_acc[j] <= fc0_acc[j] + mul_to_acc(
                                avg_mem[fc0_k],
                                weight_lane(weight_vec, j)
                            );
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
                        fc0_requant_product[j]
                            <= $signed(fc0_acc[j])
                             * $signed(fc0_multiplier_q15_mem[fc0_oc_index[j]]);
                        fc0_requant_shift[j]
                            <= fc0_right_shift_mem[fc0_oc_index[j]];
                    end
                    state <= STATE_FC0_REQUANT;
                end

                STATE_FC0_REQUANT: begin
                    busy <= 1'b1;
                    for (j = 0; j < FC0_OUT_LANES; j = j + 1) begin
                        hidden_mem[fc0_oc_index[j]] <= relu_int8(
                            saturate_int8(
                                requant_product_q15(
                                    fc0_requant_product[j],
                                    fc0_requant_shift[j]
                                )
                            )
                        );
                    end
                    state <= STATE_FC0_ADVANCE;
                end

                STATE_FC0_ADVANCE: begin
                    busy <= 1'b1;
                    if (fc0_group == FC0_GROUPS-1) begin
                        fc0_group <= {FC0_GROUP_W{1'b0}};
                        state <= STATE_FC1_BIAS_REQ;
                    end else begin
                        fc0_group <= fc0_group + 1'b1;
                        state <= STATE_FC0_PREP;
                    end
                end

                STATE_FC1_BIAS_REQ: begin
                    busy <= 1'b1;
                    fc1_k <= {FC1_K_W{1'b0}};
                    for (j = 0; j < FC1_OUT; j = j + 1) begin
                        fc1_acc[j] <= $signed({
                            {(ACC_W-32){fc1_bias_int32_mem[j][31]}},
                            fc1_bias_int32_mem[j]
                        });
                    end
                    state <= STATE_FC1_MAC_REQ;
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
                        fc1_requant_product[j]
                            <= $signed(fc1_acc[j])
                             * $signed(fc1_multiplier_q15_mem[j]);
                        fc1_requant_shift[j] <= fc1_right_shift_mem[j];
                    end
                    state <= STATE_FC1_REQUANT;
                end

                STATE_FC1_REQUANT: begin
                    busy <= 1'b1;
                    for (j = 0; j < FC1_OUT; j = j + 1) begin
                        logit_mem[j] <= saturate_int8(
                            requant_product_q15(
                                fc1_requant_product[j],
                                fc1_requant_shift[j]
                            )
                        );
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

    function [6:0] fc0_group_base;
        input [FC0_GROUP_W-1:0] group_i;
        begin
            fc0_group_base = group_i * FC0_OUT_LANES;
        end
    endfunction

    function integer fc0_index;
        input [FC0_GROUP_W-1:0] group_i;
        input integer lane_i;
        begin
            fc0_index = fc0_group_base(group_i) + lane_i;
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

    function signed [DATA_W-1:0] saturate_int8;
        input signed [ACC_W-1:0] value;
        begin
            if (value > 127) begin
                saturate_int8 = 8'sh7F;
            end else if (value < -127) begin
                saturate_int8 = -8'sd127;
            end else begin
                saturate_int8 = value[DATA_W-1:0];
            end
        end
    endfunction

    function signed [ACC_W-1:0] requant_product_q15;
        input signed [63:0] product;
        input [7:0] shift;
        reg [63:0] magnitude;
        reg [63:0] rounded_mag;
        reg [63:0] round_offset;
        reg signed [63:0] rounded;
        begin
            magnitude = product[63] ? (~product + 64'd1) : product;
            round_offset = (shift == 0) ? 64'd0 : (64'd1 << (shift - 1));
            rounded_mag = (magnitude + round_offset) >> shift;
            rounded = product[63] ? -$signed(rounded_mag) : $signed(rounded_mag);
            requant_product_q15 = rounded[ACC_W-1:0];
        end
    endfunction

    function signed [DATA_W-1:0] relu_int8;
        input signed [DATA_W-1:0] value;
        begin
            relu_int8 = value[DATA_W-1] ? {DATA_W{1'b0}} : value;
        end
    endfunction

endmodule
