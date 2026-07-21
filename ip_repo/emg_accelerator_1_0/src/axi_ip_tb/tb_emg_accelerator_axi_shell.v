`timescale 1ns / 1ps

`ifdef EMG_AXI_SHELL_STUB_ACCELERATOR
module accelerator (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    output reg busy,
    output reg done,
    input  wire act_wr_en,
    input  wire [8:0] act_wr_addr,
    input  wire [31:0] act_wr_data,
    output wire act_wr_ready,
    output reg class_valid,
    output reg [2:0] class_idx
);

    reg [3:0] cycles_left;
    assign act_wr_ready = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            class_valid <= 1'b0;
            class_idx <= 3'd0;
            cycles_left <= 4'd0;
        end else begin
            done <= 1'b0;
            class_valid <= 1'b0;
            if (start && !busy) begin
                busy <= 1'b1;
                cycles_left <= 4'd8;
            end else if (busy && cycles_left == 1) begin
                busy <= 1'b0;
                done <= 1'b1;
                class_valid <= 1'b1;
                class_idx <= 3'd3;
                cycles_left <= 4'd0;
            end else if (busy) begin
                cycles_left <= cycles_left - 1'b1;
            end
        end
    end

endmodule
`endif

module tb_emg_accelerator_axi_shell;

    reg clk;
    reg rst_n;
    wire irq;
    wire class_valid;
    wire [2:0] class_id;
    wire inference_done;
    wire inference_busy;

    reg [5:0] awaddr;
    reg awvalid;
    wire awready;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    reg wvalid;
    wire wready;
    wire [1:0] bresp;
    wire bvalid;
    reg bready;
    reg [5:0] araddr;
    reg arvalid;
    wire arready;
    wire [31:0] rdata;
    wire [1:0] rresp;
    wire rvalid;
    reg rready;

    wire tready;
    reg [31:0] tdata;
    reg [3:0] tkeep;
    reg tlast;
    reg tvalid;

    reg [31:0] read_value;
    integer index;
    reg saw_class_valid;
    reg saw_inference_done;
    reg [2:0] observed_class_id;

    emg_accelerator_v1_0 dut (
        .irq(irq),
        .class_valid(class_valid),
        .class_id(class_id),
        .inference_done(inference_done),
        .inference_busy(inference_busy),
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
        .s00_axis_tready(tready),
        .s00_axis_tdata(tdata),
        .s00_axis_tkeep(tkeep),
        .s00_axis_tlast(tlast),
        .s00_axis_tvalid(tvalid)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n) begin
            saw_class_valid <= 1'b0;
            saw_inference_done <= 1'b0;
            observed_class_id <= 3'd0;
        end else begin
            if (class_valid) begin
                saw_class_valid <= 1'b1;
                observed_class_id <= class_id;
            end
            if (inference_done) begin
                saw_inference_done <= 1'b1;
            end
        end
    end

    task axis_send;
        input [31:0] value;
        input last;
        begin
            @(negedge clk);
            tdata = value;
            tlast = last;
            tvalid = 1'b1;
            @(posedge clk);
            while (tready !== 1'b1) begin
                @(posedge clk);
            end
            @(negedge clk);
            tvalid = 1'b0;
            tlast = 1'b0;
        end
    endtask

    task axi_write;
        input [5:0] address;
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
        input [5:0] address;
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
        awaddr = 0;
        awvalid = 0;
        wdata = 0;
        wstrb = 4'hf;
        wvalid = 0;
        bready = 0;
        araddr = 0;
        arvalid = 0;
        rready = 0;
        tdata = 0;
        tkeep = 4'hf;
        tlast = 0;
        tvalid = 0;
        saw_class_valid = 1'b0;
        saw_inference_done = 1'b0;
        observed_class_id = 3'd0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        for (index = 0; index < 435; index = index + 1) begin
            axis_send(index, index == 434);
        end

        axi_read(6'h04, read_value);
        if (!read_value[2] || read_value[0]) begin
            $display(
                "FAIL frame ready status=%h beats=%0d frames=%0d errors=%b%b%b%b",
                read_value,
                dut.beat_count,
                dut.frame_count,
                dut.error_dropped_frame,
                dut.error_bad_keep,
                dut.error_missing_tlast,
                dut.error_early_tlast
            );
            $fatal;
        end

        axi_write(6'h20, 32'h0000_0002);
        axi_write(6'h00, 32'h0000_0001);
        repeat (2) @(posedge clk);
        axi_read(6'h04, read_value);
        if (!read_value[0] || read_value[2]) begin
            $display("FAIL start/consume status %h", read_value);
            $fatal;
        end

        wait (irq);
        axi_read(6'h08, read_value);
        if (read_value[2:0] != 3'd3) begin
            $display("FAIL result %h", read_value);
            $fatal;
        end
        if (!saw_class_valid || !saw_inference_done || observed_class_id != 3'd3) begin
            $display(
                "FAIL functional outputs class_valid=%b done=%b class_id=%0d",
                saw_class_valid,
                saw_inference_done,
                observed_class_id
            );
            $fatal;
        end
        axi_read(6'h04, read_value);
        if (!read_value[1] || !read_value[6] || read_value[0]) begin
            $display("FAIL completion status %h", read_value);
            $fatal;
        end

        $display("PASS tb_emg_accelerator_axi_shell");
        $finish;
    end

endmodule
