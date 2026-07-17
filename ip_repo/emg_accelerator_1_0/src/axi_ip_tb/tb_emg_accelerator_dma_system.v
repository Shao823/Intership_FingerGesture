`timescale 1ns / 1ps

`ifndef EMG_TEST_PROJECT_ROOT
`define EMG_TEST_PROJECT_ROOT "D:/Intership"
`endif

module tb_emg_accelerator_dma_system #(
    parameter integer TEST_CASE = 0,
    parameter integer DMA_TIMEOUT = 10000,
    parameter integer CORE_TIMEOUT = 200000
);

    localparam integer FRAME_BYTES = 1740;
    localparam integer FRAME_WORDS = 435;
    localparam integer N_CASES = 10;
    localparam [31:0] CONTROL_AUTO_IRQ = 32'h0000_0012;
    localparam [31:0] CONTROL_CLEAR_DONE_AUTO_IRQ = 32'h0000_0016;

    reg clk;
    reg rst_n;

    reg [4:0] awaddr;
    reg awvalid;
    wire awready;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    reg wvalid;
    wire wready;
    wire [1:0] bresp;
    wire bvalid;
    reg bready;

    reg [4:0] araddr;
    reg arvalid;
    wire arready;
    wire [31:0] rdata;
    wire [1:0] rresp;
    wire rvalid;
    reg rready;

    wire irq;
    wire axis_tready;
    wire [31:0] axis_tdata;
    wire [3:0] axis_tkeep;
    wire axis_tlast;
    wire axis_tvalid;

    reg dma_start;
    reg [31:0] dma_source_address;
    reg [31:0] dma_transfer_bytes;
    wire dma_busy;
    wire dma_done;
    wire dma_error;
    wire [31:0] dma_beats_sent;
    wire [31:0] ddr_rd_addr;
    wire [31:0] ddr_rd_data;

    reg [7:0] expected_class [0:N_CASES-1];
    reg [31:0] read_value;
    reg [31:0] result_value;
    reg [31:0] status_value;
    reg [31:0] error_value;
    reg [31:0] rx_status_value;
    reg [31:0] cycle_count_value;

    integer timeout;

    emg_ddr_model #(
        .N_CASES(N_CASES),
        .RAW_INPUT_FILE({`EMG_TEST_PROJECT_ROOT,
            "/emg_gesture_vivado/src/top/accelerator/testdata/raw_input.mem"})
    ) u_ddr (
        .rd_addr(ddr_rd_addr),
        .rd_data(ddr_rd_data)
    );

    axi_dma_mm2s_model u_dma (
        .clk(clk),
        .rst_n(rst_n),
        .start(dma_start),
        .source_address(dma_source_address),
        .transfer_bytes(dma_transfer_bytes),
        .busy(dma_busy),
        .done(dma_done),
        .error(dma_error),
        .beats_sent(dma_beats_sent),
        .ddr_rd_addr(ddr_rd_addr),
        .ddr_rd_data(ddr_rd_data),
        .m_axis_tdata(axis_tdata),
        .m_axis_tkeep(axis_tkeep),
        .m_axis_tlast(axis_tlast),
        .m_axis_tvalid(axis_tvalid),
        .m_axis_tready(axis_tready)
    );

    emg_accelerator_v1_0 dut (
        .irq(irq),
        .s00_axi_aclk(clk),
        .s00_axi_aresetn(rst_n),
        .s00_axi_awaddr(awaddr),
        .s00_axi_awprot(3'b000),
        .s00_axi_awvalid(awvalid),
        .s00_axi_awready(awready),
        .s00_axi_wdata(wdata),
        .s00_axi_wstrb(wstrb),
        .s00_axi_wvalid(wvalid),
        .s00_axi_wready(wready),
        .s00_axi_bresp(bresp),
        .s00_axi_bvalid(bvalid),
        .s00_axi_bready(bready),
        .s00_axi_araddr(araddr),
        .s00_axi_arprot(3'b000),
        .s00_axi_arvalid(arvalid),
        .s00_axi_arready(arready),
        .s00_axi_rdata(rdata),
        .s00_axi_rresp(rresp),
        .s00_axi_rvalid(rvalid),
        .s00_axi_rready(rready),
        .s00_axis_aclk(clk),
        .s00_axis_aresetn(rst_n),
        .s00_axis_tready(axis_tready),
        .s00_axis_tdata(axis_tdata),
        .s00_axis_tkeep(axis_tkeep),
        .s00_axis_tlast(axis_tlast),
        .s00_axis_tvalid(axis_tvalid)
    );

    always #5 clk = ~clk;

    task axi_write;
        input [4:0] address;
        input [31:0] value;
        begin
            @(negedge clk);
            awaddr = address;
            wdata = value;
            awvalid = 1'b1;
            wvalid = 1'b1;
            bready = 1'b1;

            while (!((awready === 1'b1) && (wready === 1'b1))) begin
                @(posedge clk);
            end

            @(negedge clk);
            awvalid = 1'b0;
            wvalid = 1'b0;

            while (bvalid !== 1'b1) begin
                @(posedge clk);
            end

            if (bresp !== 2'b00) begin
                $fatal(1, "AXI write response error address=%h response=%b",
                    address, bresp);
            end

            @(negedge clk);
            bready = 1'b0;
        end
    endtask

    task axi_read;
        input [4:0] address;
        output [31:0] value;
        begin
            @(negedge clk);
            araddr = address;
            arvalid = 1'b1;
            rready = 1'b1;

            while (arready !== 1'b1) begin
                @(posedge clk);
            end

            @(negedge clk);
            arvalid = 1'b0;

            while (rvalid !== 1'b1) begin
                @(posedge clk);
            end

            if (rresp !== 2'b00) begin
                $fatal(1, "AXI read response error address=%h response=%b",
                    address, rresp);
            end

            value = rdata;
            @(negedge clk);
            rready = 1'b0;
        end
    endtask

    initial begin
        $readmemh({`EMG_TEST_PROJECT_ROOT,
            "/emg_gesture_vivado/src/top/accelerator/testdata/fc_expected_class.mem"},
            expected_class);

        if (^expected_class[TEST_CASE] === 1'bx) begin
            $fatal(1, "Expected-class file was not loaded for case %0d", TEST_CASE);
        end

        clk = 1'b0;
        rst_n = 1'b0;
        awaddr = 5'd0;
        awvalid = 1'b0;
        wdata = 32'd0;
        wstrb = 4'hf;
        wvalid = 1'b0;
        bready = 1'b0;
        araddr = 5'd0;
        arvalid = 1'b0;
        rready = 1'b0;
        dma_start = 1'b0;
        dma_source_address = TEST_CASE * FRAME_BYTES;
        dma_transfer_bytes = FRAME_BYTES;

        repeat (8) @(posedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        axi_write(5'h00, CONTROL_AUTO_IRQ);

        @(negedge clk);
        dma_start = 1'b1;
        @(negedge clk);
        dma_start = 1'b0;

        timeout = 0;
        while ((dma_done !== 1'b1) && (timeout < DMA_TIMEOUT)) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (dma_done !== 1'b1) begin
            $fatal(1, "DMA timeout busy=%0b beats=%0d ready=%0b",
                dma_busy, dma_beats_sent, axis_tready);
        end
        if (dma_error) begin
            $fatal(1, "DMA model reported configuration error");
        end
        if (dma_beats_sent != FRAME_WORDS) begin
            $fatal(1, "DMA beat count got=%0d expected=%0d",
                dma_beats_sent, FRAME_WORDS);
        end

        axi_read(5'h10, rx_status_value);
        if (rx_status_value[31:16] != 16'd1) begin
            $fatal(1, "RX frame count got=%0d expected=1 status=%h",
                rx_status_value[31:16], rx_status_value);
        end

        timeout = 0;
        while ((irq !== 1'b1) && (timeout < CORE_TIMEOUT)) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (irq !== 1'b1) begin
            $fatal(1, "Accelerator timeout status busy=%0b frame_ready=%0b",
                dut.core_busy, dut.frame_ready);
        end

        axi_read(5'h04, status_value);
        axi_read(5'h08, result_value);
        axi_read(5'h14, error_value);
        axi_read(5'h18, cycle_count_value);

        if (!status_value[1] || status_value[0]) begin
            $fatal(1, "Unexpected completion status=%h", status_value);
        end
        if (error_value != 32'd0) begin
            $fatal(1, "Accelerator error status=%h", error_value);
        end
        if (result_value[2:0] !== expected_class[TEST_CASE][2:0]) begin
            $fatal(1, "Classification mismatch got=%0d expected=%0d",
                result_value[2:0], expected_class[TEST_CASE][2:0]);
        end

        $display(
            "PASS tb_emg_accelerator_dma_system case=%0d beats=%0d class=%0d cycles=%0d",
            TEST_CASE,
            dma_beats_sent,
            result_value[2:0],
            cycle_count_value
        );

        axi_write(5'h00, CONTROL_CLEAR_DONE_AUTO_IRQ);
        repeat (2) @(posedge clk);
        if (irq !== 1'b0) begin
            $fatal(1, "IRQ did not clear after CLEAR_DONE");
        end

        $finish;
    end

endmodule
