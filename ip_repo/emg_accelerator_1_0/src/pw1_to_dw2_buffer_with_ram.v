`timescale 1ns / 1ps

// Vivado integration wrapper for the PW1-to-DW2 buffer controller and the
// generated blk_mem_gen_pw_to_dw_conv2 true-dual-port RAM IP.

module pw1_to_dw2_buffer_with_ram #(
    parameter integer DATA_W     =  8,
    parameter integer TIME_W     = 8,
    parameter integer INPUT_LEN  = 174,
    parameter integer PW1_OC     = 64,
    parameter integer POOL_ROWS  = 2,
    parameter integer PW1_OC_LANES = 8,
    parameter integer CH_LANES   = 4,
    parameter integer DW_K       = 5,
    parameter integer DW_PAD     = 2,
    parameter integer RING_ROWS  = 16,
    parameter integer BANKS      = PW1_OC / CH_LANES,
    parameter integer TILE_BANKS = PW1_OC_LANES / CH_LANES,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer OC_BASE_W  = (PW1_OC <= 1) ? 1 : $clog2(PW1_OC),
    parameter integer ADDR_W     = (BANKS * RING_ROWS <= 1)
        ? 1 : $clog2(BANKS * RING_ROWS),
    parameter integer BANK_W     = (BANKS <= 1) ? 1 : $clog2(BANKS),
    parameter integer ROW_IDX_W  = (RING_ROWS <= 1) ? 1 : $clog2(RING_ROWS),
    parameter integer TAP_W      = (DW_K <= 1) ? 1 : $clog2(DW_K + 1),
    parameter integer WRITE_WORDS = POOL_ROWS * TILE_BANKS,
    parameter integer WRITE_W    = (WRITE_WORDS <= 1) ? 1 : $clog2(WRITE_WORDS + 1)
) (
    input  wire clk,
    input  wire rst_n,
    input  wire clear,

    input  wire pw1_out_valid,
    output wire pw1_out_ready,
    input  wire [TIME_W-1:0] pw1_out_pool_t_base,
    input  wire [OC_BASE_W-1:0] pw1_out_oc_base,
    input  wire signed [POOL_ROWS*PW1_OC_LANES*DATA_W-1:0] pw1_out_tile,

    input  wire dw2_win_req_valid,
    output wire dw2_win_req_ready,
    input  wire [TIME_W-1:0] dw2_win_req_out_t,
    input  wire [OC_BASE_W-1:0] dw2_win_req_ch_base,

    output wire dw2_win_vec_valid,
    input  wire dw2_win_vec_ready,
    output wire signed [DW_K*CH_LANES*DATA_W-1:0] dw2_win_vec,

    output wire wr_busy,
    output wire rd_busy,
    output wire pw1_overwrite_stall
);

    localparam integer WORD_W = CH_LANES * DATA_W;

    wire bram_wr_en;
    wire [ADDR_W-1:0] bram_wr_addr;
    wire [WORD_W-1:0] bram_wr_data;
    wire bram_rd_en;
    wire [ADDR_W-1:0] bram_rd_addr;
    wire [WORD_W-1:0] bram_rd_dout;
    wire [WORD_W-1:0] bram_unused_douta;

    pw1_to_dw2_buffer #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .PW1_OC(PW1_OC),
        .POOL_ROWS(POOL_ROWS),
        .PW1_OC_LANES(PW1_OC_LANES),
        .CH_LANES(CH_LANES),
        .DW_K(DW_K),
        .DW_PAD(DW_PAD),
        .RING_ROWS(RING_ROWS),
        .BANKS(BANKS),
        .TILE_BANKS(TILE_BANKS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .OC_BASE_W(OC_BASE_W),
        .ADDR_W(ADDR_W),
        .BANK_W(BANK_W),
        .ROW_IDX_W(ROW_IDX_W),
        .TAP_W(TAP_W),
        .WRITE_WORDS(WRITE_WORDS),
        .WRITE_W(WRITE_W)
    ) u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .pw1_out_valid(pw1_out_valid),
        .pw1_out_ready(pw1_out_ready),
        .pw1_out_pool_t_base(pw1_out_pool_t_base),
        .pw1_out_oc_base(pw1_out_oc_base),
        .pw1_out_tile(pw1_out_tile),
        .dw2_win_req_valid(dw2_win_req_valid),
        .dw2_win_req_ready(dw2_win_req_ready),
        .dw2_win_req_out_t(dw2_win_req_out_t),
        .dw2_win_req_ch_base(dw2_win_req_ch_base),
        .dw2_win_vec_valid(dw2_win_vec_valid),
        .dw2_win_vec_ready(dw2_win_vec_ready),
        .dw2_win_vec(dw2_win_vec),
        .bram_wr_en(bram_wr_en),
        .bram_wr_addr(bram_wr_addr),
        .bram_wr_data(bram_wr_data),
        .bram_rd_en(bram_rd_en),
        .bram_rd_addr(bram_rd_addr),
        .bram_rd_dout(bram_rd_dout),
        .wr_busy(wr_busy),
        .rd_busy(rd_busy),
        .pw1_overwrite_stall(pw1_overwrite_stall)
    );

    blk_mem_gen_pw_to_dw_conv2 u_pw1_to_dw2_ram (
        .clka(clk),
        .ena(bram_wr_en),
        .wea({bram_wr_en}),
        .addra(bram_wr_addr),
        .dina(bram_wr_data),
        .douta(bram_unused_douta),
        .clkb(clk),
        .enb(bram_rd_en),
        .web({1'b0}),
        .addrb(bram_rd_addr),
        .dinb({WORD_W{1'b0}}),
        .doutb(bram_rd_dout)
    );

endmodule
