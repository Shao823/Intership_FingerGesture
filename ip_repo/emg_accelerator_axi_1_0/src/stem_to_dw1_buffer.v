`timescale 1ns / 1ps

// Inter-stage buffer controller from stem_conv_array_4x4 to
// dw_conv1_4ch_5tap.
//
// BRAM layout expected by this controller:
//   128 x 64-bit simple-dual-port RAM
//   bank = ch_base / 4, bank 0..7 for 32 stem channels
//   row  = absolute_time % 16
//   addr = bank * 16 + row
//   word = {x[ch_base+3], x[ch_base+2], x[ch_base+1], x[ch_base+0]}
//
// The BRAM only stores feature data. The ring metadata stays in registers:
//   slot_valid[bank][row]
//   slot_tag[bank][row] = absolute input time stored in the slot
//
// This file is the storage controller only. It exposes BRAM control/data ports
// so mock RAMs and generated Xilinx blk_mem_gen IP can be tested separately.
// stem_to_dw1_buffer_with_ram.v wraps this controller with
// blk_mem_gen_stem_to_dw_conv1.
//
// A stem output tile is written as four serial BRAM words. A DW1 request is
// accepted only when all non-padding taps for that output window are already
// present and their tags match the requested absolute times. The read side then
// issues up to five serial BRAM reads and assembles one DW1 5-tap window.
//
// Overwrite safety is driven by a per-bank DW1 served watermark. A slot holding
// old sample time t may be overwritten only after the same bank has returned
// output windows through t + PAD, which is the last DW1 output that can consume
// that sample.
//
// Scheduler contract:
//   For each 4-channel bank, the top-level scheduler must request DW1 windows
//   in monotonic out_t order and must not skip an out_t that may be requested
//   later. The served watermark intentionally tracks the largest returned out_t
//   per bank; out-of-order or skipped-then-late requests can allow old slots to
//   be overwritten and later make the skipped window unavailable.
//
// clear behavior:
//   clear resets controller state and all valid/tag/watermark metadata. It does
//   not clear BRAM contents. Stale BRAM words are ignored until their metadata
//   is written again.

module stem_to_dw1_buffer #(
    parameter integer DATA_W     =  8,
    parameter integer TIME_W     = 9,
    parameter integer INPUT_LEN  = 348,
    parameter integer STEM_OC    = 32,
    parameter integer ROWS       = 4,
    parameter integer OC_LANES   = 4,
    parameter integer DW_K       = 5,
    parameter integer DW_PAD     = 2,
    parameter integer RING_ROWS  = 16,
    parameter integer BANKS      = STEM_OC / OC_LANES,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer OC_BASE_W  = (STEM_OC <= 1) ? 1 : $clog2(STEM_OC + 1),
    parameter integer ADDR_W     = (BANKS * RING_ROWS <= 1)
        ? 1 : $clog2(BANKS * RING_ROWS),
    parameter integer BANK_W     = (BANKS <= 1) ? 1 : $clog2(BANKS),
    parameter integer ROW_IDX_W  = (RING_ROWS <= 1) ? 1 : $clog2(RING_ROWS),
    parameter integer TAP_W      = (DW_K <= 1) ? 1 : $clog2(DW_K + 1)
) (
    input  wire clk,
    input  wire rst_n,
    input  wire clear,

    input  wire stem_out_valid,
    output wire stem_out_ready,
    input  wire [TIME_W-1:0] stem_out_tile_t_base,
    input  wire [OC_BASE_W-1:0] stem_out_tile_oc_base,
    input  wire signed [ROWS*OC_LANES*DATA_W-1:0] stem_out_tile,

    input  wire dw1_win_req_valid,
    output wire dw1_win_req_ready,
    input  wire [TIME_W-1:0] dw1_win_req_out_t,
    input  wire [OC_BASE_W-1:0] dw1_win_req_ch_base,

    output wire dw1_win_vec_valid,
    input  wire dw1_win_vec_ready,
    output wire signed [DW_K*OC_LANES*DATA_W-1:0] dw1_win_vec,

    output wire bram_wr_en,
    output wire [ADDR_W-1:0] bram_wr_addr,
    output wire [OC_LANES*DATA_W-1:0] bram_wr_data,
    output wire bram_rd_en,
    output wire [ADDR_W-1:0] bram_rd_addr,
    input  wire [OC_LANES*DATA_W-1:0] bram_rd_dout,

    output wire wr_busy,
    output wire rd_busy,
    output wire stem_watermark_stall
);

    localparam integer WORD_W = OC_LANES * DATA_W;
    localparam integer TILE_W = ROWS * WORD_W;
    localparam integer WIN_W  = DW_K * WORD_W;

    localparam [0:0] WR_IDLE  = 1'b0;
    localparam [0:0] WR_WRITE = 1'b1;

    localparam [1:0] RD_IDLE = 2'd0;
    localparam [1:0] RD_RUN  = 2'd1;
    localparam [1:0] RD_RESP = 2'd2;

    reg wr_state;
    reg [TIME_W-1:0] wr_t_base;
    reg [BANK_W-1:0] wr_bank;
    reg [TAP_W-1:0] wr_row;
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

    wire stem_fire;
    wire rd_req_fire;
    wire rd_resp_fire;

    reg stem_tile_params_valid_c;
    reg stem_tile_safe_c;
    reg [BANK_W-1:0] stem_bank_c;
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

    integer comb_row;
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
        if ((STEM_OC % OC_LANES) != 0) begin
            $error("stem_to_dw1_buffer: STEM_OC must be divisible by OC_LANES");
        end
        if (RING_ROWS < (ROWS * 2)) begin
            $error(
                "stem_to_dw1_buffer: RING_ROWS %0d too small, need >= %0d",
                RING_ROWS,
                ROWS * 2
            );
        end
        if (BRAM_READ_LATENCY < 1) begin
            $error("stem_to_dw1_buffer: BRAM_READ_LATENCY must be >= 1");
        end
    end

    assign stem_out_ready = (wr_state == WR_IDLE)
        && stem_tile_params_valid_c
        && stem_tile_safe_c
        && !clear;
    assign stem_fire = stem_out_valid && stem_out_ready;
    assign stem_watermark_stall = stem_out_valid
        && stem_tile_params_valid_c
        && !stem_tile_safe_c
        && !clear;

    assign rd_req_window_available = rd_req_window_available_c;
    assign dw1_win_req_ready = (rd_state == RD_IDLE)
        && rd_req_window_available
        && !clear;
    assign rd_req_fire = dw1_win_req_valid && dw1_win_req_ready;

    assign dw1_win_vec_valid = (rd_state == RD_RESP);
    assign dw1_win_vec = rd_win_buf;
    assign rd_resp_fire = dw1_win_vec_valid && dw1_win_vec_ready;

    assign rd_issue_valid = (rd_state == RD_RUN) && (rd_issue_tap < DW_K);
    assign rd_issue_padding = tap_is_padding(rd_out_t, rd_issue_tap);
    assign bram_rd_issue = rd_issue_valid && !rd_issue_padding;
    // During padding gaps, the read port may stay enabled to advance the BMG
    // output register pipeline. Those held-address reads are intentionally
    // discarded because bram_rd_valid_d marks only real tap requests.
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

    assign bram_wr_en = (wr_state == WR_WRITE);
    assign bram_wr_addr = calc_sample_addr(wr_bank, wr_t_base + wr_row);
    assign bram_wr_data = wr_tile[wr_row*WORD_W +: WORD_W];
    assign wr_busy = (wr_state != WR_IDLE);
    assign rd_busy = (rd_state != RD_IDLE);

    always @* begin
        stem_bank_c = stem_out_tile_oc_base / OC_LANES;
        stem_tile_params_valid_c = ((stem_out_tile_oc_base % OC_LANES) == 0)
            && (stem_out_tile_oc_base <= (STEM_OC - OC_LANES))
            && (stem_out_tile_t_base <= (INPUT_LEN - ROWS));
        stem_tile_safe_c = stem_tile_params_valid_c;

        if (stem_tile_params_valid_c) begin
            for (comb_row = 0; comb_row < ROWS; comb_row = comb_row + 1) begin
                comb_t = stem_out_tile_t_base + comb_row;
                comb_idx = comb_t % RING_ROWS;
                comb_t_vec = comb_t;
                if (!slot_can_overwrite_value(
                        slot_valid[stem_bank_c][comb_idx[ROW_IDX_W-1:0]],
                        slot_tag[stem_bank_c][comb_idx[ROW_IDX_W-1:0]],
                        served_valid[stem_bank_c],
                        served_out_t[stem_bank_c],
                        comb_t_vec
                    )) begin
                    stem_tile_safe_c = 1'b0;
                end
            end
        end
    end

    always @* begin
        rd_req_bank_c = dw1_win_req_ch_base / OC_LANES;
        dw_req_params_valid_c = ((dw1_win_req_ch_base % OC_LANES) == 0)
            && (dw1_win_req_ch_base <= (STEM_OC - OC_LANES))
            && (dw1_win_req_out_t < INPUT_LEN);
        rd_req_window_available_c = dw_req_params_valid_c;

        if (rd_req_window_available_c) begin
            for (comb_tap = 0; comb_tap < DW_K; comb_tap = comb_tap + 1) begin
                comb_sample_t = dw1_win_req_out_t + comb_tap - DW_PAD;
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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            wr_state <= WR_IDLE;
            wr_t_base <= {TIME_W{1'b0}};
            wr_bank <= {BANK_W{1'b0}};
            wr_row <= {TAP_W{1'b0}};
            wr_tile <= {TILE_W{1'b0}};
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    wr_row <= {TAP_W{1'b0}};
                    if (stem_fire) begin
                        wr_t_base <= stem_out_tile_t_base;
                        wr_bank <= stem_out_tile_oc_base[4:2];
                        wr_tile <= stem_out_tile;
                        wr_state <= WR_WRITE;
                    end
                end

                WR_WRITE: begin
                    if (wr_row == (ROWS - 1)) begin
                        wr_row <= {TAP_W{1'b0}};
                        wr_state <= WR_IDLE;
                    end else begin
                        wr_row <= wr_row + 1'b1;
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
                slot_valid[wr_bank][(wr_t_base + wr_row) % RING_ROWS] <= 1'b1;
                slot_tag[wr_bank][(wr_t_base + wr_row) % RING_ROWS]
                    <= wr_t_base + wr_row;
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
                        rd_out_t <= dw1_win_req_out_t;
                        rd_ch_base <= dw1_win_req_ch_base;
                        rd_bank <= dw1_win_req_ch_base / OC_LANES;
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
    reg [31:0] invalid_stem_req_count;
    reg [31:0] stem_watermark_stall_count;
    reg [31:0] invalid_dw_req_count;
    reg [31:0] unavailable_dw_req_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            invalid_stem_req_count <= 32'd0;
            stem_watermark_stall_count <= 32'd0;
            invalid_dw_req_count <= 32'd0;
            unavailable_dw_req_count <= 32'd0;
        end else begin
            if (stem_out_valid && !stem_tile_params_valid_c) begin
                invalid_stem_req_count <= invalid_stem_req_count + 1'b1;
            end
            if (stem_watermark_stall) begin
                stem_watermark_stall_count <= stem_watermark_stall_count + 1'b1;
            end
            if (dw1_win_req_valid
                && (rd_state == RD_IDLE)
                && !dw_req_params_valid_c) begin
                invalid_dw_req_count <= invalid_dw_req_count + 1'b1;
            end
            if (dw1_win_req_valid
                && (rd_state == RD_IDLE)
                && dw_req_params_valid_c
                && !rd_req_window_available) begin
                unavailable_dw_req_count <= unavailable_dw_req_count + 1'b1;
            end
        end
    end
`endif

endmodule
