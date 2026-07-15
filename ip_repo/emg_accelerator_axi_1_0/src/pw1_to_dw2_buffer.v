`timescale 1ns / 1ps

// Inter-stage buffer controller from pw_conv1_array_4x8 to
// dw_conv2_4ch_5tap.
//
// BRAM layout expected by this controller:
//   256 x 64-bit true-dual-port RAM
//   bank = ch_base / 4, bank 0..15 for 64 PW1 output channels
//   row  = absolute low-resolution pool_t % 16
//   addr = bank * 16 + row
//   word = {x[ch_base+3], x[ch_base+2], x[ch_base+1], x[ch_base+0]}
//
// PW1 writes one pooled tile as 2 rows x 8 channels. The controller serializes
// that tile into four BRAM words:
//   row0 bank0, row0 bank1, row1 bank0, row1 bank1.
//
// DW2 requests one 5-tap window for one output time and one 4-channel group.
// Padding taps are inserted as zero; non-padding taps are read serially from
// BRAM and assembled into one response vector.
//
// Ring metadata is kept in registers:
//   slot_valid[bank][row]
//   slot_tag[bank][row] = absolute pool_t stored in that row.
//
// Overwrite safety follows the stem_to_dw1 design: a slot holding old sample
// time t may be overwritten only after the same bank has served DW2 output
// windows through t + DW_PAD, which is the last output that can consume t.

module pw1_to_dw2_buffer #(
    parameter integer DATA_W     =  8,
    parameter integer TIME_W     = 8,
    parameter integer INPUT_LEN  = 174,
    parameter integer PW1_OC     = 64,
    parameter integer POOL_ROWS  = 2,
    parameter integer PW1_OC_LANES = 8,
    parameter integer CH_LANES   = 4,
    parameter integer DW_K       = 5,
    parameter integer DW_PAD     = 2,
    parameter integer RING_ROWS  = 16,
    parameter integer BANKS      = PW1_OC / CH_LANES,
    parameter integer TILE_BANKS = PW1_OC_LANES / CH_LANES,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer OC_BASE_W  = (PW1_OC <= 1) ? 1 : $clog2(PW1_OC),
    parameter integer ADDR_W     = (BANKS * RING_ROWS <= 1)
        ? 1 : $clog2(BANKS * RING_ROWS),
    parameter integer BANK_W     = (BANKS <= 1) ? 1 : $clog2(BANKS),
    parameter integer ROW_IDX_W  = (RING_ROWS <= 1) ? 1 : $clog2(RING_ROWS),
    parameter integer TAP_W      = (DW_K <= 1) ? 1 : $clog2(DW_K + 1),
    parameter integer WRITE_WORDS = POOL_ROWS * TILE_BANKS,
    parameter integer WRITE_W    = (WRITE_WORDS <= 1) ? 1 : $clog2(WRITE_WORDS + 1)
) (
    input  wire clk,
    input  wire rst_n,
    input  wire clear,

    input  wire pw1_out_valid,
    output wire pw1_out_ready,
    input  wire [TIME_W-1:0] pw1_out_pool_t_base,
    input  wire [OC_BASE_W-1:0] pw1_out_oc_base,
    input  wire signed [POOL_ROWS*PW1_OC_LANES*DATA_W-1:0] pw1_out_tile,

    input  wire dw2_win_req_valid,
    output wire dw2_win_req_ready,
    input  wire [TIME_W-1:0] dw2_win_req_out_t,
    input  wire [OC_BASE_W-1:0] dw2_win_req_ch_base,

    output wire dw2_win_vec_valid,
    input  wire dw2_win_vec_ready,
    output wire signed [DW_K*CH_LANES*DATA_W-1:0] dw2_win_vec,

    output wire bram_wr_en,
    output wire [ADDR_W-1:0] bram_wr_addr,
    output wire [CH_LANES*DATA_W-1:0] bram_wr_data,
    output wire bram_rd_en,
    output wire [ADDR_W-1:0] bram_rd_addr,
    input  wire [CH_LANES*DATA_W-1:0] bram_rd_dout,

    output wire wr_busy,
    output wire rd_busy,
    output wire pw1_overwrite_stall
);

    localparam integer WORD_W = CH_LANES * DATA_W;
    localparam integer TILE_W = POOL_ROWS * PW1_OC_LANES * DATA_W;
    localparam integer WIN_W  = DW_K * WORD_W;

    localparam [0:0] WR_IDLE  = 1'b0;
    localparam [0:0] WR_WRITE = 1'b1;

    localparam [1:0] RD_IDLE = 2'd0;
    localparam [1:0] RD_RUN  = 2'd1;
    localparam [1:0] RD_RESP = 2'd2;

    reg wr_state;
    reg [TIME_W-1:0] wr_t_base;
    reg [BANK_W-1:0] wr_base_bank;
    reg [WRITE_W-1:0] wr_word;
    reg [TILE_W-1:0] wr_tile;

    reg [1:0] rd_state;
    reg [TIME_W-1:0] rd_out_t;
    reg [OC_BASE_W-1:0] rd_ch_base;
    reg [BANK_W-1:0] rd_bank;
    reg [TAP_W-1:0] rd_issue_tap;
    reg [DW_K-1:0] rd_done_mask;
    reg [WIN_W-1:0] rd_win_buf;

    (* ram_style = "distributed" *) reg slot_valid [0:BANKS-1][0:RING_ROWS-1];
    (* ram_style = "distributed" *) reg [TIME_W-1:0] slot_tag [0:BANKS-1][0:RING_ROWS-1];
    reg served_valid [0:BANKS-1];
    reg [TIME_W-1:0] served_out_t [0:BANKS-1];

    reg [BRAM_READ_LATENCY:0] bram_rd_valid_d;
    reg [TAP_W-1:0] bram_rd_tap_d [0:BRAM_READ_LATENCY];
    reg [ADDR_W-1:0] bram_rd_addr_hold;

    wire pw1_fire;
    wire rd_req_fire;
    wire rd_resp_fire;

    reg pw1_tile_params_valid_c;
    reg pw1_tile_safe_c;
    reg [BANK_W-1:0] pw1_base_bank_c;
    reg dw_req_params_valid_c;
    reg rd_req_window_available_c;

    wire rd_req_window_available;
    wire rd_issue_valid;
    wire rd_issue_padding;
    wire bram_rd_issue;
    wire bram_rd_pipe_en;
    wire bram_rd_capture;
    wire [DW_K-1:0] rd_done_after_capture;
    wire [DW_K-1:0] rd_done_next;
    wire [TAP_W-1:0] rd_issue_tap_next;
    wire rd_run_done_next;

    wire [BANK_W-1:0] wr_cur_bank;
    wire [TIME_W-1:0] wr_cur_t;

    integer comb_row;
    integer comb_subbank;
    integer comb_t;
    integer comb_idx;
    integer comb_tap;
    integer comb_sample_t;
    integer comb_sample_idx;
    reg [TIME_W-1:0] comb_t_vec;
    reg [TIME_W-1:0] comb_sample_t_vec;
    reg [BANK_W-1:0] rd_req_bank_c;
    integer rst_bank;
    integer rst_row;
    integer seq_i;

    initial begin
        if ((PW1_OC % CH_LANES) != 0) begin
            $error("pw1_to_dw2_buffer: PW1_OC must be divisible by CH_LANES");
        end
        if ((PW1_OC_LANES % CH_LANES) != 0) begin
            $error("pw1_to_dw2_buffer: PW1_OC_LANES must be divisible by CH_LANES");
        end
        if (RING_ROWS < (DW_K + POOL_ROWS)) begin
            $error(
                "pw1_to_dw2_buffer: RING_ROWS %0d too small, need >= %0d",
                RING_ROWS,
                DW_K + POOL_ROWS
            );
        end
        if (BRAM_READ_LATENCY < 1) begin
            $error("pw1_to_dw2_buffer: BRAM_READ_LATENCY must be >= 1");
        end
    end

    assign pw1_out_ready = (wr_state == WR_IDLE)
        && pw1_tile_params_valid_c
        && pw1_tile_safe_c
        && !clear;
    assign pw1_fire = pw1_out_valid && pw1_out_ready;
    assign pw1_overwrite_stall = pw1_out_valid
        && pw1_tile_params_valid_c
        && !pw1_tile_safe_c
        && !clear;

    assign rd_req_window_available = rd_req_window_available_c;
    assign dw2_win_req_ready = (rd_state == RD_IDLE)
        && rd_req_window_available
        && !clear;
    assign rd_req_fire = dw2_win_req_valid && dw2_win_req_ready;

    assign dw2_win_vec_valid = (rd_state == RD_RESP);
    assign dw2_win_vec = rd_win_buf;
    assign rd_resp_fire = dw2_win_vec_valid && dw2_win_vec_ready;

    assign rd_issue_valid = (rd_state == RD_RUN) && (rd_issue_tap < DW_K);
    assign rd_issue_padding = tap_is_padding(rd_out_t, rd_issue_tap);
    assign bram_rd_issue = rd_issue_valid && !rd_issue_padding;
    assign bram_rd_pipe_en = any_pre_response_valid(bram_rd_valid_d);
    assign bram_rd_en = bram_rd_issue || bram_rd_pipe_en;
    assign bram_rd_addr = bram_rd_issue
        ? calc_tap_addr(rd_bank, rd_out_t, rd_issue_tap)
        : bram_rd_addr_hold;
    assign bram_rd_capture = bram_rd_valid_d[BRAM_READ_LATENCY];

    assign rd_done_after_capture = bram_rd_capture
        ? (rd_done_mask | tap_onehot(bram_rd_tap_d[BRAM_READ_LATENCY]))
        : rd_done_mask;
    assign rd_done_next = (rd_issue_valid && rd_issue_padding)
        ? (rd_done_after_capture | tap_onehot(rd_issue_tap))
        : rd_done_after_capture;
    assign rd_issue_tap_next = rd_issue_valid
        ? (rd_issue_tap + 1'b1)
        : rd_issue_tap;
    assign rd_run_done_next = (rd_done_next == {DW_K{1'b1}});

    assign wr_cur_bank = wr_base_bank + (wr_word % TILE_BANKS);
    assign wr_cur_t = wr_t_base + (wr_word / TILE_BANKS);
    assign bram_wr_en = (wr_state == WR_WRITE);
    assign bram_wr_addr = calc_sample_addr(wr_cur_bank, wr_cur_t);
    assign bram_wr_data = select_write_word(wr_tile, wr_word);
    assign wr_busy = (wr_state != WR_IDLE);
    assign rd_busy = (rd_state != RD_IDLE);

    always @* begin
        pw1_base_bank_c = pw1_out_oc_base / CH_LANES;
        pw1_tile_params_valid_c = ((pw1_out_oc_base % PW1_OC_LANES) == 0)
            && (pw1_out_oc_base <= (PW1_OC - PW1_OC_LANES))
            && (pw1_out_pool_t_base <= (INPUT_LEN - POOL_ROWS));
        pw1_tile_safe_c = pw1_tile_params_valid_c;

        if (pw1_tile_params_valid_c) begin
            for (comb_row = 0; comb_row < POOL_ROWS; comb_row = comb_row + 1) begin
                comb_t = pw1_out_pool_t_base + comb_row;
                comb_idx = comb_t % RING_ROWS;
                comb_t_vec = comb_t;
                for (comb_subbank = 0;
                     comb_subbank < TILE_BANKS;
                     comb_subbank = comb_subbank + 1) begin
                    if (!slot_can_overwrite_value(
                            slot_valid[pw1_base_bank_c + comb_subbank]
                                      [comb_idx[ROW_IDX_W-1:0]],
                            slot_tag[pw1_base_bank_c + comb_subbank]
                                    [comb_idx[ROW_IDX_W-1:0]],
                            served_valid[pw1_base_bank_c + comb_subbank],
                            served_out_t[pw1_base_bank_c + comb_subbank],
                            comb_t_vec
                        )) begin
                        pw1_tile_safe_c = 1'b0;
                    end
                end
            end
        end
    end

    always @* begin
        rd_req_bank_c = dw2_win_req_ch_base / CH_LANES;
        dw_req_params_valid_c = ((dw2_win_req_ch_base % CH_LANES) == 0)
            && (dw2_win_req_ch_base <= (PW1_OC - CH_LANES))
            && (dw2_win_req_out_t < INPUT_LEN);
        rd_req_window_available_c = dw_req_params_valid_c;

        if (rd_req_window_available_c) begin
            for (comb_tap = 0; comb_tap < DW_K; comb_tap = comb_tap + 1) begin
                comb_sample_t = dw2_win_req_out_t + comb_tap - DW_PAD;
                if ((comb_sample_t >= 0) && (comb_sample_t < INPUT_LEN)) begin
                    comb_sample_idx = comb_sample_t % RING_ROWS;
                    comb_sample_t_vec = comb_sample_t;
                    if (!slot_has_time(
                            slot_valid[rd_req_bank_c][comb_sample_idx[ROW_IDX_W-1:0]],
                            slot_tag[rd_req_bank_c][comb_sample_idx[ROW_IDX_W-1:0]],
                            comb_sample_t_vec
                        )) begin
                        rd_req_window_available_c = 1'b0;
                    end
                end
            end
        end
    end

    function [ADDR_W-1:0] calc_sample_addr;
        input [BANK_W-1:0] bank_i;
        input [TIME_W-1:0] time_i;
        begin
            calc_sample_addr = (bank_i * RING_ROWS) + (time_i % RING_ROWS);
        end
    endfunction

    function [ADDR_W-1:0] calc_tap_addr;
        input [BANK_W-1:0] bank_i;
        input [TIME_W-1:0] out_t_i;
        input [TAP_W-1:0] tap_i;
        integer sample_t_i;
        begin
            sample_t_i = out_t_i + tap_i - DW_PAD;
            calc_tap_addr = (bank_i * RING_ROWS) + (sample_t_i % RING_ROWS);
        end
    endfunction

    function tap_is_padding;
        input [TIME_W-1:0] out_t_i;
        input [TAP_W-1:0] tap_i;
        integer sample_t_i;
        begin
            sample_t_i = out_t_i + tap_i - DW_PAD;
            tap_is_padding = (sample_t_i < 0) || (sample_t_i >= INPUT_LEN);
        end
    endfunction

    function [DW_K-1:0] tap_onehot;
        input [TAP_W-1:0] tap_i;
        begin
            tap_onehot = {DW_K{1'b0}};
            if (tap_i < DW_K) begin
                tap_onehot[tap_i] = 1'b1;
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

    function slot_has_time;
        input valid_i;
        input [TIME_W-1:0] tag_i;
        input [TIME_W-1:0] target_t_i;
        begin
            slot_has_time = valid_i && (tag_i == target_t_i);
        end
    endfunction

    function slot_can_overwrite_value;
        input valid_i;
        input [TIME_W-1:0] tag_i;
        input served_valid_i;
        input [TIME_W-1:0] served_out_t_i;
        input [TIME_W-1:0] target_t_i;
        reg [TIME_W:0] old_last_use_i;
        begin
            old_last_use_i = {1'b0, tag_i} + DW_PAD;
            slot_can_overwrite_value = !valid_i
                || (tag_i == target_t_i)
                || (served_valid_i
                    && ({1'b0, served_out_t_i} >= old_last_use_i));
        end
    endfunction

    function [WORD_W-1:0] select_write_word;
        input [TILE_W-1:0] tile_i;
        input [WRITE_W-1:0] word_i;
        integer row_i;
        integer subbank_i;
        integer lane_i;
        integer oc_lane_i;
        begin
            select_write_word = {WORD_W{1'b0}};
            row_i = word_i / TILE_BANKS;
            subbank_i = word_i % TILE_BANKS;
            for (lane_i = 0; lane_i < CH_LANES; lane_i = lane_i + 1) begin
                oc_lane_i = subbank_i * CH_LANES + lane_i;
                select_write_word[lane_i*DATA_W +: DATA_W]
                    = tile_i[(row_i*PW1_OC_LANES + oc_lane_i)*DATA_W +: DATA_W];
            end
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            wr_state <= WR_IDLE;
            wr_t_base <= {TIME_W{1'b0}};
            wr_base_bank <= {BANK_W{1'b0}};
            wr_word <= {WRITE_W{1'b0}};
            wr_tile <= {TILE_W{1'b0}};
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    wr_word <= {WRITE_W{1'b0}};
                    if (pw1_fire) begin
                        wr_t_base <= pw1_out_pool_t_base;
                        wr_base_bank <= pw1_out_oc_base / CH_LANES;
                        wr_tile <= pw1_out_tile;
                        wr_state <= WR_WRITE;
                    end
                end

                WR_WRITE: begin
                    if (wr_word == (WRITE_WORDS - 1)) begin
                        wr_word <= {WRITE_W{1'b0}};
                        wr_state <= WR_IDLE;
                    end else begin
                        wr_word <= wr_word + 1'b1;
                    end
                end

                default: begin
                    wr_state <= WR_IDLE;
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            for (rst_bank = 0; rst_bank < BANKS; rst_bank = rst_bank + 1) begin
                served_valid[rst_bank] <= 1'b0;
                served_out_t[rst_bank] <= {TIME_W{1'b0}};
                for (rst_row = 0; rst_row < RING_ROWS; rst_row = rst_row + 1) begin
                    slot_valid[rst_bank][rst_row] <= 1'b0;
                    slot_tag[rst_bank][rst_row] <= {TIME_W{1'b0}};
                end
            end
        end else begin
            if (bram_wr_en) begin
                slot_valid[wr_cur_bank][wr_cur_t % RING_ROWS] <= 1'b1;
                slot_tag[wr_cur_bank][wr_cur_t % RING_ROWS] <= wr_cur_t;
            end

            if (rd_resp_fire) begin
                served_valid[rd_bank] <= 1'b1;
                if (!served_valid[rd_bank]
                    || ({1'b0, rd_out_t} >= {1'b0, served_out_t[rd_bank]})) begin
                    served_out_t[rd_bank] <= rd_out_t;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            bram_rd_valid_d <= {(BRAM_READ_LATENCY+1){1'b0}};
            bram_rd_addr_hold <= {ADDR_W{1'b0}};
            for (seq_i = 0; seq_i <= BRAM_READ_LATENCY; seq_i = seq_i + 1) begin
                bram_rd_tap_d[seq_i] <= {TAP_W{1'b0}};
            end
        end else begin
            if (bram_rd_issue) begin
                bram_rd_addr_hold <= bram_rd_addr;
            end

            bram_rd_valid_d[0] <= bram_rd_issue;
            bram_rd_tap_d[0] <= rd_issue_tap;
            for (seq_i = 1; seq_i <= BRAM_READ_LATENCY; seq_i = seq_i + 1) begin
                bram_rd_valid_d[seq_i] <= bram_rd_valid_d[seq_i-1];
                bram_rd_tap_d[seq_i] <= bram_rd_tap_d[seq_i-1];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            rd_state <= RD_IDLE;
            rd_out_t <= {TIME_W{1'b0}};
            rd_ch_base <= {OC_BASE_W{1'b0}};
            rd_bank <= {BANK_W{1'b0}};
            rd_issue_tap <= {TAP_W{1'b0}};
            rd_done_mask <= {DW_K{1'b0}};
            rd_win_buf <= {WIN_W{1'b0}};
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    rd_issue_tap <= {TAP_W{1'b0}};
                    rd_done_mask <= {DW_K{1'b0}};
                    if (rd_req_fire) begin
                        rd_out_t <= dw2_win_req_out_t;
                        rd_ch_base <= dw2_win_req_ch_base;
                        rd_bank <= dw2_win_req_ch_base / CH_LANES;
                        rd_win_buf <= {WIN_W{1'b0}};
                        rd_state <= RD_RUN;
                    end
                end

                RD_RUN: begin
                    rd_issue_tap <= rd_issue_tap_next;
                    rd_done_mask <= rd_done_next;
                    if (bram_rd_capture) begin
                        rd_win_buf[
                            bram_rd_tap_d[BRAM_READ_LATENCY]*WORD_W +: WORD_W
                        ] <= bram_rd_dout;
                    end
                    if (rd_run_done_next) begin
                        rd_state <= RD_RESP;
                    end
                end

                RD_RESP: begin
                    if (rd_resp_fire) begin
                        rd_state <= RD_IDLE;
                    end
                end

                default: begin
                    rd_state <= RD_IDLE;
                end
            endcase
        end
    end

`ifndef SYNTHESIS
    reg [31:0] invalid_pw1_req_count;
    reg [31:0] pw1_overwrite_stall_count;
    reg [31:0] invalid_dw_req_count;
    reg [31:0] unavailable_dw_req_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            invalid_pw1_req_count <= 32'd0;
            pw1_overwrite_stall_count <= 32'd0;
            invalid_dw_req_count <= 32'd0;
            unavailable_dw_req_count <= 32'd0;
        end else begin
            if (pw1_out_valid && !pw1_tile_params_valid_c) begin
                invalid_pw1_req_count <= invalid_pw1_req_count + 1'b1;
            end
            if (pw1_overwrite_stall) begin
                pw1_overwrite_stall_count <= pw1_overwrite_stall_count + 1'b1;
            end
            if (dw2_win_req_valid
                && (rd_state == RD_IDLE)
                && !dw_req_params_valid_c) begin
                invalid_dw_req_count <= invalid_dw_req_count + 1'b1;
            end
            if (dw2_win_req_valid
                && (rd_state == RD_IDLE)
                && dw_req_params_valid_c
                && !rd_req_window_available) begin
                unavailable_dw_req_count <= unavailable_dw_req_count + 1'b1;
            end
        end
    end
`endif

endmodule
