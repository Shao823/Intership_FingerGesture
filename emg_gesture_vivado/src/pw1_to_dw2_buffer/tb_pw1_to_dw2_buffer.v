`timescale 1ns / 1ps

`ifndef PW1_TO_DW2_TB_MODULE
`define PW1_TO_DW2_TB_MODULE tb_pw1_to_dw2_buffer
`endif

`ifdef USE_PW1_TO_DW2_WITH_RAM
`define PW1_TO_DW2_CTRL dut.u_ctrl
`else
`define PW1_TO_DW2_CTRL dut
`endif

module `PW1_TO_DW2_TB_MODULE;

    parameter integer BRAM_READ_LATENCY = 1;
`ifdef USE_PW1_TO_DW2_WITH_RAM
    parameter integer RUN_FULL_SCAN = 0;
    parameter integer RUN_SUBSET_SCAN = 1;
`else
    parameter integer RUN_FULL_SCAN = 1;
    parameter integer RUN_SUBSET_SCAN = 0;
`endif

    localparam integer DATA_W     =  8;
    localparam integer MULT_W     = 16;
    localparam integer TIME_W     = 8;
    localparam integer INPUT_LEN  = 174;
    localparam integer PW1_OC     = 64;
    localparam integer POOL_ROWS  = 2;
    localparam integer PW1_OC_LANES = 8;
    localparam integer CH_LANES   = 4;
    localparam integer DW_K       = 5;
    localparam integer DW_PAD     = 2;
    localparam integer RING_ROWS  = 8;
    localparam integer BANKS      = PW1_OC / CH_LANES;
    localparam integer WORD_W     = CH_LANES * DATA_W;
    localparam integer TILE_W     = POOL_ROWS * PW1_OC_LANES * DATA_W;
    localparam integer WIN_W      = DW_K * WORD_W;
    localparam integer OC_BASE_W  = (PW1_OC <= 1) ? 1 : $clog2(PW1_OC);
    localparam integer ADDR_W     = (BANKS * RING_ROWS <= 1)
        ? 1 : $clog2(BANKS * RING_ROWS);
    localparam integer TIMEOUT    = 5000;

    reg clk;
    reg rst_n;
    reg clear;

    reg pw1_out_valid;
    wire pw1_out_ready;
    reg [TIME_W-1:0] pw1_out_pool_t_base;
    reg [OC_BASE_W-1:0] pw1_out_oc_base;
    reg signed [TILE_W-1:0] pw1_out_tile;

    reg dw2_win_req_valid;
    wire dw2_win_req_ready;
    reg [TIME_W-1:0] dw2_win_req_out_t;
    reg [OC_BASE_W-1:0] dw2_win_req_ch_base;

    wire dw2_win_vec_valid;
    reg dw2_win_vec_ready;
    wire signed [WIN_W-1:0] dw2_win_vec;

`ifndef USE_PW1_TO_DW2_WITH_RAM
    wire bram_wr_en;
    wire [ADDR_W-1:0] bram_wr_addr;
    wire [WORD_W-1:0] bram_wr_data;
    wire bram_rd_en;
    wire [ADDR_W-1:0] bram_rd_addr;
    wire [WORD_W-1:0] bram_rd_dout;
`endif

    wire wr_busy;
    wire rd_busy;
    wire pw1_overwrite_stall;

    integer errors;
    integer timeout_count;
    integer scan_t;
    integer scan_oc;
    integer scan_out_t;
    integer scan_ch;
    integer tap;
    integer lane;
    integer bank_idx;

`ifdef USE_PW1_TO_DW2_WITH_RAM
    pw1_to_dw2_buffer_with_ram #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .PW1_OC(PW1_OC),
        .POOL_ROWS(POOL_ROWS),
        .PW1_OC_LANES(PW1_OC_LANES),
        .CH_LANES(CH_LANES),
        .DW_K(DW_K),
        .DW_PAD(DW_PAD),
        .RING_ROWS(RING_ROWS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .OC_BASE_W(OC_BASE_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .pw1_out_valid(pw1_out_valid),
        .pw1_out_ready(pw1_out_ready),
        .pw1_out_pool_t_base(pw1_out_pool_t_base),
        .pw1_out_oc_base(pw1_out_oc_base),
        .pw1_out_tile(pw1_out_tile),
        .dw2_win_req_valid(dw2_win_req_valid),
        .dw2_win_req_ready(dw2_win_req_ready),
        .dw2_win_req_out_t(dw2_win_req_out_t),
        .dw2_win_req_ch_base(dw2_win_req_ch_base),
        .dw2_win_vec_valid(dw2_win_vec_valid),
        .dw2_win_vec_ready(dw2_win_vec_ready),
        .dw2_win_vec(dw2_win_vec),
        .wr_busy(wr_busy),
        .rd_busy(rd_busy),
        .pw1_overwrite_stall(pw1_overwrite_stall)
    );
`else
    pw1_to_dw2_buffer #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .PW1_OC(PW1_OC),
        .POOL_ROWS(POOL_ROWS),
        .PW1_OC_LANES(PW1_OC_LANES),
        .CH_LANES(CH_LANES),
        .DW_K(DW_K),
        .DW_PAD(DW_PAD),
        .RING_ROWS(RING_ROWS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .OC_BASE_W(OC_BASE_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .pw1_out_valid(pw1_out_valid),
        .pw1_out_ready(pw1_out_ready),
        .pw1_out_pool_t_base(pw1_out_pool_t_base),
        .pw1_out_oc_base(pw1_out_oc_base),
        .pw1_out_tile(pw1_out_tile),
        .dw2_win_req_valid(dw2_win_req_valid),
        .dw2_win_req_ready(dw2_win_req_ready),
        .dw2_win_req_out_t(dw2_win_req_out_t),
        .dw2_win_req_ch_base(dw2_win_req_ch_base),
        .dw2_win_vec_valid(dw2_win_vec_valid),
        .dw2_win_vec_ready(dw2_win_vec_ready),
        .dw2_win_vec(dw2_win_vec),
        .bram_wr_en(bram_wr_en),
        .bram_wr_addr(bram_wr_addr),
        .bram_wr_data(bram_wr_data),
        .bram_rd_en(bram_rd_en),
        .bram_rd_addr(bram_rd_addr),
        .bram_rd_dout(bram_rd_dout),
        .wr_busy(wr_busy),
        .rd_busy(rd_busy),
        .pw1_overwrite_stall(pw1_overwrite_stall)
    );

    pw1_to_dw2_mock_ram #(
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
            value_i = ch_i * 256 + t_i;
            sample_value = value_i[DATA_W-1:0];
        end
    endfunction

    function [TILE_W-1:0] make_tile;
        input integer t_base_i;
        input integer oc_base_i;
        integer row_i_f;
        integer lane_i_f;
        begin
            make_tile = {TILE_W{1'b0}};
            for (row_i_f = 0; row_i_f < POOL_ROWS; row_i_f = row_i_f + 1) begin
                for (lane_i_f = 0;
                     lane_i_f < PW1_OC_LANES;
                     lane_i_f = lane_i_f + 1) begin
                    make_tile[(row_i_f*PW1_OC_LANES + lane_i_f)*DATA_W +: DATA_W]
                        = sample_value(oc_base_i + lane_i_f, t_base_i + row_i_f);
                end
            end
        end
    endfunction

    function [WIN_W-1:0] expected_window;
        input integer out_t_i;
        input integer ch_base_i;
        integer tap_i_f;
        integer lane_i_f;
        integer sample_t_f;
        begin
            expected_window = {WIN_W{1'b0}};
            for (tap_i_f = 0; tap_i_f < DW_K; tap_i_f = tap_i_f + 1) begin
                sample_t_f = out_t_i + tap_i_f - DW_PAD;
                for (lane_i_f = 0; lane_i_f < CH_LANES; lane_i_f = lane_i_f + 1) begin
                    if ((sample_t_f >= 0) && (sample_t_f < INPUT_LEN)) begin
                        expected_window[(tap_i_f*CH_LANES + lane_i_f)*DATA_W +: DATA_W]
                            = sample_value(ch_base_i + lane_i_f, sample_t_f);
                    end
                end
            end
        end
    endfunction

    task reset_dut;
        begin
            rst_n = 1'b1;
            clear = 1'b0;
            pw1_out_valid = 1'b0;
            pw1_out_pool_t_base = {TIME_W{1'b0}};
            pw1_out_oc_base = {OC_BASE_W{1'b0}};
            pw1_out_tile = {TILE_W{1'b0}};
            dw2_win_req_valid = 1'b0;
            dw2_win_req_out_t = {TIME_W{1'b0}};
            dw2_win_req_ch_base = {OC_BASE_W{1'b0}};
            dw2_win_vec_ready = 1'b1;
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
        input integer oc_base_i;
        begin
            @(negedge clk);
            pw1_out_pool_t_base = t_base_i[TIME_W-1:0];
            pw1_out_oc_base = oc_base_i[OC_BASE_W-1:0];
            pw1_out_tile = make_tile(t_base_i, oc_base_i);
            pw1_out_valid = 1'b1;
            #1;
            timeout_count = 0;
            while (pw1_out_ready !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display(
                        "ERROR write_tile timeout t_base=%0d oc_base=%0d",
                        t_base_i,
                        oc_base_i
                    );
                    errors = errors + 1;
                    disable write_tile;
                end
            end
            @(posedge clk);
            #1;
            if (wr_busy !== 1'b1) begin
                $display(
                    "ERROR wr_busy did not assert after accepted write t_base=%0d oc_base=%0d",
                    t_base_i,
                    oc_base_i
                );
                errors = errors + 1;
            end
            @(negedge clk);
            #1;
            if (wr_busy !== 1'b1) begin
                $display(
                    "ERROR wr_busy dropped early during write t_base=%0d oc_base=%0d",
                    t_base_i,
                    oc_base_i
                );
                errors = errors + 1;
            end
            pw1_out_valid = 1'b0;
        end
    endtask

    task write_all_groups;
        input integer t_base_i;
        integer oc_i;
        begin
            for (oc_i = 0; oc_i < PW1_OC; oc_i = oc_i + PW1_OC_LANES) begin
                write_tile(t_base_i, oc_i);
            end
        end
    endtask

    task expect_invalid_write;
        input integer t_base_i;
        input integer oc_base_i;
        integer invalid_before;
        begin
            invalid_before = `PW1_TO_DW2_CTRL.invalid_pw1_req_count;
            @(negedge clk);
            pw1_out_pool_t_base = t_base_i[TIME_W-1:0];
            pw1_out_oc_base = oc_base_i[OC_BASE_W-1:0];
            pw1_out_tile = make_tile(0, 0);
            pw1_out_valid = 1'b1;
            #1;
            if (pw1_out_ready !== 1'b0) begin
                $display("ERROR invalid PW1 write accepted t_base=%0d oc_base=%0d", t_base_i, oc_base_i);
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`PW1_TO_DW2_CTRL.invalid_pw1_req_count !== (invalid_before + 1)) begin
                $display("ERROR invalid_pw1_req_count did not increment");
                errors = errors + 1;
            end
            @(negedge clk);
            pw1_out_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task expect_write_blocked;
        input integer t_base_i;
        input integer oc_base_i;
        begin
            expect_write_blocked_cycles(t_base_i, oc_base_i, 1);
        end
    endtask

    task expect_write_blocked_cycles;
        input integer t_base_i;
        input integer oc_base_i;
        input integer cycles_i;
        integer stall_before;
        integer stall_cycle_i;
        begin
            stall_before = `PW1_TO_DW2_CTRL.pw1_overwrite_stall_count;
            @(negedge clk);
            pw1_out_pool_t_base = t_base_i[TIME_W-1:0];
            pw1_out_oc_base = oc_base_i[OC_BASE_W-1:0];
            pw1_out_tile = make_tile(t_base_i, oc_base_i);
            pw1_out_valid = 1'b1;
            #1;
            if (pw1_out_ready !== 1'b0) begin
                $display("ERROR PW1 overwrite should block t_base=%0d oc_base=%0d", t_base_i, oc_base_i);
                errors = errors + 1;
            end
            if (pw1_overwrite_stall !== 1'b1) begin
                $display("ERROR pw1_overwrite_stall should assert");
                errors = errors + 1;
            end
            for (stall_cycle_i = 0;
                 stall_cycle_i < cycles_i;
                 stall_cycle_i = stall_cycle_i + 1) begin
                @(posedge clk);
                #1;
                if (pw1_out_ready !== 1'b0) begin
                    $display(
                        "ERROR blocked PW1 write became ready during stall cycle=%0d",
                        stall_cycle_i
                    );
                    errors = errors + 1;
                end
                if (pw1_overwrite_stall !== 1'b1) begin
                    $display(
                        "ERROR pw1_overwrite_stall dropped during stall cycle=%0d",
                        stall_cycle_i
                    );
                    errors = errors + 1;
                end
            end
            if (`PW1_TO_DW2_CTRL.pw1_overwrite_stall_count
                !== (stall_before + cycles_i)) begin
                $display(
                    "ERROR pw1_overwrite_stall_count got=%0d expected=%0d",
                    `PW1_TO_DW2_CTRL.pw1_overwrite_stall_count,
                    stall_before + cycles_i
                );
                errors = errors + 1;
            end
            @(negedge clk);
            pw1_out_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task expect_unavailable_req;
        input integer out_t_i;
        input integer ch_base_i;
        integer unavailable_before;
        begin
            unavailable_before = `PW1_TO_DW2_CTRL.unavailable_dw_req_count;
            @(negedge clk);
            dw2_win_req_out_t = out_t_i[TIME_W-1:0];
            dw2_win_req_ch_base = ch_base_i[OC_BASE_W-1:0];
            dw2_win_req_valid = 1'b1;
            #1;
            if (dw2_win_req_ready !== 1'b0) begin
                $display("ERROR unavailable DW2 request accepted out_t=%0d ch_base=%0d", out_t_i, ch_base_i);
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`PW1_TO_DW2_CTRL.unavailable_dw_req_count !== (unavailable_before + 1)) begin
                $display("ERROR unavailable_dw_req_count did not increment");
                errors = errors + 1;
            end
            @(negedge clk);
            dw2_win_req_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task expect_invalid_req;
        input integer out_t_i;
        input integer ch_base_i;
        integer invalid_before;
        begin
            invalid_before = `PW1_TO_DW2_CTRL.invalid_dw_req_count;
            @(negedge clk);
            dw2_win_req_out_t = out_t_i[TIME_W-1:0];
            dw2_win_req_ch_base = ch_base_i[OC_BASE_W-1:0];
            dw2_win_req_valid = 1'b1;
            #1;
            if (dw2_win_req_ready !== 1'b0) begin
                $display("ERROR invalid DW2 request accepted out_t=%0d ch_base=%0d", out_t_i, ch_base_i);
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`PW1_TO_DW2_CTRL.invalid_dw_req_count !== (invalid_before + 1)) begin
                $display("ERROR invalid_dw_req_count did not increment");
                errors = errors + 1;
            end
            @(negedge clk);
            dw2_win_req_valid = 1'b0;
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
            for (tap = 0; tap < DW_K; tap = tap + 1) begin
                for (lane = 0; lane < CH_LANES; lane = lane + 1) begin
                    got_sample = got_i[(tap*CH_LANES + lane)*DATA_W +: DATA_W];
                    exp_sample = exp_i[(tap*CH_LANES + lane)*DATA_W +: DATA_W];
                    if (got_sample !== exp_sample) begin
                        $display(
                            "ERROR window mismatch out_t=%0d ch_base=%0d tap=%0d lane=%0d got=%0d expected=%0d",
                            out_t_i,
                            ch_base_i,
                            tap,
                            lane,
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
            dw2_win_req_out_t = out_t_i[TIME_W-1:0];
            dw2_win_req_ch_base = ch_base_i[OC_BASE_W-1:0];
            dw2_win_req_valid = 1'b1;
            #1;
            timeout_count = 0;
            while (dw2_win_req_ready !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display("ERROR request_window timeout out_t=%0d ch_base=%0d", out_t_i, ch_base_i);
                    errors = errors + 1;
                    disable request_window_expect;
                end
            end
            @(posedge clk);
            #1;
            if (rd_busy !== 1'b1) begin
                $display(
                    "ERROR rd_busy did not assert after accepted request out_t=%0d ch_base=%0d",
                    out_t_i,
                    ch_base_i
                );
                errors = errors + 1;
            end
            @(negedge clk);
            dw2_win_req_valid = 1'b0;

            timeout_count = 0;
            while (dw2_win_vec_valid !== 1'b1) begin
                #1;
                if (rd_busy !== 1'b1) begin
                    $display(
                        "ERROR rd_busy dropped before response out_t=%0d ch_base=%0d",
                        out_t_i,
                        ch_base_i
                    );
                    errors = errors + 1;
                end
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display("ERROR window response timeout out_t=%0d ch_base=%0d", out_t_i, ch_base_i);
                    errors = errors + 1;
                    disable request_window_expect;
                end
            end

            if (stall_cycles_i > 0) begin
                dw2_win_vec_ready = 1'b0;
                for (stall_i = 0; stall_i < stall_cycles_i; stall_i = stall_i + 1) begin
                    #1;
                    if (dw2_win_vec_valid !== 1'b1) begin
                        $display("ERROR dw2_win_vec_valid dropped during backpressure");
                        errors = errors + 1;
                    end
                    if (rd_busy !== 1'b1) begin
                        $display("ERROR rd_busy dropped during response backpressure");
                        errors = errors + 1;
                    end
                    compare_window(out_t_i, ch_base_i, dw2_win_vec, exp_vec);
                    @(negedge clk);
                end
                dw2_win_vec_ready = 1'b1;
            end

            #1;
            if (rd_busy !== 1'b1) begin
                $display("ERROR rd_busy dropped while response valid");
                errors = errors + 1;
            end
            compare_window(out_t_i, ch_base_i, dw2_win_vec, exp_vec);
            @(posedge clk);
            @(negedge clk);
        end
    endtask

    task clear_during_read_case;
        begin
            reset_dut();
            write_all_groups(0);
            write_all_groups(2);
            @(negedge clk);
            dw2_win_req_out_t = {TIME_W{1'b0}};
            dw2_win_req_ch_base = {OC_BASE_W{1'b0}};
            dw2_win_req_valid = 1'b1;
            #1;
            if (dw2_win_req_ready !== 1'b1) begin
                $display("ERROR clear_during_read initial request ready low");
                errors = errors + 1;
            end
            @(posedge clk);
            @(negedge clk);
            dw2_win_req_valid = 1'b0;
            clear = 1'b1;
            @(negedge clk);
            clear = 1'b0;
            @(negedge clk);
            if (rd_busy || dw2_win_vec_valid) begin
                $display("ERROR clear_during_read_case did not return idle");
                errors = errors + 1;
            end
            expect_unavailable_req(0, 0);
        end
    endtask

    task subset_stream_scan;
        begin
            reset_dut();
            for (scan_t = 0; scan_t < 16; scan_t = scan_t + POOL_ROWS) begin
                write_all_groups(scan_t);
                if (scan_t >= DW_PAD) begin
                    for (scan_out_t = scan_t - DW_PAD;
                         scan_out_t < scan_t;
                         scan_out_t = scan_out_t + 1) begin
                        for (scan_ch = 0;
                             scan_ch < PW1_OC;
                             scan_ch = scan_ch + CH_LANES) begin
                            request_window_expect(scan_out_t, scan_ch, 0);
                        end
                    end
                end
            end
            $display("INFO pw1_to_dw2 subset_stream_scan complete");
        end
    endtask

    task concurrent_write_read_case;
        begin
            reset_dut();
            for (scan_t = 0; scan_t < 8; scan_t = scan_t + POOL_ROWS) begin
                write_tile(scan_t, 0);
            end

            for (scan_t = 0; scan_t < 6; scan_t = scan_t + POOL_ROWS) begin
                write_tile(scan_t, 32);
                #1;
                if (wr_busy !== 1'b1) begin
                    $display(
                        "ERROR concurrent_write_read_case expected wr_busy before read t=%0d",
                        scan_t
                    );
                    errors = errors + 1;
                end
                request_window_expect(scan_t, 0, (scan_t == 4) ? 2 : 0);
            end
            $display("INFO pw1_to_dw2 concurrent_write_read_case complete");
        end
    endtask

    task bank_served_independence_case;
        begin
            reset_dut();

            write_tile(0, PW1_OC - PW1_OC_LANES);
            write_tile(2, PW1_OC - PW1_OC_LANES);
            write_tile(0, 0);
            write_tile(2, 0);
            write_tile(4, 0);

            request_window_expect(2, 0, 0);
            request_window_expect(2, CH_LANES, 0);
            request_window_expect(3, 0, 0);
            request_window_expect(3, CH_LANES, 0);
            #1;
            if (`PW1_TO_DW2_CTRL.served_valid[0] !== 1'b1
                || `PW1_TO_DW2_CTRL.served_out_t[0] !== 8'd3) begin
                $display(
                    "ERROR bank0 served state got valid=%0d out_t=%0d expected 3",
                    `PW1_TO_DW2_CTRL.served_valid[0],
                    `PW1_TO_DW2_CTRL.served_out_t[0]
                );
                errors = errors + 1;
            end
            if (`PW1_TO_DW2_CTRL.served_valid[1] !== 1'b1
                || `PW1_TO_DW2_CTRL.served_out_t[1] !== 8'd3) begin
                $display(
                    "ERROR bank1 served state got valid=%0d out_t=%0d expected 3",
                    `PW1_TO_DW2_CTRL.served_valid[1],
                    `PW1_TO_DW2_CTRL.served_out_t[1]
                );
                errors = errors + 1;
            end
            if (`PW1_TO_DW2_CTRL.served_valid[BANKS-1] !== 1'b0) begin
                $display("ERROR bank15 served state changed before bank15 request");
                errors = errors + 1;
            end

            write_tile(8, 0);
            request_window_expect(0, PW1_OC - CH_LANES, 0);
            #1;
            if (`PW1_TO_DW2_CTRL.served_valid[0] !== 1'b1
                || `PW1_TO_DW2_CTRL.served_out_t[0] !== 8'd3) begin
                $display(
                    "ERROR bank0 served state changed after bank15 request out_t=%0d",
                    `PW1_TO_DW2_CTRL.served_out_t[0]
                );
                errors = errors + 1;
            end
            if (`PW1_TO_DW2_CTRL.served_valid[BANKS-1] !== 1'b1
                || `PW1_TO_DW2_CTRL.served_out_t[BANKS-1] !== {TIME_W{1'b0}}) begin
                $display(
                    "ERROR bank15 served state got valid=%0d out_t=%0d expected 0",
                    `PW1_TO_DW2_CTRL.served_valid[BANKS-1],
                    `PW1_TO_DW2_CTRL.served_out_t[BANKS-1]
                );
                errors = errors + 1;
            end
            expect_write_blocked_cycles(8, PW1_OC - PW1_OC_LANES, 2);
            $display("INFO pw1_to_dw2 bank_served_independence_case complete");
        end
    endtask

    task tail_padding_long_backpressure_case;
        begin
            reset_dut();
            write_all_groups(INPUT_LEN - 4);
            write_all_groups(INPUT_LEN - 2);
            request_window_expect(INPUT_LEN - 1, PW1_OC - CH_LANES, 50);
            $display("INFO pw1_to_dw2 tail_padding_long_backpressure_case complete");
        end
    endtask

    task overwrite_stall_count_case;
        begin
            reset_dut();
            write_all_groups(0);
            write_all_groups(2);
            expect_write_blocked_cycles(16, 0, 10);
            $display("INFO pw1_to_dw2 overwrite_stall_count_case complete");
        end
    endtask

    task full_stream_scan;
        begin
            reset_dut();
            for (scan_t = 0; scan_t < INPUT_LEN; scan_t = scan_t + POOL_ROWS) begin
                write_all_groups(scan_t);
                if (scan_t >= DW_PAD) begin
                    if (scan_t == (INPUT_LEN - POOL_ROWS)) begin
                        for (scan_out_t = scan_t - DW_PAD;
                             scan_out_t < INPUT_LEN;
                             scan_out_t = scan_out_t + 1) begin
                            for (scan_ch = 0;
                                 scan_ch < PW1_OC;
                                 scan_ch = scan_ch + CH_LANES) begin
                                request_window_expect(scan_out_t, scan_ch, 0);
                            end
                        end
                    end else begin
                        for (scan_out_t = scan_t - DW_PAD;
                             scan_out_t < scan_t;
                             scan_out_t = scan_out_t + 1) begin
                            for (scan_ch = 0;
                                 scan_ch < PW1_OC;
                                 scan_ch = scan_ch + CH_LANES) begin
                                request_window_expect(scan_out_t, scan_ch, 0);
                            end
                        end
                    end
                end
            end
            $display("INFO pw1_to_dw2 full_stream_scan complete");
        end
    endtask

    initial begin
        errors = 0;
        reset_dut();

        expect_invalid_write(0, 4);
        expect_invalid_write(INPUT_LEN - 1, 0);
        expect_invalid_req(INPUT_LEN, 0);
        expect_invalid_req(0, 2);
        expect_unavailable_req(0, 0);

        write_all_groups(0);
        expect_unavailable_req(0, 0);
        write_all_groups(2);
        request_window_expect(0, 0, 3);
        request_window_expect(1, PW1_OC - CH_LANES, 0);
        expect_write_blocked(16, 0);

        pulse_clear();
        expect_unavailable_req(0, 0);

        clear_during_read_case();
        tail_padding_long_backpressure_case();
        concurrent_write_read_case();
        bank_served_independence_case();
        overwrite_stall_count_case();
        if (RUN_SUBSET_SCAN) begin
            subset_stream_scan();
        end
        if (RUN_FULL_SCAN) begin
            full_stream_scan();
        end

        if (errors == 0) begin
            $display("PASS %m latency=%0d", BRAM_READ_LATENCY);
        end else begin
            $display("FAIL tb_pw1_to_dw2_buffer errors=%0d", errors);
        end
        $finish;
    end

endmodule

module pw1_to_dw2_mock_ram #(
    parameter integer WORD_W = 64,
    parameter integer ADDR_W = 8,
    parameter integer DEPTH = 256,
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
