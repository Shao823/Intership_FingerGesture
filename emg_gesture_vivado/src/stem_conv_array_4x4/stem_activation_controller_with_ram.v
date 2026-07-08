`timescale 1ns / 1ps

// Vivado integration wrapper for the stem activation controller and the
// generated blk_mem_gen_stem_activation true-dual-port RAM IP.
//
// Port A is time-multiplexed: external activation writes use it while the stem
// core is idle; otherwise the controller uses it as read port 0. Port B is read
// port 1. The current non-ping-pong top-level schedule must not write this RAM
// while the stem activation controller is reading it.

module stem_activation_controller_with_ram #(
    parameter integer DATA_W     = 16,
    parameter integer ROWS       = 4,
    parameter integer INPUT_LEN  = 348,
    parameter integer STEM_IC    = 5,
    parameter integer KERNEL     = 7,
    parameter integer PADDING    = 3,
    parameter integer TIME_W     = 9,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer STEM_K     = STEM_IC * KERNEL,
    parameter integer TIME_WORDS = (INPUT_LEN + ROWS - 1) / ROWS,
    parameter integer RAM_DEPTH  = STEM_IC * TIME_WORDS,
    parameter integer ADDR_W     = (RAM_DEPTH <= 1) ? 1 : $clog2(RAM_DEPTH)
) (
    input  wire clk,
    input  wire rst_n,

    input  wire act_wr_en,
    input  wire [ADDR_W-1:0] act_wr_addr,
    input  wire [ROWS*DATA_W-1:0] act_wr_data,
    output wire act_wr_ready,

    input  wire act_req_valid,
    input  wire [TIME_W-1:0] act_req_t_base,
    input  wire [5:0] act_req_k,
    output wire act_req_ready,

    output wire act_vec_valid,
    input  wire act_vec_ready,
    output wire signed [ROWS*DATA_W-1:0] act_vec
);

    wire ram0_en;
    wire [ADDR_W-1:0] ram0_addr;
    wire [ROWS*DATA_W-1:0] ram0_dout;
    wire ram1_en;
    wire [ADDR_W-1:0] ram1_addr;
    wire [ROWS*DATA_W-1:0] ram1_dout;

    wire porta_en;
    wire porta_we;
    wire [ADDR_W-1:0] porta_addr;
    wire [ROWS*DATA_W-1:0] porta_din;

    assign act_wr_ready = 1'b1;
    assign porta_en = act_wr_en || ram0_en;
    assign porta_we = act_wr_en;
    assign porta_addr = act_wr_en ? act_wr_addr : ram0_addr;
    assign porta_din = act_wr_en ? act_wr_data : {(ROWS*DATA_W){1'b0}};

    stem_activation_controller #(
        .DATA_W(DATA_W),
        .ROWS(ROWS),
        .INPUT_LEN(INPUT_LEN),
        .STEM_IC(STEM_IC),
        .KERNEL(KERNEL),
        .PADDING(PADDING),
        .TIME_W(TIME_W),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .STEM_K(STEM_K),
        .TIME_WORDS(TIME_WORDS),
        .RAM_DEPTH(RAM_DEPTH),
        .ADDR_W(ADDR_W)
    ) u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .act_req_valid(act_req_valid),
        .act_req_t_base(act_req_t_base),
        .act_req_k(act_req_k),
        .act_req_ready(act_req_ready),
        .act_vec_valid(act_vec_valid),
        .act_vec_ready(act_vec_ready),
        .act_vec(act_vec),
        .ram0_en(ram0_en),
        .ram0_addr(ram0_addr),
        .ram0_dout(ram0_dout),
        .ram1_en(ram1_en),
        .ram1_addr(ram1_addr),
        .ram1_dout(ram1_dout)
    );

    blk_mem_gen_stem_activation u_stem_activation_ram (
        .clka(clk),
        .ena(porta_en),
        .wea({porta_we}),
        .addra(porta_addr),
        .dina(porta_din),
        .douta(ram0_dout),
        .clkb(clk),
        .enb(ram1_en),
        .web(1'b0),
        .addrb(ram1_addr),
        .dinb({(ROWS*DATA_W){1'b0}}),
        .doutb(ram1_dout)
    );

endmodule
