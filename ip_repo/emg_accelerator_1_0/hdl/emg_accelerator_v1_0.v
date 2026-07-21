`timescale 1ns / 1ps

module emg_accelerator_v1_0 #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 6,
    parameter integer C_S00_AXIS_TDATA_WIDTH = 32,
    parameter integer C_FRAME_WORDS = 435,
    parameter integer C_FRAME_BYTES = 1740
) (
    output wire irq,
    output wire class_valid,
    output wire [2:0] class_id,
    output wire inference_done,
    output wire inference_busy,

    input  wire s00_axi_aclk,
    input  wire s00_axi_aresetn,
    input  wire [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr,
    input  wire [2:0] s00_axi_awprot,
    input  wire s00_axi_awvalid,
    output wire s00_axi_awready,
    input  wire [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata,
    input  wire [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb,
    input  wire s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1:0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input  wire s00_axi_bready,
    input  wire [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr,
    input  wire [2:0] s00_axi_arprot,
    input  wire s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata,
    output wire [1:0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input  wire s00_axi_rready,

    input  wire s00_axis_aclk,
    input  wire s00_axis_aresetn,
    output wire s00_axis_tready,
    input  wire [C_S00_AXIS_TDATA_WIDTH-1:0] s00_axis_tdata,
    input  wire [(C_S00_AXIS_TDATA_WIDTH/8)-1:0] s00_axis_tkeep,
    input  wire s00_axis_tlast,
    input  wire s00_axis_tvalid
);

    localparam integer ACT_ADDR_WIDTH = (C_FRAME_WORDS <= 1)
        ? 1 : $clog2(C_FRAME_WORDS);

    wire ctrl_start_pulse;
    wire ctrl_auto_start;
    wire ctrl_clear_errors;
    wire ctrl_irq_enable;

    wire act_wr_en;
    wire [ACT_ADDR_WIDTH-1:0] act_wr_addr;
    wire [C_S00_AXIS_TDATA_WIDTH-1:0] act_wr_data;
    wire act_wr_ready;

    wire frame_ready;
    wire rx_active;
    wire [15:0] beat_count;
    wire [15:0] frame_count;
    wire error_early_tlast;
    wire error_missing_tlast;
    wire error_bad_keep;
    wire error_dropped_frame;

    wire core_start;
    wire core_busy;
    wire core_done;
    wire core_class_valid;
    wire [2:0] core_class_idx;
    wire start_reject_no_frame;
    wire start_reject_busy;
    wire combined_reset_n;
    wire data_plane_rst_n;

    reg [31:0] active_cycle_count;
    reg [31:0] inference_cycles;
    reg [1:0] data_plane_reset_sync;

    assign combined_reset_n = s00_axi_aresetn && s00_axis_aresetn;
    assign data_plane_rst_n = data_plane_reset_sync[1];
    assign core_start = !core_busy
        && frame_ready
        && (ctrl_start_pulse || ctrl_auto_start);
    assign start_reject_busy = ctrl_start_pulse && core_busy;
    assign start_reject_no_frame = ctrl_start_pulse
        && !core_busy
        && !frame_ready;
    assign class_valid = core_class_valid;
    assign class_id = core_class_idx;
    assign inference_done = core_done;
    assign inference_busy = core_busy;

    initial begin
        if (C_S00_AXI_DATA_WIDTH != 32) begin
            $error("emg_accelerator_v1_0 requires a 32-bit AXI-Lite interface");
        end
        if (C_S00_AXIS_TDATA_WIDTH != 32) begin
            $error("emg_accelerator_v1_0 requires a 32-bit AXI Stream interface");
        end
        if (C_FRAME_BYTES != C_FRAME_WORDS * (C_S00_AXIS_TDATA_WIDTH / 8)) begin
            $error("C_FRAME_BYTES must match C_FRAME_WORDS times stream bytes");
        end
    end

    always @(posedge s00_axis_aclk or negedge combined_reset_n) begin
        if (!combined_reset_n) begin
            data_plane_reset_sync <= 2'b00;
        end else begin
            data_plane_reset_sync <= {data_plane_reset_sync[0], 1'b1};
        end
    end

    always @(posedge s00_axis_aclk or negedge data_plane_rst_n) begin
        if (!data_plane_rst_n) begin
            active_cycle_count <= 32'd0;
            inference_cycles <= 32'd0;
        end else begin
            if (core_start) begin
                active_cycle_count <= 32'd0;
            end else if (core_busy) begin
                active_cycle_count <= active_cycle_count + 1'b1;
            end
            if (core_done) begin
                inference_cycles <= active_cycle_count;
            end
        end
    end

    emg_accelerator_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
        .FRAME_WORDS(C_FRAME_WORDS),
        .FRAME_BYTES(C_FRAME_BYTES)
    ) u_s00_axi (
        .start_pulse(ctrl_start_pulse),
        .auto_start(ctrl_auto_start),
        .clear_errors_pulse(ctrl_clear_errors),
        .irq_enable(ctrl_irq_enable),
        .irq(irq),
        .core_busy(core_busy),
        .core_done(core_done),
        .core_class_valid(core_class_valid),
        .core_class_idx(core_class_idx),
        .frame_ready(frame_ready),
        .rx_active(rx_active),
        .act_wr_ready(act_wr_ready),
        .beat_count(beat_count),
        .frame_count(frame_count),
        .error_early_tlast(error_early_tlast),
        .error_missing_tlast(error_missing_tlast),
        .error_bad_keep(error_bad_keep),
        .error_dropped_frame(error_dropped_frame),
        .start_accept(core_start),
        .start_reject_no_frame(start_reject_no_frame),
        .start_reject_busy(start_reject_busy),
        .inference_cycles(inference_cycles),
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

    emg_accelerator_v1_0_S00_AXIS #(
        .C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
        .FRAME_WORDS(C_FRAME_WORDS),
        .ACT_ADDR_WIDTH(ACT_ADDR_WIDTH)
    ) u_s00_axis (
        .S_AXIS_ACLK(s00_axis_aclk),
        .S_AXIS_ARESETN(data_plane_rst_n),
        .S_AXIS_TREADY(s00_axis_tready),
        .S_AXIS_TDATA(s00_axis_tdata),
        .S_AXIS_TKEEP(s00_axis_tkeep),
        .S_AXIS_TLAST(s00_axis_tlast),
        .S_AXIS_TVALID(s00_axis_tvalid),
        .act_wr_en(act_wr_en),
        .act_wr_addr(act_wr_addr),
        .act_wr_data(act_wr_data),
        .act_wr_ready(act_wr_ready),
        .frame_consume(core_start),
        .clear_errors(ctrl_clear_errors),
        .frame_ready(frame_ready),
        .rx_active(rx_active),
        .beat_count(beat_count),
        .frame_count(frame_count),
        .error_early_tlast(error_early_tlast),
        .error_missing_tlast(error_missing_tlast),
        .error_bad_keep(error_bad_keep),
        .error_dropped_frame(error_dropped_frame)
    );

    accelerator u_accelerator (
        .clk(s00_axis_aclk),
        .rst_n(data_plane_rst_n),
        .start(core_start),
        .busy(core_busy),
        .done(core_done),
        .act_wr_en(act_wr_en),
        .act_wr_addr(act_wr_addr),
        .act_wr_data(act_wr_data),
        .act_wr_ready(act_wr_ready),
        .class_valid(core_class_valid),
        .class_idx(core_class_idx)
    );

endmodule
