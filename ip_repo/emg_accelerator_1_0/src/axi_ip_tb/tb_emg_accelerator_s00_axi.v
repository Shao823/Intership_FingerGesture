`timescale 1ns / 1ps

module tb_emg_accelerator_s00_axi;

    reg clk;
    reg rst_n;
    wire start_pulse;
    wire auto_start;
    wire clear_errors_pulse;
    wire irq_enable;
    wire irq;
    reg core_busy;
    reg core_done;
    reg core_class_valid;
    reg [2:0] core_class_idx;
    reg frame_ready;
    reg rx_active;
    reg act_wr_ready;
    reg [15:0] beat_count;
    reg [15:0] frame_count;
    reg error_early_tlast;
    reg error_missing_tlast;
    reg error_bad_keep;
    reg error_dropped_frame;
    reg start_accept;
    reg start_reject_no_frame;
    reg start_reject_busy;
    reg [31:0] inference_cycles;

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

    reg [31:0] read_value;
    reg saw_clear_errors;

    emg_accelerator_v1_0_S00_AXI dut (
        .start_pulse(start_pulse),
        .auto_start(auto_start),
        .clear_errors_pulse(clear_errors_pulse),
        .irq_enable(irq_enable),
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
        .start_accept(start_accept),
        .start_reject_no_frame(start_reject_no_frame),
        .start_reject_busy(start_reject_busy),
        .inference_cycles(inference_cycles),
        .S_AXI_ACLK(clk),
        .S_AXI_ARESETN(rst_n),
        .S_AXI_AWADDR(awaddr),
        .S_AXI_AWPROT(3'b000),
        .S_AXI_AWVALID(awvalid),
        .S_AXI_AWREADY(awready),
        .S_AXI_WDATA(wdata),
        .S_AXI_WSTRB(wstrb),
        .S_AXI_WVALID(wvalid),
        .S_AXI_WREADY(wready),
        .S_AXI_BRESP(bresp),
        .S_AXI_BVALID(bvalid),
        .S_AXI_BREADY(bready),
        .S_AXI_ARADDR(araddr),
        .S_AXI_ARPROT(3'b000),
        .S_AXI_ARVALID(arvalid),
        .S_AXI_ARREADY(arready),
        .S_AXI_RDATA(rdata),
        .S_AXI_RRESP(rresp),
        .S_AXI_RVALID(rvalid),
        .S_AXI_RREADY(rready)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n) begin
            saw_clear_errors <= 1'b0;
        end else if (clear_errors_pulse) begin
            saw_clear_errors <= 1'b1;
        end
    end

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
            while (!(awready && wready)) begin
                @(posedge clk);
            end
            @(negedge clk);
            awvalid = 1'b0;
            wvalid = 1'b0;
            while (!bvalid) begin
                @(posedge clk);
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
            while (!arready) begin
                @(posedge clk);
            end
            @(negedge clk);
            arvalid = 1'b0;
            while (!rvalid) begin
                @(posedge clk);
            end
            value = rdata;
            @(negedge clk);
            rready = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        core_busy = 1'b0;
        core_done = 1'b0;
        core_class_valid = 1'b0;
        core_class_idx = 3'd0;
        frame_ready = 1'b0;
        rx_active = 1'b0;
        act_wr_ready = 1'b1;
        beat_count = 16'd12;
        frame_count = 16'd3;
        error_early_tlast = 1'b0;
        error_missing_tlast = 1'b0;
        error_bad_keep = 1'b0;
        error_dropped_frame = 1'b0;
        start_accept = 1'b0;
        start_reject_no_frame = 1'b0;
        start_reject_busy = 1'b0;
        inference_cycles = 32'd12345;
        awaddr = 0;
        awvalid = 0;
        wdata = 0;
        wstrb = 4'hf;
        wvalid = 0;
        bready = 0;
        araddr = 0;
        arvalid = 0;
        rready = 0;
        saw_clear_errors = 1'b0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        axi_read(5'h0c, read_value);
        if (read_value != {16'd1740, 16'd435}) begin
            $display("FAIL FRAME_INFO %h", read_value);
            $fatal;
        end

        axi_write(5'h00, 32'h0000_0012);
        if (!auto_start || !irq_enable) begin
            $display("FAIL persistent control bits");
            $fatal;
        end

        fork
            begin
                axi_write(5'h00, 32'h0000_0013);
            end
            begin
                wait (start_pulse);
                @(posedge clk);
            end
        join

        @(negedge clk);
        start_reject_no_frame = 1'b1;
        @(posedge clk);
        @(negedge clk);
        start_reject_no_frame = 1'b0;
        axi_read(5'h14, read_value);
        if (!read_value[4]) begin
            $display("FAIL rejected start sticky");
            $fatal;
        end

        axi_write(5'h00, 32'h0000_001a);
        axi_read(5'h14, read_value);
        if (read_value[5:0] != 6'd0 || !saw_clear_errors) begin
            $display("FAIL clear errors %h", read_value);
            $fatal;
        end

        @(negedge clk);
        core_class_idx = 3'd4;
        core_class_valid = 1'b1;
        core_done = 1'b1;
        @(posedge clk);
        @(negedge clk);
        core_class_valid = 1'b0;
        core_done = 1'b0;

        axi_read(5'h08, read_value);
        if (read_value[2:0] != 3'd4) begin
            $display("FAIL class result");
            $fatal;
        end
        axi_read(5'h04, read_value);
        if (!read_value[1] || !read_value[6] || !irq) begin
            $display("FAIL done/irq status %h", read_value);
            $fatal;
        end
        axi_read(5'h18, read_value);
        if (read_value != 32'd12345) begin
            $display("FAIL cycle count");
            $fatal;
        end

        axi_write(5'h00, 32'h0000_0016);
        axi_read(5'h04, read_value);
        if (read_value[1] || irq) begin
            $display("FAIL clear done");
            $fatal;
        end

        $display("PASS tb_emg_accelerator_s00_axi");
        $finish;
    end

endmodule
