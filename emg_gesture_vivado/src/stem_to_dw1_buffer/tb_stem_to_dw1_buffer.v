`timescale 1ns / 1ps

`ifndef STEM_TO_DW1_TB_MODULE
`define STEM_TO_DW1_TB_MODULE tb_stem_to_dw1_buffer
`endif

`ifdef USE_STEM_TO_DW1_WITH_RAM
`define STEM_TO_DW1_CTRL dut.u_ctrl
`else
`define STEM_TO_DW1_CTRL dut
`endif

module `STEM_TO_DW1_TB_MODULE;

    parameter integer BRAM_READ_LATENCY = 1;
`ifdef USE_STEM_TO_DW1_WITH_RAM
    parameter integer RUN_FULL_SCAN = 0;
`else
    parameter integer RUN_FULL_SCAN = 1;
`endif

    localparam integer DATA_W     =  8;
    localparam integer MULT_W     = 16;
    localparam integer TIME_W     = 9;
    localparam integer INPUT_LEN  = 348;
    localparam integer STEM_OC    = 32;
    localparam integer ROWS       = 4;
    localparam integer OC_LANES   = 4;
    localparam integer DW_K       = 5;
    localparam integer DW_PAD     = 2;
    localparam integer RING_ROWS  = 8;
    localparam integer BANKS      = STEM_OC / OC_LANES;
    localparam integer WORD_W     = OC_LANES * DATA_W;
    localparam integer TILE_W     = ROWS * WORD_W;
    localparam integer WIN_W      = DW_K * WORD_W;
    localparam integer OC_BASE_W  = (STEM_OC <= 1) ? 1 : $clog2(STEM_OC + 1);
    localparam integer ADDR_W     = (BANKS * RING_ROWS <= 1)
        ? 1 : $clog2(BANKS * RING_ROWS);
    localparam integer TIMEOUT    = 4000;

    reg clk;
    reg rst_n;
    reg clear;

    reg stem_out_valid;
    wire stem_out_ready;
    reg [TIME_W-1:0] stem_out_tile_t_base;
    reg [OC_BASE_W-1:0] stem_out_tile_oc_base;
    reg signed [TILE_W-1:0] stem_out_tile;

    reg dw1_win_req_valid;
    wire dw1_win_req_ready;
    reg [TIME_W-1:0] dw1_win_req_out_t;
    reg [OC_BASE_W-1:0] dw1_win_req_ch_base;

    wire dw1_win_vec_valid;
    reg dw1_win_vec_ready;
    wire signed [WIN_W-1:0] dw1_win_vec;
`ifndef USE_STEM_TO_DW1_WITH_RAM
    wire bram_wr_en;
    wire [ADDR_W-1:0] bram_wr_addr;
    wire [WORD_W-1:0] bram_wr_data;
    wire bram_rd_en;
    wire [ADDR_W-1:0] bram_rd_addr;
    wire [WORD_W-1:0] bram_rd_dout;
`endif
    wire wr_busy;
    wire rd_busy;
    wire stem_watermark_stall;

    integer errors;
    integer timeout_count;
    integer tap_i;
    integer lane_i;
    integer scan_t;
    integer scan_ch;
    integer scan_out_t;
    integer scan_start_t;
    integer scan_last_t;

`ifdef USE_STEM_TO_DW1_WITH_RAM
    stem_to_dw1_buffer_with_ram #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .STEM_OC(STEM_OC),
        .ROWS(ROWS),
        .OC_LANES(OC_LANES),
        .DW_K(DW_K),
        .DW_PAD(DW_PAD),
        .RING_ROWS(RING_ROWS),
        .BANKS(BANKS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .OC_BASE_W(OC_BASE_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .stem_out_valid(stem_out_valid),
        .stem_out_ready(stem_out_ready),
        .stem_out_tile_t_base(stem_out_tile_t_base),
        .stem_out_tile_oc_base(stem_out_tile_oc_base),
        .stem_out_tile(stem_out_tile),
        .dw1_win_req_valid(dw1_win_req_valid),
        .dw1_win_req_ready(dw1_win_req_ready),
        .dw1_win_req_out_t(dw1_win_req_out_t),
        .dw1_win_req_ch_base(dw1_win_req_ch_base),
        .dw1_win_vec_valid(dw1_win_vec_valid),
        .dw1_win_vec_ready(dw1_win_vec_ready),
        .dw1_win_vec(dw1_win_vec),
        .wr_busy(wr_busy),
        .rd_busy(rd_busy),
        .stem_watermark_stall(stem_watermark_stall)
    );
`else
    stem_to_dw1_buffer #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .STEM_OC(STEM_OC),
        .ROWS(ROWS),
        .OC_LANES(OC_LANES),
        .DW_K(DW_K),
        .DW_PAD(DW_PAD),
        .RING_ROWS(RING_ROWS),
        .BANKS(BANKS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .OC_BASE_W(OC_BASE_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .stem_out_valid(stem_out_valid),
        .stem_out_ready(stem_out_ready),
        .stem_out_tile_t_base(stem_out_tile_t_base),
        .stem_out_tile_oc_base(stem_out_tile_oc_base),
        .stem_out_tile(stem_out_tile),
        .dw1_win_req_valid(dw1_win_req_valid),
        .dw1_win_req_ready(dw1_win_req_ready),
        .dw1_win_req_out_t(dw1_win_req_out_t),
        .dw1_win_req_ch_base(dw1_win_req_ch_base),
        .dw1_win_vec_valid(dw1_win_vec_valid),
        .dw1_win_vec_ready(dw1_win_vec_ready),
        .dw1_win_vec(dw1_win_vec),
        .bram_wr_en(bram_wr_en),
        .bram_wr_addr(bram_wr_addr),
        .bram_wr_data(bram_wr_data),
        .bram_rd_en(bram_rd_en),
        .bram_rd_addr(bram_rd_addr),
        .bram_rd_dout(bram_rd_dout),
        .wr_busy(wr_busy),
        .rd_busy(rd_busy),
        .stem_watermark_stall(stem_watermark_stall)
    );

    stem_to_dw1_mock_ram #(
        .WORD_W(WORD_W),
        .ADDR_W(ADDR_W),
        .DEPTH(BANKS * RING_ROWS),
        .READ_LATENCY(BRAM_READ_LATENCY)
    ) u_mock_ram (
        .clk(clk),
        .wr_en(bram_wr_en),
        .wr_addr(bram_wr_addr),
        .wr_data(bram_wr_data),
        .rd_en(bram_rd_en),
        .rd_addr(bram_rd_addr),
        .rd_data(bram_rd_dout)
    );
`endif

    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;

    function signed [DATA_W-1:0] sample_value;
        input integer ch_i;
        input integer t_i;
        integer value_i;
        begin
            value_i = ch_i * 1000 + t_i;
            sample_value = value_i[DATA_W-1:0];
        end
    endfunction

    function [TILE_W-1:0] make_tile;
        input integer t_base_i;
        input integer ch_base_i;
        integer row_i;
        integer lane_i_f;
        begin
            make_tile = {TILE_W{1'b0}};
            for (row_i = 0; row_i < ROWS; row_i = row_i + 1) begin
                for (lane_i_f = 0; lane_i_f < OC_LANES; lane_i_f = lane_i_f + 1) begin
                    make_tile[(row_i*OC_LANES + lane_i_f)*DATA_W +: DATA_W]
                        = sample_value(ch_base_i + lane_i_f, t_base_i + row_i);
                end
            end
        end
    endfunction

    function [WIN_W-1:0] expected_window;
        input integer out_t_i;
        input integer ch_base_i;
        integer tap_f;
        integer lane_f;
        integer sample_t_i;
        begin
            expected_window = {WIN_W{1'b0}};
            for (tap_f = 0; tap_f < DW_K; tap_f = tap_f + 1) begin
                sample_t_i = out_t_i + tap_f - DW_PAD;
                if ((sample_t_i >= 0) && (sample_t_i < INPUT_LEN)) begin
                    for (lane_f = 0; lane_f < OC_LANES; lane_f = lane_f + 1) begin
                        expected_window[(tap_f*OC_LANES + lane_f)*DATA_W +: DATA_W]
                            = sample_value(ch_base_i + lane_f, sample_t_i);
                    end
                end
            end
        end
    endfunction

    task reset_dut;
        begin
            rst_n = 1'b1;
            clear = 1'b0;
            stem_out_valid = 1'b0;
            stem_out_tile_t_base = {TIME_W{1'b0}};
            stem_out_tile_oc_base = 5'd0;
            stem_out_tile = {TILE_W{1'b0}};
            dw1_win_req_valid = 1'b0;
            dw1_win_req_out_t = {TIME_W{1'b0}};
            dw1_win_req_ch_base = 5'd0;
            dw1_win_vec_ready = 1'b1;
            @(negedge clk);
            rst_n = 1'b0;
            repeat (5) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

    task pulse_clear;
        begin
            @(negedge clk);
            clear = 1'b1;
            @(negedge clk);
            clear = 1'b0;
            @(negedge clk);
        end
    endtask

    task write_tile;
        input integer t_base_i;
        input integer ch_base_i;
        begin
            @(negedge clk);
            stem_out_tile_t_base = t_base_i[TIME_W-1:0];
            stem_out_tile_oc_base = ch_base_i[OC_BASE_W-1:0];
            stem_out_tile = make_tile(t_base_i, ch_base_i);
            stem_out_valid = 1'b1;
            #1;
            timeout_count = 0;
            while (stem_out_ready !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display(
                        "ERROR write_tile timeout t_base=%0d ch_base=%0d",
                        t_base_i,
                        ch_base_i
                    );
                    errors = errors + 1;
                    disable write_tile;
                end
            end
            @(posedge clk);
            @(negedge clk);
            stem_out_valid = 1'b0;
        end
    endtask

    task expect_stem_blocked;
        input integer t_base_i;
        input integer ch_base_i;
        integer stall_before;
        begin
            stall_before = `STEM_TO_DW1_CTRL.stem_watermark_stall_count;
            @(negedge clk);
            stem_out_tile_t_base = t_base_i[TIME_W-1:0];
            stem_out_tile_oc_base = ch_base_i[OC_BASE_W-1:0];
            stem_out_tile = make_tile(t_base_i, ch_base_i);
            stem_out_valid = 1'b1;
            #1;
            if (stem_out_ready !== 1'b0) begin
                $display(
                    "ERROR stem_out_ready should block overwrite t_base=%0d ch_base=%0d",
                    t_base_i,
                    ch_base_i
                );
                errors = errors + 1;
            end
            if (stem_watermark_stall !== 1'b1) begin
                $display("ERROR stem_watermark_stall should assert");
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`STEM_TO_DW1_CTRL.stem_watermark_stall_count !== (stall_before + 1)) begin
                $display(
                    "ERROR stem_watermark_stall_count got=%0d expected=%0d",
                    `STEM_TO_DW1_CTRL.stem_watermark_stall_count,
                    stall_before + 1
                );
                errors = errors + 1;
            end
            @(negedge clk);
            stem_out_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task expect_request_blocked;
        input integer out_t_i;
        input integer ch_base_i;
        integer unavailable_before;
        begin
            unavailable_before = `STEM_TO_DW1_CTRL.unavailable_dw_req_count;
            @(negedge clk);
            dw1_win_req_out_t = out_t_i[TIME_W-1:0];
            dw1_win_req_ch_base = ch_base_i[OC_BASE_W-1:0];
            dw1_win_req_valid = 1'b1;
            #1;
            if (dw1_win_req_ready !== 1'b0) begin
                $display(
                    "ERROR dw1_win_req_ready should block unavailable window out_t=%0d ch_base=%0d",
                    out_t_i,
                    ch_base_i
                );
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`STEM_TO_DW1_CTRL.unavailable_dw_req_count !== (unavailable_before + 1)) begin
                $display(
                    "ERROR unavailable_dw_req_count got=%0d expected=%0d",
                    `STEM_TO_DW1_CTRL.unavailable_dw_req_count,
                    unavailable_before + 1
                );
                errors = errors + 1;
            end
            @(negedge clk);
            dw1_win_req_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task expect_invalid_stem;
        input integer t_base_i;
        input integer ch_base_i;
        integer invalid_before;
        begin
            invalid_before = `STEM_TO_DW1_CTRL.invalid_stem_req_count;
            @(negedge clk);
            stem_out_tile_t_base = t_base_i[TIME_W-1:0];
            stem_out_tile_oc_base = ch_base_i[OC_BASE_W-1:0];
            stem_out_tile = make_tile(t_base_i, ch_base_i);
            stem_out_valid = 1'b1;
            #1;
            if (stem_out_ready !== 1'b0) begin
                $display(
                    "ERROR invalid stem tile accepted t_base=%0d ch_base=%0d",
                    t_base_i,
                    ch_base_i
                );
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`STEM_TO_DW1_CTRL.invalid_stem_req_count !== (invalid_before + 1)) begin
                $display(
                    "ERROR invalid_stem_req_count got=%0d expected=%0d",
                    `STEM_TO_DW1_CTRL.invalid_stem_req_count,
                    invalid_before + 1
                );
                errors = errors + 1;
            end
            @(negedge clk);
            stem_out_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task expect_invalid_request;
        input integer out_t_i;
        input integer ch_base_i;
        integer invalid_before;
        begin
            invalid_before = `STEM_TO_DW1_CTRL.invalid_dw_req_count;
            @(negedge clk);
            dw1_win_req_out_t = out_t_i[TIME_W-1:0];
            dw1_win_req_ch_base = ch_base_i[OC_BASE_W-1:0];
            dw1_win_req_valid = 1'b1;
            #1;
            if (dw1_win_req_ready !== 1'b0) begin
                $display(
                    "ERROR invalid DW request accepted out_t=%0d ch_base=%0d",
                    out_t_i,
                    ch_base_i
                );
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`STEM_TO_DW1_CTRL.invalid_dw_req_count !== (invalid_before + 1)) begin
                $display(
                    "ERROR invalid_dw_req_count got=%0d expected=%0d",
                    `STEM_TO_DW1_CTRL.invalid_dw_req_count,
                    invalid_before + 1
                );
                errors = errors + 1;
            end
            @(negedge clk);
            dw1_win_req_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task compare_window;
        input integer out_t_i;
        input integer ch_base_i;
        input [WIN_W-1:0] got_i;
        input [WIN_W-1:0] exp_i;
        reg signed [DATA_W-1:0] got_sample;
        reg signed [DATA_W-1:0] exp_sample;
        begin
            for (tap_i = 0; tap_i < DW_K; tap_i = tap_i + 1) begin
                for (lane_i = 0; lane_i < OC_LANES; lane_i = lane_i + 1) begin
                    got_sample = got_i[(tap_i*OC_LANES + lane_i)*DATA_W +: DATA_W];
                    exp_sample = exp_i[(tap_i*OC_LANES + lane_i)*DATA_W +: DATA_W];
                    if (got_sample !== exp_sample) begin
                        $display(
                            "ERROR window mismatch out_t=%0d ch_base=%0d tap=%0d lane=%0d got=%0d expected=%0d",
                            out_t_i,
                            ch_base_i,
                            tap_i,
                            lane_i,
                            got_sample,
                            exp_sample
                        );
                        errors = errors + 1;
                    end
                end
            end
        end
    endtask

    task request_window_expect;
        input integer out_t_i;
        input integer ch_base_i;
        input integer stall_cycles_i;
        reg [WIN_W-1:0] exp_vec;
        integer stall_i;
        begin
            exp_vec = expected_window(out_t_i, ch_base_i);

            @(negedge clk);
            dw1_win_req_out_t = out_t_i[TIME_W-1:0];
            dw1_win_req_ch_base = ch_base_i[OC_BASE_W-1:0];
            dw1_win_req_valid = 1'b1;
            #1;
            timeout_count = 0;
            while (dw1_win_req_ready !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display(
                        "ERROR request timeout out_t=%0d ch_base=%0d",
                        out_t_i,
                        ch_base_i
                    );
                    errors = errors + 1;
                    disable request_window_expect;
                end
            end
            @(posedge clk);
            @(negedge clk);
            dw1_win_req_valid = 1'b0;

            timeout_count = 0;
            while (dw1_win_vec_valid !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display(
                        "ERROR response timeout out_t=%0d ch_base=%0d",
                        out_t_i,
                        ch_base_i
                    );
                    errors = errors + 1;
                    disable request_window_expect;
                end
            end

            if (stall_cycles_i > 0) begin
                dw1_win_vec_ready = 1'b0;
                for (stall_i = 0; stall_i < stall_cycles_i; stall_i = stall_i + 1) begin
                    #1;
                    if (dw1_win_vec_valid !== 1'b1) begin
                        $display("ERROR response valid dropped during backpressure");
                        errors = errors + 1;
                    end
                    compare_window(out_t_i, ch_base_i, dw1_win_vec, exp_vec);
                    @(negedge clk);
                end
                dw1_win_vec_ready = 1'b1;
            end

            #1;
            compare_window(out_t_i, ch_base_i, dw1_win_vec, exp_vec);
            @(posedge clk);
            @(negedge clk);
        end
    endtask

    task clear_during_write_case;
        begin
            reset_dut();
            @(negedge clk);
            stem_out_tile_t_base = {TIME_W{1'b0}};
            stem_out_tile_oc_base = {OC_BASE_W{1'b0}};
            stem_out_tile = make_tile(0, 0);
            stem_out_valid = 1'b1;
            #1;
            if (stem_out_ready !== 1'b1) begin
                $display("ERROR clear_during_write_case initial ready low");
                errors = errors + 1;
            end
            @(posedge clk);
            @(negedge clk);
            stem_out_valid = 1'b0;
            clear = 1'b1;
            @(negedge clk);
            clear = 1'b0;
            @(negedge clk);
            if (wr_busy || rd_busy || dw1_win_vec_valid) begin
                $display("ERROR clear_during_write_case did not return idle");
                errors = errors + 1;
            end
            expect_request_blocked(0, 0);
        end
    endtask

    task clear_during_read_case;
        begin
            reset_dut();
            write_tile(0, 0);
            @(negedge clk);
            dw1_win_req_out_t = {TIME_W{1'b0}};
            dw1_win_req_ch_base = {OC_BASE_W{1'b0}};
            dw1_win_req_valid = 1'b1;
            #1;
            timeout_count = 0;
            while (dw1_win_req_ready !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display("ERROR clear_during_read_case request timeout");
                    errors = errors + 1;
                    disable clear_during_read_case;
                end
            end
            @(posedge clk);
            @(negedge clk);
            dw1_win_req_valid = 1'b0;
            clear = 1'b1;
            @(negedge clk);
            clear = 1'b0;
            @(negedge clk);
            if (wr_busy || rd_busy || dw1_win_vec_valid) begin
                $display("ERROR clear_during_read_case did not return idle");
                errors = errors + 1;
            end
            expect_request_blocked(0, 0);
        end
    endtask

    task skipped_out_t_negative_case;
        begin
            reset_dut();
            write_tile(0, 0);
            request_window_expect(0, 0, 0);
            request_window_expect(1, 0, 0);
            write_tile(4, 0);
            request_window_expect(3, 0, 0);
            request_window_expect(4, 0, 0);
            request_window_expect(5, 0, 0);
            write_tile(8, 0);
            request_window_expect(6, 0, 0);
            request_window_expect(7, 0, 0);
            request_window_expect(8, 0, 0);
            request_window_expect(9, 0, 0);
            write_tile(12, 0);
            request_window_expect(10, 0, 0);
            request_window_expect(11, 0, 0);
            request_window_expect(12, 0, 0);
            request_window_expect(13, 0, 0);
            write_tile(16, 0);
            expect_request_blocked(2, 0);
        end
    endtask

    task full_stream_scan;
        begin
            reset_dut();
            for (scan_t = 0; scan_t <= (INPUT_LEN - ROWS); scan_t = scan_t + ROWS) begin
                for (scan_ch = 0; scan_ch < STEM_OC; scan_ch = scan_ch + OC_LANES) begin
                    write_tile(scan_t, scan_ch);
                end

                if (scan_t < DW_PAD) begin
                    scan_start_t = 0;
                end else begin
                    scan_start_t = scan_t - DW_PAD;
                end

                if (scan_t == (INPUT_LEN - ROWS)) begin
                    scan_last_t = INPUT_LEN - 1;
                end else begin
                    scan_last_t = scan_t + ROWS - 1 - DW_PAD;
                end

                if (scan_last_t >= scan_start_t) begin
                    for (scan_out_t = scan_start_t;
                         scan_out_t <= scan_last_t;
                         scan_out_t = scan_out_t + 1) begin
                        for (scan_ch = 0; scan_ch < STEM_OC; scan_ch = scan_ch + OC_LANES) begin
                            request_window_expect(scan_out_t, scan_ch, 0);
                        end
                    end
                end
            end
            $display("INFO stem_to_dw1 full_stream_scan complete");
        end
    endtask

    initial begin
        errors = 0;
        reset_dut();

        expect_invalid_stem(0, 1);
        expect_invalid_stem(0, STEM_OC);
        expect_invalid_stem(INPUT_LEN, 0);
        expect_invalid_request(0, 1);
        expect_invalid_request(INPUT_LEN, 0);
        expect_request_blocked(0, 0);

        write_tile(0, 0);
        request_window_expect(0, 0, 0);

        write_tile(4, 0);
        request_window_expect(2, 0, 0);
        expect_stem_blocked(16, 0);

        request_window_expect(3, 0, 0);
        request_window_expect(4, 0, 0);
        request_window_expect(5, 0, 3);

        write_tile(8, 0);
        request_window_expect(6, 0, 0);
        request_window_expect(7, 0, 0);
        request_window_expect(8, 0, 0);
        request_window_expect(9, 0, 0);
        write_tile(12, 0);
        request_window_expect(10, 0, 0);
        request_window_expect(11, 0, 0);
        request_window_expect(12, 0, 0);
        request_window_expect(13, 0, 0);
        write_tile(16, 0);
        request_window_expect(16, 0, 0);
        expect_request_blocked(0, 0);

        write_tile(0, 4);
        request_window_expect(0, 4, 0);

        pulse_clear();
        expect_request_blocked(16, 0);

        write_tile(0, 0);
        request_window_expect(1, 0, 0);

        clear_during_write_case();
        clear_during_read_case();
        skipped_out_t_negative_case();
        if (RUN_FULL_SCAN) begin
            full_stream_scan();
        end

        if (errors == 0) begin
            $display(
                "PASS %m latency=%0d",
                BRAM_READ_LATENCY
            );
        end else begin
            $display("FAIL tb_stem_to_dw1_buffer errors=%0d", errors);
        end
        $finish;
    end

endmodule

module stem_to_dw1_mock_ram #(
    parameter integer WORD_W = 64,
    parameter integer ADDR_W = 7,
    parameter integer DEPTH = 128,
    parameter integer READ_LATENCY = 1,
    parameter integer PIPE_DEPTH = (READ_LATENCY <= 1) ? 1 : READ_LATENCY
) (
    input  wire clk,
    input  wire wr_en,
    input  wire [ADDR_W-1:0] wr_addr,
    input  wire [WORD_W-1:0] wr_data,
    input  wire rd_en,
    input  wire [ADDR_W-1:0] rd_addr,
    output reg [WORD_W-1:0] rd_data
);

    reg [WORD_W-1:0] mem [0:DEPTH-1];
    reg [WORD_W-1:0] rd_pipe [0:PIPE_DEPTH-1];

    integer i;

    initial begin
        rd_data = {WORD_W{1'b0}};
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = {WORD_W{1'b0}};
        end
        for (i = 0; i < PIPE_DEPTH; i = i + 1) begin
            rd_pipe[i] = {WORD_W{1'b0}};
        end
    end

    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end

        if (rd_en) begin
            rd_pipe[0] <= mem[rd_addr];
            for (i = 1; i < PIPE_DEPTH; i = i + 1) begin
                rd_pipe[i] <= rd_pipe[i-1];
            end
            rd_data <= rd_pipe[PIPE_DEPTH-1];
        end
    end

endmodule
