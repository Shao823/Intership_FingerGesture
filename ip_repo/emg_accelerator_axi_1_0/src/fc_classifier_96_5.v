`timescale 1ns / 1ps

// FC classifier top: compute core + FC packed weight ROM controller.

module fc_classifier_96_5 #(
    parameter integer DATA_W        =  8,
    parameter integer MULT_W        = 16,
    parameter integer GAP_ACC_W     = 48,
    parameter integer ACC_W         = 48,
    parameter integer FC0_IN        = 96,
    parameter integer FC0_OUT       = 96,
    parameter integer FC1_OUT       = 5,
    parameter integer FC0_OUT_LANES = 16,
    parameter integer AVG_LANES     = 12,
    parameter integer GAP_LEN       = 174,
    parameter integer FRAC_BITS     = 8,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer FC_ROM_ADDR_W = 10
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire [8:0] gap_count,
    input  wire signed [FC0_IN*GAP_ACC_W-1:0] gap_sum_vec,

    input  wire result_ready,
    output wire busy,
    output wire done,
    output wire result_valid,
    output wire [2:0] class_idx,
    output wire input_count_error,
    output wire signed [FC1_OUT*DATA_W-1:0] logits_vec
);

    wire weight_req_valid;
    wire weight_req_layer;
    wire [6:0] weight_req_oc_base;
    wire [6:0] weight_req_k;
    wire weight_req_ready;
    wire weight_vec_valid;
    wire weight_vec_ready;
    wire signed [FC0_OUT_LANES*DATA_W-1:0] weight_vec;

    fc_classifier_96_5_compute #(
        .DATA_W(DATA_W),
        .MULT_W(MULT_W),
        .GAP_ACC_W(GAP_ACC_W),
        .ACC_W(ACC_W),
        .FC0_IN(FC0_IN),
        .FC0_OUT(FC0_OUT),
        .FC1_OUT(FC1_OUT),
        .FC0_OUT_LANES(FC0_OUT_LANES),
        .AVG_LANES(AVG_LANES),
        .GAP_LEN(GAP_LEN),
        .FRAC_BITS(FRAC_BITS)
    ) u_compute (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .gap_count(gap_count),
        .gap_sum_vec(gap_sum_vec),
        .weight_req_valid(weight_req_valid),
        .weight_req_layer(weight_req_layer),
        .weight_req_oc_base(weight_req_oc_base),
        .weight_req_k(weight_req_k),
        .weight_req_ready(weight_req_ready),
        .weight_vec_valid(weight_vec_valid),
        .weight_vec_ready(weight_vec_ready),
        .weight_vec(weight_vec),
        .result_ready(result_ready),
        .busy(busy),
        .done(done),
        .result_valid(result_valid),
        .class_idx(class_idx),
        .input_count_error(input_count_error),
        .logits_vec(logits_vec)
    );

    fc_weight_controller_with_rom #(
        .DATA_W(DATA_W),
        .FC0_IN(FC0_IN),
        .FC0_OUT(FC0_OUT),
        .FC1_OUT(FC1_OUT),
        .FC0_OUT_LANES(FC0_OUT_LANES),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .ADDR_W(FC_ROM_ADDR_W)
    ) u_weight_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .weight_req_valid(weight_req_valid),
        .weight_req_layer(weight_req_layer),
        .weight_req_oc_base(weight_req_oc_base),
        .weight_req_k(weight_req_k),
        .weight_req_ready(weight_req_ready),
        .weight_vec_valid(weight_vec_valid),
        .weight_vec_ready(weight_vec_ready),
        .weight_vec(weight_vec)
    );

endmodule
