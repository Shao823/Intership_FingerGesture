`timescale 1ns / 1ps

module emg_accelerator_v1_0_S00_AXIS #(
    parameter integer C_S_AXIS_TDATA_WIDTH = 32,
    parameter integer FRAME_WORDS = 435,
    parameter integer ACT_ADDR_WIDTH = (FRAME_WORDS <= 1) ? 1 : $clog2(FRAME_WORDS)
) (
    input  wire S_AXIS_ACLK,
    input  wire S_AXIS_ARESETN,
    output wire S_AXIS_TREADY,
    input  wire [C_S_AXIS_TDATA_WIDTH-1:0] S_AXIS_TDATA,
    input  wire [(C_S_AXIS_TDATA_WIDTH/8)-1:0] S_AXIS_TKEEP,
    input  wire S_AXIS_TLAST,
    input  wire S_AXIS_TVALID,

    output wire act_wr_en,
    output wire [ACT_ADDR_WIDTH-1:0] act_wr_addr,
    output wire [C_S_AXIS_TDATA_WIDTH-1:0] act_wr_data,
    input  wire act_wr_ready,

    input  wire frame_consume,
    input  wire clear_errors,

    output wire frame_ready,
    output wire rx_active,
    output wire [15:0] beat_count,
    output wire [15:0] frame_count,
    output wire error_early_tlast,
    output wire error_missing_tlast,
    output wire error_bad_keep,
    output wire error_dropped_frame
);

    initial begin
        if (C_S_AXIS_TDATA_WIDTH != 32) begin
            $error("emg_accelerator_v1_0_S00_AXIS requires a 32-bit AXI Stream");
        end
        if (FRAME_WORDS != 435) begin
            $error("emg_accelerator_v1_0_S00_AXIS expects 435 words per EMG frame");
        end
    end

    emg_dma_pingpong_controller #(
        .DATA_WIDTH(C_S_AXIS_TDATA_WIDTH),
        .FRAME_WORDS(FRAME_WORDS),
        .ADDR_WIDTH(ACT_ADDR_WIDTH)
    ) u_dma_pingpong_controller (
        .clk(S_AXIS_ACLK),
        .rst_n(S_AXIS_ARESETN),
        .s_axis_tdata(S_AXIS_TDATA),
        .s_axis_tkeep(S_AXIS_TKEEP),
        .s_axis_tlast(S_AXIS_TLAST),
        .s_axis_tvalid(S_AXIS_TVALID),
        .s_axis_tready(S_AXIS_TREADY),
        .act_wr_en(act_wr_en),
        .act_wr_addr(act_wr_addr),
        .act_wr_data(act_wr_data),
        .act_wr_ready(act_wr_ready),
        .frame_consume(frame_consume),
        .clear_errors(clear_errors),
        .frame_ready(frame_ready),
        .rx_active(rx_active),
        .beat_count(beat_count),
        .frame_count(frame_count),
        .error_early_tlast(error_early_tlast),
        .error_missing_tlast(error_missing_tlast),
        .error_bad_keep(error_bad_keep),
        .error_dropped_frame(error_dropped_frame)
    );

endmodule
