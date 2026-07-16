`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

// Final EMG gesture accelerator top for synthesis/IP packaging.
//
// This module is intentionally parallel to the verification-oriented full top.
// It directly instantiates the compute blocks and inter-stage buffers, fixes
// all model weights to their internal ROM/BRAM IPs, and exposes only the
// runtime activation write port plus final class result.

module accelerator #(
    parameter integer DATA_W     =  8,
    parameter integer MULT_W     = 16,
    parameter integer ACC_W      = 48,
    parameter integer ROWS       = 4,
    parameter integer STEM_OC_LANES = 4,
    parameter integer PW1_OC_LANES  = 8,
    parameter integer PW2_OC_LANES  = 12,
    parameter integer FC_AVG_LANES  = 12,
    parameter integer POOL_ROWS  = 2,
    parameter integer CH_LANES   = 4,
    parameter integer STEM_OC    = 32,
    parameter integer PW1_OC     = 64,
    parameter integer PW2_OC     = 96,
    parameter integer FC_CLASSES = 5,
    parameter integer STEM_K     = 35,
    parameter integer STEM_IC    = 5,
    parameter integer STEM_KERNEL = 7,
    parameter integer STEM_PADDING = 3,
    parameter integer DW_K       = 5,
    parameter integer DW_PAD     = 2,
    parameter integer INPUT_LEN  = 348,
    parameter integer FRAC_BITS  = 8,
    parameter integer TIME_W     = 9,
    parameter integer ROWS_W     = 4,
    parameter integer LOW_TIME_W = 8,
    parameter integer DW2_ROWS_W = 3,
    parameter integer STEM_TO_DW1_RING_ROWS = 8,
    parameter integer DW1_TO_PW1_RING_ROWS  = 16,
    parameter integer PW1_TO_DW2_RING_ROWS  = 8,
    parameter integer DW2_TO_PW2_RING_ROWS  = 8,
    parameter integer PENDING_DEPTH = 8,
    parameter integer DW2_PENDING_DEPTH = 32,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer POOL_LEN   = INPUT_LEN / 2,
    parameter integer CH_GROUPS  = STEM_OC / STEM_OC_LANES,
    parameter integer ACT_TIME_WORDS = (INPUT_LEN + ROWS - 1) / ROWS,
    parameter integer ACT_RAM_DEPTH  = STEM_IC * ACT_TIME_WORDS,
    parameter integer ACT_ADDR_W     = (ACT_RAM_DEPTH <= 1)
        ? 1 : $clog2(ACT_RAM_DEPTH),
    parameter integer PENDING_PTR_W  = (PENDING_DEPTH <= 1)
        ? 1 : $clog2(PENDING_DEPTH),
    parameter integer PENDING_CNT_W  = (PENDING_DEPTH <= 1)
        ? 1 : $clog2(PENDING_DEPTH + 1),
    parameter integer DW2_PENDING_PTR_W = (DW2_PENDING_DEPTH <= 1)
        ? 1 : $clog2(DW2_PENDING_DEPTH),
    parameter integer DW2_PENDING_CNT_W = (DW2_PENDING_DEPTH <= 1)
        ? 1 : $clog2(DW2_PENDING_DEPTH + 1)
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    output reg busy,
    output reg done,

    input  wire act_wr_en,
    input  wire [ACT_ADDR_W-1:0] act_wr_addr,
    input  wire [ROWS*DATA_W-1:0] act_wr_data,
    output wire act_wr_ready,

    output wire class_valid,
    output wire [2:0] class_idx
);

    localparam integer STEM_OC_BASE_W = 5;
    localparam integer PW1_CH_BASE_W = 6;
    localparam integer LOW_CH_BASE_W = 6;
    localparam integer PW2_CH_BASE_W = 7;
    localparam [PENDING_CNT_W-1:0] PENDING_DEPTH_COUNT = PENDING_DEPTH;
    localparam [DW2_PENDING_CNT_W-1:0] DW2_PENDING_DEPTH_COUNT =
        DW2_PENDING_DEPTH;
    localparam [ROWS_W-1:0] ROWS_VALUE = ROWS;
    localparam [DW2_ROWS_W-1:0] POOL_ROWS_VALUE = POOL_ROWS;
    localparam integer STEM_TO_DW1_SLICE_DEPTH = 2;
    localparam [PENDING_CNT_W-1:0] DW1_PENDING_LAUNCH_LIMIT =
        PENDING_DEPTH - STEM_TO_DW1_SLICE_DEPTH;
    localparam integer STEM_OUT_SLICE_W = TIME_W + 5
        + (ROWS * STEM_OC_LANES * DATA_W);
    localparam integer DW1_OUT_SLICE_W = TIME_W + 5
        + (STEM_OC_LANES * DATA_W);
    localparam integer PW1_OUT_SLICE_W = LOW_TIME_W + 6
        + (POOL_ROWS * PW1_OC_LANES * DATA_W);
    localparam integer DW2_OUT_SLICE_W = LOW_TIME_W + 6
        + (CH_LANES * DATA_W);
    localparam integer PW2_FINAL_TILE_T_BASE = ((POOL_LEN - 1) / ROWS) * ROWS;
    localparam [LOW_TIME_W-1:0] PW2_FINAL_TILE_T_BASE_VALUE =
        PW2_FINAL_TILE_T_BASE;

    reg buffer_clear;
    reg pw2_gap_clear;
    reg activation_load_bank;
    reg activation_read_bank;

    reg stem_start;
    reg [4:0] stem_oc_base;
    reg [TIME_W-1:0] stem_tile_t_base;
    wire stem_busy;
    wire stem_done;
    wire stem_out_valid;
    wire stem_to_buffer_ready;
    wire [TIME_W-1:0] stem_out_tile_t_base;
    wire [4:0] stem_out_tile_oc_base;
    wire signed [ROWS*STEM_OC_LANES*DATA_W-1:0] stem_out_tile;
    wire stem_to_dw1_in_valid;
    wire stem_to_dw1_in_ready;
    wire stem_to_dw1_slice_valid;
    wire stem_to_dw1_slice_ready;
    wire stem_to_dw1_slice_busy;
    wire [STEM_OUT_SLICE_W-1:0] stem_to_dw1_slice_in;
    wire [STEM_OUT_SLICE_W-1:0] stem_to_dw1_slice_out;
    wire [TIME_W-1:0] stem_to_dw1_slice_tile_t_base;
    wire [4:0] stem_to_dw1_slice_tile_oc_base;
    wire signed [ROWS*STEM_OC_LANES*DATA_W-1:0] stem_to_dw1_slice_tile;
    wire [TIME_W-1:0] stem_to_dw1_out_tile_t_base;
    wire [4:0] stem_to_dw1_out_tile_oc_base;
    wire signed [ROWS*STEM_OC_LANES*DATA_W-1:0] stem_to_dw1_out_tile;

    wire dw1_win_req_valid;
    wire [TIME_W-1:0] dw1_win_req_out_t;
    wire [4:0] dw1_win_req_ch_base;
    wire dw1_win_req_ready;
    wire dw1_win_vec_valid;
    wire dw1_win_vec_ready;
    wire signed [DW_K*STEM_OC_LANES*DATA_W-1:0] dw1_win_vec;

    reg dw1_start;
    reg [4:0] dw1_ch_base;
    reg [TIME_W-1:0] dw1_input_t_base;
    reg [ROWS_W-1:0] dw1_input_rows;
    reg dw1_final_chunk;
    wire dw1_busy;
    wire dw1_done;
    wire dw1_mid_out_valid;
    wire dw1_mid_out_ready;
    wire [TIME_W-1:0] dw1_mid_out_t;
    wire [4:0] dw1_mid_out_ch_base;
    wire signed [STEM_OC_LANES*DATA_W-1:0] dw1_mid_out_vec;
    wire dw1_to_pw1_in_valid;
    wire dw1_to_pw1_in_ready;
    wire dw1_to_pw1_slice_valid;
    wire dw1_to_pw1_slice_ready;
    wire dw1_to_pw1_slice_busy;
    wire [DW1_OUT_SLICE_W-1:0] dw1_to_pw1_slice_in;
    wire [DW1_OUT_SLICE_W-1:0] dw1_to_pw1_slice_out;
    wire [TIME_W-1:0] dw1_to_pw1_slice_t;
    wire [4:0] dw1_to_pw1_slice_ch_base;
    wire signed [STEM_OC_LANES*DATA_W-1:0] dw1_to_pw1_slice_vec;
    wire [TIME_W-1:0] dw1_to_pw1_out_t;
    wire [4:0] dw1_to_pw1_out_ch_base;
    wire signed [STEM_OC_LANES*DATA_W-1:0] dw1_to_pw1_out_vec;

    wire pw1_input_tile_req_valid;
    wire [TIME_W-1:0] pw1_input_tile_req_t_base;
    wire pw1_input_tile_req_ready;
    wire pw1_act_req_valid;
    wire [TIME_W-1:0] pw1_act_req_t_base;
    wire [5:0] pw1_act_req_k;
    wire pw1_act_req_ready;
    wire pw1_act_vec_valid;
    wire pw1_act_vec_ready;
    wire signed [ROWS*DATA_W-1:0] pw1_act_vec;
    reg pw1_start;
    reg [TIME_W-1:0] pw1_tile_t_base;
    wire pw1_busy;
    wire pw1_done;
    wire pw1_out_ready;
    wire pw1_out_valid;
    wire [TIME_W-1:0] pw1_out_pool_t_base;
    wire [5:0] pw1_out_oc_base;
    wire signed [POOL_ROWS*PW1_OC_LANES*DATA_W-1:0] pw1_out_tile;

    wire pw1_to_dw2_in_valid;
    wire pw1_to_dw2_in_ready;
    wire pw1_to_dw2_slice_valid;
    wire pw1_to_dw2_slice_raw_valid;
    wire pw1_to_dw2_slice_ready;
    wire pw1_to_dw2_out_ready;
    wire pw1_to_dw2_slice_busy;
    wire [PW1_OUT_SLICE_W-1:0] pw1_to_dw2_slice_in;
    wire [PW1_OUT_SLICE_W-1:0] pw1_to_dw2_slice_out;
    wire [LOW_TIME_W-1:0] pw1_to_dw2_slice_pool_t_base;
    wire [5:0] pw1_to_dw2_slice_oc_base;
    wire signed [POOL_ROWS*PW1_OC_LANES*DATA_W-1:0] pw1_to_dw2_slice_tile;
    wire [LOW_TIME_W-1:0] pw1_to_dw2_pool_t_base;
    wire [5:0] pw1_to_dw2_oc_base;
    wire signed [POOL_ROWS*PW1_OC_LANES*DATA_W-1:0] pw1_to_dw2_tile;
    wire dw2_win_req_valid;
    wire dw2_win_req_ready;
    wire [LOW_TIME_W-1:0] dw2_win_req_out_t;
    wire [5:0] dw2_win_req_ch_base;
    wire dw2_win_vec_valid;
    wire dw2_win_vec_ready;
    wire signed [DW_K*CH_LANES*DATA_W-1:0] dw2_win_vec;

    reg dw2_start;
    reg [5:0] dw2_ch_base;
    reg [LOW_TIME_W-1:0] dw2_input_t_base;
    reg [DW2_ROWS_W-1:0] dw2_input_rows;
    reg dw2_final_chunk;
    wire dw2_busy;
    wire dw2_done;
    wire dw2_mid_out_valid;
    wire dw2_mid_out_ready;
    wire [LOW_TIME_W-1:0] dw2_mid_out_t;
    wire [5:0] dw2_mid_out_ch_base;
    wire signed [CH_LANES*DATA_W-1:0] dw2_mid_out_vec;
    wire dw2_to_pw2_in_valid;
    wire dw2_to_pw2_in_ready;
    wire dw2_to_pw2_slice_valid;
    wire dw2_to_pw2_slice_ready;
    wire dw2_to_pw2_slice_busy;
    wire [DW2_OUT_SLICE_W-1:0] dw2_to_pw2_slice_in;
    wire [DW2_OUT_SLICE_W-1:0] dw2_to_pw2_slice_out;
    wire [LOW_TIME_W-1:0] dw2_to_pw2_slice_t;
    wire [5:0] dw2_to_pw2_slice_ch_base;
    wire signed [CH_LANES*DATA_W-1:0] dw2_to_pw2_slice_vec;
    wire [LOW_TIME_W-1:0] dw2_to_pw2_out_t;
    wire [5:0] dw2_to_pw2_out_ch_base;
    wire signed [CH_LANES*DATA_W-1:0] dw2_to_pw2_out_vec;

    wire pw2_input_tile_req_valid;
    wire [LOW_TIME_W-1:0] pw2_input_tile_req_t_base;
    wire [ROWS-1:0] pw2_input_tile_req_row_valid_mask;
    wire pw2_input_tile_req_ready;
    wire pw2_act_req_valid;
    wire [LOW_TIME_W-1:0] pw2_act_req_t_base;
    wire [6:0] pw2_act_req_k;
    wire [ROWS-1:0] pw2_act_req_row_valid_mask;
    wire pw2_act_req_ready;
    wire pw2_act_vec_valid;
    wire pw2_act_vec_ready;
    wire signed [ROWS*DATA_W-1:0] pw2_act_vec;
    reg pw2_start;
    reg [LOW_TIME_W-1:0] pw2_tile_t_base;
    reg [ROWS-1:0] pw2_row_valid_mask;
    wire pw2_busy;
    wire pw2_done;
    wire pw2_gap_frame_done;
    wire [8:0] gap_count;
    wire signed [PW2_OC*ACC_W-1:0] gap_sum_vec;

    reg fc_start;
    reg fc_started;
    wire fc_busy;
    wire fc_done;
    wire fc_result_valid;
    wire [2:0] fc_class_idx;

    reg all_stem_issued;
    reg [TIME_W-1:0] next_tile_t_base;
    reg [4:0] next_ch_base;
    reg [TIME_W-1:0] launched_t_base;
    reg [4:0] launched_ch_base;
    reg launched_final_chunk;

    reg all_pw1_issued;
    reg [TIME_W-1:0] next_pw1_tile_t_base;
    reg all_pw2_issued;
    reg [LOW_TIME_W-1:0] next_pw2_tile_t_base;
    reg pw2_gap_done_seen;

    reg [TIME_W-1:0] dw1_pending_t_base [0:PENDING_DEPTH-1];
    reg [4:0] dw1_pending_ch_base [0:PENDING_DEPTH-1];
    reg dw1_pending_final_chunk [0:PENDING_DEPTH-1];
    reg [PENDING_PTR_W-1:0] dw1_pending_rd_ptr;
    reg [PENDING_PTR_W-1:0] dw1_pending_wr_ptr;
    reg [PENDING_CNT_W-1:0] dw1_pending_count;

    reg [LOW_TIME_W-1:0] dw2_pending_t_base [0:DW2_PENDING_DEPTH-1];
    reg [5:0] dw2_pending_ch_base [0:DW2_PENDING_DEPTH-1];
    reg dw2_pending_final_chunk [0:DW2_PENDING_DEPTH-1];
    reg [DW2_PENDING_PTR_W-1:0] dw2_pending_rd_ptr;
    reg [DW2_PENDING_PTR_W-1:0] dw2_pending_wr_ptr;
    reg [DW2_PENDING_CNT_W-1:0] dw2_pending_count;

    wire schedule_active;
    wire dw1_pending_empty;
    wire dw1_pending_launch_room;
    wire dw2_pending_empty;
    wire dw2_pending_room;
    wire stem_issue_now;
    wire dw1_start_now;
    wire pw1_start_now;
    wire dw2_start_now;
    wire pw2_start_now;
    wire pw1_issue_in_range;
    wire pw2_issue_in_range;
    wire dw1_pending_push;
    wire dw1_pending_pop;
    wire dw2_pending_push;
    wire dw2_pending_pop;
    wire [PENDING_CNT_W-1:0] dw1_pending_count_after_pop;
    wire [PENDING_CNT_W-1:0] dw1_pending_count_next;
    wire [DW2_PENDING_CNT_W-1:0] dw2_pending_count_after_pop;
    wire [DW2_PENDING_CNT_W-1:0] dw2_pending_count_next;
    wire pw1_out_fire;
    assign class_valid = fc_result_valid;
    assign class_idx = fc_class_idx;

    assign schedule_active = busy && !pw2_gap_done_seen && !fc_started;

    assign dw1_pending_empty = (dw1_pending_count == {PENDING_CNT_W{1'b0}});
    assign dw1_pending_count_after_pop = dw1_pending_count
        - {{(PENDING_CNT_W-1){1'b0}}, dw1_pending_pop};
    assign dw1_pending_launch_room = (dw1_pending_count_after_pop
        < DW1_PENDING_LAUNCH_LIMIT);

    assign dw2_pending_empty = (dw2_pending_count == {DW2_PENDING_CNT_W{1'b0}});
    assign dw2_pending_count_after_pop = dw2_pending_count
        - {{(DW2_PENDING_CNT_W-1){1'b0}}, dw2_pending_pop};
    assign dw2_pending_room = (dw2_pending_count_after_pop
        < DW2_PENDING_DEPTH_COUNT);

    assign pw1_issue_in_range = (next_pw1_tile_t_base <= (INPUT_LEN - ROWS));
    assign pw2_issue_in_range =
        (next_pw2_tile_t_base <= PW2_FINAL_TILE_T_BASE_VALUE);

    assign stem_issue_now = schedule_active
        && !buffer_clear
        && !all_stem_issued
        && !stem_busy
        && !stem_start
        && dw1_pending_launch_room;

    assign dw1_start_now = schedule_active
        && !dw1_pending_empty
        && !dw1_busy
        && !dw1_start;

    assign pw1_start_now = schedule_active
        && !buffer_clear
        && pw1_issue_in_range
        && !pw1_busy
        && !pw1_start;

    assign dw2_start_now = schedule_active
        && !dw2_pending_empty
        && !dw2_busy
        && !dw2_start;

    assign pw2_start_now = schedule_active
        && !buffer_clear
        && !pw2_gap_clear
        && pw2_issue_in_range
        && !pw2_busy
        && !pw2_start;

    assign stem_to_dw1_slice_in = {
        stem_out_tile_t_base,
        stem_out_tile_oc_base,
        stem_out_tile
    };
    assign {
        stem_to_dw1_slice_tile_t_base,
        stem_to_dw1_slice_tile_oc_base,
        stem_to_dw1_slice_tile
    } = stem_to_dw1_slice_out;
    assign stem_to_dw1_slice_ready = stem_to_dw1_in_ready;
    assign stem_to_dw1_in_valid = stem_to_dw1_slice_valid;
    assign stem_to_dw1_out_tile_t_base = stem_to_dw1_slice_tile_t_base;
    assign stem_to_dw1_out_tile_oc_base = stem_to_dw1_slice_tile_oc_base;
    assign stem_to_dw1_out_tile = stem_to_dw1_slice_tile;

    assign dw1_pending_push = busy
        && stem_to_dw1_in_valid
        && stem_to_dw1_in_ready;
    assign dw1_pending_pop = dw1_start_now;
    assign dw1_pending_count_next = dw1_pending_count
        + {{(PENDING_CNT_W-1){1'b0}}, dw1_pending_push}
        - {{(PENDING_CNT_W-1){1'b0}}, dw1_pending_pop};

    assign dw1_to_pw1_slice_in = {
        dw1_mid_out_t,
        dw1_mid_out_ch_base,
        dw1_mid_out_vec
    };
    assign {
        dw1_to_pw1_slice_t,
        dw1_to_pw1_slice_ch_base,
        dw1_to_pw1_slice_vec
    } = dw1_to_pw1_slice_out;
    assign dw1_to_pw1_slice_ready = dw1_to_pw1_in_ready;
    assign dw1_to_pw1_in_valid = dw1_to_pw1_slice_valid;
    assign dw1_to_pw1_out_t = dw1_to_pw1_slice_t;
    assign dw1_to_pw1_out_ch_base = dw1_to_pw1_slice_ch_base;
    assign dw1_to_pw1_out_vec = dw1_to_pw1_slice_vec;

    assign pw1_to_dw2_slice_in = {
        pw1_out_pool_t_base[LOW_TIME_W-1:0],
        pw1_out_oc_base,
        pw1_out_tile
    };
    assign {
        pw1_to_dw2_slice_pool_t_base,
        pw1_to_dw2_slice_oc_base,
        pw1_to_dw2_slice_tile
    } = pw1_to_dw2_slice_out;
    assign pw1_to_dw2_slice_ready = pw1_to_dw2_out_ready;
    assign pw1_to_dw2_slice_valid = pw1_to_dw2_slice_raw_valid;
    assign pw1_to_dw2_pool_t_base = pw1_to_dw2_slice_pool_t_base;
    assign pw1_to_dw2_oc_base = pw1_to_dw2_slice_oc_base;
    assign pw1_to_dw2_tile = pw1_to_dw2_slice_tile;
    assign pw1_to_dw2_in_valid = pw1_to_dw2_slice_valid && dw2_pending_room;
    assign pw1_to_dw2_out_ready = pw1_to_dw2_in_ready && dw2_pending_room;
    assign pw1_out_fire = pw1_out_valid && pw1_out_ready;
    assign dw2_pending_push = pw1_to_dw2_in_valid && pw1_to_dw2_in_ready;

    assign dw2_to_pw2_slice_in = {
        dw2_mid_out_t,
        dw2_mid_out_ch_base,
        dw2_mid_out_vec
    };
    assign {
        dw2_to_pw2_slice_t,
        dw2_to_pw2_slice_ch_base,
        dw2_to_pw2_slice_vec
    } = dw2_to_pw2_slice_out;
    assign dw2_to_pw2_slice_ready = dw2_to_pw2_in_ready;
    assign dw2_to_pw2_in_valid = dw2_to_pw2_slice_valid;
    assign dw2_to_pw2_out_t = dw2_to_pw2_slice_t;
    assign dw2_to_pw2_out_ch_base = dw2_to_pw2_slice_ch_base;
    assign dw2_to_pw2_out_vec = dw2_to_pw2_slice_vec;

    assign dw2_pending_pop = dw2_start_now;
    assign dw2_pending_count_next = dw2_pending_count
        + {{(DW2_PENDING_CNT_W-1){1'b0}}, dw2_pending_push}
        - {{(DW2_PENDING_CNT_W-1){1'b0}}, dw2_pending_pop};

    function [PENDING_PTR_W-1:0] next_dw1_pending_ptr;
        input [PENDING_PTR_W-1:0] ptr;
        begin
            if (ptr == (PENDING_DEPTH - 1)) begin
                next_dw1_pending_ptr = {PENDING_PTR_W{1'b0}};
            end else begin
                next_dw1_pending_ptr = ptr + 1'b1;
            end
        end
    endfunction

    function [DW2_PENDING_PTR_W-1:0] next_dw2_pending_ptr;
        input [DW2_PENDING_PTR_W-1:0] ptr;
        begin
            if (ptr == (DW2_PENDING_DEPTH - 1)) begin
                next_dw2_pending_ptr = {DW2_PENDING_PTR_W{1'b0}};
            end else begin
                next_dw2_pending_ptr = ptr + 1'b1;
            end
        end
    endfunction

    function is_final_tile;
        input [TIME_W-1:0] tile_t_base_i;
        begin
            is_final_tile = (tile_t_base_i == (INPUT_LEN - ROWS));
        end
    endfunction

    function is_final_dw2_input_chunk;
        input [LOW_TIME_W-1:0] pool_t_base_i;
        begin
            is_final_dw2_input_chunk = (pool_t_base_i == (POOL_LEN - POOL_ROWS));
        end
    endfunction

    function [ROWS-1:0] calc_pw2_row_valid_mask;
        input [LOW_TIME_W-1:0] tile_t_base_i;
        integer row_i;
        integer t_i;
        begin
            calc_pw2_row_valid_mask = {ROWS{1'b0}};
            for (row_i = 0; row_i < ROWS; row_i = row_i + 1) begin
                t_i = tile_t_base_i + row_i;
                if (t_i < POOL_LEN) begin
                    calc_pw2_row_valid_mask[row_i] = 1'b1;
                end
            end
        end
    endfunction

    stem_conv_array_4x4 #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .ROWS(ROWS),
        .OC_LANES(STEM_OC_LANES),
        .STEM_OC(STEM_OC),
        .STEM_K(STEM_K),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .STEM_IC(STEM_IC),
        .KERNEL(STEM_KERNEL),
        .PADDING(STEM_PADDING),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .ACT_TIME_WORDS(ACT_TIME_WORDS),
        .ACT_RAM_DEPTH(ACT_RAM_DEPTH),
        .ACT_ADDR_W(ACT_ADDR_W)
    ) u_stem (
        .clk(clk),
        .rst_n(rst_n),
        .start(stem_start),
        .oc_base(stem_oc_base),
        .tile_t_base(stem_tile_t_base),
        .act_wr_en(act_wr_en),
        .act_wr_addr(act_wr_addr),
        .act_wr_data(act_wr_data),
        .act_wr_bank(activation_load_bank),
        .act_rd_bank(activation_read_bank),
        .act_rd_active(busy || start),
        .act_wr_ready(act_wr_ready),
        .w_fold_we(1'b0),
        .w_fold_oc(5'd0),
        .w_fold_wdata({MULT_W{1'b0}}),
        .bias_fold_we(1'b0),
        .bias_fold_oc(5'd0),
        .bias_fold_wdata(32'd0),
        .out_ready(stem_to_buffer_ready),
        .busy(stem_busy),
        .done(stem_done),
        .out_valid(stem_out_valid),
        .out_tile_t_base(stem_out_tile_t_base),
        .out_tile_oc_base(stem_out_tile_oc_base),
        .out_tile(stem_out_tile)
    );

    emg_stream_fifo_slice #(
        .DATA_W(STEM_OUT_SLICE_W),
        .DEPTH(STEM_TO_DW1_SLICE_DEPTH)
    ) u_stem_to_dw1_ready_slice (
        .clk(clk),
        .rst_n(rst_n),
        .clear(buffer_clear),
        .in_valid(stem_out_valid),
        .in_ready(stem_to_buffer_ready),
        .in_data(stem_to_dw1_slice_in),
        .out_valid(stem_to_dw1_slice_valid),
        .out_ready(stem_to_dw1_slice_ready),
        .out_data(stem_to_dw1_slice_out),
        .busy(stem_to_dw1_slice_busy)
    );

    stem_to_dw1_buffer_with_ram #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .STEM_OC(STEM_OC),
        .ROWS(ROWS),
        .OC_LANES(STEM_OC_LANES),
        .DW_K(DW_K),
        .DW_PAD(DW_PAD),
        .RING_ROWS(STEM_TO_DW1_RING_ROWS),
        .BANKS(CH_GROUPS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .OC_BASE_W(STEM_OC_BASE_W)
    ) u_stem_to_dw1 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(buffer_clear),
        .stem_out_valid(stem_to_dw1_in_valid),
        .stem_out_ready(stem_to_dw1_in_ready),
        .stem_out_tile_t_base(stem_to_dw1_out_tile_t_base),
        .stem_out_tile_oc_base(stem_to_dw1_out_tile_oc_base),
        .stem_out_tile(stem_to_dw1_out_tile),
        .dw1_win_req_valid(dw1_win_req_valid),
        .dw1_win_req_ready(dw1_win_req_ready),
        .dw1_win_req_out_t(dw1_win_req_out_t),
        .dw1_win_req_ch_base(dw1_win_req_ch_base),
        .dw1_win_vec_valid(dw1_win_vec_valid),
        .dw1_win_vec_ready(dw1_win_vec_ready),
        .dw1_win_vec(dw1_win_vec),
        .wr_busy(),
        .rd_busy(),
        .stem_watermark_stall()
    );

    dw_conv1_4ch_5tap #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .CHANNELS(STEM_OC),
        .P_CH(STEM_OC_LANES),
        .K(DW_K),
        .PAD(DW_PAD),
        .INPUT_LEN(INPUT_LEN),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W),
        .ROWS_W(ROWS_W)
    ) u_dw1 (
        .clk(clk),
        .rst_n(rst_n),
        .start(dw1_start),
        .ch_base(dw1_ch_base),
        .input_t_base(dw1_input_t_base),
        .input_rows(dw1_input_rows),
        .final_chunk(dw1_final_chunk),
        .win_req_valid(dw1_win_req_valid),
        .win_req_out_t(dw1_win_req_out_t),
        .win_req_ch_base(dw1_win_req_ch_base),
        .win_req_ready(dw1_win_req_ready),
        .win_vec_valid(dw1_win_vec_valid),
        .win_vec_ready(dw1_win_vec_ready),
        .win_vec(dw1_win_vec),
        .weight_we(1'b0),
        .weight_ch(5'd0),
        .weight_tap(3'd0),
        .weight_wdata({DATA_W{1'b0}}),
        .out_ready(dw1_mid_out_ready),
        .busy(dw1_busy),
        .done(dw1_done),
        .out_valid(dw1_mid_out_valid),
        .out_t(dw1_mid_out_t),
        .out_ch_base(dw1_mid_out_ch_base),
        .out_vec(dw1_mid_out_vec),
        .job_out_t_start(),
        .job_out_count()
    );

    emg_stream_fifo_slice #(
        .DATA_W(DW1_OUT_SLICE_W),
        .DEPTH(2)
    ) u_dw1_to_pw1_ready_slice (
        .clk(clk),
        .rst_n(rst_n),
        .clear(buffer_clear),
        .in_valid(dw1_mid_out_valid),
        .in_ready(dw1_mid_out_ready),
        .in_data(dw1_to_pw1_slice_in),
        .out_valid(dw1_to_pw1_slice_valid),
        .out_ready(dw1_to_pw1_slice_ready),
        .out_data(dw1_to_pw1_slice_out),
        .busy(dw1_to_pw1_slice_busy)
    );

    dw1_to_pw1_buffer_with_ram #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .PW1_IC(STEM_OC),
        .ROWS(ROWS),
        .CH_LANES(STEM_OC_LANES),
        .RING_ROWS(DW1_TO_PW1_RING_ROWS),
        .BANKS(CH_GROUPS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .CH_BASE_W(PW1_CH_BASE_W)
    ) u_dw1_to_pw1 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(buffer_clear),
        .dw1_out_valid(dw1_to_pw1_in_valid),
        .dw1_out_ready(dw1_to_pw1_in_ready),
        .dw1_out_t(dw1_to_pw1_out_t),
        .dw1_out_ch_base({1'b0, dw1_to_pw1_out_ch_base}),
        .dw1_out_vec(dw1_to_pw1_out_vec),
        .input_tile_req_valid(pw1_input_tile_req_valid),
        .input_tile_req_ready(pw1_input_tile_req_ready),
        .input_tile_req_t_base(pw1_input_tile_req_t_base),
        .act_req_valid(pw1_act_req_valid),
        .act_req_ready(pw1_act_req_ready),
        .act_req_t_base(pw1_act_req_t_base),
        .act_req_k(pw1_act_req_k),
        .act_vec_valid(pw1_act_vec_valid),
        .act_vec_ready(pw1_act_vec_ready),
        .act_vec(pw1_act_vec),
        .wr_busy(),
        .rd_busy(),
        .tile_cache_valid(),
        .dw1_overwrite_stall()
    );

    pw_conv1_array_4x8 #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .ROWS(ROWS),
        .POOL_ROWS(POOL_ROWS),
        .OC_LANES(PW1_OC_LANES),
        .PW1_IC(STEM_OC),
        .PW1_OC(PW1_OC),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY)
    ) u_pw1 (
        .clk(clk),
        .rst_n(rst_n),
        .start(pw1_start),
        .oc_base(6'd0),
        .tile_t_base(pw1_tile_t_base),
        .input_tile_req_valid(pw1_input_tile_req_valid),
        .input_tile_req_t_base(pw1_input_tile_req_t_base),
        .input_tile_req_ready(pw1_input_tile_req_ready),
        .act_req_valid(pw1_act_req_valid),
        .act_req_t_base(pw1_act_req_t_base),
        .act_req_k(pw1_act_req_k),
        .act_req_ready(pw1_act_req_ready),
        .act_vec_valid(pw1_act_vec_valid),
        .act_vec_ready(pw1_act_vec_ready),
        .act_vec(pw1_act_vec),
        .w_fold_we(1'b0),
        .w_fold_oc(6'd0),
        .w_fold_wdata({MULT_W{1'b0}}),
        .bias_fold_we(1'b0),
        .bias_fold_oc(6'd0),
        .bias_fold_wdata(32'd0),
        .out_ready(pw1_out_ready),
        .busy(pw1_busy),
        .done(pw1_done),
        .out_valid(pw1_out_valid),
        .out_pool_t_base(pw1_out_pool_t_base),
        .out_oc_base(pw1_out_oc_base),
        .out_last_group(),
        .out_tile(pw1_out_tile)
    );

    emg_stream_fifo_slice #(
        .DATA_W(PW1_OUT_SLICE_W),
        .DEPTH(2)
    ) u_pw1_to_dw2_ready_slice (
        .clk(clk),
        .rst_n(rst_n),
        .clear(buffer_clear),
        .in_valid(pw1_out_valid),
        .in_ready(pw1_out_ready),
        .in_data(pw1_to_dw2_slice_in),
        .out_valid(pw1_to_dw2_slice_raw_valid),
        .out_ready(pw1_to_dw2_slice_ready),
        .out_data(pw1_to_dw2_slice_out),
        .busy(pw1_to_dw2_slice_busy)
    );

    pw1_to_dw2_buffer_with_ram #(
        .DATA_W(DATA_W),
        .TIME_W(LOW_TIME_W),
        .INPUT_LEN(POOL_LEN),
        .PW1_OC(PW1_OC),
        .POOL_ROWS(POOL_ROWS),
        .PW1_OC_LANES(PW1_OC_LANES),
        .CH_LANES(CH_LANES),
        .DW_K(DW_K),
        .DW_PAD(DW_PAD),
        .RING_ROWS(PW1_TO_DW2_RING_ROWS),
        .BANKS(PW1_OC / CH_LANES),
        .TILE_BANKS(PW1_OC_LANES / CH_LANES),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .OC_BASE_W(LOW_CH_BASE_W)
    ) u_pw1_to_dw2 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(buffer_clear),
        .pw1_out_valid(pw1_to_dw2_in_valid),
        .pw1_out_ready(pw1_to_dw2_in_ready),
        .pw1_out_pool_t_base(pw1_to_dw2_pool_t_base),
        .pw1_out_oc_base(pw1_to_dw2_oc_base),
        .pw1_out_tile(pw1_to_dw2_tile),
        .dw2_win_req_valid(dw2_win_req_valid),
        .dw2_win_req_ready(dw2_win_req_ready),
        .dw2_win_req_out_t(dw2_win_req_out_t),
        .dw2_win_req_ch_base(dw2_win_req_ch_base),
        .dw2_win_vec_valid(dw2_win_vec_valid),
        .dw2_win_vec_ready(dw2_win_vec_ready),
        .dw2_win_vec(dw2_win_vec),
        .wr_busy(),
        .rd_busy(),
        .pw1_overwrite_stall()
    );

    dw_conv2_4ch_5tap #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .CHANNELS(PW1_OC),
        .P_CH(CH_LANES),
        .K(DW_K),
        .PAD(DW_PAD),
        .INPUT_LEN(POOL_LEN),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(LOW_TIME_W),
        .ROWS_W(DW2_ROWS_W)
    ) u_dw2 (
        .clk(clk),
        .rst_n(rst_n),
        .start(dw2_start),
        .ch_base(dw2_ch_base),
        .input_t_base(dw2_input_t_base),
        .input_rows(dw2_input_rows),
        .final_chunk(dw2_final_chunk),
        .win_req_valid(dw2_win_req_valid),
        .win_req_out_t(dw2_win_req_out_t),
        .win_req_ch_base(dw2_win_req_ch_base),
        .win_req_ready(dw2_win_req_ready),
        .win_vec_valid(dw2_win_vec_valid),
        .win_vec_ready(dw2_win_vec_ready),
        .win_vec(dw2_win_vec),
        .weight_we(1'b0),
        .weight_ch(6'd0),
        .weight_tap(3'd0),
        .weight_wdata({DATA_W{1'b0}}),
        .out_ready(dw2_mid_out_ready),
        .busy(dw2_busy),
        .done(dw2_done),
        .out_valid(dw2_mid_out_valid),
        .out_t(dw2_mid_out_t),
        .out_ch_base(dw2_mid_out_ch_base),
        .out_vec(dw2_mid_out_vec),
        .job_out_t_start(),
        .job_out_count()
    );

    emg_stream_fifo_slice #(
        .DATA_W(DW2_OUT_SLICE_W),
        .DEPTH(2)
    ) u_dw2_to_pw2_ready_slice (
        .clk(clk),
        .rst_n(rst_n),
        .clear(buffer_clear),
        .in_valid(dw2_mid_out_valid),
        .in_ready(dw2_mid_out_ready),
        .in_data(dw2_to_pw2_slice_in),
        .out_valid(dw2_to_pw2_slice_valid),
        .out_ready(dw2_to_pw2_slice_ready),
        .out_data(dw2_to_pw2_slice_out),
        .busy(dw2_to_pw2_slice_busy)
    );

    dw2_to_pw2_buffer_with_ram #(
        .DATA_W(DATA_W),
        .TIME_W(LOW_TIME_W),
        .INPUT_LEN(POOL_LEN),
        .PW2_IC(PW1_OC),
        .ROWS(ROWS),
        .CH_LANES(CH_LANES),
        .RING_ROWS(DW2_TO_PW2_RING_ROWS),
        .BANKS(PW1_OC / CH_LANES),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .CH_BASE_W(PW2_CH_BASE_W)
    ) u_dw2_to_pw2 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(buffer_clear),
        .dw2_out_valid(dw2_to_pw2_in_valid),
        .dw2_out_ready(dw2_to_pw2_in_ready),
        .dw2_out_t(dw2_to_pw2_out_t),
        .dw2_out_ch_base({1'b0, dw2_to_pw2_out_ch_base}),
        .dw2_out_vec(dw2_to_pw2_out_vec),
        .input_tile_req_valid(pw2_input_tile_req_valid),
        .input_tile_req_ready(pw2_input_tile_req_ready),
        .input_tile_req_t_base(pw2_input_tile_req_t_base),
        .input_tile_req_row_valid_mask(pw2_input_tile_req_row_valid_mask),
        .act_req_valid(pw2_act_req_valid),
        .act_req_ready(pw2_act_req_ready),
        .act_req_t_base(pw2_act_req_t_base),
        .act_req_k(pw2_act_req_k),
        .act_req_row_valid_mask(pw2_act_req_row_valid_mask),
        .act_vec_valid(pw2_act_vec_valid),
        .act_vec_ready(pw2_act_vec_ready),
        .act_vec(pw2_act_vec),
        .wr_busy(),
        .rd_busy(),
        .tile_cache_valid(),
        .dw2_overwrite_stall()
    );

    pw_conv2_array_4x12 #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .ROWS(ROWS),
        .OC_LANES(PW2_OC_LANES),
        .PW2_IC(PW1_OC),
        .PW2_OC(PW2_OC),
        .GAP_LEN(POOL_LEN),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(LOW_TIME_W),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY)
    ) u_pw2 (
        .clk(clk),
        .rst_n(rst_n),
        .start(pw2_start),
        .gap_clear(pw2_gap_clear),
        .tile_t_base(pw2_tile_t_base),
        .row_valid_mask(pw2_row_valid_mask),
        .input_tile_req_valid(pw2_input_tile_req_valid),
        .input_tile_req_t_base(pw2_input_tile_req_t_base),
        .input_tile_req_row_valid_mask(pw2_input_tile_req_row_valid_mask),
        .input_tile_req_ready(pw2_input_tile_req_ready),
        .act_req_valid(pw2_act_req_valid),
        .act_req_t_base(pw2_act_req_t_base),
        .act_req_k(pw2_act_req_k),
        .act_req_row_valid_mask(pw2_act_req_row_valid_mask),
        .act_req_ready(pw2_act_req_ready),
        .act_vec_valid(pw2_act_vec_valid),
        .act_vec_ready(pw2_act_vec_ready),
        .act_vec(pw2_act_vec),
        .w_fold_we(1'b0),
        .w_fold_oc(7'd0),
        .w_fold_wdata({MULT_W{1'b0}}),
        .bias_fold_we(1'b0),
        .bias_fold_oc(7'd0),
        .bias_fold_wdata(32'd0),
        .busy(pw2_busy),
        .done(pw2_done),
        .gap_frame_done(pw2_gap_frame_done),
        .gap_count(gap_count),
        .gap_sum_vec(gap_sum_vec)
    );

    fc_classifier_96_5 #(
        .DATA_W(DATA_W),
        .GAP_ACC_W(ACC_W),
        .ACC_W(ACC_W),
        .FC0_IN(PW2_OC),
        .FC0_OUT(PW2_OC),
        .FC1_OUT(FC_CLASSES),
        .FC0_OUT_LANES(16),
        .AVG_LANES(FC_AVG_LANES),
        .GAP_LEN(POOL_LEN),
        .FRAC_BITS(FRAC_BITS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .FC_ROM_ADDR_W(10)
    ) u_fc (
        .clk(clk),
        .rst_n(rst_n),
        .start(fc_start),
        .gap_count(gap_count),
        .gap_sum_vec(gap_sum_vec),
        .result_ready(1'b1),
        .busy(fc_busy),
        .done(fc_done),
        .result_valid(fc_result_valid),
        .class_idx(fc_class_idx),
        .input_count_error(),
        .logits_vec()
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            buffer_clear <= 1'b0;
            pw2_gap_clear <= 1'b0;
            activation_load_bank <= 1'b0;
            activation_read_bank <= 1'b0;
            stem_start <= 1'b0;
            stem_oc_base <= 5'd0;
            stem_tile_t_base <= {TIME_W{1'b0}};
            dw1_start <= 1'b0;
            dw1_ch_base <= 5'd0;
            dw1_input_t_base <= {TIME_W{1'b0}};
            dw1_input_rows <= ROWS_VALUE;
            dw1_final_chunk <= 1'b0;
            pw1_start <= 1'b0;
            pw1_tile_t_base <= {TIME_W{1'b0}};
            dw2_start <= 1'b0;
            dw2_ch_base <= 6'd0;
            dw2_input_t_base <= {LOW_TIME_W{1'b0}};
            dw2_input_rows <= POOL_ROWS_VALUE;
            dw2_final_chunk <= 1'b0;
            pw2_start <= 1'b0;
            pw2_tile_t_base <= {LOW_TIME_W{1'b0}};
            pw2_row_valid_mask <= {ROWS{1'b0}};
            fc_start <= 1'b0;
            fc_started <= 1'b0;
            all_stem_issued <= 1'b0;
            next_tile_t_base <= {TIME_W{1'b0}};
            next_ch_base <= 5'd0;
            launched_t_base <= {TIME_W{1'b0}};
            launched_ch_base <= 5'd0;
            launched_final_chunk <= 1'b0;
            all_pw1_issued <= 1'b0;
            next_pw1_tile_t_base <= {TIME_W{1'b0}};
            all_pw2_issued <= 1'b0;
            next_pw2_tile_t_base <= {LOW_TIME_W{1'b0}};
            pw2_gap_done_seen <= 1'b0;
            dw1_pending_rd_ptr <= {PENDING_PTR_W{1'b0}};
            dw1_pending_wr_ptr <= {PENDING_PTR_W{1'b0}};
            dw1_pending_count <= {PENDING_CNT_W{1'b0}};
            dw2_pending_rd_ptr <= {DW2_PENDING_PTR_W{1'b0}};
            dw2_pending_wr_ptr <= {DW2_PENDING_PTR_W{1'b0}};
            dw2_pending_count <= {DW2_PENDING_CNT_W{1'b0}};
        end else begin
            done <= 1'b0;
            stem_start <= 1'b0;
            dw1_start <= 1'b0;
            pw1_start <= 1'b0;
            dw2_start <= 1'b0;
            pw2_start <= 1'b0;
            fc_start <= 1'b0;
            pw2_gap_clear <= 1'b0;

            if (buffer_clear) begin
                buffer_clear <= 1'b0;
            end

            if (start && !busy) begin
                busy <= 1'b1;
                buffer_clear <= 1'b1;
                pw2_gap_clear <= 1'b1;
                activation_read_bank <= activation_load_bank;
                activation_load_bank <= !activation_load_bank;
                all_stem_issued <= 1'b0;
                next_tile_t_base <= {TIME_W{1'b0}};
                next_ch_base <= 5'd0;
                launched_t_base <= {TIME_W{1'b0}};
                launched_ch_base <= 5'd0;
                launched_final_chunk <= 1'b0;
                all_pw1_issued <= 1'b0;
                next_pw1_tile_t_base <= {TIME_W{1'b0}};
                all_pw2_issued <= 1'b0;
                next_pw2_tile_t_base <= {LOW_TIME_W{1'b0}};
                pw2_gap_done_seen <= 1'b0;
                fc_started <= 1'b0;
                dw1_pending_rd_ptr <= {PENDING_PTR_W{1'b0}};
                dw1_pending_wr_ptr <= {PENDING_PTR_W{1'b0}};
                dw1_pending_count <= {PENDING_CNT_W{1'b0}};
                dw2_pending_rd_ptr <= {DW2_PENDING_PTR_W{1'b0}};
                dw2_pending_wr_ptr <= {DW2_PENDING_PTR_W{1'b0}};
                dw2_pending_count <= {DW2_PENDING_CNT_W{1'b0}};
            end else if (busy) begin
                if (pw2_gap_frame_done) begin
                    pw2_gap_done_seen <= 1'b1;
                end

                if (stem_issue_now) begin
                    stem_start <= 1'b1;
                    stem_oc_base <= next_ch_base;
                    stem_tile_t_base <= next_tile_t_base;
                    launched_t_base <= next_tile_t_base;
                    launched_ch_base <= next_ch_base;
                    launched_final_chunk <= is_final_tile(next_tile_t_base);

                    if (next_ch_base == (STEM_OC - STEM_OC_LANES)) begin
                        next_ch_base <= 5'd0;
                        if (next_tile_t_base == (INPUT_LEN - ROWS)) begin
                            all_stem_issued <= 1'b1;
                        end else begin
                            next_tile_t_base <= next_tile_t_base + ROWS;
                        end
                    end else begin
                        next_ch_base <= next_ch_base + STEM_OC_LANES;
                    end
                end

                if (dw1_pending_push) begin
                    dw1_pending_t_base[dw1_pending_wr_ptr]
                        <= stem_to_dw1_out_tile_t_base;
                    dw1_pending_ch_base[dw1_pending_wr_ptr]
                        <= stem_to_dw1_out_tile_oc_base;
                    dw1_pending_final_chunk[dw1_pending_wr_ptr]
                        <= is_final_tile(stem_to_dw1_out_tile_t_base);
                    dw1_pending_wr_ptr
                        <= next_dw1_pending_ptr(dw1_pending_wr_ptr);
                end

                if (dw1_pending_pop) begin
                    dw1_start <= 1'b1;
                    dw1_ch_base <= dw1_pending_ch_base[dw1_pending_rd_ptr];
                    dw1_input_t_base <= dw1_pending_t_base[dw1_pending_rd_ptr];
                    dw1_input_rows <= ROWS_VALUE;
                    dw1_final_chunk
                        <= dw1_pending_final_chunk[dw1_pending_rd_ptr];
                    dw1_pending_rd_ptr
                        <= next_dw1_pending_ptr(dw1_pending_rd_ptr);
                end

                if (pw1_start_now) begin
                    pw1_start <= 1'b1;
                    pw1_tile_t_base <= next_pw1_tile_t_base;
                    if (next_pw1_tile_t_base == (INPUT_LEN - ROWS)) begin
                        all_pw1_issued <= 1'b1;
                        next_pw1_tile_t_base <= next_pw1_tile_t_base + ROWS;
                    end else begin
                        next_pw1_tile_t_base <= next_pw1_tile_t_base + ROWS;
                    end
                end

                if (dw2_pending_push) begin
                    dw2_pending_t_base[dw2_pending_wr_ptr]
                        <= pw1_to_dw2_pool_t_base;
                    dw2_pending_ch_base[dw2_pending_wr_ptr]
                        <= pw1_to_dw2_oc_base;
                    dw2_pending_final_chunk[dw2_pending_wr_ptr]
                        <= is_final_dw2_input_chunk(
                            pw1_to_dw2_pool_t_base
                        );
                    dw2_pending_wr_ptr
                        <= next_dw2_pending_ptr(dw2_pending_wr_ptr);
                end

                if (dw2_pending_pop) begin
                    dw2_start <= 1'b1;
                    dw2_ch_base <= dw2_pending_ch_base[dw2_pending_rd_ptr];
                    dw2_input_t_base <= dw2_pending_t_base[dw2_pending_rd_ptr];
                    dw2_input_rows <= POOL_ROWS_VALUE;
                    dw2_final_chunk
                        <= dw2_pending_final_chunk[dw2_pending_rd_ptr];
                    dw2_pending_rd_ptr
                        <= next_dw2_pending_ptr(dw2_pending_rd_ptr);
                end

                if (pw2_start_now) begin
                    pw2_start <= 1'b1;
                    pw2_tile_t_base <= next_pw2_tile_t_base;
                    pw2_row_valid_mask
                        <= calc_pw2_row_valid_mask(next_pw2_tile_t_base);
                    if (next_pw2_tile_t_base == PW2_FINAL_TILE_T_BASE_VALUE) begin
                        all_pw2_issued <= 1'b1;
                        next_pw2_tile_t_base <= next_pw2_tile_t_base + ROWS;
                    end else begin
                        next_pw2_tile_t_base <= next_pw2_tile_t_base + ROWS;
                    end
                end

                dw1_pending_count <= dw1_pending_count_next;
                dw2_pending_count <= dw2_pending_count_next;

                if (pw2_gap_done_seen && !fc_started && !fc_busy) begin
                    fc_start <= 1'b1;
                    fc_started <= 1'b1;
                end

                if (fc_done) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    fc_started <= 1'b0;
                end
            end
        end
    end

endmodule
