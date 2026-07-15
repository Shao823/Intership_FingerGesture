`timescale 1ns / 1ps

// Vivado integration wrapper for the DW2-to-PW2 buffer controller and the
// generated blk_mem_gen_dw_to_pw_conv2 true-dual-port RAM IP.

module dw2_to_pw2_buffer_with_ram #(
    parameter integer DATA_W     =  8,
    parameter integer TIME_W     = 8,
    parameter integer INPUT_LEN  = 174,
    parameter integer PW2_IC     = 64,
    parameter integer ROWS       = 4,
    parameter integer CH_LANES   = 4,
    parameter integer RING_ROWS  = 16,
    parameter integer BANKS      = PW2_IC / CH_LANES,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer CH_BASE_W  = (PW2_IC <= 1) ? 1 : $clog2(PW2_IC + 1),
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

    input  wire dw2_out_valid,
    output wire dw2_out_ready,
    input  wire [TIME_W-1:0] dw2_out_t,
    input  wire [CH_BASE_W-1:0] dw2_out_ch_base,
    input  wire signed [CH_LANES*DATA_W-1:0] dw2_out_vec,

    input  wire input_tile_req_valid,
    output wire input_tile_req_ready,
    input  wire [TIME_W-1:0] input_tile_req_t_base,
    input  wire [ROWS-1:0] input_tile_req_row_valid_mask,

    input  wire act_req_valid,
    output wire act_req_ready,
    input  wire [TIME_W-1:0] act_req_t_base,
    input  wire [6:0] act_req_k,
    input  wire [ROWS-1:0] act_req_row_valid_mask,

    output wire act_vec_valid,
    input  wire act_vec_ready,
    output wire signed [ROWS*DATA_W-1:0] act_vec,

    output wire wr_busy,
    output wire rd_busy,
    output wire tile_cache_valid,
    output wire dw2_overwrite_stall
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

    dw2_to_pw2_buffer #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .PW2_IC(PW2_IC),
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
        .dw2_out_valid(dw2_out_valid),
        .dw2_out_ready(dw2_out_ready),
        .dw2_out_t(dw2_out_t),
        .dw2_out_ch_base(dw2_out_ch_base),
        .dw2_out_vec(dw2_out_vec),
        .input_tile_req_valid(input_tile_req_valid),
        .input_tile_req_ready(input_tile_req_ready),
        .input_tile_req_t_base(input_tile_req_t_base),
        .input_tile_req_row_valid_mask(input_tile_req_row_valid_mask),
        .act_req_valid(act_req_valid),
        .act_req_ready(act_req_ready),
        .act_req_t_base(act_req_t_base),
        .act_req_k(act_req_k),
        .act_req_row_valid_mask(act_req_row_valid_mask),
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
        .dw2_overwrite_stall(dw2_overwrite_stall)
    );

    blk_mem_gen_dw_to_pw_conv2 u_dw2_to_pw2_ram (
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
