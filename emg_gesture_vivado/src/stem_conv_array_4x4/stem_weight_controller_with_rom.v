`timescale 1ns / 1ps

// Vivado integration wrapper for the stem weight controller and the generated
// blk_mem_gen_stem_weight single-port ROM IP.

module stem_weight_controller_with_rom #(
    parameter integer DATA_W   = 16,
    parameter integer OC_LANES = 4,
    parameter integer STEM_OC  = 32,
    parameter integer STEM_K   = 35,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer ADDR_W   = (((STEM_OC / OC_LANES) * STEM_K) <= 1)
        ? 1 : $clog2((STEM_OC / OC_LANES) * STEM_K)
) (
    input  wire clk,
    input  wire rst_n,

    input  wire weight_req_valid,
    input  wire [4:0] weight_req_oc_base,
    input  wire [5:0] weight_req_k,
    output wire weight_req_ready,

    output wire weight_vec_valid,
    input  wire weight_vec_ready,
    output wire signed [OC_LANES*DATA_W-1:0] weight_vec
);

    wire rom_en;
    wire [ADDR_W-1:0] rom_addr;
    wire [OC_LANES*DATA_W-1:0] rom_dout;

    stem_weight_controller #(
        .DATA_W(DATA_W),
        .OC_LANES(OC_LANES),
        .STEM_OC(STEM_OC),
        .STEM_K(STEM_K),
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

    blk_mem_gen_stem_weight u_stem_weight_rom (
        .clka(clk),
        .ena(rom_en),
        .addra(rom_addr),
        .douta(rom_dout)
    );

endmodule
