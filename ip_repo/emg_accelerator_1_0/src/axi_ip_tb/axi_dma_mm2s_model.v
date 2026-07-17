`timescale 1ns / 1ps

module axi_dma_mm2s_model #(
    parameter integer DATA_WIDTH = 32
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire [31:0] source_address,
    input  wire [31:0] transfer_bytes,
    output reg busy,
    output reg done,
    output reg error,
    output reg [31:0] beats_sent,

    output wire [31:0] ddr_rd_addr,
    input  wire [DATA_WIDTH-1:0] ddr_rd_data,

    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire [(DATA_WIDTH/8)-1:0] m_axis_tkeep,
    output wire m_axis_tlast,
    output wire m_axis_tvalid,
    input  wire m_axis_tready
);

    localparam integer BYTES_PER_BEAT = DATA_WIDTH / 8;

    reg [31:0] active_source_address;
    reg [31:0] active_transfer_bytes;
    reg [31:0] byte_offset;

    wire axis_fire;
    wire final_beat;

    assign ddr_rd_addr = active_source_address + byte_offset;
    assign m_axis_tdata = ddr_rd_data;
    assign m_axis_tkeep = {(DATA_WIDTH/8){1'b1}};
    assign m_axis_tvalid = busy;
    assign final_beat = (byte_offset + BYTES_PER_BEAT)
        >= active_transfer_bytes;
    assign m_axis_tlast = busy && final_beat;
    assign axis_fire = m_axis_tvalid && m_axis_tready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_source_address <= 32'd0;
            active_transfer_bytes <= 32'd0;
            byte_offset <= 32'd0;
            busy <= 1'b0;
            done <= 1'b0;
            error <= 1'b0;
            beats_sent <= 32'd0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                active_source_address <= source_address;
                active_transfer_bytes <= transfer_bytes;
                byte_offset <= 32'd0;
                beats_sent <= 32'd0;
                error <= (transfer_bytes == 0)
                    || (transfer_bytes % BYTES_PER_BEAT != 0)
                    || (source_address % BYTES_PER_BEAT != 0);
                busy <= (transfer_bytes != 0)
                    && (transfer_bytes % BYTES_PER_BEAT == 0)
                    && (source_address % BYTES_PER_BEAT == 0);
            end else if (axis_fire) begin
                beats_sent <= beats_sent + 1'b1;
                if (final_beat) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    byte_offset <= byte_offset + BYTES_PER_BEAT;
                end
            end
        end
    end

endmodule
