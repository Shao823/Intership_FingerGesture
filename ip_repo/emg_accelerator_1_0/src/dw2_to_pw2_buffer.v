`timescale 1ns / 1ps

// Inter-stage buffer controller from dw_conv2_4ch_5tap to
// pw_conv2_array_4x12.
//
// BRAM layout expected by this controller:
//   256 x 64-bit true-dual-port RAM
//   bank = ch_base / 4, bank 0..15 for 64 DW2 channels
//   row  = absolute out_t % 16
//   addr = bank * 16 + row
//   word = {x[ch_base+3], x[ch_base+2], x[ch_base+1], x[ch_base+0]}
//
// The BRAM stores only feature data. Ring metadata stays in registers:
//   slot_valid[bank][row]
//   slot_tag[bank][row] = absolute DW2 output time stored in the slot
//
// A PW2 tile request is accepted when every row asserted in row_valid_mask is
// present for all sixteen 4-channel banks. Normal tiles use mask 4'b1111. The
// final default 174-row tile at t_base=172 uses mask 4'b0011; invalid rows are
// not read from BRAM and are returned as zero in act_vec.
//
// After a tile request is accepted, both BRAM ports preload the requested
// activation tile into local registers. Runtime act_req reads then come from
// the local cache, so PW2 can reuse the same activation tile across all output
// channel groups without creating BRAM backpressure.
//
// Scheduler contract:
//   PW2 tile requests must be monotonic and must not skip a tile that may be
//   requested later. A row slot may be overwritten after the tile containing the
//   old row has been preloaded into this controller's local cache.
//
// clear behavior:
//   clear resets controller state and all valid/tag/watermark metadata. It does
//   not clear BRAM contents. Stale BRAM words are ignored until metadata is
//   written again.

module dw2_to_pw2_buffer #(
    parameter integer DATA_W     =  8,
    parameter integer TIME_W     = 8,
    parameter integer INPUT_LEN  = 174,
    parameter integer PW2_IC     = 64,
    parameter integer ROWS       = 4,
    parameter integer CH_LANES   = 4,
    parameter integer RING_ROWS  = 16,
    parameter integer BANKS      = PW2_IC / CH_LANES,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer CH_BASE_W  = (PW2_IC <= 1) ? 1 : $clog2(PW2_IC + 1),
    parameter integer ADDR_W     = (BANKS * RING_ROWS <= 1)
        ? 1 : $clog2(BANKS * RING_ROWS),
    parameter integer BANK_W     = (BANKS <= 1) ? 1 : $clog2(BANKS),
    parameter integer ROW_IDX_W  = (RING_ROWS <= 1) ? 1 : $clog2(RING_ROWS),
    parameter integer LOAD_WORDS = BANKS * ROWS,
    parameter integer LOAD_W     = (LOAD_WORDS <= 1) ? 1 : $clog2(LOAD_WORDS + 1)
) (
    input  wire clk,
    input  wire rst_n,
    input  wire clear,

    input  wire dw2_out_valid,
    output wire dw2_out_ready,
    input  wire [TIME_W-1:0] dw2_out_t,
    input  wire [CH_BASE_W-1:0] dw2_out_ch_base,
    input  wire signed [CH_LANES*DATA_W-1:0] dw2_out_vec,

    input  wire input_tile_req_valid,
    output wire input_tile_req_ready,
    input  wire [TIME_W-1:0] input_tile_req_t_base,
    input  wire [ROWS-1:0] input_tile_req_row_valid_mask,

    input  wire act_req_valid,
    output wire act_req_ready,
    input  wire [TIME_W-1:0] act_req_t_base,
    input  wire [6:0] act_req_k,
    input  wire [ROWS-1:0] act_req_row_valid_mask,

    output wire act_vec_valid,
    input  wire act_vec_ready,
    output wire signed [ROWS*DATA_W-1:0] act_vec,

    output wire bram_a_en,
    output wire bram_a_we,
    output wire [ADDR_W-1:0] bram_a_addr,
    output wire [CH_LANES*DATA_W-1:0] bram_a_din,
    input  wire [CH_LANES*DATA_W-1:0] bram_a_dout,

    output wire bram_b_en,
    output wire bram_b_we,
    output wire [ADDR_W-1:0] bram_b_addr,
    output wire [CH_LANES*DATA_W-1:0] bram_b_din,
    input  wire [CH_LANES*DATA_W-1:0] bram_b_dout,

    output wire wr_busy,
    output wire rd_busy,
    output wire tile_cache_valid,
    output wire dw2_overwrite_stall
);

    localparam integer WORD_W = CH_LANES * DATA_W;
    localparam integer ACT_W  = ROWS * DATA_W;
    localparam integer ROW_SEL_W = (ROWS <= 1) ? 1 : $clog2(ROWS);
    localparam [BANKS-1:0] ALL_BANKS_MASK = {BANKS{1'b1}};

    localparam [1:0] RD_IDLE   = 2'd0;
    localparam [1:0] RD_LOAD   = 2'd1;
    localparam [1:0] RD_COMMIT = 2'd2;
    localparam [1:0] RD_READY  = 2'd3;

    reg [1:0] rd_state;
    reg [TIME_W-1:0] rd_tile_t_base;
    reg [ROWS-1:0] rd_row_valid_mask;
    reg [LOAD_W-1:0] load_issue_idx;
    reg [LOAD_W-1:0] load_capture_count;
    reg act_resp_valid;
    reg act_resp_last;
    reg signed [ACT_W-1:0] act_resp_data;

    (* ram_style = "distributed" *) reg slot_valid [0:BANKS-1][0:RING_ROWS-1];
    (* ram_style = "distributed" *) reg [TIME_W-1:0] slot_tag [0:BANKS-1][0:RING_ROWS-1];
    reg row_seen_valid [0:RING_ROWS-1];
    reg [TIME_W-1:0] row_seen_tag [0:RING_ROWS-1];
    reg [BANKS-1:0] row_seen_mask [0:RING_ROWS-1];
    reg served_valid;
    reg [TIME_W:0] served_last_t;

    (* ram_style = "registers" *) reg signed [WORD_W-1:0] tile_cache_row0 [0:BANKS-1];
    (* ram_style = "registers" *) reg signed [WORD_W-1:0] tile_cache_row1 [0:BANKS-1];
    (* ram_style = "registers" *) reg signed [WORD_W-1:0] tile_cache_row2 [0:BANKS-1];
    (* ram_style = "registers" *) reg signed [WORD_W-1:0] tile_cache_row3 [0:BANKS-1];

    reg [BRAM_READ_LATENCY:0] bram_a_valid_d;
    reg [BRAM_READ_LATENCY:0] bram_b_valid_d;
    reg [BANK_W-1:0] bram_a_cache_bank_d [0:BRAM_READ_LATENCY];
    reg [BANK_W-1:0] bram_b_cache_bank_d [0:BRAM_READ_LATENCY];
    reg [ROW_SEL_W-1:0] bram_a_cache_row_d [0:BRAM_READ_LATENCY];
    reg [ROW_SEL_W-1:0] bram_b_cache_row_d [0:BRAM_READ_LATENCY];
    reg [ADDR_W-1:0] bram_a_addr_hold;
    reg [ADDR_W-1:0] bram_b_addr_hold;
    reg cache_wr_a_valid;
    reg cache_wr_b_valid;
    reg [BANKS-1:0] cache_wr_a_bank_oh;
    reg [BANKS-1:0] cache_wr_b_bank_oh;
    reg [ROWS-1:0] cache_wr_a_row_oh;
    reg [ROWS-1:0] cache_wr_b_row_oh;
    reg signed [WORD_W-1:0] cache_wr_a_data;
    reg signed [WORD_W-1:0] cache_wr_b_data;

    wire dw2_fire;
    wire tile_req_fire;
    wire act_req_fire;
    wire act_resp_fire;
    wire load_active;
    wire load_issue_a;
    wire load_issue_b;
    wire load_pipe_a_en;
    wire load_pipe_b_en;
    wire load_capture_a;
    wire load_capture_b;
    wire [1:0] load_capture_inc;
    wire load_done_next;
    wire act_resp_last_fire;
    wire [LOAD_W-1:0] active_load_words;

    reg dw2_params_valid_c;
    reg dw2_slot_safe_c;
    reg [BANK_W-1:0] dw2_bank_c;
    reg tile_params_valid_c;
    reg tile_available_c;
    reg act_req_params_valid_c;
    reg tile_req_pending;
    reg tile_req_ready_q;
    reg [TIME_W-1:0] tile_req_t_base_q;
    reg [ROWS-1:0] tile_req_row_valid_mask_q;
    reg tile_req_pending_params_valid_c;
    reg tile_req_pending_available_c;

    integer wr_comb_idx;
    integer tile_comb_row;
    integer tile_comb_t;
    integer tile_comb_idx;
    reg [TIME_W-1:0] tile_comb_t_vec;
    integer pending_tile_comb_row;
    integer pending_tile_comb_t;
    integer pending_tile_comb_idx;
    reg [TIME_W-1:0] pending_tile_comb_t_vec;
    integer full_idx;
    integer rst_bank;
    integer rst_row;
    integer seq_i;
    integer cache_bank;

    initial begin
        if ((PW2_IC % CH_LANES) != 0) begin
            $error("dw2_to_pw2_buffer: PW2_IC must be divisible by CH_LANES");
        end
        if (ROWS != 4) begin
            $error("dw2_to_pw2_buffer: this implementation requires ROWS == 4");
        end
        if (RING_ROWS < (ROWS * 2)) begin
            $error(
                "dw2_to_pw2_buffer: RING_ROWS %0d too small, need >= %0d",
                RING_ROWS,
                ROWS * 2
            );
        end
        if (BRAM_READ_LATENCY < 1) begin
            $error("dw2_to_pw2_buffer: BRAM_READ_LATENCY must be >= 1");
        end
    end

    assign load_active = (rd_state == RD_LOAD);
    assign active_load_words = count_valid_rows(rd_row_valid_mask) * BANKS;

    assign dw2_out_ready = !clear
        && !load_active
        && dw2_params_valid_c
        && dw2_slot_safe_c;
    assign dw2_fire = dw2_out_valid && dw2_out_ready;
    assign dw2_overwrite_stall = dw2_out_valid
        && dw2_params_valid_c
        && !dw2_slot_safe_c
        && !clear;

    assign input_tile_req_ready = !clear
        && (rd_state == RD_IDLE)
        && tile_req_pending
        && tile_req_ready_q;
    assign tile_req_fire = input_tile_req_valid && input_tile_req_ready;

    assign act_req_ready = !clear
        && (rd_state == RD_READY)
        && act_req_params_valid_c
        && (!act_resp_valid || act_vec_ready);
    assign act_req_fire = act_req_valid && act_req_ready;

    assign act_vec_valid = act_resp_valid;
    assign act_vec = act_resp_data;
    assign act_resp_fire = act_vec_valid && act_vec_ready;
    assign act_resp_last_fire = act_resp_fire && act_resp_last;

    assign load_issue_a = load_active && (load_issue_idx < active_load_words);
    assign load_issue_b = load_active
        && ((load_issue_idx + 1'b1) < active_load_words);
    assign load_pipe_a_en = load_active && any_pre_response_valid(bram_a_valid_d);
    assign load_pipe_b_en = load_active && any_pre_response_valid(bram_b_valid_d);
    assign load_capture_a = bram_a_valid_d[BRAM_READ_LATENCY];
    assign load_capture_b = bram_b_valid_d[BRAM_READ_LATENCY];
    assign load_capture_inc = {1'b0, load_capture_a} + {1'b0, load_capture_b};
    assign load_done_next = load_active
        && ((load_capture_count + load_capture_inc) >= active_load_words);

    assign bram_a_en = load_issue_a || load_pipe_a_en || dw2_fire;
    assign bram_a_we = !load_active && dw2_fire;
    assign bram_a_addr = load_issue_a
        ? calc_load_addr(rd_tile_t_base, rd_row_valid_mask, load_issue_idx)
        : (load_pipe_a_en
            ? bram_a_addr_hold
            : calc_sample_addr(dw2_bank_c, dw2_out_t));
    assign bram_a_din = dw2_out_vec;

    assign bram_b_en = load_issue_b || load_pipe_b_en;
    assign bram_b_we = 1'b0;
    assign bram_b_addr = load_issue_b
        ? calc_load_addr(
            rd_tile_t_base,
            rd_row_valid_mask,
            load_issue_idx + 1'b1
        )
        : bram_b_addr_hold;
    assign bram_b_din = {WORD_W{1'b0}};

    assign wr_busy = dw2_fire;
    assign rd_busy = (rd_state != RD_IDLE);
    assign tile_cache_valid = (rd_state == RD_READY);

    always @* begin
        dw2_bank_c = dw2_out_ch_base / CH_LANES;
        wr_comb_idx = 0;
        dw2_params_valid_c = ((dw2_out_ch_base % CH_LANES) == 0)
            && (dw2_out_ch_base <= (PW2_IC - CH_LANES))
            && (dw2_out_t < INPUT_LEN);
        dw2_slot_safe_c = dw2_params_valid_c;

        if (dw2_params_valid_c) begin
            wr_comb_idx = dw2_out_t % RING_ROWS;
            if (!slot_can_overwrite_value(
                    slot_valid[dw2_bank_c][wr_comb_idx[ROW_IDX_W-1:0]],
                    slot_tag[dw2_bank_c][wr_comb_idx[ROW_IDX_W-1:0]],
                    served_valid,
                    served_last_t,
                    dw2_out_t
                )) begin
                dw2_slot_safe_c = 1'b0;
            end
        end
    end

    always @* begin
        tile_params_valid_c = (input_tile_req_row_valid_mask != {ROWS{1'b0}});
        tile_available_c = tile_params_valid_c;
        tile_comb_t = 0;
        tile_comb_idx = 0;
        tile_comb_t_vec = {TIME_W{1'b0}};

        for (tile_comb_row = 0;
             tile_comb_row < ROWS;
             tile_comb_row = tile_comb_row + 1) begin
            if (input_tile_req_row_valid_mask[tile_comb_row]) begin
                tile_comb_t = input_tile_req_t_base + tile_comb_row;
                if (tile_comb_t >= INPUT_LEN) begin
                    tile_params_valid_c = 1'b0;
                    tile_available_c = 1'b0;
                end
            end
        end

        if (tile_params_valid_c) begin
            for (tile_comb_row = 0;
                 tile_comb_row < ROWS;
                 tile_comb_row = tile_comb_row + 1) begin
                if (input_tile_req_row_valid_mask[tile_comb_row]) begin
                    tile_comb_t = input_tile_req_t_base + tile_comb_row;
                    tile_comb_idx = tile_comb_t % RING_ROWS;
                    tile_comb_t_vec = tile_comb_t;
                    if (!row_has_all_banks(
                            row_seen_valid[tile_comb_idx[ROW_IDX_W-1:0]],
                            row_seen_tag[tile_comb_idx[ROW_IDX_W-1:0]],
                            row_seen_mask[tile_comb_idx[ROW_IDX_W-1:0]],
                            tile_comb_t_vec
                        )) begin
                        tile_available_c = 1'b0;
                    end
                end
            end
        end
    end

    always @* begin
        tile_req_pending_params_valid_c =
            (tile_req_row_valid_mask_q != {ROWS{1'b0}});
        tile_req_pending_available_c = tile_req_pending_params_valid_c;
        pending_tile_comb_t = 0;
        pending_tile_comb_idx = 0;
        pending_tile_comb_t_vec = {TIME_W{1'b0}};

        for (pending_tile_comb_row = 0;
             pending_tile_comb_row < ROWS;
             pending_tile_comb_row = pending_tile_comb_row + 1) begin
            if (tile_req_row_valid_mask_q[pending_tile_comb_row]) begin
                pending_tile_comb_t = tile_req_t_base_q + pending_tile_comb_row;
                if (pending_tile_comb_t >= INPUT_LEN) begin
                    tile_req_pending_params_valid_c = 1'b0;
                    tile_req_pending_available_c = 1'b0;
                end
            end
        end

        if (tile_req_pending_params_valid_c) begin
            for (pending_tile_comb_row = 0;
                 pending_tile_comb_row < ROWS;
                 pending_tile_comb_row = pending_tile_comb_row + 1) begin
                if (tile_req_row_valid_mask_q[pending_tile_comb_row]) begin
                    pending_tile_comb_t = tile_req_t_base_q + pending_tile_comb_row;
                    pending_tile_comb_idx = pending_tile_comb_t % RING_ROWS;
                    pending_tile_comb_t_vec = pending_tile_comb_t;
                    if (!row_has_all_banks(
                            row_seen_valid[pending_tile_comb_idx[ROW_IDX_W-1:0]],
                            row_seen_tag[pending_tile_comb_idx[ROW_IDX_W-1:0]],
                            row_seen_mask[pending_tile_comb_idx[ROW_IDX_W-1:0]],
                            pending_tile_comb_t_vec
                        )) begin
                        tile_req_pending_available_c = 1'b0;
                    end
                end
            end
        end
    end

    always @* begin
        act_req_params_valid_c = (act_req_t_base == rd_tile_t_base)
            && (act_req_k < PW2_IC)
            && (act_req_row_valid_mask == rd_row_valid_mask);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            tile_req_pending <= 1'b0;
            tile_req_ready_q <= 1'b0;
            tile_req_t_base_q <= {TIME_W{1'b0}};
            tile_req_row_valid_mask_q <= {ROWS{1'b0}};
        end else if ((rd_state != RD_IDLE) || tile_req_fire) begin
            tile_req_pending <= 1'b0;
            tile_req_ready_q <= 1'b0;
        end else if (!input_tile_req_valid) begin
            tile_req_pending <= 1'b0;
            tile_req_ready_q <= 1'b0;
        end else if (!tile_req_pending) begin
            tile_req_ready_q <= 1'b0;
            if (tile_params_valid_c) begin
                tile_req_pending <= 1'b1;
                tile_req_t_base_q <= input_tile_req_t_base;
                tile_req_row_valid_mask_q <= input_tile_req_row_valid_mask;
                tile_req_ready_q <= tile_available_c;
            end
        end else begin
            tile_req_ready_q <= tile_req_pending_available_c;
        end
    end

    function [ADDR_W-1:0] calc_sample_addr;
        input [BANK_W-1:0] bank_i;
        input [TIME_W-1:0] time_i;
        begin
            calc_sample_addr = (bank_i * RING_ROWS) + (time_i % RING_ROWS);
        end
    endfunction

    function [ADDR_W-1:0] calc_load_addr;
        input [TIME_W-1:0] tile_t_base_i;
        input [ROWS-1:0] mask_i;
        input [LOAD_W-1:0] load_idx_i;
        integer active_rows_i;
        integer bank_i;
        integer row_ord_i;
        integer row_i;
        integer time_i;
        begin
            active_rows_i = count_valid_rows(mask_i);
            if (active_rows_i == 0) begin
                calc_load_addr = {ADDR_W{1'b0}};
            end else begin
                case (active_rows_i)
                    1: begin
                        bank_i = load_idx_i;
                        row_ord_i = 0;
                    end
                    2: begin
                        bank_i = load_idx_i >> 1;
                        row_ord_i = load_idx_i[0];
                    end
                    3: begin
                        bank_i = load_idx_i / 3;
                        row_ord_i = load_idx_i - (bank_i * 3);
                    end
                    default: begin
                        bank_i = load_idx_i >> 2;
                        row_ord_i = load_idx_i[1:0];
                    end
                endcase
                row_i = active_row_index(mask_i, row_ord_i);
                time_i = tile_t_base_i + row_i;
                calc_load_addr = (bank_i * RING_ROWS) + (time_i % RING_ROWS);
            end
        end
    endfunction

    function [LOAD_W-1:0] count_valid_rows;
        input [ROWS-1:0] mask_i;
        integer row_i;
        begin
            count_valid_rows = {LOAD_W{1'b0}};
            for (row_i = 0; row_i < ROWS; row_i = row_i + 1) begin
                if (mask_i[row_i]) begin
                    count_valid_rows = count_valid_rows + 1'b1;
                end
            end
        end
    endfunction

    function integer active_row_index;
        input [ROWS-1:0] mask_i;
        input integer ord_i;
        integer row_i;
        integer seen_i;
        begin
            active_row_index = 0;
            seen_i = 0;
            for (row_i = 0; row_i < ROWS; row_i = row_i + 1) begin
                if (mask_i[row_i]) begin
                    if (seen_i == ord_i) begin
                        active_row_index = row_i;
                    end
                    seen_i = seen_i + 1;
                end
            end
        end
    endfunction

    function [TIME_W:0] calc_mask_last_t;
        input [TIME_W-1:0] tile_t_base_i;
        input [ROWS-1:0] mask_i;
        integer row_i;
        begin
            calc_mask_last_t = {1'b0, tile_t_base_i};
            for (row_i = 0; row_i < ROWS; row_i = row_i + 1) begin
                if (mask_i[row_i]) begin
                    calc_mask_last_t = {1'b0, tile_t_base_i} + row_i;
                end
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

    function row_has_all_banks;
        input valid_i;
        input [TIME_W-1:0] tag_i;
        input [BANKS-1:0] mask_i;
        input [TIME_W-1:0] target_t_i;
        begin
            row_has_all_banks = valid_i
                && (tag_i == target_t_i)
                && (mask_i == ALL_BANKS_MASK);
        end
    endfunction

    function [BANKS-1:0] bank_onehot;
        input [BANK_W-1:0] bank_i;
        begin
            bank_onehot = {BANKS{1'b0}};
            bank_onehot[bank_i] = 1'b1;
        end
    endfunction

    function [ROWS-1:0] row_onehot;
        input [ROW_SEL_W-1:0] row_i;
        begin
            row_onehot = {ROWS{1'b0}};
            row_onehot[row_i] = 1'b1;
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

    function slot_can_overwrite_value;
        input valid_i;
        input [TIME_W-1:0] tag_i;
        input served_valid_i;
        input [TIME_W:0] served_last_t_i;
        input [TIME_W-1:0] target_t_i;
        begin
            slot_can_overwrite_value = !valid_i
                || (tag_i == target_t_i)
                || (served_valid_i && ({1'b0, tag_i} <= served_last_t_i));
        end
    endfunction

    function signed [ACT_W-1:0] make_act_vec_from_cache;
        input [6:0] k_i;
        input [ROWS-1:0] mask_i;
        integer row_i;
        integer bank_i;
        integer lane_i;
        reg signed [WORD_W-1:0] word_i;
        begin
            make_act_vec_from_cache = {ACT_W{1'b0}};
            bank_i = k_i / CH_LANES;
            lane_i = k_i % CH_LANES;
            for (row_i = 0; row_i < ROWS; row_i = row_i + 1) begin
                if (mask_i[row_i]) begin
                    word_i = read_tile_cache(bank_i, row_i);
                    make_act_vec_from_cache[row_i*DATA_W +: DATA_W]
                        = word_i[lane_i*DATA_W +: DATA_W];
                end
            end
        end
    endfunction

    function signed [WORD_W-1:0] read_tile_cache;
        input integer bank_i;
        input integer row_i;
        begin
            case (row_i)
                0: read_tile_cache = tile_cache_row0[bank_i];
                1: read_tile_cache = tile_cache_row1[bank_i];
                2: read_tile_cache = tile_cache_row2[bank_i];
                default: read_tile_cache = tile_cache_row3[bank_i];
            endcase
        end
    endfunction

    function [BANK_W-1:0] load_cache_bank;
        input [ROWS-1:0] mask_i;
        input [LOAD_W-1:0] load_idx_i;
        integer active_rows_i;
        begin
            active_rows_i = count_valid_rows(mask_i);
            if (active_rows_i == 0) begin
                load_cache_bank = {BANK_W{1'b0}};
            end else begin
                case (active_rows_i)
                    1: load_cache_bank = load_idx_i;
                    2: load_cache_bank = load_idx_i >> 1;
                    3: load_cache_bank = load_idx_i / 3;
                    default: load_cache_bank = load_idx_i >> 2;
                endcase
            end
        end
    endfunction

    function [ROW_SEL_W-1:0] load_cache_row;
        input [ROWS-1:0] mask_i;
        input [LOAD_W-1:0] load_idx_i;
        integer active_rows_i;
        integer row_ord_i;
        begin
            active_rows_i = count_valid_rows(mask_i);
            if (active_rows_i == 0) begin
                row_ord_i = 0;
            end else begin
                case (active_rows_i)
                    1: row_ord_i = 0;
                    2: row_ord_i = load_idx_i[0];
                    3: row_ord_i = load_idx_i - ((load_idx_i / 3) * 3);
                    default: row_ord_i = load_idx_i[1:0];
                endcase
            end
            load_cache_row = active_row_index(mask_i, row_ord_i);
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            for (rst_bank = 0; rst_bank < BANKS; rst_bank = rst_bank + 1) begin
                for (rst_row = 0; rst_row < RING_ROWS; rst_row = rst_row + 1) begin
                    slot_valid[rst_bank][rst_row] <= 1'b0;
                    slot_tag[rst_bank][rst_row] <= {TIME_W{1'b0}};
                end
            end
            for (rst_row = 0; rst_row < RING_ROWS; rst_row = rst_row + 1) begin
                row_seen_valid[rst_row] <= 1'b0;
                row_seen_tag[rst_row] <= {TIME_W{1'b0}};
                row_seen_mask[rst_row] <= {BANKS{1'b0}};
            end
            served_valid <= 1'b0;
            served_last_t <= {(TIME_W+1){1'b0}};
        end else begin
            if (dw2_fire) begin
                full_idx = dw2_out_t % RING_ROWS;
                slot_valid[dw2_bank_c][full_idx[ROW_IDX_W-1:0]] <= 1'b1;
                slot_tag[dw2_bank_c][full_idx[ROW_IDX_W-1:0]] <= dw2_out_t;

                row_seen_valid[full_idx[ROW_IDX_W-1:0]] <= 1'b1;
                row_seen_tag[full_idx[ROW_IDX_W-1:0]] <= dw2_out_t;
                if (!row_seen_valid[full_idx[ROW_IDX_W-1:0]]
                    || (row_seen_tag[full_idx[ROW_IDX_W-1:0]] != dw2_out_t)) begin
                    row_seen_mask[full_idx[ROW_IDX_W-1:0]]
                        <= bank_onehot(dw2_bank_c);
                end else begin
                    row_seen_mask[full_idx[ROW_IDX_W-1:0]]
                        <= row_seen_mask[full_idx[ROW_IDX_W-1:0]]
                        | bank_onehot(dw2_bank_c);
                end
            end

            if (load_done_next) begin
                served_valid <= 1'b1;
                if (!served_valid
                    || (calc_mask_last_t(rd_tile_t_base, rd_row_valid_mask)
                        >= served_last_t)) begin
                    served_last_t
                        <= calc_mask_last_t(rd_tile_t_base, rd_row_valid_mask);
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            bram_a_valid_d <= {(BRAM_READ_LATENCY+1){1'b0}};
            bram_b_valid_d <= {(BRAM_READ_LATENCY+1){1'b0}};
            bram_a_addr_hold <= {ADDR_W{1'b0}};
            bram_b_addr_hold <= {ADDR_W{1'b0}};
            cache_wr_a_valid <= 1'b0;
            cache_wr_b_valid <= 1'b0;
            cache_wr_a_bank_oh <= {BANKS{1'b0}};
            cache_wr_b_bank_oh <= {BANKS{1'b0}};
            cache_wr_a_row_oh <= {ROWS{1'b0}};
            cache_wr_b_row_oh <= {ROWS{1'b0}};
            cache_wr_a_data <= {WORD_W{1'b0}};
            cache_wr_b_data <= {WORD_W{1'b0}};
            for (seq_i = 0; seq_i <= BRAM_READ_LATENCY; seq_i = seq_i + 1) begin
                bram_a_cache_bank_d[seq_i] <= {BANK_W{1'b0}};
                bram_b_cache_bank_d[seq_i] <= {BANK_W{1'b0}};
                bram_a_cache_row_d[seq_i] <= {ROW_SEL_W{1'b0}};
                bram_b_cache_row_d[seq_i] <= {ROW_SEL_W{1'b0}};
            end
        end else begin
            if (load_issue_a) begin
                bram_a_addr_hold <= bram_a_addr;
            end
            if (load_issue_b) begin
                bram_b_addr_hold <= bram_b_addr;
            end

            bram_a_valid_d[0] <= load_issue_a;
            bram_b_valid_d[0] <= load_issue_b;
            bram_a_cache_bank_d[0]
                <= load_cache_bank(rd_row_valid_mask, load_issue_idx);
            bram_b_cache_bank_d[0]
                <= load_cache_bank(rd_row_valid_mask, load_issue_idx + 1'b1);
            bram_a_cache_row_d[0]
                <= load_cache_row(rd_row_valid_mask, load_issue_idx);
            bram_b_cache_row_d[0]
                <= load_cache_row(rd_row_valid_mask, load_issue_idx + 1'b1);
            for (seq_i = 1; seq_i <= BRAM_READ_LATENCY; seq_i = seq_i + 1) begin
                bram_a_valid_d[seq_i] <= bram_a_valid_d[seq_i-1];
                bram_b_valid_d[seq_i] <= bram_b_valid_d[seq_i-1];
                bram_a_cache_bank_d[seq_i] <= bram_a_cache_bank_d[seq_i-1];
                bram_b_cache_bank_d[seq_i] <= bram_b_cache_bank_d[seq_i-1];
                bram_a_cache_row_d[seq_i] <= bram_a_cache_row_d[seq_i-1];
                bram_b_cache_row_d[seq_i] <= bram_b_cache_row_d[seq_i-1];
            end

            cache_wr_a_valid <= load_capture_a;
            cache_wr_b_valid <= load_capture_b;
            cache_wr_a_bank_oh
                <= bank_onehot(bram_a_cache_bank_d[BRAM_READ_LATENCY]);
            cache_wr_b_bank_oh
                <= bank_onehot(bram_b_cache_bank_d[BRAM_READ_LATENCY]);
            cache_wr_a_row_oh
                <= row_onehot(bram_a_cache_row_d[BRAM_READ_LATENCY]);
            cache_wr_b_row_oh
                <= row_onehot(bram_b_cache_row_d[BRAM_READ_LATENCY]);
            cache_wr_a_data <= bram_a_dout;
            cache_wr_b_data <= bram_b_dout;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            rd_state <= RD_IDLE;
            rd_tile_t_base <= {TIME_W{1'b0}};
            rd_row_valid_mask <= {ROWS{1'b0}};
            load_issue_idx <= {LOAD_W{1'b0}};
            load_capture_count <= {LOAD_W{1'b0}};
            act_resp_valid <= 1'b0;
            act_resp_last <= 1'b0;
            act_resp_data <= {ACT_W{1'b0}};
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    load_issue_idx <= {LOAD_W{1'b0}};
                    load_capture_count <= {LOAD_W{1'b0}};
                    act_resp_valid <= 1'b0;
                    act_resp_last <= 1'b0;
                    if (tile_req_fire) begin
                        rd_tile_t_base <= tile_req_t_base_q;
                        rd_row_valid_mask <= tile_req_row_valid_mask_q;
                        rd_state <= RD_LOAD;
                    end
                end

                RD_LOAD: begin
                    if (load_issue_idx < active_load_words) begin
                        load_issue_idx <= load_issue_idx + 2'd2;
                    end

                    load_capture_count <= load_capture_count + load_capture_inc;
                    if (load_done_next) begin
                        load_issue_idx <= {LOAD_W{1'b0}};
                        load_capture_count <= {LOAD_W{1'b0}};
                        act_resp_last <= 1'b0;
                        rd_state <= RD_COMMIT;
                    end
                end

                RD_COMMIT: begin
                        rd_state <= RD_READY;
                end

                RD_READY: begin
                    if (act_req_fire) begin
                        act_resp_valid <= 1'b1;
                        act_resp_last <= (act_req_k == (PW2_IC - 1));
                        act_resp_data
                            <= make_act_vec_from_cache(act_req_k, rd_row_valid_mask);
                    end else if (act_resp_fire) begin
                        act_resp_valid <= 1'b0;
                        act_resp_last <= 1'b0;
                        act_resp_data <= {ACT_W{1'b0}};
                    end

                    if (act_resp_last_fire && !act_req_fire) begin
                        rd_state <= RD_IDLE;
                        act_resp_valid <= 1'b0;
                        act_resp_last <= 1'b0;
                        act_resp_data <= {ACT_W{1'b0}};
                    end
                end

                default: begin
                    rd_state <= RD_IDLE;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        for (cache_bank = 0; cache_bank < BANKS; cache_bank = cache_bank + 1) begin
            if (cache_wr_a_valid && cache_wr_a_bank_oh[cache_bank]) begin
                if (cache_wr_a_row_oh[0]) begin
                    tile_cache_row0[cache_bank] <= cache_wr_a_data;
                end
                if (cache_wr_a_row_oh[1]) begin
                    tile_cache_row1[cache_bank] <= cache_wr_a_data;
                end
                if (cache_wr_a_row_oh[2]) begin
                    tile_cache_row2[cache_bank] <= cache_wr_a_data;
                end
                if (cache_wr_a_row_oh[3]) begin
                    tile_cache_row3[cache_bank] <= cache_wr_a_data;
                end
            end
            if (cache_wr_b_valid && cache_wr_b_bank_oh[cache_bank]) begin
                if (cache_wr_b_row_oh[0]) begin
                    tile_cache_row0[cache_bank] <= cache_wr_b_data;
                end
                if (cache_wr_b_row_oh[1]) begin
                    tile_cache_row1[cache_bank] <= cache_wr_b_data;
                end
                if (cache_wr_b_row_oh[2]) begin
                    tile_cache_row2[cache_bank] <= cache_wr_b_data;
                end
                if (cache_wr_b_row_oh[3]) begin
                    tile_cache_row3[cache_bank] <= cache_wr_b_data;
                end
            end
        end
    end

`ifndef SYNTHESIS
    reg [31:0] invalid_dw2_write_count;
    reg [31:0] dw2_overwrite_stall_count;
    reg [31:0] invalid_tile_req_count;
    reg [31:0] unavailable_tile_req_count;
    reg [31:0] invalid_act_req_count;
    reg [31:0] early_act_req_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            invalid_dw2_write_count <= 32'd0;
            dw2_overwrite_stall_count <= 32'd0;
            invalid_tile_req_count <= 32'd0;
            unavailable_tile_req_count <= 32'd0;
            invalid_act_req_count <= 32'd0;
            early_act_req_count <= 32'd0;
        end else begin
            if (dw2_out_valid && !dw2_params_valid_c) begin
                invalid_dw2_write_count <= invalid_dw2_write_count + 1'b1;
            end
            if (dw2_overwrite_stall) begin
                dw2_overwrite_stall_count <= dw2_overwrite_stall_count + 1'b1;
            end
            if (input_tile_req_valid
                && (rd_state == RD_IDLE)
                && !tile_params_valid_c) begin
                invalid_tile_req_count <= invalid_tile_req_count + 1'b1;
            end
            if (input_tile_req_valid
                && (rd_state == RD_IDLE)
                && tile_params_valid_c
                && !tile_available_c) begin
                unavailable_tile_req_count <= unavailable_tile_req_count + 1'b1;
            end
            if (act_req_valid
                && (rd_state == RD_READY)
                && !act_req_params_valid_c) begin
                invalid_act_req_count <= invalid_act_req_count + 1'b1;
            end
            if (act_req_valid && (rd_state != RD_READY)) begin
                early_act_req_count <= early_act_req_count + 1'b1;
            end
        end
    end
`endif

endmodule
