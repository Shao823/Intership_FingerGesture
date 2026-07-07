`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_stem_conv_array_4x4;

    // Top-level integration test:
    // - activation input/cases come from this folder's deterministic testdata;
    // - stem convolution weights and folded BN parameters come from
    //   weight_data/stem, matching the generated blk_mem_gen_stem_weight IP.
    //
    // The synthetic testdata/weight.mem, bn_*.mem, and expected.mem files are
    // intentionally used by tb_stem_conv_array_4x4_compute, not by this wrapper
    // test. This test catches stale/mismatched ROM initialization through the
    // final tile comparison and the separate controller-with-ROM readback test.

    localparam integer DATA_W       = 16;
    localparam integer ACC_W        = 48;
    localparam integer ROWS         = 4;
    localparam integer OC_LANES     = 4;
    localparam integer STEM_OC      = 32;
    localparam integer STEM_K       = 35;
    localparam integer FRAC_BITS    = 8;
    localparam integer TIME_W       = 9;
    localparam integer INPUT_LEN    = 348;
    localparam integer STEM_IC      = 5;
    localparam integer FILE_CASES   = 4;
    localparam integer TOP_CASES    = 9;
    localparam integer DONE_TIMEOUT = 3000;

    localparam integer STALL_NONE     = 0;
    localparam integer STALL_PERIODIC = 1;
    localparam integer STALL_LATE     = 2;

    reg clk;
    reg rst_n;
    reg start;
    reg [4:0] oc_base;
    reg [TIME_W-1:0] tile_t_base;

    wire act_req_valid;
    wire [TIME_W-1:0] act_req_t_base;
    wire [5:0] act_req_k;
    reg act_req_ready;
    reg act_vec_valid;
    wire act_vec_ready;
    reg signed [ROWS*DATA_W-1:0] act_vec;

    reg w_fold_we;
    reg [4:0] w_fold_oc;
    reg signed [DATA_W-1:0] w_fold_wdata;

    reg bias_fold_we;
    reg [4:0] bias_fold_oc;
    reg signed [DATA_W-1:0] bias_fold_wdata;

    reg out_ready;
    wire busy;
    wire done;
    wire out_valid;
    wire [TIME_W-1:0] out_tile_t_base;
    wire [4:0] out_tile_oc_base;
    wire signed [ROWS*OC_LANES*DATA_W-1:0] out_tile;

    integer errors;
    integer r;
    integer c;
    integer k;
    integer av;
    integer test_oc_base;
    integer test_t_base;
    integer stall_mode;
    integer ready_cycle;
    integer act_req_count;
    integer last_timeout;
    integer out_ready_delay;
    integer out_ready_count;
    integer out_ready_delay_active;
    integer file_case_idx;
    integer top_case_idx;

    reg signed [DATA_W-1:0] expected [0:ROWS-1][0:OC_LANES-1];
    reg signed [DATA_W-1:0] file_raw_input [0:INPUT_LEN*STEM_IC-1];
    reg [7:0] file_case_oc_base [0:FILE_CASES-1];
    reg [15:0] file_case_t_base [0:FILE_CASES-1];
    reg signed [DATA_W-1:0] file_expected_top [0:TOP_CASES*ROWS*OC_LANES-1];
    reg observed_out_valid;
    reg [TIME_W-1:0] observed_out_tile_t_base;
    reg [4:0] observed_out_tile_oc_base;
    reg signed [ROWS*OC_LANES*DATA_W-1:0] observed_out_tile;

    wire act_req_fire_tb;
    wire act_output_blocked;
    wire out_fire_tb;

    assign act_req_fire_tb = act_req_valid && act_req_ready;
    assign act_output_blocked = act_vec_valid && !act_vec_ready;
    assign out_fire_tb = out_valid && out_ready;

    stem_conv_array_4x4 dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .oc_base(oc_base),
        .tile_t_base(tile_t_base),
        .act_req_valid(act_req_valid),
        .act_req_t_base(act_req_t_base),
        .act_req_k(act_req_k),
        .act_req_ready(act_req_ready),
        .act_vec_valid(act_vec_valid),
        .act_vec_ready(act_vec_ready),
        .act_vec(act_vec),
        .w_fold_we(w_fold_we),
        .w_fold_oc(w_fold_oc),
        .w_fold_wdata(w_fold_wdata),
        .bias_fold_we(bias_fold_we),
        .bias_fold_oc(bias_fold_oc),
        .bias_fold_wdata(bias_fold_wdata),
        .out_ready(out_ready),
        .busy(busy),
        .done(done),
        .out_valid(out_valid),
        .out_tile_t_base(out_tile_t_base),
        .out_tile_oc_base(out_tile_oc_base),
        .out_tile(out_tile)
    );

    initial begin
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/stem_conv_array_4x4/testdata/raw_input.mem"},
            file_raw_input
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/stem_conv_array_4x4/testdata/case_oc_base.mem"},
            file_case_oc_base
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/stem_conv_array_4x4/testdata/case_t_base.mem"},
            file_case_t_base
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/stem_conv_array_4x4/testdata/expected_top_checkpoint.mem"},
            file_expected_top
        );
    end

    always #5 clk = ~clk;

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_req_ready <= 1'b1;
            ready_cycle <= 0;
        end else if (busy) begin
            ready_cycle <= ready_cycle + 1;
            case (stall_mode)
                STALL_NONE: begin
                    act_req_ready <= !act_output_blocked;
                end

                STALL_PERIODIC: begin
                    act_req_ready <= ((ready_cycle % 7) != 3) && !act_output_blocked;
                end

                STALL_LATE: begin
                    act_req_ready <= (ready_cycle >= 5) && !act_output_blocked;
                end

                default: begin
                    act_req_ready <= !act_output_blocked;
                end
            endcase
        end else begin
            ready_cycle <= 0;
            act_req_ready <= !act_output_blocked;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_vec_valid <= 1'b0;
            act_vec <= {(ROWS*DATA_W){1'b0}};
            act_req_count <= 0;
        end else begin
            if (act_vec_valid && !act_vec_ready) begin
                act_vec_valid <= act_vec_valid;
                act_vec <= act_vec;
            end else if (act_req_fire_tb) begin
                if (act_req_t_base !== test_t_base[TIME_W-1:0]) begin
                    $display(
                        "ERROR act_req_t_base got=%0d expected=%0d",
                        act_req_t_base,
                        test_t_base
                    );
                    errors = errors + 1;
                end
                if (act_req_k !== act_req_count[5:0]) begin
                    $display(
                        "ERROR act_req_k got=%0d expected=%0d",
                        act_req_k,
                        act_req_count
                    );
                    errors = errors + 1;
                end
                act_req_count = act_req_count + 1;
                act_vec_valid <= 1'b1;
                for (av = 0; av < ROWS; av = av + 1) begin
                    act_vec[av*DATA_W +: DATA_W] <= input_value(av, act_req_k);
                end
            end else begin
                act_vec_valid <= 1'b0;
                act_vec <= {(ROWS*DATA_W){1'b0}};
            end
        end
    end

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_ready <= 1'b1;
            out_ready_count <= 0;
            out_ready_delay_active <= 0;
        end else if (!out_valid) begin
            out_ready <= 1'b1;
            out_ready_count <= 0;
            out_ready_delay_active <= 0;
        end else if ((out_ready_delay > 0) && !out_ready_delay_active) begin
            out_ready <= 1'b0;
            out_ready_count <= 1;
            out_ready_delay_active <= 1;
        end else if (out_ready_delay_active && (out_ready_count < out_ready_delay)) begin
            out_ready <= 1'b0;
            out_ready_count <= out_ready_count + 1;
        end else begin
            out_ready <= 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            observed_out_valid <= 1'b0;
            observed_out_tile_t_base <= {TIME_W{1'b0}};
            observed_out_tile_oc_base <= 5'd0;
            observed_out_tile <= {(ROWS*OC_LANES*DATA_W){1'b0}};
        end else if (out_fire_tb) begin
            observed_out_valid <= 1'b1;
            observed_out_tile_t_base <= out_tile_t_base;
            observed_out_tile_oc_base <= out_tile_oc_base;
            observed_out_tile <= out_tile;
        end
    end

    function signed [DATA_W-1:0] get_out;
        input integer row;
        input integer col;
        begin
            get_out = observed_out_tile[(row*OC_LANES + col)*DATA_W +: DATA_W];
        end
    endfunction

    function signed [DATA_W-1:0] input_value;
        input integer row;
        input integer idx;
        integer in_ch;
        integer tap;
        integer in_t;
        begin
            in_ch = idx / 7;
            tap = idx % 7;
            in_t = test_t_base + row + tap - 3;
            if ((in_t < 0) || (in_t >= INPUT_LEN)) begin
                input_value = 16'sd0;
            end else begin
                input_value = file_raw_input[in_t*STEM_IC + in_ch];
            end
        end
    endfunction

    task load_expected;
        begin
            for (r = 0; r < ROWS; r = r + 1) begin
                for (c = 0; c < OC_LANES; c = c + 1) begin
                    expected[r][c] =
                        file_expected_top[top_case_idx*ROWS*OC_LANES + r*OC_LANES + c];
                end
            end
        end
    endtask

    task launch_tile;
        begin
            @(negedge clk);
            observed_out_valid = 1'b0;
            observed_out_tile_t_base = {TIME_W{1'b0}};
            observed_out_tile_oc_base = 5'd0;
            observed_out_tile = {(ROWS*OC_LANES*DATA_W){1'b0}};
            act_req_count = 0;
            start = 1'b1;
            oc_base = test_oc_base[4:0];
            tile_t_base = test_t_base[TIME_W-1:0];
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_for_done;
        integer timeout;
        begin
            timeout = 0;
            last_timeout = 0;
            while ((done !== 1'b1) && (timeout < DONE_TIMEOUT)) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end

            if (done !== 1'b1) begin
                $display(
                    "ERROR timeout waiting for done oc_base=%0d t_base=%0d stall=%0d",
                    test_oc_base,
                    test_t_base,
                    stall_mode
                );
                errors = errors + 1;
                last_timeout = 1;
            end
        end
    endtask

    task check_outputs;
        begin
            if (act_req_count != STEM_K) begin
                $display("ERROR act_req_count got=%0d expected=%0d", act_req_count, STEM_K);
                errors = errors + 1;
            end
            if (observed_out_valid !== 1'b1) begin
                $display("ERROR no output tile was accepted by out_ready");
                errors = errors + 1;
            end
            if (observed_out_tile_t_base !== test_t_base[TIME_W-1:0]) begin
                $display(
                    "ERROR out_tile_t_base got=%0d expected=%0d",
                    observed_out_tile_t_base,
                    test_t_base
                );
                errors = errors + 1;
            end
            if (observed_out_tile_oc_base !== test_oc_base[4:0]) begin
                $display(
                    "ERROR out_tile_oc_base got=%0d expected=%0d",
                    observed_out_tile_oc_base,
                    test_oc_base
                );
                errors = errors + 1;
            end
            for (r = 0; r < ROWS; r = r + 1) begin
                for (c = 0; c < OC_LANES; c = c + 1) begin
                    if (get_out(r, c) !== expected[r][c]) begin
                        $display(
                            "ERROR row=%0d col=%0d got=%0d expected=%0d",
                            r,
                            c,
                            $signed(get_out(r, c)),
                            $signed(expected[r][c])
                        );
                        errors = errors + 1;
                    end
                end
            end
        end
    endtask

    task run_checked_tile;
        input integer case_idx;
        input integer oc_base_i;
        input integer t_base_i;
        input integer stall_i;
        begin
            top_case_idx = case_idx;
            test_oc_base = oc_base_i;
            test_t_base = t_base_i;
            stall_mode = stall_i;
            load_expected();
            launch_tile();
            wait_for_done();
            if (!last_timeout) begin
                check_outputs();
            end
        end
    endtask

    task run_file_cases;
        integer case_i;
        begin
            for (case_i = 0; case_i < FILE_CASES; case_i = case_i + 1) begin
                file_case_idx = case_i;
                run_checked_tile(
                    case_i,
                    file_case_oc_base[case_i],
                    file_case_t_base[case_i],
                    (case_i % 2) ? STALL_PERIODIC : STALL_NONE
                );
            end
        end
    endtask

    task run_back_to_back_tiles;
        begin
            run_checked_tile(4, 4, 37, STALL_NONE);
            run_checked_tile(5, 8, 48, STALL_NONE);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        oc_base = 5'd0;
        tile_t_base = {TIME_W{1'b0}};
        act_req_ready = 1'b1;
        act_vec_valid = 1'b0;
        act_vec = {(ROWS*DATA_W){1'b0}};
        w_fold_we = 1'b0;
        w_fold_oc = 5'd0;
        w_fold_wdata = 16'sd0;
        bias_fold_we = 1'b0;
        bias_fold_oc = 5'd0;
        bias_fold_wdata = 16'sd0;
        out_ready = 1'b1;
        out_ready_delay = 0;
        out_ready_count = 0;
        out_ready_delay_active = 0;
        observed_out_valid = 1'b0;
        observed_out_tile_t_base = {TIME_W{1'b0}};
        observed_out_tile_oc_base = 5'd0;
        observed_out_tile = {(ROWS*OC_LANES*DATA_W){1'b0}};
        test_oc_base = 0;
        test_t_base = 0;
        stall_mode = STALL_NONE;
        ready_cycle = 0;
        act_req_count = 0;
        last_timeout = 0;
        file_case_idx = 0;
        top_case_idx = 0;
        errors = 0;

        repeat (5) @(negedge clk);
        rst_n = 1'b1;

        run_file_cases();
        run_back_to_back_tiles();
        run_checked_tile(6, 0, 0, STALL_NONE);
        run_checked_tile(7, 28, 340, STALL_LATE);

        out_ready_delay = 4;
        run_checked_tile(8, 12, 128, STALL_PERIODIC);
        out_ready_delay = 0;

        if (errors == 0) begin
            $display("PASS stem_conv_array_4x4 top self-check");
            $finish;
        end else begin
            $display("FAIL stem_conv_array_4x4 top errors=%0d", errors);
            $finish;
        end
    end

endmodule
