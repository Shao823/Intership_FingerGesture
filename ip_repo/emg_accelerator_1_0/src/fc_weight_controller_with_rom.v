`timescale 1ns / 1ps

// Vivado integration wrapper for the FC weight controller and generated
// blk_mem_gen_fc_weight single-port ROM IP.

module fc_weight_controller_with_rom #(
    parameter integer DATA_W        =  8,
    parameter integer FC0_IN        = 96,
    parameter integer FC0_OUT       = 96,
    parameter integer FC1_OUT       = 5,
    parameter integer FC0_OUT_LANES = 16,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer ADDR_W        = 10
) (
    input  wire clk,
    input  wire rst_n,

    input  wire weight_req_valid,
    input  wire weight_req_layer,
    input  wire [6:0] weight_req_oc_base,
    input  wire [6:0] weight_req_k,
    output wire weight_req_ready,

    output wire weight_vec_valid,
    input  wire weight_vec_ready,
    output wire signed [FC0_OUT_LANES*DATA_W-1:0] weight_vec
);

    wire rom_en;
    wire [ADDR_W-1:0] rom_addr;
    wire [FC0_OUT_LANES*DATA_W-1:0] rom_dout;

    fc_weight_controller #(
        .DATA_W(DATA_W),
        .FC0_IN(FC0_IN),
        .FC0_OUT(FC0_OUT),
        .FC1_OUT(FC1_OUT),
        .FC0_OUT_LANES(FC0_OUT_LANES),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .ADDR_W(ADDR_W)
    ) u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .weight_req_valid(weight_req_valid),
        .weight_req_layer(weight_req_layer),
        .weight_req_oc_base(weight_req_oc_base),
        .weight_req_k(weight_req_k),
        .weight_req_ready(weight_req_ready),
        .weight_vec_valid(weight_vec_valid),
        .weight_vec_ready(weight_vec_ready),
        .weight_vec(weight_vec),
        .rom_en(rom_en),
        .rom_addr(rom_addr),
        .rom_dout(rom_dout)
    );

    blk_mem_gen_fc_weight u_fc_weight_rom (
        .clka(clk),
        .ena(rom_en),
        .addra(rom_addr),
        .douta(rom_dout)
    );

endmodule
