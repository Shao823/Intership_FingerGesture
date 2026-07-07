`timescale 1ns / 1ps

// Weight address and response controller for the LightCNN1D stem convolution.
//
// The stem weight ROM is organized as 280 x 64-bit words:
//   addr = (oc_base / 4) * 35 + k
//   dout = {W[oc_base+3][k], ..., W[oc_base+0][k]}
//
// The current blk_mem_gen_stem_weight IP is configured with READ_LATENCY_A=1.
// Its registered douta updates after the next clock edge, so this controller
// samples rom_dout one clock later than the IP update edge. The effective
// request-to-weight_vec latency is therefore two controller clock edges.
// rom_en is kept high for one cycle after a real request so the BMG output
// register can advance even when no new request is accepted.
// A four-entry response FIFO keeps one-read-per-cycle throughput while safely
// absorbing in-flight ROM responses when weight_vec_ready stalls.

module stem_weight_controller #(
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
    output wire signed [OC_LANES*DATA_W-1:0] weight_vec,

    output wire rom_en,
    output wire [ADDR_W-1:0] rom_addr,
    input  wire [OC_LANES*DATA_W-1:0] rom_dout
);

    localparam integer WORD_W = OC_LANES * DATA_W;
    localparam integer FIFO_DEPTH = BRAM_READ_LATENCY + 3;
    localparam integer FIFO_PTR_W = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH);
    localparam integer FIFO_CNT_W = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH + 1);

    reg [WORD_W-1:0] fifo_data [0:FIFO_DEPTH-1];
    reg [FIFO_CNT_W-1:0] fifo_count;
    reg [FIFO_PTR_W-1:0] fifo_rd_ptr;
    reg [FIFO_PTR_W-1:0] fifo_wr_ptr;
    reg [BRAM_READ_LATENCY:0] rom_valid_d;
    reg [ADDR_W-1:0] rom_addr_hold;

    wire resp_fire;
    wire req_fire;
    wire [7:0] reserved_count_after_pop;
    wire fifo_push;
    wire rom_pipe_en;

    integer seq_i;

    assign weight_vec_valid = (fifo_count != {FIFO_CNT_W{1'b0}});
    assign weight_vec = fifo_data[fifo_rd_ptr];
    assign resp_fire = weight_vec_valid && weight_vec_ready;
    assign fifo_push = rom_valid_d[BRAM_READ_LATENCY];
    assign rom_pipe_en = any_pre_response_valid(rom_valid_d);

    // Reserve space for both ROM words already in flight. This prevents the
    // FIFO from overflowing if the downstream stalls after a request is issued.
    assign reserved_count_after_pop = {4'b0000, fifo_count}
        + count_valid(rom_valid_d)
        - {7'b0000000, resp_fire};
    assign weight_req_ready = (reserved_count_after_pop < FIFO_DEPTH);

    assign req_fire = weight_req_valid && weight_req_ready;
    assign rom_en = req_fire || rom_pipe_en;
    assign rom_addr = req_fire
        ? calc_weight_addr(weight_req_oc_base, weight_req_k)
        : rom_addr_hold;

    function [7:0] count_valid;
        input [BRAM_READ_LATENCY:0] valid_vec;
        integer idx;
        begin
            count_valid = 8'd0;
            for (idx = 0; idx <= BRAM_READ_LATENCY; idx = idx + 1) begin
                count_valid = count_valid + valid_vec[idx];
            end
        end
    endfunction

    function any_pre_response_valid;
        input [BRAM_READ_LATENCY:0] valid_vec;
        integer idx;
        begin
            any_pre_response_valid = 1'b0;
            for (idx = 0; idx < BRAM_READ_LATENCY; idx = idx + 1) begin
                any_pre_response_valid = any_pre_response_valid || valid_vec[idx];
            end
        end
    endfunction

    function [FIFO_PTR_W-1:0] next_fifo_ptr;
        input [FIFO_PTR_W-1:0] ptr;
        begin
            if (ptr == FIFO_DEPTH - 1) begin
                next_fifo_ptr = {FIFO_PTR_W{1'b0}};
            end else begin
                next_fifo_ptr = ptr + 1'b1;
            end
        end
    endfunction

    function [ADDR_W-1:0] calc_weight_addr;
        input [4:0] oc_base_i;
        input [5:0] k_i;
        begin
            calc_weight_addr = (oc_base_i[4:2] * STEM_K) + k_i;
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (seq_i = 0; seq_i < FIFO_DEPTH; seq_i = seq_i + 1) begin
                fifo_data[seq_i] <= {WORD_W{1'b0}};
            end
            fifo_count <= {FIFO_CNT_W{1'b0}};
            fifo_rd_ptr <= {FIFO_PTR_W{1'b0}};
            fifo_wr_ptr <= {FIFO_PTR_W{1'b0}};
            rom_valid_d <= {(BRAM_READ_LATENCY+1){1'b0}};
            rom_addr_hold <= {ADDR_W{1'b0}};
        end else begin
            if (resp_fire) begin
                fifo_rd_ptr <= next_fifo_ptr(fifo_rd_ptr);
            end

            if (fifo_push) begin
                fifo_data[fifo_wr_ptr] <= rom_dout;
                fifo_wr_ptr <= next_fifo_ptr(fifo_wr_ptr);
            end

            fifo_count <= fifo_count
                + {{(FIFO_CNT_W-1){1'b0}}, fifo_push}
                - {{(FIFO_CNT_W-1){1'b0}}, resp_fire};

            if (req_fire) begin
                rom_addr_hold <= calc_weight_addr(weight_req_oc_base, weight_req_k);
            end

            rom_valid_d[0] <= req_fire;
            for (seq_i = 1; seq_i <= BRAM_READ_LATENCY; seq_i = seq_i + 1) begin
                rom_valid_d[seq_i] <= rom_valid_d[seq_i-1];
            end
        end
    end

`ifndef SYNTHESIS
    reg [31:0] invalid_req_count;

    wire invalid_oc_align;
    wire invalid_oc_range;
    wire invalid_k;

    assign invalid_oc_align = (weight_req_oc_base[1:0] != 2'b00);
    assign invalid_oc_range = (weight_req_oc_base > (STEM_OC - OC_LANES));
    assign invalid_k = (weight_req_k >= STEM_K);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            invalid_req_count <= 32'd0;
        end else if (req_fire) begin
            if (invalid_oc_align || invalid_oc_range || invalid_k) begin
                invalid_req_count <= invalid_req_count + 1'b1;
            end
            if (invalid_oc_align) begin
                $display(
                    "ERROR stem_weight_controller: oc_base %0d is not 4-aligned",
                    weight_req_oc_base
                );
            end
            if (invalid_oc_range) begin
                $display(
                    "ERROR stem_weight_controller: oc_base %0d exceeds max %0d",
                    weight_req_oc_base,
                    STEM_OC - OC_LANES
                );
            end
            if (invalid_k) begin
                $display(
                    "ERROR stem_weight_controller: k %0d exceeds max %0d",
                    weight_req_k,
                    STEM_K - 1
                );
            end
        end
    end
`endif

endmodule
