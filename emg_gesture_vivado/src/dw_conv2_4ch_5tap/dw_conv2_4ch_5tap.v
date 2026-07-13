`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

// LightCNN1D DW2 depthwise Conv1d compute unit.
//
// DW2 consumes the low-resolution stream produced by PW1 + MaxPool:
//   64 channels, INPUT_LEN=174, kernel=5, padding=2
//
// One start pulse processes two 4-channel groups for the output time range that
// becomes computable after a newly written pool chunk. This matches one PW1
// output tile, which produces 2 low-resolution rows x 8 channels:
//   group 0: ch_base
//   group 1: ch_base + 4
// Output order is all computable time rows for group 0, then all computable
// time rows for group 1.
//
// Typical pool-chunk boundary behavior for input_rows=2:
//   input_t_base = 0,   final_chunk = 0 -> no output rows
//   input_t_base = 2,   final_chunk = 0 -> out_t 0..1
//   middle base B,      final_chunk = 0 -> out_t B-2..B-1
//   input_t_base = 172, final_chunk = 1 -> out_t 170..173
//
// The upstream pool_to_dw2 window loader returns a full 5-tap window for one
// output time and 4 channels:
//   win_vec[(tap*P_CH + lane)] = X[out_t + tap - PAD][ch_base + lane]
// It inserts zeros for padding positions and only asserts win_vec_valid when
// the requested window is available. The request/response contract is one
// outstanding request at most, matching dw_conv1_4ch_5tap.
//
// The downstream dw2_to_pw2 writer should use:
//   buffer[out_t][out_ch_base + lane] <= out_vec[lane]
// and mark that channel-group valid for out_t. PW2 can start once four
// consecutive low-resolution rows have all 64 channels valid. The final two
// rows are handled by the later PW2 partial-flush valid mask.

module dw_conv2_4ch_5tap #(
    parameter integer DATA_W     = 16,
    parameter integer ACC_W      = 48,
    parameter integer CHANNELS   = 64,
    parameter integer P_CH       = 4,
    parameter integer K          = 5,
    parameter integer PAD        = 2,
    parameter integer INPUT_LEN  = 174,
    parameter integer FRAC_BITS  = 8,
    parameter integer TIME_W     = 8,
    parameter integer ROWS_W     = 3,
    parameter WEIGHT_INIT_FILE   = {`PROJECT_ROOT, "/weight_data/dw2/weight.mem"}
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire [5:0] ch_base,
    input  wire [TIME_W-1:0] input_t_base,
    input  wire [ROWS_W-1:0] input_rows,
    input  wire final_chunk,

    output wire win_req_valid,
    output wire [TIME_W-1:0] win_req_out_t,
    output wire [5:0] win_req_ch_base,
    input  wire win_req_ready,
    input  wire win_vec_valid,
    output wire win_vec_ready,
    input  wire signed [K*P_CH*DATA_W-1:0] win_vec,

    input  wire weight_we,
    input  wire [5:0] weight_ch,
    input  wire [2:0] weight_tap,
    input  wire signed [DATA_W-1:0] weight_wdata,

    input  wire out_ready,
    output reg busy,
    output reg done,
    output wire out_valid,
    output wire [TIME_W-1:0] out_t,
    output wire [5:0] out_ch_base,
    output wire signed [P_CH*DATA_W-1:0] out_vec,

    output reg [TIME_W-1:0] job_out_t_start,
    output reg [TIME_W:0] job_out_count
);

    localparam [1:0] CH_GROUPS_PER_JOB = 2'd2;
    localparam [5:0] P_CH_STEP = P_CH;

    localparam [1:0] STATE_IDLE = 2'd0;
    localparam [1:0] STATE_RUN  = 2'd1;

    reg [1:0] state;
    reg [5:0] ch_base_reg;
    reg [TIME_W:0] req_count;
    reg [TIME_W:0] resp_count;
    reg [1:0] req_group_idx;
    reg [1:0] resp_group_idx;
    reg outstanding;

    reg signed [DATA_W-1:0] weight_mem [0:CHANNELS*K-1];
    reg [TIME_W-1:0] fifo_t [0:1];
    reg [5:0] fifo_ch_base [0:1];
    reg signed [P_CH*DATA_W-1:0] fifo_vec [0:1];
    reg [1:0] fifo_count;

    wire out_fire;
    wire fifo_push;
    wire fifo_has_space;
    wire pipe_advance;
    wire pipe_out_fire;
    wire weight_write_en;
    wire win_req_fire;
    wire win_vec_fire;
    wire can_accept_resp;
    wire [TIME_W-1:0] current_req_out_t;
    wire [TIME_W-1:0] current_resp_out_t;
    wire [5:0] current_req_ch_base;
    wire [5:0] current_resp_ch_base;

    reg s0_valid;
    reg [TIME_W-1:0] s0_t;
    reg [5:0] s0_ch_base;
    reg signed [DATA_W-1:0] s0_x [0:K-1][0:P_CH-1];
    reg signed [DATA_W-1:0] s0_w [0:K-1][0:P_CH-1];

    reg s1_valid;
    reg [TIME_W-1:0] s1_t;
    reg [5:0] s1_ch_base;
    reg signed [31:0] s1_p [0:K-1][0:P_CH-1];

    reg s2_valid;
    reg [TIME_W-1:0] s2_t;
    reg [5:0] s2_ch_base;
    reg signed [P_CH*DATA_W-1:0] s2_vec;

    integer pipe_tap;
    integer pipe_lane;
    reg signed [ACC_W-1:0] pipe_acc;

    assign out_fire = out_valid && out_ready;
    assign fifo_push = pipe_out_fire;
    assign fifo_has_space = (fifo_count != 2'd2) || out_fire;
    assign pipe_advance = !s2_valid || fifo_has_space;
    assign pipe_out_fire = s2_valid && fifo_has_space;
    assign weight_write_en = weight_we && (state == STATE_IDLE) && !start;
    assign current_req_out_t = job_out_t_start + req_count[TIME_W-1:0];
    assign current_resp_out_t = job_out_t_start + resp_count[TIME_W-1:0];
    assign current_req_ch_base = ch_base_reg
        + (req_group_idx == 2'd0 ? 6'd0 : P_CH_STEP);
    assign current_resp_ch_base = ch_base_reg
        + (resp_group_idx == 2'd0 ? 6'd0 : P_CH_STEP);

    assign out_valid = (fifo_count != 2'd0);
    assign out_t = fifo_t[0];
    assign out_ch_base = fifo_ch_base[0];
    assign out_vec = fifo_vec[0];

    assign win_req_valid = (state == STATE_RUN)
        && (job_out_count != 0)
        && (req_group_idx < CH_GROUPS_PER_JOB)
        && !outstanding
        && pipe_advance;
    assign win_req_out_t = current_req_out_t;
    assign win_req_ch_base = current_req_ch_base;
    assign win_req_fire = win_req_valid && win_req_ready;

    assign can_accept_resp = (state == STATE_RUN)
        && (job_out_count != 0)
        && (resp_group_idx < CH_GROUPS_PER_JOB)
        && (outstanding || win_req_fire)
        && pipe_advance;
    assign win_vec_ready = can_accept_resp;
    assign win_vec_fire = win_vec_valid && win_vec_ready;

    initial begin
        $readmemh(WEIGHT_INIT_FILE, weight_mem);
    end

    always @(posedge clk) begin
        if (weight_write_en) begin
            weight_mem[weight_ch*K + weight_tap] <= weight_wdata;
        end
    end

    function [TIME_W-1:0] calc_out_start;
        input [TIME_W-1:0] base;
        begin
            if (base < PAD) begin
                calc_out_start = {TIME_W{1'b0}};
            end else begin
                calc_out_start = base - PAD[TIME_W-1:0];
            end
        end
    endfunction

    function [TIME_W:0] calc_out_count;
        input [TIME_W-1:0] base;
        input [ROWS_W-1:0] rows;
        input is_final;
        integer start_i;
        integer last_i;
        begin
            if (base < PAD) begin
                start_i = 0;
            end else begin
                start_i = base - PAD;
            end

            if (is_final) begin
                last_i = INPUT_LEN - 1;
            end else begin
                last_i = base + rows - 1 - PAD;
            end

            if ((rows == 0) || (last_i < start_i)) begin
                calc_out_count = {(TIME_W+1){1'b0}};
            end else begin
                calc_out_count = last_i - start_i + 1;
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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            ch_base_reg <= 6'd0;
            req_count <= {(TIME_W+1){1'b0}};
            resp_count <= {(TIME_W+1){1'b0}};
            req_group_idx <= 2'd0;
            resp_group_idx <= 2'd0;
            outstanding <= 1'b0;
            fifo_t[0] <= {TIME_W{1'b0}};
            fifo_t[1] <= {TIME_W{1'b0}};
            fifo_ch_base[0] <= 6'd0;
            fifo_ch_base[1] <= 6'd0;
            fifo_vec[0] <= {(P_CH*DATA_W){1'b0}};
            fifo_vec[1] <= {(P_CH*DATA_W){1'b0}};
            fifo_count <= 2'd0;
            s0_valid <= 1'b0;
            s0_t <= {TIME_W{1'b0}};
            s0_ch_base <= 6'd0;
            s1_valid <= 1'b0;
            s1_t <= {TIME_W{1'b0}};
            s1_ch_base <= 6'd0;
            s2_valid <= 1'b0;
            s2_t <= {TIME_W{1'b0}};
            s2_ch_base <= 6'd0;
            s2_vec <= {(P_CH*DATA_W){1'b0}};
            busy <= 1'b0;
            done <= 1'b0;
            job_out_t_start <= {TIME_W{1'b0}};
            job_out_count <= {(TIME_W+1){1'b0}};
        end else begin
            done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    req_count <= {(TIME_W+1){1'b0}};
                    resp_count <= {(TIME_W+1){1'b0}};
                    req_group_idx <= 2'd0;
                    resp_group_idx <= 2'd0;
                    outstanding <= 1'b0;
                    fifo_count <= 2'd0;
                    s0_valid <= 1'b0;
                    s1_valid <= 1'b0;
                    s2_valid <= 1'b0;

                    if (start) begin
                        ch_base_reg <= ch_base;
                        job_out_t_start <= calc_out_start(input_t_base);
                        job_out_count <= calc_out_count(
                            input_t_base,
                            input_rows,
                            final_chunk
                        );
                        busy <= 1'b1;
                        state <= STATE_RUN;
                    end
                end

                STATE_RUN: begin
                    busy <= 1'b1;

                    if (win_req_fire && !win_vec_fire) begin
                        outstanding <= 1'b1;
                    end else if (!win_req_fire && win_vec_fire) begin
                        outstanding <= 1'b0;
                    end

                    if (win_req_fire) begin
                        if (req_count == (job_out_count - 1'b1)) begin
                            req_count <= {(TIME_W+1){1'b0}};
                            req_group_idx <= req_group_idx + 1'b1;
                        end else begin
                            req_count <= req_count + 1'b1;
                        end
                    end

                    if (win_vec_fire) begin
                        if (resp_count == (job_out_count - 1'b1)) begin
                            resp_count <= {(TIME_W+1){1'b0}};
                            resp_group_idx <= resp_group_idx + 1'b1;
                        end else begin
                            resp_count <= resp_count + 1'b1;
                        end
                    end

                    case ({out_fire, fifo_push})
                        2'b01: begin
                            if (fifo_count == 2'd0) begin
                                fifo_t[0] <= s2_t;
                                fifo_ch_base[0] <= s2_ch_base;
                                fifo_vec[0] <= s2_vec;
                                fifo_count <= 2'd1;
                            end else if (fifo_count == 2'd1) begin
                                fifo_t[1] <= s2_t;
                                fifo_ch_base[1] <= s2_ch_base;
                                fifo_vec[1] <= s2_vec;
                                fifo_count <= 2'd2;
                            end
                        end

                        2'b10: begin
                            if (fifo_count == 2'd2) begin
                                fifo_t[0] <= fifo_t[1];
                                fifo_ch_base[0] <= fifo_ch_base[1];
                                fifo_vec[0] <= fifo_vec[1];
                                fifo_count <= 2'd1;
                            end else begin
                                fifo_count <= 2'd0;
                            end
                        end

                        2'b11: begin
                            if (fifo_count == 2'd2) begin
                                fifo_t[0] <= fifo_t[1];
                                fifo_ch_base[0] <= fifo_ch_base[1];
                                fifo_vec[0] <= fifo_vec[1];
                                fifo_t[1] <= s2_t;
                                fifo_ch_base[1] <= s2_ch_base;
                                fifo_vec[1] <= s2_vec;
                                fifo_count <= 2'd2;
                            end else begin
                                fifo_t[0] <= s2_t;
                                fifo_ch_base[0] <= s2_ch_base;
                                fifo_vec[0] <= s2_vec;
                                fifo_count <= 2'd1;
                            end
                        end

                        default: begin
                            fifo_count <= fifo_count;
                        end
                    endcase

                    if (pipe_advance) begin
                        s2_valid <= s1_valid;
                        s2_t <= s1_t;
                        s2_ch_base <= s1_ch_base;
                        for (pipe_lane = 0; pipe_lane < P_CH; pipe_lane = pipe_lane + 1) begin
                            pipe_acc = {ACC_W{1'b0}};
                            for (pipe_tap = 0; pipe_tap < K; pipe_tap = pipe_tap + 1) begin
                                pipe_acc = pipe_acc + $signed({
                                    {(ACC_W-32){s1_p[pipe_tap][pipe_lane][31]}},
                                    s1_p[pipe_tap][pipe_lane]
                                });
                            end
                            s2_vec[pipe_lane*DATA_W +: DATA_W]
                                <= sat_q8_8_from_acc_shift(pipe_acc);
                        end

                        s1_valid <= s0_valid;
                        s1_t <= s0_t;
                        s1_ch_base <= s0_ch_base;
                        for (pipe_tap = 0; pipe_tap < K; pipe_tap = pipe_tap + 1) begin
                            for (pipe_lane = 0; pipe_lane < P_CH; pipe_lane = pipe_lane + 1) begin
                                s1_p[pipe_tap][pipe_lane]
                                    <= $signed(s0_x[pipe_tap][pipe_lane])
                                     * $signed(s0_w[pipe_tap][pipe_lane]);
                            end
                        end

                        s0_valid <= win_vec_fire;
                        if (win_vec_fire) begin
                            s0_t <= current_resp_out_t;
                            s0_ch_base <= current_resp_ch_base;
                            for (pipe_tap = 0; pipe_tap < K; pipe_tap = pipe_tap + 1) begin
                                for (pipe_lane = 0; pipe_lane < P_CH; pipe_lane = pipe_lane + 1) begin
                                    s0_x[pipe_tap][pipe_lane]
                                        <= win_vec[(pipe_tap*P_CH + pipe_lane)*DATA_W +: DATA_W];
                                    s0_w[pipe_tap][pipe_lane]
                                        <= weight_mem[(current_resp_ch_base + pipe_lane)*K + pipe_tap];
                                end
                            end
                        end
                    end

                    if (((job_out_count == 0)
                        || ((req_group_idx == CH_GROUPS_PER_JOB)
                            && (resp_group_idx == CH_GROUPS_PER_JOB)))
                        && !outstanding
                        && !s0_valid
                        && !s1_valid
                        && !s2_valid
                        && (fifo_count == 2'd0)) begin
                        busy <= 1'b0;
                        done <= 1'b1;
                        state <= STATE_IDLE;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                    busy <= 1'b0;
                    fifo_count <= 2'd0;
                    s0_valid <= 1'b0;
                    s1_valid <= 1'b0;
                    s2_valid <= 1'b0;
                end
            endcase
        end
    end

endmodule

module dw_conv2_lane_5tap #(
    parameter integer DATA_W    = 16,
    parameter integer ACC_W     = 48,
    parameter integer FRAC_BITS = 8
) (
    input  wire signed [DATA_W-1:0] x0,
    input  wire signed [DATA_W-1:0] x1,
    input  wire signed [DATA_W-1:0] x2,
    input  wire signed [DATA_W-1:0] x3,
    input  wire signed [DATA_W-1:0] x4,
    input  wire signed [DATA_W-1:0] w0,
    input  wire signed [DATA_W-1:0] w1,
    input  wire signed [DATA_W-1:0] w2,
    input  wire signed [DATA_W-1:0] w3,
    input  wire signed [DATA_W-1:0] w4,
    output wire signed [DATA_W-1:0] y
);

    (* use_dsp = "yes" *) wire signed [31:0] p0;
    (* use_dsp = "yes" *) wire signed [31:0] p1;
    (* use_dsp = "yes" *) wire signed [31:0] p2;
    (* use_dsp = "yes" *) wire signed [31:0] p3;
    (* use_dsp = "yes" *) wire signed [31:0] p4;

    wire signed [ACC_W-1:0] sum;

    assign p0 = $signed(x0) * $signed(w0);
    assign p1 = $signed(x1) * $signed(w1);
    assign p2 = $signed(x2) * $signed(w2);
    assign p3 = $signed(x3) * $signed(w3);
    assign p4 = $signed(x4) * $signed(w4);

    assign sum =
        $signed({{(ACC_W-32){p0[31]}}, p0})
      + $signed({{(ACC_W-32){p1[31]}}, p1})
      + $signed({{(ACC_W-32){p2[31]}}, p2})
      + $signed({{(ACC_W-32){p3[31]}}, p3})
      + $signed({{(ACC_W-32){p4[31]}}, p4});

    assign y = sat_q8_8_from_acc_shift(sum);

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
