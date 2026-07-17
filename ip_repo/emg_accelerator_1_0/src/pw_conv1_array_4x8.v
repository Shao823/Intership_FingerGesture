`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership/ip_repo/emg_accelerator_1_0/src"
`endif

// PW1 pointwise Conv1d tile wrapper.
//
// This module is the integration boundary for the PW1 layer. The compute core
// lives in pw_conv1_array_4x8_compute. Fixed pointwise weights are supplied by
// the local generated blk_mem_gen_pw_conv1_weight ROM through
// pw_conv1_weight_controller_with_rom. Runtime activations still arrive from
// the upstream DW1-to-PW1 row packer as request/response vectors.

module pw_conv1_array_4x8 #(
    parameter integer DATA_W     =  8,
    parameter integer MULT_W     = 16,
    parameter integer ACC_W      = 48,
    parameter integer ROWS       = 4,
    parameter integer POOL_ROWS  = 2,
    parameter integer OC_LANES   = 8,
    parameter integer PW1_IC     = 32,
    parameter integer PW1_OC     = 64,
    parameter integer FRAC_BITS  = 8,
    parameter integer TIME_W     = 9,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer ADDR_W     = (((PW1_OC / OC_LANES) * PW1_IC) <= 1)
        ? 1 : $clog2((PW1_OC / OC_LANES) * PW1_IC),
    parameter BIAS_INIT_FILE     = {`PROJECT_ROOT, "/weight_data/pw1/bias_int32.mem"},
    parameter MULT_INIT_FILE     = {`PROJECT_ROOT, "/weight_data/pw1/multiplier_q15.mem"},
    parameter SHIFT_INIT_FILE    = {`PROJECT_ROOT, "/weight_data/pw1/right_shift.mem"}
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire [5:0] oc_base,
    input  wire [TIME_W-1:0] tile_t_base,

    output wire input_tile_req_valid,
    output wire [TIME_W-1:0] input_tile_req_t_base,
    input  wire input_tile_req_ready,

    output wire act_req_valid,
    output wire [TIME_W-1:0] act_req_t_base,
    output wire [5:0] act_req_k,
    input  wire act_req_ready,
    input  wire act_vec_valid,
    output wire act_vec_ready,
    input  wire signed [ROWS*DATA_W-1:0] act_vec,

    input  wire w_fold_we,
    input  wire [5:0] w_fold_oc,
    input  wire signed [MULT_W-1:0] w_fold_wdata,

    input  wire bias_fold_we,
    input  wire [5:0] bias_fold_oc,
    input  wire signed [31:0] bias_fold_wdata,

    input  wire out_ready,
    output wire busy,
    output wire done,
    output wire out_valid,
    output wire [TIME_W-1:0] out_pool_t_base,
    output wire [5:0] out_oc_base,
    output wire out_last_group,
    output wire signed [POOL_ROWS*OC_LANES*DATA_W-1:0] out_tile
);

    wire weight_req_valid;
    wire [5:0] weight_req_oc_base;
    wire [5:0] weight_req_k;
    wire weight_req_ready;
    wire weight_vec_valid;
    wire weight_vec_ready;
    wire signed [OC_LANES*DATA_W-1:0] weight_vec;

    pw_conv1_array_4x8_compute #(
        .DATA_W(DATA_W),
        .MULT_W(MULT_W),
        .ACC_W(ACC_W),
        .ROWS(ROWS),
        .POOL_ROWS(POOL_ROWS),
        .OC_LANES(OC_LANES),
        .PW1_IC(PW1_IC),
        .PW1_OC(PW1_OC),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W),
        .BIAS_INIT_FILE(BIAS_INIT_FILE),
        .MULT_INIT_FILE(MULT_INIT_FILE),
        .SHIFT_INIT_FILE(SHIFT_INIT_FILE)
    ) u_compute (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .oc_base(oc_base),
        .tile_t_base(tile_t_base),
        .input_tile_req_valid(input_tile_req_valid),
        .input_tile_req_t_base(input_tile_req_t_base),
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
        .out_ready(out_ready),
        .busy(busy),
        .done(done),
        .out_valid(out_valid),
        .out_pool_t_base(out_pool_t_base),
        .out_oc_base(out_oc_base),
        .out_last_group(out_last_group),
        .out_tile(out_tile)
    );

    pw_conv1_weight_controller_with_rom #(
        .DATA_W(DATA_W),
        .OC_LANES(OC_LANES),
        .PW1_IC(PW1_IC),
        .PW1_OC(PW1_OC),
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
