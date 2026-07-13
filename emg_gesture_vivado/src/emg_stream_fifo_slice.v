`timescale 1ns / 1ps

module emg_stream_fifo_slice #(
    parameter integer DATA_W = 8,
    parameter integer DEPTH  = 4,
    parameter integer PTR_W  = (DEPTH <= 1) ? 1 : $clog2(DEPTH),
    parameter integer CNT_W  = (DEPTH <= 1) ? 1 : $clog2(DEPTH + 1)
) (
    input  wire clk,
    input  wire rst_n,
    input  wire clear,

    input  wire in_valid,
    output wire in_ready,
    input  wire [DATA_W-1:0] in_data,

    output wire out_valid,
    input  wire out_ready,
    output wire [DATA_W-1:0] out_data,

    output wire busy
);

    localparam [CNT_W-1:0] DEPTH_COUNT = DEPTH;

    reg [DATA_W-1:0] data_mem [0:DEPTH-1];
    reg [PTR_W-1:0] rd_ptr;
    reg [PTR_W-1:0] wr_ptr;
    reg [CNT_W-1:0] count;

    wire in_fire;
    wire out_fire;

    integer rst_i;

    assign in_ready = (count < DEPTH_COUNT);
    assign out_valid = (count != {CNT_W{1'b0}});
    assign out_data = data_mem[rd_ptr];
    assign busy = out_valid;

    assign in_fire = in_valid && in_ready;
    assign out_fire = out_valid && out_ready;

    function [PTR_W-1:0] next_ptr;
        input [PTR_W-1:0] ptr_i;
        begin
            if (ptr_i == (DEPTH - 1)) begin
                next_ptr = {PTR_W{1'b0}};
            end else begin
                next_ptr = ptr_i + 1'b1;
            end
        end
    endfunction

    initial begin
        if (DEPTH < 2) begin
            $error("emg_stream_fifo_slice: DEPTH must be >= 2");
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            rd_ptr <= {PTR_W{1'b0}};
            wr_ptr <= {PTR_W{1'b0}};
            count <= {CNT_W{1'b0}};
            for (rst_i = 0; rst_i < DEPTH; rst_i = rst_i + 1) begin
                data_mem[rst_i] <= {DATA_W{1'b0}};
            end
        end else begin
            if (in_fire) begin
                data_mem[wr_ptr] <= in_data;
                wr_ptr <= next_ptr(wr_ptr);
            end

            if (out_fire) begin
                rd_ptr <= next_ptr(rd_ptr);
            end

            case ({in_fire, out_fire})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
