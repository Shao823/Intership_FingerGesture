`timescale 1ns / 1ps

// Vivado integration wrapper for the stem_to_dw1 buffer controller and the
// generated blk_mem_gen_stem_to_dw_conv1 simple-dual-port RAM IP.

module stem_to_dw1_buffer_with_ram #(
    parameter integer DATA_W     = 16,
    parameter integer TIME_W     = 9,
    parameter integer INPUT_LEN  = 348,
    parameter integer STEM_OC    = 32,
    parameter integer ROWS       = 4,
    parameter integer OC_LANES   = 4,
    parameter integer DW_K       = 5,
    parameter integer DW_PAD     = 2,
    parameter integer RING_ROWS  = 16,
    parameter integer BANKS      = STEM_OC / OC_LANES,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer OC_BASE_W  = (STEM_OC <= 1) ? 1 : $clog2(STEM_OC + 1),
    parameter integer ADDR_W     = (BANKS * RING_ROWS <= 1)
        ? 1 : $clog2(BANKS * RING_ROWS),
    parameter integer BANK_W     = (BANKS <= 1) ? 1 : $clog2(BANKS),
    parameter integer ROW_IDX_W  = (RING_ROWS <= 1) ? 1 : $clog2(RING_ROWS),
    parameter integer TAP_W      = (DW_K <= 1) ? 1 : $clog2(DW_K + 1)
) (
    input  wire clk,
    input  wire rst_n,
    input  wire clear,

    input  wire stem_out_valid,
    output wire stem_out_ready,
    input  wire [TIME_W-1:0] stem_out_tile_t_base,
    input  wire [OC_BASE_W-1:0] stem_out_tile_oc_base,
    input  wire signed [ROWS*OC_LANES*DATA_W-1:0] stem_out_tile,

    input  wire dw1_win_req_valid,
    output wire dw1_win_req_ready,
    input  wire [TIME_W-1:0] dw1_win_req_out_t,
    input  wire [OC_BASE_W-1:0] dw1_win_req_ch_base,

    output wire dw1_win_vec_valid,
    input  wire dw1_win_vec_ready,
    output wire signed [DW_K*OC_LANES*DATA_W-1:0] dw1_win_vec,

    output wire wr_busy,
    output wire rd_busy,
    output wire stem_watermark_stall
);

    localparam integer WORD_W = OC_LANES * DATA_W;

    wire bram_wr_en;
    wire [ADDR_W-1:0] bram_wr_addr;
    wire [WORD_W-1:0] bram_wr_data;
    wire bram_rd_en;
    wire [ADDR_W-1:0] bram_rd_addr;
    wire [WORD_W-1:0] bram_rd_dout;

    stem_to_dw1_buffer #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .STEM_OC(STEM_OC),
        .ROWS(ROWS),
        .OC_LANES(OC_LANES),
        .DW_K(DW_K),
        .DW_PAD(DW_PAD),
        .RING_ROWS(RING_ROWS),
        .BANKS(BANKS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .OC_BASE_W(OC_BASE_W),
        .ADDR_W(ADDR_W),
        .BANK_W(BANK_W),
        .ROW_IDX_W(ROW_IDX_W),
        .TAP_W(TAP_W)
    ) u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .stem_out_valid(stem_out_valid),
        .stem_out_ready(stem_out_ready),
        .stem_out_tile_t_base(stem_out_tile_t_base),
        .stem_out_tile_oc_base(stem_out_tile_oc_base),
        .stem_out_tile(stem_out_tile),
        .dw1_win_req_valid(dw1_win_req_valid),
        .dw1_win_req_ready(dw1_win_req_ready),
        .dw1_win_req_out_t(dw1_win_req_out_t),
        .dw1_win_req_ch_base(dw1_win_req_ch_base),
        .dw1_win_vec_valid(dw1_win_vec_valid),
        .dw1_win_vec_ready(dw1_win_vec_ready),
        .dw1_win_vec(dw1_win_vec),
        .bram_wr_en(bram_wr_en),
        .bram_wr_addr(bram_wr_addr),
        .bram_wr_data(bram_wr_data),
        .bram_rd_en(bram_rd_en),
        .bram_rd_addr(bram_rd_addr),
        .bram_rd_dout(bram_rd_dout),
        .wr_busy(wr_busy),
        .rd_busy(rd_busy),
        .stem_watermark_stall(stem_watermark_stall)
    );

    blk_mem_gen_stem_to_dw_conv1 u_stem_to_dw1_ram (
        .clka(clk),
        .ena(bram_wr_en),
        .wea({bram_wr_en}),
        .addra(bram_wr_addr),
        .dina(bram_wr_data),
        .clkb(clk),
        .enb(bram_rd_en),
        .addrb(bram_rd_addr),
        .doutb(bram_rd_dout)
    );

endmodule
