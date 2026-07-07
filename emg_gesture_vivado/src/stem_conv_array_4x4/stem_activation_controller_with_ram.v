`timescale 1ns / 1ps

// Vivado integration wrapper for the stem activation controller and the
// generated blk_mem_gen_stem_activation simple-dual-port RAM IP.

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

    wire ram_en;
    wire [ADDR_W-1:0] ram_addr;
    wire [ROWS*DATA_W-1:0] ram_dout;

    assign act_wr_ready = 1'b1;

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
        .ram_en(ram_en),
        .ram_addr(ram_addr),
        .ram_dout(ram_dout)
    );

    blk_mem_gen_stem_activation u_stem_activation_ram (
        .clka(clk),
        .ena(act_wr_en),
        .wea({act_wr_en}),
        .addra(act_wr_addr),
        .dina(act_wr_data),
        .clkb(clk),
        .enb(ram_en),
        .addrb(ram_addr),
        .doutb(ram_dout)
    );

endmodule
