`timescale 1ns / 1ps

`ifndef DW2_TO_PW2_TB_MODULE
`define DW2_TO_PW2_TB_MODULE tb_dw2_to_pw2_buffer
`endif

`ifdef USE_DW2_TO_PW2_WITH_RAM
`define DW2_TO_PW2_CTRL dut.u_ctrl
`else
`define DW2_TO_PW2_CTRL dut
`endif

module `DW2_TO_PW2_TB_MODULE;

    parameter integer BRAM_READ_LATENCY = 1;
`ifdef USE_DW2_TO_PW2_WITH_RAM
    parameter integer RUN_FULL_SCAN = 0;
`else
    parameter integer RUN_FULL_SCAN = 1;
`endif

    localparam integer DATA_W     =  8;
    localparam integer MULT_W     = 16;
    localparam integer TIME_W     = 8;
    localparam integer INPUT_LEN  = 174;
    localparam integer PW2_IC     = 64;
    localparam integer ROWS       = 4;
    localparam integer CH_LANES   = 4;
    localparam integer RING_ROWS  = 8;
    localparam integer BANKS      = PW2_IC / CH_LANES;
    localparam integer WORD_W     = CH_LANES * DATA_W;
    localparam integer ACT_W      = ROWS * DATA_W;
    localparam integer CH_BASE_W  = (PW2_IC <= 1) ? 1 : $clog2(PW2_IC + 1);
    localparam integer ADDR_W     = (BANKS * RING_ROWS <= 1)
        ? 1 : $clog2(BANKS * RING_ROWS);
    localparam integer TIMEOUT    = 10000;
    localparam [ROWS-1:0] FULL_MASK  = {ROWS{1'b1}};
    localparam [ROWS-1:0] FINAL_MASK = 4'b0011;

    reg clk;
    reg rst_n;
    reg clear;

    reg dw2_out_valid;
    wire dw2_out_ready;
    reg [TIME_W-1:0] dw2_out_t;
    reg [CH_BASE_W-1:0] dw2_out_ch_base;
    reg signed [WORD_W-1:0] dw2_out_vec;

    reg input_tile_req_valid;
    wire input_tile_req_ready;
    reg [TIME_W-1:0] input_tile_req_t_base;
    reg [ROWS-1:0] input_tile_req_row_valid_mask;

    reg act_req_valid;
    wire act_req_ready;
    reg [TIME_W-1:0] act_req_t_base;
    reg [6:0] act_req_k;
    reg [ROWS-1:0] act_req_row_valid_mask;

    wire act_vec_valid;
    reg act_vec_ready;
    wire signed [ACT_W-1:0] act_vec;

`ifndef USE_DW2_TO_PW2_WITH_RAM
    wire bram_a_en;
    wire bram_a_we;
    wire [ADDR_W-1:0] bram_a_addr;
    wire [WORD_W-1:0] bram_a_din;
    wire [WORD_W-1:0] bram_a_dout;
    wire bram_b_en;
    wire bram_b_we;
    wire [ADDR_W-1:0] bram_b_addr;
    wire [WORD_W-1:0] bram_b_din;
    wire [WORD_W-1:0] bram_b_dout;
`endif

    wire wr_busy;
    wire rd_busy;
    wire tile_cache_valid;
    wire dw2_overwrite_stall;

    integer errors;
    integer timeout_count;
    integer scan_t;
    integer row;

`ifdef USE_DW2_TO_PW2_WITH_RAM
    dw2_to_pw2_buffer_with_ram #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .PW2_IC(PW2_IC),
        .ROWS(ROWS),
        .CH_LANES(CH_LANES),
        .RING_ROWS(RING_ROWS),
        .BANKS(BANKS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .CH_BASE_W(CH_BASE_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .dw2_out_valid(dw2_out_valid),
        .dw2_out_ready(dw2_out_ready),
        .dw2_out_t(dw2_out_t),
        .dw2_out_ch_base(dw2_out_ch_base),
        .dw2_out_vec(dw2_out_vec),
        .input_tile_req_valid(input_tile_req_valid),
        .input_tile_req_ready(input_tile_req_ready),
        .input_tile_req_t_base(input_tile_req_t_base),
        .input_tile_req_row_valid_mask(input_tile_req_row_valid_mask),
        .act_req_valid(act_req_valid),
        .act_req_ready(act_req_ready),
        .act_req_t_base(act_req_t_base),
        .act_req_k(act_req_k),
        .act_req_row_valid_mask(act_req_row_valid_mask),
        .act_vec_valid(act_vec_valid),
        .act_vec_ready(act_vec_ready),
        .act_vec(act_vec),
        .wr_busy(wr_busy),
        .rd_busy(rd_busy),
        .tile_cache_valid(tile_cache_valid),
        .dw2_overwrite_stall(dw2_overwrite_stall)
    );
`else
    dw2_to_pw2_buffer #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .PW2_IC(PW2_IC),
        .ROWS(ROWS),
        .CH_LANES(CH_LANES),
        .RING_ROWS(RING_ROWS),
        .BANKS(BANKS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .CH_BASE_W(CH_BASE_W),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .dw2_out_valid(dw2_out_valid),
        .dw2_out_ready(dw2_out_ready),
        .dw2_out_t(dw2_out_t),
        .dw2_out_ch_base(dw2_out_ch_base),
        .dw2_out_vec(dw2_out_vec),
        .input_tile_req_valid(input_tile_req_valid),
        .input_tile_req_ready(input_tile_req_ready),
        .input_tile_req_t_base(input_tile_req_t_base),
        .input_tile_req_row_valid_mask(input_tile_req_row_valid_mask),
        .act_req_valid(act_req_valid),
        .act_req_ready(act_req_ready),
        .act_req_t_base(act_req_t_base),
        .act_req_k(act_req_k),
        .act_req_row_valid_mask(act_req_row_valid_mask),
        .act_vec_valid(act_vec_valid),
        .act_vec_ready(act_vec_ready),
        .act_vec(act_vec),
        .bram_a_en(bram_a_en),
        .bram_a_we(bram_a_we),
        .bram_a_addr(bram_a_addr),
        .bram_a_din(bram_a_din),
        .bram_a_dout(bram_a_dout),
        .bram_b_en(bram_b_en),
        .bram_b_we(bram_b_we),
        .bram_b_addr(bram_b_addr),
        .bram_b_din(bram_b_din),
        .bram_b_dout(bram_b_dout),
        .wr_busy(wr_busy),
        .rd_busy(rd_busy),
        .tile_cache_valid(tile_cache_valid),
        .dw2_overwrite_stall(dw2_overwrite_stall)
    );

    dw2_to_pw2_mock_tdp_ram #(
        .WORD_W(WORD_W),
        .ADDR_W(ADDR_W),
        .DEPTH(BANKS * RING_ROWS),
        .READ_LATENCY(BRAM_READ_LATENCY)
    ) u_mock_ram (
        .clk(clk),
        .a_en(bram_a_en),
        .a_we(bram_a_we),
        .a_addr(bram_a_addr),
        .a_din(bram_a_din),
        .a_dout(bram_a_dout),
        .b_en(bram_b_en),
        .b_we(bram_b_we),
        .b_addr(bram_b_addr),
        .b_din(bram_b_din),
        .b_dout(bram_b_dout)
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
            value_i = ch_i * 200 + t_i;
            sample_value = value_i[DATA_W-1:0];
        end
    endfunction

    function [WORD_W-1:0] make_word;
        input integer t_i;
        input integer ch_base_i;
        integer lane_i_f;
        begin
            make_word = {WORD_W{1'b0}};
            for (lane_i_f = 0; lane_i_f < CH_LANES; lane_i_f = lane_i_f + 1) begin
                make_word[lane_i_f*DATA_W +: DATA_W]
                    = sample_value(ch_base_i + lane_i_f, t_i);
            end
        end
    endfunction

    function [ACT_W-1:0] expected_act_vec;
        input integer t_base_i;
        input integer k_i;
        input [ROWS-1:0] mask_i;
        integer row_i_f;
        begin
            expected_act_vec = {ACT_W{1'b0}};
            for (row_i_f = 0; row_i_f < ROWS; row_i_f = row_i_f + 1) begin
                if (mask_i[row_i_f]) begin
                    expected_act_vec[row_i_f*DATA_W +: DATA_W]
                        = sample_value(k_i, t_base_i + row_i_f);
                end
            end
        end
    endfunction

    task reset_dut;
        begin
            rst_n = 1'b1;
            clear = 1'b0;
            dw2_out_valid = 1'b0;
            dw2_out_t = {TIME_W{1'b0}};
            dw2_out_ch_base = {CH_BASE_W{1'b0}};
            dw2_out_vec = {WORD_W{1'b0}};
            input_tile_req_valid = 1'b0;
            input_tile_req_t_base = {TIME_W{1'b0}};
            input_tile_req_row_valid_mask = FULL_MASK;
            act_req_valid = 1'b0;
            act_req_t_base = {TIME_W{1'b0}};
            act_req_k = 7'd0;
            act_req_row_valid_mask = FULL_MASK;
            act_vec_ready = 1'b1;
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

    task write_word;
        input integer t_i;
        input integer ch_base_i;
        begin
            @(negedge clk);
            dw2_out_t = t_i[TIME_W-1:0];
            dw2_out_ch_base = ch_base_i[CH_BASE_W-1:0];
            dw2_out_vec = make_word(t_i, ch_base_i);
            dw2_out_valid = 1'b1;
            #1;
            timeout_count = 0;
            while (dw2_out_ready !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display(
                        "ERROR write_word timeout t=%0d ch_base=%0d",
                        t_i,
                        ch_base_i
                    );
                    errors = errors + 1;
                    disable write_word;
                end
            end
            @(posedge clk);
            @(negedge clk);
            dw2_out_valid = 1'b0;
        end
    endtask

    task write_row;
        input integer t_i;
        integer ch_i;
        begin
            for (ch_i = 0; ch_i < PW2_IC; ch_i = ch_i + CH_LANES) begin
                write_word(t_i, ch_i);
            end
        end
    endtask

    task expect_write_blocked;
        input integer t_i;
        input integer ch_base_i;
        integer stall_before;
        begin
            stall_before = `DW2_TO_PW2_CTRL.dw2_overwrite_stall_count;
            @(negedge clk);
            dw2_out_t = t_i[TIME_W-1:0];
            dw2_out_ch_base = ch_base_i[CH_BASE_W-1:0];
            dw2_out_vec = make_word(t_i, ch_base_i);
            dw2_out_valid = 1'b1;
            #1;
            if (dw2_out_ready !== 1'b0) begin
                $display(
                    "ERROR dw2_out_ready should block overwrite t=%0d ch_base=%0d",
                    t_i,
                    ch_base_i
                );
                errors = errors + 1;
            end
            if (dw2_overwrite_stall !== 1'b1) begin
                $display("ERROR dw2_overwrite_stall should assert");
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`DW2_TO_PW2_CTRL.dw2_overwrite_stall_count !== (stall_before + 1)) begin
                $display("ERROR dw2_overwrite_stall_count did not increment");
                errors = errors + 1;
            end
            @(negedge clk);
            dw2_out_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task expect_invalid_write;
        input integer t_i;
        input integer ch_base_i;
        integer invalid_before;
        begin
            invalid_before = `DW2_TO_PW2_CTRL.invalid_dw2_write_count;
            @(negedge clk);
            dw2_out_t = t_i[TIME_W-1:0];
            dw2_out_ch_base = ch_base_i[CH_BASE_W-1:0];
            dw2_out_vec = make_word(t_i, ch_base_i);
            dw2_out_valid = 1'b1;
            #1;
            if (dw2_out_ready !== 1'b0) begin
                $display(
                    "ERROR invalid write accepted t=%0d ch_base=%0d",
                    t_i,
                    ch_base_i
                );
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`DW2_TO_PW2_CTRL.invalid_dw2_write_count !== (invalid_before + 1)) begin
                $display("ERROR invalid_dw2_write_count did not increment");
                errors = errors + 1;
            end
            @(negedge clk);
            dw2_out_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task expect_tile_blocked;
        input integer t_base_i;
        input [ROWS-1:0] mask_i;
        integer unavailable_before;
        begin
            unavailable_before = `DW2_TO_PW2_CTRL.unavailable_tile_req_count;
            @(negedge clk);
            input_tile_req_t_base = t_base_i[TIME_W-1:0];
            input_tile_req_row_valid_mask = mask_i;
            input_tile_req_valid = 1'b1;
            #1;
            if (input_tile_req_ready !== 1'b0) begin
                $display(
                    "ERROR input_tile_req_ready should block unavailable tile t_base=%0d mask=%b",
                    t_base_i,
                    mask_i
                );
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`DW2_TO_PW2_CTRL.unavailable_tile_req_count !== (unavailable_before + 1)) begin
                $display("ERROR unavailable_tile_req_count did not increment");
                errors = errors + 1;
            end
            @(negedge clk);
            input_tile_req_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task expect_invalid_tile_req;
        input integer t_base_i;
        input [ROWS-1:0] mask_i;
        integer invalid_before;
        begin
            invalid_before = `DW2_TO_PW2_CTRL.invalid_tile_req_count;
            @(negedge clk);
            input_tile_req_t_base = t_base_i[TIME_W-1:0];
            input_tile_req_row_valid_mask = mask_i;
            input_tile_req_valid = 1'b1;
            #1;
            if (input_tile_req_ready !== 1'b0) begin
                $display(
                    "ERROR invalid tile request accepted t_base=%0d mask=%b",
                    t_base_i,
                    mask_i
                );
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`DW2_TO_PW2_CTRL.invalid_tile_req_count !== (invalid_before + 1)) begin
                $display("ERROR invalid_tile_req_count did not increment");
                errors = errors + 1;
            end
            @(negedge clk);
            input_tile_req_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task expect_tile_busy_blocked;
        input integer t_base_i;
        input [ROWS-1:0] mask_i;
        begin
            @(negedge clk);
            input_tile_req_t_base = t_base_i[TIME_W-1:0];
            input_tile_req_row_valid_mask = mask_i;
            input_tile_req_valid = 1'b1;
            #1;
            if (input_tile_req_ready !== 1'b0) begin
                $display("ERROR tile request accepted while buffer is busy");
                errors = errors + 1;
            end
            @(negedge clk);
            input_tile_req_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task request_tile;
        input integer t_base_i;
        input [ROWS-1:0] mask_i;
        begin
            @(negedge clk);
            input_tile_req_t_base = t_base_i[TIME_W-1:0];
            input_tile_req_row_valid_mask = mask_i;
            input_tile_req_valid = 1'b1;
            #1;
            timeout_count = 0;
            while (input_tile_req_ready !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display(
                        "ERROR request_tile timeout t_base=%0d mask=%b",
                        t_base_i,
                        mask_i
                    );
                    errors = errors + 1;
                    disable request_tile;
                end
            end
            @(posedge clk);
            @(negedge clk);
            input_tile_req_valid = 1'b0;

            timeout_count = 0;
            while (tile_cache_valid !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display(
                        "ERROR tile cache load timeout t_base=%0d mask=%b",
                        t_base_i,
                        mask_i
                    );
                    errors = errors + 1;
                    disable request_tile;
                end
            end
        end
    endtask

    task expect_invalid_act_req;
        input integer t_base_i;
        input integer k_i;
        input [ROWS-1:0] mask_i;
        integer invalid_before;
        begin
            invalid_before = `DW2_TO_PW2_CTRL.invalid_act_req_count;
            @(negedge clk);
            act_req_t_base = t_base_i[TIME_W-1:0];
            act_req_k = k_i[6:0];
            act_req_row_valid_mask = mask_i;
            act_req_valid = 1'b1;
            #1;
            if (act_req_ready !== 1'b0) begin
                $display(
                    "ERROR invalid act request accepted t_base=%0d k=%0d mask=%b",
                    t_base_i,
                    k_i,
                    mask_i
                );
                errors = errors + 1;
            end
            @(posedge clk);
            #1;
            if (`DW2_TO_PW2_CTRL.invalid_act_req_count !== (invalid_before + 1)) begin
                $display("ERROR invalid_act_req_count did not increment");
                errors = errors + 1;
            end
            @(negedge clk);
            act_req_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    task compare_act_vec;
        input integer t_base_i;
        input integer k_i;
        input [ROWS-1:0] mask_i;
        input [ACT_W-1:0] got_i;
        input [ACT_W-1:0] exp_i;
        reg signed [DATA_W-1:0] got_sample;
        reg signed [DATA_W-1:0] exp_sample;
        begin
            for (row = 0; row < ROWS; row = row + 1) begin
                got_sample = got_i[row*DATA_W +: DATA_W];
                exp_sample = exp_i[row*DATA_W +: DATA_W];
                if (got_sample !== exp_sample) begin
                    $display(
                        "ERROR act vec mismatch t_base=%0d k=%0d mask=%b row=%0d got=%0d expected=%0d",
                        t_base_i,
                        k_i,
                        mask_i,
                        row,
                        got_sample,
                        exp_sample
                    );
                    errors = errors + 1;
                end
            end
        end
    endtask

    task request_act_expect;
        input integer t_base_i;
        input integer k_i;
        input [ROWS-1:0] mask_i;
        input integer stall_cycles_i;
        reg [ACT_W-1:0] exp_vec;
        integer stall_i;
        begin
            exp_vec = expected_act_vec(t_base_i, k_i, mask_i);
            @(negedge clk);
            act_req_t_base = t_base_i[TIME_W-1:0];
            act_req_k = k_i[6:0];
            act_req_row_valid_mask = mask_i;
            act_req_valid = 1'b1;
            #1;
            timeout_count = 0;
            while (act_req_ready !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display(
                        "ERROR act request timeout t_base=%0d k=%0d mask=%b",
                        t_base_i,
                        k_i,
                        mask_i
                    );
                    errors = errors + 1;
                    disable request_act_expect;
                end
            end
            @(posedge clk);
            @(negedge clk);
            act_req_valid = 1'b0;

            timeout_count = 0;
            while (act_vec_valid !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display(
                        "ERROR act response timeout t_base=%0d k=%0d",
                        t_base_i,
                        k_i
                    );
                    errors = errors + 1;
                    disable request_act_expect;
                end
            end

            if (stall_cycles_i > 0) begin
                act_vec_ready = 1'b0;
                for (stall_i = 0; stall_i < stall_cycles_i; stall_i = stall_i + 1) begin
                    #1;
                    if (act_vec_valid !== 1'b1) begin
                        $display("ERROR act_vec_valid dropped during backpressure");
                        errors = errors + 1;
                    end
                    compare_act_vec(t_base_i, k_i, mask_i, act_vec, exp_vec);
                    @(negedge clk);
                end
                act_vec_ready = 1'b1;
            end

            #1;
            compare_act_vec(t_base_i, k_i, mask_i, act_vec, exp_vec);
            @(posedge clk);
            @(negedge clk);
        end
    endtask

    task drain_tile_acts;
        input integer t_base_i;
        input [ROWS-1:0] mask_i;
        integer k_i;
        begin
            for (k_i = 0; k_i < PW2_IC; k_i = k_i + 1) begin
                request_act_expect(t_base_i, k_i, mask_i, (k_i == 7) ? 3 : 0);
            end
        end
    endtask

    task clear_during_load_case;
        begin
            reset_dut();
            write_row(0);
            write_row(1);
            write_row(2);
            write_row(3);
            @(negedge clk);
            input_tile_req_t_base = {TIME_W{1'b0}};
            input_tile_req_row_valid_mask = FULL_MASK;
            input_tile_req_valid = 1'b1;
            #1;
            timeout_count = 0;
            while (input_tile_req_ready !== 1'b1) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
                if (timeout_count > TIMEOUT) begin
                    $display("ERROR clear_during_load tile request timeout");
                    errors = errors + 1;
                    disable clear_during_load_case;
                end
            end
            @(posedge clk);
            @(negedge clk);
            input_tile_req_valid = 1'b0;
            clear = 1'b1;
            @(negedge clk);
            clear = 1'b0;
            @(negedge clk);
            if (rd_busy || tile_cache_valid || act_vec_valid) begin
                $display("ERROR clear_during_load_case did not return idle");
                errors = errors + 1;
            end
            expect_tile_blocked(0, FULL_MASK);
        end
    endtask

    task partial_final_tile_case;
        begin
            reset_dut();
            write_row(172);
            write_row(173);
            expect_invalid_tile_req(172, FULL_MASK);
            request_tile(172, FINAL_MASK);
            expect_invalid_act_req(172, 0, FULL_MASK);
            drain_tile_acts(172, FINAL_MASK);
        end
    endtask

    task full_stream_scan;
        begin
            reset_dut();
            for (scan_t = 0; scan_t < INPUT_LEN; scan_t = scan_t + 1) begin
                write_row(scan_t);
                if ((scan_t % ROWS) == (ROWS - 1)) begin
                    request_tile(scan_t - ROWS + 1, FULL_MASK);
                    drain_tile_acts(scan_t - ROWS + 1, FULL_MASK);
                end
            end
            request_tile(172, FINAL_MASK);
            drain_tile_acts(172, FINAL_MASK);
            $display("INFO dw2_to_pw2 full_stream_scan complete");
        end
    endtask

    initial begin
        errors = 0;
        reset_dut();

        expect_invalid_write(0, 1);
        expect_invalid_write(0, PW2_IC);
        expect_invalid_write(INPUT_LEN, 0);
        expect_invalid_tile_req(0, {ROWS{1'b0}});
        expect_invalid_tile_req(172, FULL_MASK);
        expect_invalid_tile_req(173, FINAL_MASK);
        expect_tile_blocked(0, FULL_MASK);

        write_row(0);
        write_row(1);
        expect_tile_blocked(0, FULL_MASK);
        write_row(2);
        write_row(3);
        expect_write_blocked(16, 0);

        request_tile(0, FULL_MASK);
        expect_tile_busy_blocked(4, FULL_MASK);
        expect_invalid_act_req(4, 0, FULL_MASK);
        expect_invalid_act_req(0, PW2_IC, FULL_MASK);
        expect_invalid_act_req(0, 0, FINAL_MASK);
        drain_tile_acts(0, FULL_MASK);

        write_word(16, 0);

        pulse_clear();
        expect_tile_blocked(0, FULL_MASK);

        clear_during_load_case();
        partial_final_tile_case();
        if (RUN_FULL_SCAN) begin
            full_stream_scan();
        end

        if (errors == 0) begin
            $display("PASS %m latency=%0d", BRAM_READ_LATENCY);
        end else begin
            $display("FAIL tb_dw2_to_pw2_buffer errors=%0d", errors);
        end
        $finish;
    end

endmodule

module dw2_to_pw2_mock_tdp_ram #(
    parameter integer WORD_W = 64,
    parameter integer ADDR_W = 8,
    parameter integer DEPTH = 256,
    parameter integer READ_LATENCY = 1,
    parameter integer PIPE_DEPTH = (READ_LATENCY <= 1) ? 1 : READ_LATENCY
) (
    input  wire clk,
    input  wire a_en,
    input  wire a_we,
    input  wire [ADDR_W-1:0] a_addr,
    input  wire [WORD_W-1:0] a_din,
    output reg [WORD_W-1:0] a_dout,
    input  wire b_en,
    input  wire b_we,
    input  wire [ADDR_W-1:0] b_addr,
    input  wire [WORD_W-1:0] b_din,
    output reg [WORD_W-1:0] b_dout
);

    reg [WORD_W-1:0] mem [0:DEPTH-1];
    reg [WORD_W-1:0] a_pipe [0:PIPE_DEPTH-1];
    reg [WORD_W-1:0] b_pipe [0:PIPE_DEPTH-1];

    integer i;

    initial begin
        a_dout = {WORD_W{1'b0}};
        b_dout = {WORD_W{1'b0}};
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = {WORD_W{1'b0}};
        end
        for (i = 0; i < PIPE_DEPTH; i = i + 1) begin
            a_pipe[i] = {WORD_W{1'b0}};
            b_pipe[i] = {WORD_W{1'b0}};
        end
    end

    always @(posedge clk) begin
        if (a_en && a_we) begin
            mem[a_addr] <= a_din;
        end
        if (b_en && b_we) begin
            mem[b_addr] <= b_din;
        end

        if (a_en) begin
            a_pipe[0] <= (a_we ? a_din : mem[a_addr]);
            for (i = 1; i < PIPE_DEPTH; i = i + 1) begin
                a_pipe[i] <= a_pipe[i-1];
            end
            a_dout <= a_pipe[PIPE_DEPTH-1];
        end

        if (b_en) begin
            b_pipe[0] <= (b_we ? b_din : mem[b_addr]);
            for (i = 1; i < PIPE_DEPTH; i = i + 1) begin
                b_pipe[i] <= b_pipe[i-1];
            end
            b_dout <= b_pipe[PIPE_DEPTH-1];
        end
    end

endmodule
