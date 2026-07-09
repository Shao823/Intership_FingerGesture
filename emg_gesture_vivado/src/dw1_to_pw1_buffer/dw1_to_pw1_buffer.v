`timescale 1ns / 1ps

// Inter-stage buffer controller from dw_conv1_4ch_5tap to
// pw_conv1_array_4x8.
//
// BRAM layout expected by this controller:
//   128 x 64-bit true-dual-port RAM
//   bank = ch_base / 4, bank 0..7 for 32 DW1 channels
//   row  = absolute out_t % 16
//   addr = bank * 16 + row
//   word = {x[ch_base+3], x[ch_base+2], x[ch_base+1], x[ch_base+0]}
//
// The BRAM stores only feature data. Ring metadata stays in registers:
//   slot_valid[bank][row]
//   slot_tag[bank][row] = absolute output time stored in the slot
//
// A PW1 tile request is accepted when four consecutive output rows are present
// for all eight 4-channel banks. After the request is accepted, both BRAM ports
// preload the 4x32 activation tile into local registers. Runtime act_req reads
// then come from the local cache, not from BRAM, so the first PW1 oc group can
// fetch each input channel once and later groups can reuse PW1's own cache.
//
// Scheduler contract:
//   PW1 tile requests must be monotonic and must not skip a tile that may be
//   requested later. A row slot may be overwritten after the tile containing the
//   old row has been preloaded into this controller's local cache.
//
// clear behavior:
//   clear resets controller state and all valid/tag/watermark metadata. It does
//   not clear BRAM contents. Stale BRAM words are ignored until metadata is
//   written again.

module dw1_to_pw1_buffer #(
    parameter integer DATA_W     = 16,
    parameter integer TIME_W     = 9,
    parameter integer INPUT_LEN  = 348,
    parameter integer PW1_IC     = 32,
    parameter integer ROWS       = 4,
    parameter integer CH_LANES   = 4,
    parameter integer RING_ROWS  = 16,
    parameter integer BANKS      = PW1_IC / CH_LANES,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer CH_BASE_W  = (PW1_IC <= 1) ? 1 : $clog2(PW1_IC + 1),
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

    input  wire dw1_out_valid,
    output wire dw1_out_ready,
    input  wire [TIME_W-1:0] dw1_out_t,
    input  wire [CH_BASE_W-1:0] dw1_out_ch_base,
    input  wire signed [CH_LANES*DATA_W-1:0] dw1_out_vec,

    input  wire input_tile_req_valid,
    output wire input_tile_req_ready,
    input  wire [TIME_W-1:0] input_tile_req_t_base,

    input  wire act_req_valid,
    output wire act_req_ready,
    input  wire [TIME_W-1:0] act_req_t_base,
    input  wire [5:0] act_req_k,

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
    output wire dw1_overwrite_stall
);

    localparam integer WORD_W = CH_LANES * DATA_W;
    localparam integer ACT_W  = ROWS * DATA_W;
    localparam [LOAD_W-1:0] LOAD_WORDS_C = LOAD_WORDS;

    localparam [1:0] RD_IDLE  = 2'd0;
    localparam [1:0] RD_LOAD  = 2'd1;
    localparam [1:0] RD_READY = 2'd2;

    reg [1:0] rd_state;
    reg [TIME_W-1:0] rd_tile_t_base;
    reg [LOAD_W-1:0] load_issue_idx;
    reg [LOAD_W-1:0] load_capture_count;
    reg [LOAD_W-1:0] act_resp_count;
    reg act_resp_valid;
    reg signed [ACT_W-1:0] act_resp_data;

    (* ram_style = "distributed" *) reg slot_valid [0:BANKS-1][0:RING_ROWS-1];
    (* ram_style = "distributed" *) reg [TIME_W-1:0] slot_tag [0:BANKS-1][0:RING_ROWS-1];
    reg served_valid;
    reg [TIME_W-1:0] served_tile_t_base;

    reg signed [WORD_W-1:0] tile_cache [0:LOAD_WORDS-1];

    reg [BRAM_READ_LATENCY:0] bram_a_valid_d;
    reg [BRAM_READ_LATENCY:0] bram_b_valid_d;
    reg [LOAD_W-1:0] bram_a_idx_d [0:BRAM_READ_LATENCY];
    reg [LOAD_W-1:0] bram_b_idx_d [0:BRAM_READ_LATENCY];
    reg [ADDR_W-1:0] bram_a_addr_hold;
    reg [ADDR_W-1:0] bram_b_addr_hold;

    wire dw1_fire;
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

    reg dw1_params_valid_c;
    reg dw1_slot_safe_c;
    reg [BANK_W-1:0] dw1_bank_c;
    reg tile_params_valid_c;
    reg tile_available_c;
    reg act_req_params_valid_c;

    integer wr_comb_idx;
    integer tile_comb_bank;
    integer tile_comb_row;
    integer tile_comb_t;
    integer tile_comb_idx;
    reg [TIME_W-1:0] tile_comb_t_vec;
    integer rst_bank;
    integer rst_row;
    integer seq_i;

    initial begin
        if ((PW1_IC % CH_LANES) != 0) begin
            $error("dw1_to_pw1_buffer: PW1_IC must be divisible by CH_LANES");
        end
        if (RING_ROWS < (ROWS * 3)) begin
            $error(
                "dw1_to_pw1_buffer: RING_ROWS %0d too small, need >= %0d",
                RING_ROWS,
                ROWS * 3
            );
        end
        if (BRAM_READ_LATENCY < 1) begin
            $error("dw1_to_pw1_buffer: BRAM_READ_LATENCY must be >= 1");
        end
    end

    assign load_active = (rd_state == RD_LOAD);

    assign dw1_out_ready = !clear
        && !load_active
        && dw1_params_valid_c
        && dw1_slot_safe_c;
    assign dw1_fire = dw1_out_valid && dw1_out_ready;
    assign dw1_overwrite_stall = dw1_out_valid
        && dw1_params_valid_c
        && !dw1_slot_safe_c
        && !clear;

    assign input_tile_req_ready = !clear
        && (rd_state == RD_IDLE)
        && tile_params_valid_c
        && tile_available_c;
    assign tile_req_fire = input_tile_req_valid && input_tile_req_ready;

    assign act_req_ready = !clear
        && (rd_state == RD_READY)
        && act_req_params_valid_c
        && (!act_resp_valid || act_vec_ready);
    assign act_req_fire = act_req_valid && act_req_ready;

    assign act_vec_valid = act_resp_valid;
    assign act_vec = act_resp_data;
    assign act_resp_fire = act_vec_valid && act_vec_ready;
    assign act_resp_last_fire = act_resp_fire
        && (act_resp_count == (PW1_IC - 1));

    assign load_issue_a = load_active && (load_issue_idx < LOAD_WORDS);
    assign load_issue_b = load_active && ((load_issue_idx + 1'b1) < LOAD_WORDS);
    assign load_pipe_a_en = load_active && any_pre_response_valid(bram_a_valid_d);
    assign load_pipe_b_en = load_active && any_pre_response_valid(bram_b_valid_d);
    assign load_capture_a = bram_a_valid_d[BRAM_READ_LATENCY];
    assign load_capture_b = bram_b_valid_d[BRAM_READ_LATENCY];
    assign load_capture_inc = {1'b0, load_capture_a} + {1'b0, load_capture_b};
    assign load_done_next = load_active
        && ((load_capture_count + load_capture_inc) >= LOAD_WORDS_C);

    assign bram_a_en = load_issue_a || load_pipe_a_en || dw1_fire;
    assign bram_a_we = !load_active && dw1_fire;
    assign bram_a_addr = load_issue_a
        ? calc_load_addr(rd_tile_t_base, load_issue_idx)
        : (load_pipe_a_en
            ? bram_a_addr_hold
            : calc_sample_addr(dw1_bank_c, dw1_out_t));
    assign bram_a_din = dw1_out_vec;

    assign bram_b_en = load_issue_b || load_pipe_b_en;
    assign bram_b_we = 1'b0;
    assign bram_b_addr = load_issue_b
        ? calc_load_addr(rd_tile_t_base, load_issue_idx + 1'b1)
        : bram_b_addr_hold;
    assign bram_b_din = {WORD_W{1'b0}};

    assign wr_busy = dw1_fire;
    assign rd_busy = (rd_state != RD_IDLE);
    assign tile_cache_valid = (rd_state == RD_READY);

    always @* begin
        dw1_bank_c = dw1_out_ch_base / CH_LANES;
        wr_comb_idx = 0;
        dw1_params_valid_c = ((dw1_out_ch_base % CH_LANES) == 0)
            && (dw1_out_ch_base <= (PW1_IC - CH_LANES))
            && (dw1_out_t < INPUT_LEN);
        dw1_slot_safe_c = dw1_params_valid_c;

        if (dw1_params_valid_c) begin
            wr_comb_idx = dw1_out_t % RING_ROWS;
            if (!slot_can_overwrite_value(
                    slot_valid[dw1_bank_c][wr_comb_idx[ROW_IDX_W-1:0]],
                    slot_tag[dw1_bank_c][wr_comb_idx[ROW_IDX_W-1:0]],
                    served_valid,
                    served_tile_t_base,
                    dw1_out_t
                )) begin
                dw1_slot_safe_c = 1'b0;
            end
        end
    end

    always @* begin
        tile_params_valid_c = (input_tile_req_t_base <= (INPUT_LEN - ROWS));
        tile_available_c = tile_params_valid_c;
        tile_comb_t = 0;
        tile_comb_idx = 0;
        tile_comb_t_vec = {TIME_W{1'b0}};

        if (tile_params_valid_c) begin
            for (tile_comb_row = 0;
                 tile_comb_row < ROWS;
                 tile_comb_row = tile_comb_row + 1) begin
                tile_comb_t = input_tile_req_t_base + tile_comb_row;
                tile_comb_idx = tile_comb_t % RING_ROWS;
                tile_comb_t_vec = tile_comb_t;
                for (tile_comb_bank = 0;
                     tile_comb_bank < BANKS;
                     tile_comb_bank = tile_comb_bank + 1) begin
                    if (!slot_has_time(
                            slot_valid[tile_comb_bank][tile_comb_idx[ROW_IDX_W-1:0]],
                            slot_tag[tile_comb_bank][tile_comb_idx[ROW_IDX_W-1:0]],
                            tile_comb_t_vec
                        )) begin
                        tile_available_c = 1'b0;
                    end
                end
            end
        end
    end

    always @* begin
        act_req_params_valid_c = (act_req_t_base == rd_tile_t_base)
            && (act_req_k < PW1_IC);
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
        input [LOAD_W-1:0] load_idx_i;
        integer bank_i;
        integer row_i;
        integer time_i;
        begin
            bank_i = load_idx_i / ROWS;
            row_i = load_idx_i % ROWS;
            time_i = tile_t_base_i + row_i;
            calc_load_addr = (bank_i * RING_ROWS) + (time_i % RING_ROWS);
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
        input [TIME_W-1:0] served_tile_t_base_i;
        input [TIME_W-1:0] target_t_i;
        reg [TIME_W:0] served_last_t_i;
        begin
            served_last_t_i = {1'b0, served_tile_t_base_i} + (ROWS - 1);
            slot_can_overwrite_value = !valid_i
                || (tag_i == target_t_i)
                || (served_valid_i && ({1'b0, tag_i} <= served_last_t_i));
        end
    endfunction

    function signed [ACT_W-1:0] make_act_vec_from_cache;
        input [5:0] k_i;
        integer row_i;
        integer bank_i;
        integer lane_i;
        reg signed [WORD_W-1:0] word_i;
        begin
            make_act_vec_from_cache = {ACT_W{1'b0}};
            bank_i = k_i / CH_LANES;
            lane_i = k_i % CH_LANES;
            for (row_i = 0; row_i < ROWS; row_i = row_i + 1) begin
                word_i = tile_cache[bank_i*ROWS + row_i];
                make_act_vec_from_cache[row_i*DATA_W +: DATA_W]
                    = word_i[lane_i*DATA_W +: DATA_W];
            end
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
            served_valid <= 1'b0;
            served_tile_t_base <= {TIME_W{1'b0}};
        end else begin
            if (dw1_fire) begin
                slot_valid[dw1_bank_c][dw1_out_t % RING_ROWS] <= 1'b1;
                slot_tag[dw1_bank_c][dw1_out_t % RING_ROWS] <= dw1_out_t;
            end

            if (load_done_next) begin
                served_valid <= 1'b1;
                if (!served_valid
                    || ({1'b0, rd_tile_t_base} >= {1'b0, served_tile_t_base})) begin
                    served_tile_t_base <= rd_tile_t_base;
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
            for (seq_i = 0; seq_i <= BRAM_READ_LATENCY; seq_i = seq_i + 1) begin
                bram_a_idx_d[seq_i] <= {LOAD_W{1'b0}};
                bram_b_idx_d[seq_i] <= {LOAD_W{1'b0}};
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
            bram_a_idx_d[0] <= load_issue_idx;
            bram_b_idx_d[0] <= load_issue_idx + 1'b1;
            for (seq_i = 1; seq_i <= BRAM_READ_LATENCY; seq_i = seq_i + 1) begin
                bram_a_valid_d[seq_i] <= bram_a_valid_d[seq_i-1];
                bram_b_valid_d[seq_i] <= bram_b_valid_d[seq_i-1];
                bram_a_idx_d[seq_i] <= bram_a_idx_d[seq_i-1];
                bram_b_idx_d[seq_i] <= bram_b_idx_d[seq_i-1];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            rd_state <= RD_IDLE;
            rd_tile_t_base <= {TIME_W{1'b0}};
            load_issue_idx <= {LOAD_W{1'b0}};
            load_capture_count <= {LOAD_W{1'b0}};
            act_resp_count <= {LOAD_W{1'b0}};
            act_resp_valid <= 1'b0;
            act_resp_data <= {ACT_W{1'b0}};
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    load_issue_idx <= {LOAD_W{1'b0}};
                    load_capture_count <= {LOAD_W{1'b0}};
                    act_resp_count <= {LOAD_W{1'b0}};
                    act_resp_valid <= 1'b0;
                    if (tile_req_fire) begin
                        rd_tile_t_base <= input_tile_req_t_base;
                        rd_state <= RD_LOAD;
                    end
                end

                RD_LOAD: begin
                    if (load_issue_idx < LOAD_WORDS) begin
                        load_issue_idx <= load_issue_idx + 2'd2;
                    end

                    if (load_capture_a) begin
                        tile_cache[bram_a_idx_d[BRAM_READ_LATENCY]] <= bram_a_dout;
                    end
                    if (load_capture_b) begin
                        tile_cache[bram_b_idx_d[BRAM_READ_LATENCY]] <= bram_b_dout;
                    end

                    load_capture_count <= load_capture_count + load_capture_inc;
                    if (load_done_next) begin
                        load_issue_idx <= {LOAD_W{1'b0}};
                        load_capture_count <= {LOAD_W{1'b0}};
                        act_resp_count <= {LOAD_W{1'b0}};
                        rd_state <= RD_READY;
                    end
                end

                RD_READY: begin
                    if (act_req_fire) begin
                        act_resp_valid <= 1'b1;
                        act_resp_data <= make_act_vec_from_cache(act_req_k);
                    end else if (act_resp_fire) begin
                        act_resp_valid <= 1'b0;
                        act_resp_data <= {ACT_W{1'b0}};
                    end

                    if (act_resp_fire) begin
                        act_resp_count <= act_resp_count + 1'b1;
                    end

                    if (act_resp_last_fire && !act_req_fire) begin
                        rd_state <= RD_IDLE;
                        act_resp_count <= {LOAD_W{1'b0}};
                        act_resp_valid <= 1'b0;
                        act_resp_data <= {ACT_W{1'b0}};
                    end
                end

                default: begin
                    rd_state <= RD_IDLE;
                end
            endcase
        end
    end

`ifndef SYNTHESIS
    reg [31:0] invalid_dw1_write_count;
    reg [31:0] dw1_overwrite_stall_count;
    reg [31:0] invalid_tile_req_count;
    reg [31:0] unavailable_tile_req_count;
    reg [31:0] invalid_act_req_count;
    reg [31:0] early_act_req_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            invalid_dw1_write_count <= 32'd0;
            dw1_overwrite_stall_count <= 32'd0;
            invalid_tile_req_count <= 32'd0;
            unavailable_tile_req_count <= 32'd0;
            invalid_act_req_count <= 32'd0;
            early_act_req_count <= 32'd0;
        end else begin
            if (dw1_out_valid && !dw1_params_valid_c) begin
                invalid_dw1_write_count <= invalid_dw1_write_count + 1'b1;
            end
            if (dw1_overwrite_stall) begin
                dw1_overwrite_stall_count <= dw1_overwrite_stall_count + 1'b1;
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
