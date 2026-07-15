`timescale 1ns / 1ps

// Vivado integration wrapper for the PW2 weight controller and generated
// blk_mem_gen_pw_conv2_weight single-port ROM IP.

module pw_conv2_weight_controller_with_rom #(
    parameter integer DATA_W   =  8,
    parameter integer OC_LANES = 12,
    parameter integer PW2_IC   = 64,
    parameter integer PW2_OC   = 96,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer ADDR_W   = (((PW2_OC / OC_LANES) * PW2_IC) <= 1)
        ? 1 : $clog2((PW2_OC / OC_LANES) * PW2_IC)
) (
    input  wire clk,
    input  wire rst_n,

    input  wire weight_req_valid,
    input  wire [6:0] weight_req_oc_base,
    input  wire [6:0] weight_req_k,
    output wire weight_req_ready,

    output wire weight_vec_valid,
    input  wire weight_vec_ready,
    output wire signed [OC_LANES*DATA_W-1:0] weight_vec
);

    wire rom_en;
    wire [ADDR_W-1:0] rom_addr;
    wire [OC_LANES*DATA_W-1:0] rom_dout;

    pw_conv2_weight_controller #(
        .DATA_W(DATA_W),
        .OC_LANES(OC_LANES),
        .PW2_IC(PW2_IC),
        .PW2_OC(PW2_OC),
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

    blk_mem_gen_pw_conv2_weight u_pw2_weight_rom (
        .clka(clk),
        .ena(rom_en),
        .addra(rom_addr),
        .douta(rom_dout)
    );

endmodule
