`timescale 1ns / 1ps

// Vivado integration wrapper for the PW1 weight controller and generated
// blk_mem_gen_pw_conv1_weight single-port ROM IP.

module pw_conv1_weight_controller_with_rom #(
    parameter integer DATA_W   = 16,
    parameter integer OC_LANES = 8,
    parameter integer PW1_IC   = 32,
    parameter integer PW1_OC   = 64,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer ADDR_W   = (((PW1_OC / OC_LANES) * PW1_IC) <= 1)
        ? 1 : $clog2((PW1_OC / OC_LANES) * PW1_IC)
) (
    input  wire clk,
    input  wire rst_n,

    input  wire weight_req_valid,
    input  wire [5:0] weight_req_oc_base,
    input  wire [5:0] weight_req_k,
    output wire weight_req_ready,

    output wire weight_vec_valid,
    input  wire weight_vec_ready,
    output wire signed [OC_LANES*DATA_W-1:0] weight_vec
);

    wire rom_en;
    wire [ADDR_W-1:0] rom_addr;
    wire [OC_LANES*DATA_W-1:0] rom_dout;

    pw_conv1_weight_controller #(
        .DATA_W(DATA_W),
        .OC_LANES(OC_LANES),
        .PW1_IC(PW1_IC),
        .PW1_OC(PW1_OC),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .ADDR_W(ADDR_W)
    ) u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .weight_req_valid(weight_req_valid),
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

    blk_mem_gen_pw_conv1_weight u_pw1_weight_rom (
        .clka(clk),
        .ena(rom_en),
        .addra(rom_addr),
        .douta(rom_dout)
    );

endmodule
