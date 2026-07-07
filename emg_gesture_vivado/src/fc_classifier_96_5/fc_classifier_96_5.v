`timescale 1ns / 1ps

// LightCNN1D classifier tail:
//   GAP(sum/174) -> FC0(96->96) -> ReLU -> FC1(96->5) -> argmax
//
// Input is the 96-channel GAP accumulator exported by pw_conv2_array_4x12.
// Each channel is divided by GAP_LEN before entering FC0. FC weights include
// bias as the last k entry:
//   FC0 weight k=0..95 are data weights, k=96 is bias
//   FC1 weight k=0..95 are hidden weights, k=96 is bias
//
// Compute organization:
//   FC0: FC0_OUT_LANES output neurons in parallel, input broadcast.
//        Default 16 lanes -> 6 groups x 96 MAC cycles.
//   FC1: all 5 output classes in parallel, hidden activation broadcast.
//        Default 5 lanes -> 96 MAC cycles.

module fc_classifier_96_5 #(
    parameter integer DATA_W        = 16,
    parameter integer GAP_ACC_W     = 48,
    parameter integer ACC_W         = 48,
    parameter integer FC0_IN        = 96,
    parameter integer FC0_OUT       = 96,
    parameter integer FC1_OUT       = 5,
    parameter integer FC0_OUT_LANES = 16,
    parameter integer GAP_LEN       = 174,
    parameter integer FRAC_BITS     = 8
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire [8:0] gap_count,
    input  wire signed [FC0_IN*GAP_ACC_W-1:0] gap_sum_vec,

    input  wire fc0_weight_we,
    input  wire [6:0] fc0_weight_out,
    input  wire [6:0] fc0_weight_k,
    input  wire signed [DATA_W-1:0] fc0_weight_wdata,

    input  wire fc1_weight_we,
    input  wire [2:0] fc1_weight_out,
    input  wire [6:0] fc1_weight_k,
    input  wire signed [DATA_W-1:0] fc1_weight_wdata,

    input  wire result_ready,
    output reg busy,
    output reg done,
    output reg result_valid,
    output reg [2:0] class_idx,
    output reg input_count_error,
    output reg signed [FC1_OUT*DATA_W-1:0] logits_vec
);

    localparam integer FC0_GROUPS = (FC0_OUT + FC0_OUT_LANES - 1) / FC0_OUT_LANES;
    localparam integer AVG_W      = (FC0_IN <= 1) ? 1 : $clog2(FC0_IN + 1);
    localparam integer FC0_K_W    = (FC0_IN <= 1) ? 1 : $clog2(FC0_IN + 1);
    localparam integer FC0_BASE_W = (FC0_OUT <= 1) ? 1 : $clog2(FC0_OUT + 1);
    localparam integer FC1_K_W    = (FC0_OUT <= 1) ? 1 : $clog2(FC0_OUT + 1);

    localparam signed [GAP_ACC_W-1:0] GAP_DIVISOR = GAP_LEN;
    localparam [8:0] GAP_TARGET = GAP_LEN[8:0];

    localparam [3:0] STATE_IDLE      = 4'd0;
    localparam [3:0] STATE_AVG       = 4'd1;
    localparam [3:0] STATE_FC0_INIT  = 4'd2;
    localparam [3:0] STATE_FC0_MAC   = 4'd3;
    localparam [3:0] STATE_FC0_STORE = 4'd4;
    localparam [3:0] STATE_FC1_INIT  = 4'd5;
    localparam [3:0] STATE_FC1_MAC   = 4'd6;
    localparam [3:0] STATE_FC1_STORE = 4'd7;
    localparam [3:0] STATE_ARGMAX    = 4'd8;
    localparam [3:0] STATE_OUT       = 4'd9;

    reg [3:0] state;
    reg [AVG_W-1:0] avg_index;
    reg [FC0_BASE_W-1:0] fc0_base_reg;
    reg [FC0_K_W-1:0] fc0_k;
    reg [FC1_K_W-1:0] fc1_k;

    reg signed [GAP_ACC_W-1:0] gap_latched_mem [0:FC0_IN-1];
    reg signed [DATA_W-1:0] avg_mem [0:FC0_IN-1];
    reg signed [DATA_W-1:0] hidden_mem [0:FC0_OUT-1];
    reg signed [DATA_W-1:0] logit_mem [0:FC1_OUT-1];

    reg signed [DATA_W-1:0] fc0_weight_mem [0:FC0_OUT-1][0:FC0_IN];
    reg signed [DATA_W-1:0] fc1_weight_mem [0:FC1_OUT-1][0:FC0_OUT];

    reg signed [ACC_W-1:0] fc0_acc [0:FC0_OUT_LANES-1];
    reg signed [ACC_W-1:0] fc1_acc [0:FC1_OUT-1];

    reg signed [DATA_W-1:0] best_val;
    reg [2:0] best_idx;

    integer i;
    integer j;

    wire weight_write_en;
    assign weight_write_en = (state == STATE_IDLE) && !start;

    always @(posedge clk) begin
        if (weight_write_en && fc0_weight_we
            && (fc0_weight_out < FC0_OUT)
            && (fc0_weight_k <= FC0_IN)) begin
            fc0_weight_mem[fc0_weight_out][fc0_weight_k] <= fc0_weight_wdata;
        end

        if (weight_write_en && fc1_weight_we
            && (fc1_weight_out < FC1_OUT)
            && (fc1_weight_k <= FC0_OUT)) begin
            fc1_weight_mem[fc1_weight_out][fc1_weight_k] <= fc1_weight_wdata;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            avg_index <= {AVG_W{1'b0}};
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
                    avg_index <= {AVG_W{1'b0}};
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
                        state <= STATE_AVG;
                    end
                end

                STATE_AVG: begin
                    busy <= 1'b1;
                    avg_mem[avg_index] <= sat_q8_8_from_gap_avg(
                        gap_latched_mem[avg_index] / GAP_DIVISOR
                    );
                    if (avg_index == FC0_IN-1) begin
                        avg_index <= {AVG_W{1'b0}};
                        fc0_base_reg <= {FC0_BASE_W{1'b0}};
                        state <= STATE_FC0_INIT;
                    end else begin
                        avg_index <= avg_index + 1'b1;
                    end
                end

                STATE_FC0_INIT: begin
                    busy <= 1'b1;
                    fc0_k <= {FC0_K_W{1'b0}};
                    for (j = 0; j < FC0_OUT_LANES; j = j + 1) begin
                        if ((fc0_base_reg + j) < FC0_OUT) begin
                            fc0_acc[j] <= bias_to_acc(
                                fc0_weight_mem[fc0_base_reg + j][FC0_IN]
                            );
                        end else begin
                            fc0_acc[j] <= {ACC_W{1'b0}};
                        end
                    end
                    state <= STATE_FC0_MAC;
                end

                STATE_FC0_MAC: begin
                    busy <= 1'b1;
                    for (j = 0; j < FC0_OUT_LANES; j = j + 1) begin
                        if ((fc0_base_reg + j) < FC0_OUT) begin
                            fc0_acc[j] <= fc0_acc[j] + mul_to_acc(
                                avg_mem[fc0_k],
                                fc0_weight_mem[fc0_base_reg + j][fc0_k]
                            );
                        end
                    end

                    if (fc0_k == FC0_IN-1) begin
                        fc0_k <= {FC0_K_W{1'b0}};
                        state <= STATE_FC0_STORE;
                    end else begin
                        fc0_k <= fc0_k + 1'b1;
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
                        state <= STATE_FC1_INIT;
                    end else begin
                        fc0_base_reg <= fc0_base_reg + FC0_OUT_LANES[FC0_BASE_W-1:0];
                        state <= STATE_FC0_INIT;
                    end
                end

                STATE_FC1_INIT: begin
                    busy <= 1'b1;
                    fc1_k <= {FC1_K_W{1'b0}};
                    for (j = 0; j < FC1_OUT; j = j + 1) begin
                        fc1_acc[j] <= bias_to_acc(fc1_weight_mem[j][FC0_OUT]);
                    end
                    state <= STATE_FC1_MAC;
                end

                STATE_FC1_MAC: begin
                    busy <= 1'b1;
                    for (j = 0; j < FC1_OUT; j = j + 1) begin
                        fc1_acc[j] <= fc1_acc[j] + mul_to_acc(
                            hidden_mem[fc1_k],
                            fc1_weight_mem[j][fc1_k]
                        );
                    end

                    if (fc1_k == FC0_OUT-1) begin
                        fc1_k <= {FC1_K_W{1'b0}};
                        state <= STATE_FC1_STORE;
                    end else begin
                        fc1_k <= fc1_k + 1'b1;
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
