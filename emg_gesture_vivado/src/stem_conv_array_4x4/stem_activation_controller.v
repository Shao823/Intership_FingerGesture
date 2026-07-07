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
// word boundary. This controller therefore issues zero, one, or two RAM reads,
// then returns the aligned 4-row vector with padding samples forced to zero.

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

    output wire ram_en,
    output wire [ADDR_W-1:0] ram_addr,
    input  wire [ROWS*DATA_W-1:0] ram_dout
);

    localparam integer WORD_W = ROWS * DATA_W;

    localparam [2:0] STATE_IDLE  = 3'd0;
    localparam [2:0] STATE_WAIT0 = 3'd1;
    localparam [2:0] STATE_ISSUE1 = 3'd2;
    localparam [2:0] STATE_WAIT1 = 3'd3;
    localparam [2:0] STATE_RESP  = 3'd4;

    reg [2:0] state;
    reg [ADDR_W-1:0] read0_addr;
    reg [ADDR_W-1:0] read1_addr;
    reg [ADDR_W-1:0] ram_addr_hold;
    reg [1:0] read_count;
    reg [ROWS-1:0] row_valid;
    reg [ROWS-1:0] row_word_sel;
    reg [ROWS*2-1:0] row_lane;
    reg [WORD_W-1:0] word0_data;
    reg [WORD_W-1:0] resp_data;
    reg [BRAM_READ_LATENCY:0] ram_valid_d;

    reg [1:0] req_read_count_c;
    reg [ADDR_W-1:0] req_read0_addr_c;
    reg [ADDR_W-1:0] req_read1_addr_c;
    reg [ROWS-1:0] req_row_valid_c;
    reg [ROWS-1:0] req_row_word_sel_c;
    reg [ROWS*2-1:0] req_row_lane_c;

    wire req_fire;
    wire ram_issue;
    wire ram_data_ready;
    wire ram_pipe_en;

    integer comb_i;
    integer comb_ch;
    integer comb_tap;
    integer comb_in_t;
    integer comb_word_idx;
    integer comb_addr;
    integer seq_i;

    assign act_req_ready = (state == STATE_IDLE);
    assign req_fire = act_req_valid && act_req_ready;

    assign act_vec_valid = (state == STATE_RESP);
    assign act_vec = resp_data;

    assign ram_issue = ((state == STATE_IDLE) && req_fire && (req_read_count_c != 0))
        || (state == STATE_ISSUE1);
    assign ram_pipe_en = any_pre_response_valid(ram_valid_d);
    assign ram_en = ram_issue || ram_pipe_en;
    assign ram_addr = ((state == STATE_IDLE) && req_fire)
        ? req_read0_addr_c
        : (state == STATE_ISSUE1)
            ? read1_addr
            : ram_addr_hold;
    assign ram_data_ready = ram_valid_d[BRAM_READ_LATENCY];

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
            ram_valid_d <= {(BRAM_READ_LATENCY+1){1'b0}};
        end else begin
            ram_valid_d[0] <= ram_issue;
            for (seq_i = 1; seq_i <= BRAM_READ_LATENCY; seq_i = seq_i + 1) begin
                ram_valid_d[seq_i] <= ram_valid_d[seq_i-1];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            read0_addr <= {ADDR_W{1'b0}};
            read1_addr <= {ADDR_W{1'b0}};
            ram_addr_hold <= {ADDR_W{1'b0}};
            read_count <= 2'd0;
            row_valid <= {ROWS{1'b0}};
            row_word_sel <= {ROWS{1'b0}};
            row_lane <= {(ROWS*2){1'b0}};
            word0_data <= {WORD_W{1'b0}};
            resp_data <= {WORD_W{1'b0}};
        end else begin
            if (ram_issue) begin
                ram_addr_hold <= ram_addr;
            end

            case (state)
                STATE_IDLE: begin
                    if (req_fire) begin
                        read0_addr <= req_read0_addr_c;
                        read1_addr <= req_read1_addr_c;
                        read_count <= req_read_count_c;
                        row_valid <= req_row_valid_c;
                        row_word_sel <= req_row_word_sel_c;
                        row_lane <= req_row_lane_c;
                        word0_data <= {WORD_W{1'b0}};

                        if (req_read_count_c == 2'd0) begin
                            resp_data <= {WORD_W{1'b0}};
                            state <= STATE_RESP;
                        end else begin
                            state <= STATE_WAIT0;
                        end
                    end
                end

                STATE_WAIT0: begin
                    if (ram_data_ready) begin
                        if (read_count == 2'd2) begin
                            word0_data <= ram_dout;
                            state <= STATE_ISSUE1;
                        end else begin
                            resp_data <= assemble_vec(
                                ram_dout,
                                {WORD_W{1'b0}},
                                row_valid,
                                row_word_sel,
                                row_lane
                            );
                            state <= STATE_RESP;
                        end
                    end
                end

                STATE_ISSUE1: begin
                    state <= STATE_WAIT1;
                end

                STATE_WAIT1: begin
                    if (ram_data_ready) begin
                        resp_data <= assemble_vec(
                            word0_data,
                            ram_dout,
                            row_valid,
                            row_word_sel,
                            row_lane
                        );
                        state <= STATE_RESP;
                    end
                end

                STATE_RESP: begin
                    if (act_vec_ready) begin
                        state <= STATE_IDLE;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

`ifndef SYNTHESIS
    reg [31:0] invalid_req_count;

    wire invalid_k;
    wire invalid_t_base;

    assign invalid_k = (act_req_k >= STEM_K);
    assign invalid_t_base = (act_req_t_base > (INPUT_LEN - ROWS));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            invalid_req_count <= 32'd0;
        end else if (req_fire) begin
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
    end
`endif

endmodule
