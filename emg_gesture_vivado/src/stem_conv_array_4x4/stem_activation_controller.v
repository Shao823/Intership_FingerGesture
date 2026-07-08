`timescale 1ns / 1ps

// Activation window read controller for the LightCNN1D stem convolution.
//
// The stem activation RAM is organized as 435 x 64-bit words:
//   TIME_WORDS = ceil(348 / 4) = 87
//   addr       = in_ch * TIME_WORDS + (input_t / 4)
//   dout       = {A[in_ch][base_t+3], ..., A[in_ch][base_t+0]}
//
// A compute request supplies tile_t_base and flattened stem k:
//   in_ch = k / 7
//   tap   = k % 7
//   input_t(row) = tile_t_base + row + tap - 3
//
// The four requested rows are consecutive, but they may cross a 4-sample RAM
// word boundary. This controller uses two read ports so both possible words are
// requested in the same cycle. Accepted requests are pipelined; metadata travels
// beside the BRAM valid pipeline and completed vectors enter a small response
// FIFO.
//
// FIFO sizing:
//   The current BMG has a 2-cycle total read latency. In this controller's
//   valid-pipe convention that is BRAM_READ_LATENCY=1, so at most two accepted
//   requests can be in flight before the first response reaches the FIFO.
//   RESP_FIFO_DEPTH = BRAM_READ_LATENCY + 3 gives four entries for the current
//   IP: enough for the in-flight responses plus one new request while a prior
//   response is popped. act_req_ready reserves space for FIFO entries and all
//   in-flight responses, matching the stem weight controller policy.

module stem_activation_controller #(
    parameter integer DATA_W     = 16,
    parameter integer ROWS       = 4,
    parameter integer INPUT_LEN  = 348,
    parameter integer STEM_IC    = 5,
    parameter integer KERNEL     = 7,
    parameter integer PADDING    = 3,
    parameter integer TIME_W     = 9,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer STEM_K     = STEM_IC * KERNEL,
    parameter integer TIME_WORDS = (INPUT_LEN + ROWS - 1) / ROWS,
    parameter integer RAM_DEPTH  = STEM_IC * TIME_WORDS,
    parameter integer ADDR_W     = (RAM_DEPTH <= 1) ? 1 : $clog2(RAM_DEPTH)
) (
    input  wire clk,
    input  wire rst_n,

    input  wire act_req_valid,
    input  wire [TIME_W-1:0] act_req_t_base,
    input  wire [5:0] act_req_k,
    output wire act_req_ready,

    output wire act_vec_valid,
    input  wire act_vec_ready,
    output wire signed [ROWS*DATA_W-1:0] act_vec,

    output wire ram0_en,
    output wire [ADDR_W-1:0] ram0_addr,
    input  wire [ROWS*DATA_W-1:0] ram0_dout,
    output wire ram1_en,
    output wire [ADDR_W-1:0] ram1_addr,
    input  wire [ROWS*DATA_W-1:0] ram1_dout
);

    localparam integer WORD_W = ROWS * DATA_W;
    localparam integer RESP_FIFO_DEPTH = BRAM_READ_LATENCY + 3;
    localparam integer FIFO_PTR_W = (RESP_FIFO_DEPTH <= 1)
        ? 1 : $clog2(RESP_FIFO_DEPTH);
    localparam integer FIFO_CNT_W = (RESP_FIFO_DEPTH <= 1)
        ? 1 : $clog2(RESP_FIFO_DEPTH + 1);

    reg [WORD_W-1:0] fifo_data [0:RESP_FIFO_DEPTH-1];
    reg [FIFO_CNT_W-1:0] fifo_count;
    reg [FIFO_PTR_W-1:0] fifo_rd_ptr;
    reg [FIFO_PTR_W-1:0] fifo_wr_ptr;

    reg [BRAM_READ_LATENCY:0] resp_valid_d;
    reg [BRAM_READ_LATENCY:0] ram0_valid_d;
    reg [BRAM_READ_LATENCY:0] ram1_valid_d;
    reg [ROWS-1:0] resp_row_valid_d [0:BRAM_READ_LATENCY];
    reg [ROWS-1:0] resp_row_word_sel_d [0:BRAM_READ_LATENCY];
    reg [ROWS*2-1:0] resp_row_lane_d [0:BRAM_READ_LATENCY];

    reg [ADDR_W-1:0] ram0_addr_hold;
    reg [ADDR_W-1:0] ram1_addr_hold;

    reg [1:0] req_read_count_c;
    reg [ADDR_W-1:0] req_read0_addr_c;
    reg [ADDR_W-1:0] req_read1_addr_c;
    reg [ROWS-1:0] req_row_valid_c;
    reg [ROWS-1:0] req_row_word_sel_c;
    reg [ROWS*2-1:0] req_row_lane_c;

    wire req_fire;
    wire resp_fire;
    wire fifo_push;
    wire fifo_push_ready;
    wire fifo_push_fire;
    wire [7:0] reserved_count_after_pop;
    wire ram0_issue;
    wire ram1_issue;
    wire ram0_pipe_en;
    wire ram1_pipe_en;
    wire [WORD_W-1:0] fifo_push_data;

    integer comb_i;
    integer comb_ch;
    integer comb_tap;
    integer comb_in_t;
    integer comb_word_idx;
    integer comb_addr;
    integer seq_i;
    integer rst_i;

    initial begin
        if (BRAM_READ_LATENCY < 1) begin
            $error("stem_activation_controller: BRAM_READ_LATENCY must be >= 1");
        end
    end

    assign act_vec_valid = (fifo_count != {FIFO_CNT_W{1'b0}});
    assign act_vec = fifo_data[fifo_rd_ptr];
    assign resp_fire = act_vec_valid && act_vec_ready;

    assign fifo_push = resp_valid_d[BRAM_READ_LATENCY];
    assign fifo_push_ready = (fifo_count != RESP_FIFO_DEPTH) || resp_fire;
    assign fifo_push_fire = fifo_push && fifo_push_ready;
    assign fifo_push_data = assemble_vec(
        ram0_dout,
        ram1_dout,
        resp_row_valid_d[BRAM_READ_LATENCY],
        resp_row_word_sel_d[BRAM_READ_LATENCY],
        resp_row_lane_d[BRAM_READ_LATENCY]
    );

    assign reserved_count_after_pop = {4'b0000, fifo_count}
        + count_valid(resp_valid_d)
        - {7'b0000000, resp_fire};
    assign act_req_ready = (reserved_count_after_pop < RESP_FIFO_DEPTH);
    assign req_fire = act_req_valid && act_req_ready;

    assign ram0_issue = req_fire && (req_read_count_c != 2'd0);
    assign ram1_issue = req_fire && (req_read_count_c == 2'd2);
    assign ram0_pipe_en = any_pre_response_valid(ram0_valid_d);
    assign ram1_pipe_en = any_pre_response_valid(ram1_valid_d);
    assign ram0_en = ram0_issue || ram0_pipe_en;
    assign ram1_en = ram1_issue || ram1_pipe_en;
    assign ram0_addr = ram0_issue ? req_read0_addr_c : ram0_addr_hold;
    assign ram1_addr = ram1_issue ? req_read1_addr_c : ram1_addr_hold;

    always @* begin
        req_read_count_c = 2'd0;
        req_read0_addr_c = {ADDR_W{1'b0}};
        req_read1_addr_c = {ADDR_W{1'b0}};
        req_row_valid_c = {ROWS{1'b0}};
        req_row_word_sel_c = {ROWS{1'b0}};
        req_row_lane_c = {(ROWS*2){1'b0}};

        if (act_req_k < STEM_K) begin
            comb_ch = act_req_k / KERNEL;
            comb_tap = act_req_k - (comb_ch * KERNEL);

            for (comb_i = 0; comb_i < ROWS; comb_i = comb_i + 1) begin
                comb_in_t = act_req_t_base;
                comb_in_t = comb_in_t + comb_i + comb_tap - PADDING;

                if ((comb_in_t >= 0) && (comb_in_t < INPUT_LEN)) begin
                    comb_word_idx = comb_in_t / ROWS;
                    comb_addr = (comb_ch * TIME_WORDS) + comb_word_idx;

                    req_row_valid_c[comb_i] = 1'b1;
                    req_row_lane_c[comb_i*2 +: 2] = comb_in_t[1:0];

                    if (req_read_count_c == 2'd0) begin
                        req_read0_addr_c = comb_addr[ADDR_W-1:0];
                        req_read_count_c = 2'd1;
                        req_row_word_sel_c[comb_i] = 1'b0;
                    end else if (comb_addr[ADDR_W-1:0] == req_read0_addr_c) begin
                        req_row_word_sel_c[comb_i] = 1'b0;
                    end else begin
                        if (req_read_count_c == 2'd1) begin
                            req_read1_addr_c = comb_addr[ADDR_W-1:0];
                            req_read_count_c = 2'd2;
                        end
                        req_row_word_sel_c[comb_i] = 1'b1;
                    end
                end
            end
        end
    end

    function [7:0] count_valid;
        input [BRAM_READ_LATENCY:0] valid_vec;
        integer idx;
        begin
            count_valid = 8'd0;
            for (idx = 0; idx <= BRAM_READ_LATENCY; idx = idx + 1) begin
                count_valid = count_valid + valid_vec[idx];
            end
        end
    endfunction

    function any_pre_response_valid;
        input [BRAM_READ_LATENCY:0] valid_vec;
        integer idx;
        begin
            any_pre_response_valid = 1'b0;
            for (idx = 0; idx < BRAM_READ_LATENCY; idx = idx + 1) begin
                any_pre_response_valid = any_pre_response_valid || valid_vec[idx];
            end
        end
    endfunction

    function [FIFO_PTR_W-1:0] next_fifo_ptr;
        input [FIFO_PTR_W-1:0] ptr;
        begin
            if (ptr == RESP_FIFO_DEPTH - 1) begin
                next_fifo_ptr = {FIFO_PTR_W{1'b0}};
            end else begin
                next_fifo_ptr = ptr + 1'b1;
            end
        end
    endfunction

    function [WORD_W-1:0] assemble_vec;
        input [WORD_W-1:0] word0;
        input [WORD_W-1:0] word1;
        input [ROWS-1:0] valid_mask;
        input [ROWS-1:0] word_sel_mask;
        input [ROWS*2-1:0] lane_vec;
        integer row_i;
        reg [1:0] lane_i;
        reg [DATA_W-1:0] sample_i;
        begin
            assemble_vec = {WORD_W{1'b0}};
            for (row_i = 0; row_i < ROWS; row_i = row_i + 1) begin
                lane_i = lane_vec[row_i*2 +: 2];
                sample_i = {DATA_W{1'b0}};
                if (valid_mask[row_i]) begin
                    if (word_sel_mask[row_i]) begin
                        sample_i = word1[lane_i*DATA_W +: DATA_W];
                    end else begin
                        sample_i = word0[lane_i*DATA_W +: DATA_W];
                    end
                end
                assemble_vec[row_i*DATA_W +: DATA_W] = sample_i;
            end
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            resp_valid_d <= {(BRAM_READ_LATENCY+1){1'b0}};
            ram0_valid_d <= {(BRAM_READ_LATENCY+1){1'b0}};
            ram1_valid_d <= {(BRAM_READ_LATENCY+1){1'b0}};
            ram0_addr_hold <= {ADDR_W{1'b0}};
            ram1_addr_hold <= {ADDR_W{1'b0}};
            for (seq_i = 0; seq_i <= BRAM_READ_LATENCY; seq_i = seq_i + 1) begin
                resp_row_valid_d[seq_i] <= {ROWS{1'b0}};
                resp_row_word_sel_d[seq_i] <= {ROWS{1'b0}};
                resp_row_lane_d[seq_i] <= {(ROWS*2){1'b0}};
            end
        end else begin
            if (ram0_issue) begin
                ram0_addr_hold <= req_read0_addr_c;
            end
            if (ram1_issue) begin
                ram1_addr_hold <= req_read1_addr_c;
            end

            resp_valid_d[0] <= req_fire;
            ram0_valid_d[0] <= ram0_issue;
            ram1_valid_d[0] <= ram1_issue;
            resp_row_valid_d[0] <= req_row_valid_c;
            resp_row_word_sel_d[0] <= req_row_word_sel_c;
            resp_row_lane_d[0] <= req_row_lane_c;

            for (seq_i = 1; seq_i <= BRAM_READ_LATENCY; seq_i = seq_i + 1) begin
                resp_valid_d[seq_i] <= resp_valid_d[seq_i-1];
                ram0_valid_d[seq_i] <= ram0_valid_d[seq_i-1];
                ram1_valid_d[seq_i] <= ram1_valid_d[seq_i-1];
                resp_row_valid_d[seq_i] <= resp_row_valid_d[seq_i-1];
                resp_row_word_sel_d[seq_i] <= resp_row_word_sel_d[seq_i-1];
                resp_row_lane_d[seq_i] <= resp_row_lane_d[seq_i-1];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_count <= {FIFO_CNT_W{1'b0}};
            fifo_rd_ptr <= {FIFO_PTR_W{1'b0}};
            fifo_wr_ptr <= {FIFO_PTR_W{1'b0}};
            for (rst_i = 0; rst_i < RESP_FIFO_DEPTH; rst_i = rst_i + 1) begin
                fifo_data[rst_i] <= {WORD_W{1'b0}};
            end
        end else begin
            if (resp_fire) begin
                fifo_rd_ptr <= next_fifo_ptr(fifo_rd_ptr);
            end

            if (fifo_push_fire) begin
                fifo_data[fifo_wr_ptr] <= fifo_push_data;
                fifo_wr_ptr <= next_fifo_ptr(fifo_wr_ptr);
            end

            fifo_count <= fifo_count
                + {{(FIFO_CNT_W-1){1'b0}}, fifo_push_fire}
                - {{(FIFO_CNT_W-1){1'b0}}, resp_fire};
        end
    end

`ifndef SYNTHESIS
    reg [31:0] invalid_req_count;
    reg [31:0] fifo_overflow_count;

    wire invalid_k;
    wire invalid_t_base;

    assign invalid_k = (act_req_k >= STEM_K);
    assign invalid_t_base = (act_req_t_base > (INPUT_LEN - ROWS));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            invalid_req_count <= 32'd0;
            fifo_overflow_count <= 32'd0;
        end else begin
            if (req_fire) begin
                if (invalid_k || invalid_t_base) begin
                    invalid_req_count <= invalid_req_count + 1'b1;
                end
                if (invalid_k) begin
                    $display(
                        "ERROR stem_activation_controller: k %0d exceeds max %0d",
                        act_req_k,
                        STEM_K - 1
                    );
                end
                if (invalid_t_base) begin
                    $display(
                        "ERROR stem_activation_controller: tile_t_base %0d exceeds max %0d",
                        act_req_t_base,
                        INPUT_LEN - ROWS
                    );
                end
            end

            if (fifo_push && !fifo_push_ready) begin
                fifo_overflow_count <= fifo_overflow_count + 1'b1;
                $display("ERROR stem_activation_controller: response FIFO overflow");
            end
        end
    end
`endif

endmodule
