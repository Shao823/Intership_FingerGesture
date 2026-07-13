`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

// Stem convolution tile wrapper.
//
// This module is the integration boundary for the stem layer. The compute core
// is kept in stem_conv_array_4x4_compute; fixed convolution weights are supplied
// internally by the stem weight ROM controller. Runtime input activations are
// written through the local activation RAM write port, then read back by the
// stem activation controller when the compute core requests each convolution
// window.

module stem_conv_array_4x4 #(
    parameter integer DATA_W     = 16,
    parameter integer ACC_W      = 48,
    parameter integer ROWS       = 4,
    parameter integer OC_LANES   = 4,
    parameter integer STEM_OC    = 32,
    parameter integer STEM_K     = 35,
    parameter integer FRAC_BITS  = 8,
    parameter integer TIME_W     = 9,
    parameter integer INPUT_LEN  = 348,
    parameter integer STEM_IC    = 5,
    parameter integer KERNEL     = 7,
    parameter integer PADDING    = 3,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer ADDR_W     = (((STEM_OC / OC_LANES) * STEM_K) <= 1)
        ? 1 : $clog2((STEM_OC / OC_LANES) * STEM_K),
    parameter integer ACT_TIME_WORDS = (INPUT_LEN + ROWS - 1) / ROWS,
    parameter integer ACT_RAM_DEPTH  = STEM_IC * ACT_TIME_WORDS,
    parameter integer ACT_ADDR_W     = (ACT_RAM_DEPTH <= 1)
        ? 1 : $clog2(ACT_RAM_DEPTH),
    parameter BN_SCALE_INIT_FILE = {`PROJECT_ROOT, "/weight_data/stem/bn_scale.mem"},
    parameter BN_BIAS_INIT_FILE  = {`PROJECT_ROOT, "/weight_data/stem/bn_bias.mem"}
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire [4:0] oc_base,
    input  wire [TIME_W-1:0] tile_t_base,

    input  wire act_wr_en,
    input  wire [ACT_ADDR_W-1:0] act_wr_addr,
    input  wire [ROWS*DATA_W-1:0] act_wr_data,
    input  wire act_wr_bank,
    input  wire act_rd_bank,
    input  wire act_rd_active,
    output wire act_wr_ready,

    input  wire w_fold_we,
    input  wire [4:0] w_fold_oc,
    input  wire signed [DATA_W-1:0] w_fold_wdata,

    input  wire bias_fold_we,
    input  wire [4:0] bias_fold_oc,
    input  wire signed [DATA_W-1:0] bias_fold_wdata,

    input  wire out_ready,
    output wire busy,
    output wire done,
    output wire out_valid,
    output wire [TIME_W-1:0] out_tile_t_base,
    output wire [4:0] out_tile_oc_base,
    output wire signed [ROWS*OC_LANES*DATA_W-1:0] out_tile
);

    wire weight_req_valid;
    wire [4:0] weight_req_oc_base;
    wire [5:0] weight_req_k;
    wire weight_req_ready;
    wire weight_vec_valid;
    wire weight_vec_ready;
    wire signed [OC_LANES*DATA_W-1:0] weight_vec;

    wire act_req_valid;
    wire [TIME_W-1:0] act_req_t_base;
    wire [5:0] act_req_k;
    wire act_req_ready;
    wire act_vec_valid;
    wire act_vec_ready;
    wire signed [ROWS*DATA_W-1:0] act_vec;

    stem_conv_array_4x4_compute #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .ROWS(ROWS),
        .OC_LANES(OC_LANES),
        .STEM_OC(STEM_OC),
        .STEM_K(STEM_K),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W),
        .BN_SCALE_INIT_FILE(BN_SCALE_INIT_FILE),
        .BN_BIAS_INIT_FILE(BN_BIAS_INIT_FILE)
    ) u_compute (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .oc_base(oc_base),
        .tile_t_base(tile_t_base),
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
        .out_tile_t_base(out_tile_t_base),
        .out_tile_oc_base(out_tile_oc_base),
        .out_tile(out_tile)
    );

    stem_weight_controller_with_rom #(
        .DATA_W(DATA_W),
        .OC_LANES(OC_LANES),
        .STEM_OC(STEM_OC),
        .STEM_K(STEM_K),
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

    stem_activation_controller_with_ram #(
        .DATA_W(DATA_W),
        .ROWS(ROWS),
        .INPUT_LEN(INPUT_LEN),
        .STEM_IC(STEM_IC),
        .KERNEL(KERNEL),
        .PADDING(PADDING),
        .TIME_W(TIME_W),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .STEM_K(STEM_K),
        .TIME_WORDS(ACT_TIME_WORDS),
        .RAM_DEPTH(ACT_RAM_DEPTH),
        .ADDR_W(ACT_ADDR_W)
    ) u_activation (
        .clk(clk),
        .rst_n(rst_n),
        .act_wr_en(act_wr_en),
        .act_wr_addr(act_wr_addr),
        .act_wr_data(act_wr_data),
        .act_wr_bank(act_wr_bank),
        .act_rd_bank(act_rd_bank),
        .act_rd_active(act_rd_active),
        .act_wr_ready(act_wr_ready),
        .act_req_valid(act_req_valid),
        .act_req_t_base(act_req_t_base),
        .act_req_k(act_req_k),
        .act_req_ready(act_req_ready),
        .act_vec_valid(act_vec_valid),
        .act_vec_ready(act_vec_ready),
        .act_vec(act_vec)
    );

endmodule
