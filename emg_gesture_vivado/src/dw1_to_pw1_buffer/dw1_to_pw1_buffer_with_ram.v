`timescale 1ns / 1ps

// Vivado integration wrapper for the DW1-to-PW1 buffer controller and the
// generated blk_mem_gen_dw_to_pw_conv1 true-dual-port RAM IP.

module dw1_to_pw1_buffer_with_ram #(
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

    output wire wr_busy,
    output wire rd_busy,
    output wire tile_cache_valid,
    output wire dw1_overwrite_stall
);

    localparam integer WORD_W = CH_LANES * DATA_W;

    wire bram_a_en;
    wire bram_a_we;
    wire [ADDR_W-1:0] bram_a_addr;
    wire [WORD_W-1:0] bram_a_din;
    wire [WORD_W-1:0] bram_a_dout;
    wire bram_b_en;
    wire bram_b_we;
    wire [ADDR_W-1:0] bram_b_addr;
    wire [WORD_W-1:0] bram_b_din;
    wire [WORD_W-1:0] bram_b_dout;

    dw1_to_pw1_buffer #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .PW1_IC(PW1_IC),
        .ROWS(ROWS),
        .CH_LANES(CH_LANES),
        .RING_ROWS(RING_ROWS),
        .BANKS(BANKS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .CH_BASE_W(CH_BASE_W),
        .ADDR_W(ADDR_W),
        .BANK_W(BANK_W),
        .ROW_IDX_W(ROW_IDX_W),
        .LOAD_WORDS(LOAD_WORDS),
        .LOAD_W(LOAD_W)
    ) u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .dw1_out_valid(dw1_out_valid),
        .dw1_out_ready(dw1_out_ready),
        .dw1_out_t(dw1_out_t),
        .dw1_out_ch_base(dw1_out_ch_base),
        .dw1_out_vec(dw1_out_vec),
        .input_tile_req_valid(input_tile_req_valid),
        .input_tile_req_ready(input_tile_req_ready),
        .input_tile_req_t_base(input_tile_req_t_base),
        .act_req_valid(act_req_valid),
        .act_req_ready(act_req_ready),
        .act_req_t_base(act_req_t_base),
        .act_req_k(act_req_k),
        .act_vec_valid(act_vec_valid),
        .act_vec_ready(act_vec_ready),
        .act_vec(act_vec),
        .bram_a_en(bram_a_en),
        .bram_a_we(bram_a_we),
        .bram_a_addr(bram_a_addr),
        .bram_a_din(bram_a_din),
        .bram_a_dout(bram_a_dout),
        .bram_b_en(bram_b_en),
        .bram_b_we(bram_b_we),
        .bram_b_addr(bram_b_addr),
        .bram_b_din(bram_b_din),
        .bram_b_dout(bram_b_dout),
        .wr_busy(wr_busy),
        .rd_busy(rd_busy),
        .tile_cache_valid(tile_cache_valid),
        .dw1_overwrite_stall(dw1_overwrite_stall)
    );

    blk_mem_gen_dw_to_pw_conv1 u_dw1_to_pw1_ram (
        .clka(clk),
        .ena(bram_a_en),
        .wea({bram_a_we}),
        .addra(bram_a_addr),
        .dina(bram_a_din),
        .douta(bram_a_dout),
        .clkb(clk),
        .enb(bram_b_en),
        .web({bram_b_we}),
        .addrb(bram_b_addr),
        .dinb(bram_b_din),
        .doutb(bram_b_dout)
    );

endmodule
