`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

// PW2 pointwise Conv1d tile wrapper.
//
// This module is the integration boundary for the PW2 layer. The compute core
// lives in pw_conv2_array_4x12_compute. Fixed pointwise weights are supplied by
// the local generated blk_mem_gen_pw_conv2_weight ROM through
// pw_conv2_weight_controller_with_rom. Runtime activations still arrive from
// the upstream DW2-to-PW2 row packer as request/response vectors.

module pw_conv2_array_4x12 #(
    parameter integer DATA_W     = 16,
    parameter integer ACC_W      = 48,
    parameter integer ROWS       = 4,
    parameter integer OC_LANES   = 12,
    parameter integer PW2_IC     = 64,
    parameter integer PW2_OC     = 96,
    parameter integer GAP_LEN    = 174,
    parameter integer FRAC_BITS  = 8,
    parameter integer TIME_W     = 8,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer ADDR_W     = (((PW2_OC / OC_LANES) * PW2_IC) <= 1)
        ? 1 : $clog2((PW2_OC / OC_LANES) * PW2_IC),
    parameter BN_SCALE_INIT_FILE = {`PROJECT_ROOT, "/weight_data/pw2/bn_scale.mem"},
    parameter BN_BIAS_INIT_FILE  = {`PROJECT_ROOT, "/weight_data/pw2/bn_bias.mem"}
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire gap_clear,
    input  wire [TIME_W-1:0] tile_t_base,
    input  wire [ROWS-1:0] row_valid_mask,

    output wire input_tile_req_valid,
    output wire [TIME_W-1:0] input_tile_req_t_base,
    output wire [ROWS-1:0] input_tile_req_row_valid_mask,
    input  wire input_tile_req_ready,

    output wire act_req_valid,
    output wire [TIME_W-1:0] act_req_t_base,
    output wire [6:0] act_req_k,
    output wire [ROWS-1:0] act_req_row_valid_mask,
    input  wire act_req_ready,
    input  wire act_vec_valid,
    output wire act_vec_ready,
    input  wire signed [ROWS*DATA_W-1:0] act_vec,

    input  wire w_fold_we,
    input  wire [6:0] w_fold_oc,
    input  wire signed [DATA_W-1:0] w_fold_wdata,

    input  wire bias_fold_we,
    input  wire [6:0] bias_fold_oc,
    input  wire signed [DATA_W-1:0] bias_fold_wdata,

    output wire busy,
    output wire done,
    output wire gap_frame_done,
    output wire [8:0] gap_count,
    output wire signed [PW2_OC*ACC_W-1:0] gap_sum_vec
);

    wire weight_req_valid;
    wire [6:0] weight_req_oc_base;
    wire [6:0] weight_req_k;
    wire weight_req_ready;
    wire weight_vec_valid;
    wire weight_vec_ready;
    wire signed [OC_LANES*DATA_W-1:0] weight_vec;

    pw_conv2_array_4x12_compute #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .ROWS(ROWS),
        .OC_LANES(OC_LANES),
        .PW2_IC(PW2_IC),
        .PW2_OC(PW2_OC),
        .GAP_LEN(GAP_LEN),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W),
        .BN_SCALE_INIT_FILE(BN_SCALE_INIT_FILE),
        .BN_BIAS_INIT_FILE(BN_BIAS_INIT_FILE)
    ) u_compute (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .gap_clear(gap_clear),
        .tile_t_base(tile_t_base),
        .row_valid_mask(row_valid_mask),
        .input_tile_req_valid(input_tile_req_valid),
        .input_tile_req_t_base(input_tile_req_t_base),
        .input_tile_req_row_valid_mask(input_tile_req_row_valid_mask),
        .input_tile_req_ready(input_tile_req_ready),
        .weight_req_valid(weight_req_valid),
        .weight_req_oc_base(weight_req_oc_base),
        .weight_req_k(weight_req_k),
        .weight_req_ready(weight_req_ready),
        .weight_vec_valid(weight_vec_valid),
        .weight_vec_ready(weight_vec_ready),
        .weight_vec(weight_vec),
        .act_req_valid(act_req_valid),
        .act_req_t_base(act_req_t_base),
        .act_req_k(act_req_k),
        .act_req_row_valid_mask(act_req_row_valid_mask),
        .act_req_ready(act_req_ready),
        .act_vec_valid(act_vec_valid),
        .act_vec_ready(act_vec_ready),
        .act_vec(act_vec),
        .w_fold_we(w_fold_we),
        .w_fold_oc(w_fold_oc),
        .w_fold_wdata(w_fold_wdata),
        .bias_fold_we(bias_fold_we),
        .bias_fold_oc(bias_fold_oc),
        .bias_fold_wdata(bias_fold_wdata),
        .busy(busy),
        .done(done),
        .gap_frame_done(gap_frame_done),
        .gap_count(gap_count),
        .gap_sum_vec(gap_sum_vec)
    );

    pw_conv2_weight_controller_with_rom #(
        .DATA_W(DATA_W),
        .OC_LANES(OC_LANES),
        .PW2_IC(PW2_IC),
        .PW2_OC(PW2_OC),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .ADDR_W(ADDR_W)
    ) u_weight (
        .clk(clk),
        .rst_n(rst_n),
        .weight_req_valid(weight_req_valid),
        .weight_req_oc_base(weight_req_oc_base),
        .weight_req_k(weight_req_k),
        .weight_req_ready(weight_req_ready),
        .weight_vec_valid(weight_vec_valid),
        .weight_vec_ready(weight_vec_ready),
        .weight_vec(weight_vec)
    );

endmodule
