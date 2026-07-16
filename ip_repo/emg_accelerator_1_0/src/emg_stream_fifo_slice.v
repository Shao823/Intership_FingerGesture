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

    localparam [CNT_W-1:0] FULL_COUNT = 2;

    reg [DATA_W-1:0] data0;
    reg [DATA_W-1:0] data1;
    reg rd_ptr;
    reg wr_ptr;
    reg [CNT_W-1:0] count;

    wire in_fire;
    wire out_fire;

    assign in_ready = (count < FULL_COUNT);
    assign out_valid = (count != {CNT_W{1'b0}});
    assign out_data = rd_ptr ? data1 : data0;
    assign busy = out_valid;

    assign in_fire = in_valid && in_ready;
    assign out_fire = out_valid && out_ready;

    initial begin
        if (DEPTH != 2) begin
            $error("emg_stream_fifo_slice: DEPTH must be 2");
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear) begin
            count <= {CNT_W{1'b0}};
            data0 <= {DATA_W{1'b0}};
            data1 <= {DATA_W{1'b0}};
            rd_ptr <= 1'b0;
            wr_ptr <= 1'b0;
        end else begin
            if (in_fire) begin
                if (wr_ptr) begin
                    data1 <= in_data;
                end else begin
                    data0 <= in_data;
                end
                wr_ptr <= ~wr_ptr;
            end

            if (out_fire) begin
                rd_ptr <= ~rd_ptr;
            end

            case ({in_fire, out_fire})
                2'b10: begin
                    count <= count + 1'b1;
                end

                2'b01: begin
                    count <= count - 1'b1;
                end

                2'b11: begin
                    count <= count;
                end

                default: begin
                    count <= count;
                end
            endcase
        end
    end

endmodule
