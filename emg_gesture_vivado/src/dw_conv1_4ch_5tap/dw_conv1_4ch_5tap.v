`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

// LightCNN1D DW1 depthwise Conv1d compute unit.
//
// One start pulse processes one 4-channel group for the output time range that
// becomes computable after a newly written stem chunk.
//
// Typical system schedule:
//   stem writes 4 time rows x all 32 channels into stem_to_dw1 buffer
//   for ch_base = 0,4,...,28:
//       start this DW1 PU for that stem chunk and channel group
//   then advance to the next stem time chunk
//
// This keeps scheduling stem-time-chunk-major at the system level: for a given
// stem chunk, all channel groups for the newly computable output rows are
// produced before the scheduler moves on to the next stem chunk. Inside one
// channel-group job, out_t increases by one each accepted output.
//
// The downstream dw1_to_pw1 writer should use:
//   buffer[out_t][out_ch_base + lane] <= out_vec[lane]
// and mark the corresponding channel-group-valid bit for that out_t. PW1 can
// start once four consecutive out_t rows have all channel groups valid.
//
// The PU computes:
//   y[t][ch] = sum_{tap=0..4} x[t + tap - 2][ch] * w[ch][tap]
//   x outside [0, INPUT_LEN-1] is zero padding.
//
// The upstream stem_to_dw1 window loader returns a full 5-tap window for one
// output time and 4 channels:
//   win_vec[(tap*P_CH + lane)] = X[out_t + tap - PAD][ch_base + lane]
// The window loader should insert zeros for padding positions. It should only
// assert win_vec_valid when that requested window is actually available.
// The request/response contract is one outstanding request at most:
//   - a request is accepted with win_req_valid && win_req_ready
//   - the loader must return exactly one response for each accepted request
//   - responses must not be dropped, duplicated, or produced without a request
//   - same-cycle request and response is allowed for a combinational loader
// With a 1-cycle synchronous loader, one-outstanding control can produce one
// output about every two clocks. This is still below the stem cadence in the
// baseline schedule. Add a small request metadata FIFO later if DW1 must issue
// one request every clock against synchronous BRAM.
//
// Output range from a newly available stem chunk:
//   input_t_base = 0, input_rows = 4, final_chunk = 0 -> out_t 0..1  (2 rows)
//   middle chunk base B                                 -> out_t B-2..B+1 (4 rows)
//   final chunk base 344 for INPUT_LEN=348              -> out_t 342..347 (6 rows)
// final_chunk must only be asserted for the last chunk that makes the right
// padded boundary available. In the default 348-point stream this is normally
// input_t_base=344,input_rows=4.
//
// Weight storage is local because DW1 weights are small: 32 channels x 5 taps.
// weight_we is accepted only while the core is idle and start is low. Runtime
// writes are ignored so one job cannot mix old and new depthwise weights.
//
// The output side uses a 2-entry valid/ready FIFO. The 5-tap datapath is split
// into a three-stage II=1 valid pipeline before the FIFO:
//   s0: latch window samples and selected weights
//   s1: multiply
//   s2: add, shift, saturate, then push into the output FIFO
// If the output FIFO is full, the whole pipeline holds and back-pressures the
// window response channel.

module dw_conv1_4ch_5tap #(
    parameter integer DATA_W     = 16,
    parameter integer ACC_W      = 48,
    parameter integer CHANNELS   = 32,
    parameter integer P_CH       = 4,
    parameter integer K          = 5,
    parameter integer PAD        = 2,
    parameter integer INPUT_LEN  = 348,
    parameter integer FRAC_BITS  = 8,
    parameter integer TIME_W     = 9,
    parameter integer ROWS_W     = 4,
    parameter WEIGHT_INIT_FILE   = {`PROJECT_ROOT, "/weight_data/dw1/weight.mem"}
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire [4:0] ch_base,
    input  wire [TIME_W-1:0] input_t_base,
    input  wire [ROWS_W-1:0] input_rows,
    input  wire final_chunk,

    output wire win_req_valid,
    output wire [TIME_W-1:0] win_req_out_t,
    output wire [4:0] win_req_ch_base,
    input  wire win_req_ready,
    input  wire win_vec_valid,
    output wire win_vec_ready,
    input  wire signed [K*P_CH*DATA_W-1:0] win_vec,

    input  wire weight_we,
    input  wire [4:0] weight_ch,
    input  wire [2:0] weight_tap,
    input  wire signed [DATA_W-1:0] weight_wdata,

    input  wire out_ready,
    output reg busy,
    output reg done,
    output wire out_valid,
    output wire [TIME_W-1:0] out_t,
    output wire [4:0] out_ch_base,
    output wire signed [P_CH*DATA_W-1:0] out_vec,

    output reg [TIME_W-1:0] job_out_t_start,
    output reg [TIME_W:0] job_out_count
);

    localparam [1:0] STATE_IDLE = 2'd0;
    localparam [1:0] STATE_RUN  = 2'd1;

    reg [1:0] state;
    reg [4:0] ch_base_reg;
    reg [TIME_W:0] req_count;
    reg [TIME_W:0] resp_count;
    reg outstanding;

    reg signed [DATA_W-1:0] weight_mem [0:CHANNELS*K-1];
    reg [TIME_W-1:0] fifo_t [0:1];
    reg [4:0] fifo_ch_base [0:1];
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

    reg s0_valid;
    reg [TIME_W-1:0] s0_t;
    reg [4:0] s0_ch_base;
    reg signed [DATA_W-1:0] s0_x [0:K-1][0:P_CH-1];
    reg signed [DATA_W-1:0] s0_w [0:K-1][0:P_CH-1];

    reg s1_valid;
    reg [TIME_W-1:0] s1_t;
    reg [4:0] s1_ch_base;
    reg signed [31:0] s1_p [0:K-1][0:P_CH-1];

    reg s2_valid;
    reg [TIME_W-1:0] s2_t;
    reg [4:0] s2_ch_base;
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

    assign out_valid = (fifo_count != 2'd0);
    assign out_t = fifo_t[0];
    assign out_ch_base = fifo_ch_base[0];
    assign out_vec = fifo_vec[0];

    assign win_req_valid = (state == STATE_RUN)
        && (req_count < job_out_count)
        && !outstanding
        && pipe_advance;
    assign win_req_out_t = current_req_out_t;
    assign win_req_ch_base = ch_base_reg;
    assign win_req_fire = win_req_valid && win_req_ready;

    assign can_accept_resp = (state == STATE_RUN)
        && (resp_count < job_out_count)
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
            ch_base_reg <= 5'd0;
            req_count <= {(TIME_W+1){1'b0}};
            resp_count <= {(TIME_W+1){1'b0}};
            outstanding <= 1'b0;
            fifo_t[0] <= {TIME_W{1'b0}};
            fifo_t[1] <= {TIME_W{1'b0}};
            fifo_ch_base[0] <= 5'd0;
            fifo_ch_base[1] <= 5'd0;
            fifo_vec[0] <= {(P_CH*DATA_W){1'b0}};
            fifo_vec[1] <= {(P_CH*DATA_W){1'b0}};
            fifo_count <= 2'd0;
            s0_valid <= 1'b0;
            s0_t <= {TIME_W{1'b0}};
            s0_ch_base <= 5'd0;
            s1_valid <= 1'b0;
            s1_t <= {TIME_W{1'b0}};
            s1_ch_base <= 5'd0;
            s2_valid <= 1'b0;
            s2_t <= {TIME_W{1'b0}};
            s2_ch_base <= 5'd0;
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
                        req_count <= req_count + 1'b1;
                    end

                    if (win_vec_fire) begin
                        resp_count <= resp_count + 1'b1;
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
                            s0_ch_base <= ch_base_reg;
                            for (pipe_tap = 0; pipe_tap < K; pipe_tap = pipe_tap + 1) begin
                                for (pipe_lane = 0; pipe_lane < P_CH; pipe_lane = pipe_lane + 1) begin
                                    s0_x[pipe_tap][pipe_lane]
                                        <= win_vec[(pipe_tap*P_CH + pipe_lane)*DATA_W +: DATA_W];
                                    s0_w[pipe_tap][pipe_lane]
                                        <= weight_mem[(ch_base_reg + pipe_lane)*K + pipe_tap];
                                end
                            end
                        end
                    end

                    if ((req_count == job_out_count)
                        && (resp_count == job_out_count)
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

module dw_conv1_lane_5tap #(
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
