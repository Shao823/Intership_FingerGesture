`timescale 1ns / 1ps

module tb_emg_dma_pingpong_controller;

    localparam integer DATA_WIDTH = 32;
    localparam integer FRAME_WORDS = 435;
    localparam integer ADDR_WIDTH = 9;

    reg clk;
    reg rst_n;
    reg [DATA_WIDTH-1:0] s_axis_tdata;
    reg [(DATA_WIDTH/8)-1:0] s_axis_tkeep;
    reg s_axis_tlast;
    reg s_axis_tvalid;
    wire s_axis_tready;
    wire act_wr_en;
    wire [ADDR_WIDTH-1:0] act_wr_addr;
    wire [DATA_WIDTH-1:0] act_wr_data;
    reg act_wr_ready;
    reg frame_consume;
    reg clear_errors;
    wire frame_ready;
    wire rx_active;
    wire [15:0] beat_count;
    wire [15:0] frame_count;
    wire error_early_tlast;
    wire error_missing_tlast;
    wire error_bad_keep;
    wire error_dropped_frame;

    integer write_count;
    integer expected_addr;

    emg_dma_pingpong_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAME_WORDS(FRAME_WORDS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
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

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (act_wr_en) begin
            if (act_wr_addr !== expected_addr[ADDR_WIDTH-1:0]) begin
                $display("FAIL address expected=%0d actual=%0d", expected_addr, act_wr_addr);
                $fatal;
            end
            write_count = write_count + 1;
            expected_addr = expected_addr + 1;
        end
    end

    task reset_dut;
        begin
            rst_n = 1'b0;
            s_axis_tdata = 0;
            s_axis_tkeep = 4'hf;
            s_axis_tlast = 1'b0;
            s_axis_tvalid = 1'b0;
            act_wr_ready = 1'b1;
            frame_consume = 1'b0;
            clear_errors = 1'b0;
            write_count = 0;
            expected_addr = 0;
            repeat (4) @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);
        end
    endtask

    task send_word;
        input [31:0] data;
        input last;
        input [3:0] keep;
        begin
            @(negedge clk);
            s_axis_tdata = data;
            s_axis_tlast = last;
            s_axis_tkeep = keep;
            s_axis_tvalid = 1'b1;
            @(posedge clk);
            while (!s_axis_tready) begin
                @(posedge clk);
            end
            @(negedge clk);
            s_axis_tvalid = 1'b0;
            s_axis_tlast = 1'b0;
            s_axis_tkeep = 4'hf;
        end
    endtask

    task consume_frame;
        begin
            @(negedge clk);
            frame_consume = 1'b1;
            @(posedge clk);
            @(negedge clk);
            frame_consume = 1'b0;
            @(posedge clk);
            expected_addr = 0;
            write_count = 0;
        end
    endtask

    integer index;
    initial begin
        clk = 1'b0;
        reset_dut();

        @(negedge clk);
        act_wr_ready = 1'b0;
        s_axis_tvalid = 1'b1;
        s_axis_tdata = 32'h12345678;
        repeat (3) @(posedge clk);
        if (s_axis_tready || act_wr_en) begin
            $display("FAIL backpressure");
            $fatal;
        end
        @(negedge clk);
        act_wr_ready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        s_axis_tvalid = 1'b0;
        if (write_count != 1) begin
            $display("FAIL backpressure release");
            $fatal;
        end

        for (index = 1; index < FRAME_WORDS; index = index + 1) begin
            send_word(index, index == FRAME_WORDS-1, 4'hf);
        end
        if (!frame_ready || frame_count != 1 || beat_count != FRAME_WORDS) begin
            $display("FAIL complete frame ready=%0d frames=%0d beats=%0d", frame_ready, frame_count, beat_count);
            $fatal;
        end
        if (s_axis_tready) begin
            $display("FAIL accepted data while frame pending");
            $fatal;
        end

        consume_frame();
        send_word(32'h1, 1'b0, 4'hf);
        send_word(32'h2, 1'b1, 4'hf);
        if (!error_early_tlast || !error_dropped_frame || frame_ready) begin
            $display("FAIL early TLAST handling");
            $fatal;
        end

        @(negedge clk);
        clear_errors = 1'b1;
        @(posedge clk);
        @(negedge clk);
        clear_errors = 1'b0;
        @(posedge clk);
        if (error_early_tlast || error_dropped_frame) begin
            $display("FAIL error clear");
            $fatal;
        end
        expected_addr = 0;
        write_count = 0;

        send_word(32'h3, 1'b1, 4'h3);
        if (!error_bad_keep || !error_dropped_frame) begin
            $display("FAIL bad TKEEP handling");
            $fatal;
        end

        @(negedge clk);
        clear_errors = 1'b1;
        @(posedge clk);
        @(negedge clk);
        clear_errors = 1'b0;
        @(posedge clk);

        expected_addr = 0;
        write_count = 0;
        for (index = 0; index < FRAME_WORDS; index = index + 1) begin
            send_word(index, 1'b0, 4'hf);
        end
        send_word(32'hdeadbeef, 1'b1, 4'hf);
        if (!error_missing_tlast || !error_dropped_frame || frame_ready) begin
            $display("FAIL missing TLAST handling");
            $fatal;
        end

        $display("PASS tb_emg_dma_pingpong_controller");
        $finish;
    end

endmodule
