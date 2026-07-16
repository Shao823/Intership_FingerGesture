`timescale 1ns / 1ps

// Vivado integration wrapper for the stem activation controller and the
// generated stem activation true-dual-port RAM IPs.
//
// Two physical RAM banks implement input ping-pong buffering. The stem
// activation controller reads act_rd_bank, while external writes target
// act_wr_bank. Port A of each bank is time-multiplexed between external writes
// and controller read port 0; Port B remains controller read port 1.

module stem_activation_controller_with_ram #(
    parameter integer DATA_W     =  8,
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
    input  wire act_wr_bank,
    input  wire act_rd_bank,
    input  wire act_rd_active,
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

    wire act_wr_fire;
    wire wr_hits_active_read_bank;

    wire bank0_ram0_en;
    wire bank1_ram0_en;
    wire bank0_ram1_en;
    wire bank1_ram1_en;

    wire bank0_porta_en;
    wire bank0_porta_we;
    wire [ADDR_W-1:0] bank0_porta_addr;
    wire [ROWS*DATA_W-1:0] bank0_porta_din;
    wire [ROWS*DATA_W-1:0] bank0_douta;
    wire [ROWS*DATA_W-1:0] bank0_doutb;

    wire bank1_porta_en;
    wire bank1_porta_we;
    wire [ADDR_W-1:0] bank1_porta_addr;
    wire [ROWS*DATA_W-1:0] bank1_porta_din;
    wire [ROWS*DATA_W-1:0] bank1_douta;
    wire [ROWS*DATA_W-1:0] bank1_doutb;

    assign wr_hits_active_read_bank = act_rd_active
        && (act_wr_bank == act_rd_bank);
    assign act_wr_ready = !wr_hits_active_read_bank;
    assign act_wr_fire = act_wr_en && act_wr_ready;

    assign bank0_ram0_en = ram0_en && (act_rd_bank == 1'b0);
    assign bank1_ram0_en = ram0_en && (act_rd_bank == 1'b1);
    assign bank0_ram1_en = ram1_en && (act_rd_bank == 1'b0);
    assign bank1_ram1_en = ram1_en && (act_rd_bank == 1'b1);

    assign bank0_porta_en = (act_wr_fire && (act_wr_bank == 1'b0))
        || bank0_ram0_en;
    assign bank0_porta_we = act_wr_fire && (act_wr_bank == 1'b0);
    assign bank0_porta_addr = bank0_porta_we ? act_wr_addr : ram0_addr;
    assign bank0_porta_din = bank0_porta_we
        ? act_wr_data : {(ROWS*DATA_W){1'b0}};

    assign bank1_porta_en = (act_wr_fire && (act_wr_bank == 1'b1))
        || bank1_ram0_en;
    assign bank1_porta_we = act_wr_fire && (act_wr_bank == 1'b1);
    assign bank1_porta_addr = bank1_porta_we ? act_wr_addr : ram0_addr;
    assign bank1_porta_din = bank1_porta_we
        ? act_wr_data : {(ROWS*DATA_W){1'b0}};

    assign ram0_dout = (act_rd_bank == 1'b0) ? bank0_douta : bank1_douta;
    assign ram1_dout = (act_rd_bank == 1'b0) ? bank0_doutb : bank1_doutb;

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

    blk_mem_gen_stem_activation u_stem_activation_bank0 (
        .clka(clk),
        .ena(bank0_porta_en),
        .wea({bank0_porta_we}),
        .addra(bank0_porta_addr),
        .dina(bank0_porta_din),
        .douta(bank0_douta),
        .clkb(clk),
        .enb(bank0_ram1_en),
        .web(1'b0),
        .addrb(ram1_addr),
        .dinb({(ROWS*DATA_W){1'b0}}),
        .doutb(bank0_doutb)
    );

    blk_mem_gen_stem_activation u_stem_activation_bank1 (
        .clka(clk),
        .ena(bank1_porta_en),
        .wea({bank1_porta_we}),
        .addra(bank1_porta_addr),
        .dina(bank1_porta_din),
        .douta(bank1_douta),
        .clkb(clk),
        .enb(bank1_ram1_en),
        .web(1'b0),
        .addrb(ram1_addr),
        .dinb({(ROWS*DATA_W){1'b0}}),
        .doutb(bank1_doutb)
    );

endmodule
