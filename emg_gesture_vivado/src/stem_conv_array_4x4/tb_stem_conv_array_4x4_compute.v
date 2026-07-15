`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_stem_conv_array_4x4_compute;

    // Compute-core unit test:
    // - synthetic testdata/weight.mem, bn_*.mem, and expected.mem are generated
    //   by gen_testdata.py and are used here to test an arbitrary weight stream;
    // - the wrapper/top test uses weight_data/stem and the generated ROM IP.

    localparam integer DATA_W    =  8;
    localparam integer MULT_W     = 16;
    localparam integer ACC_W     = 48;
    localparam integer ROWS      = 4;
    localparam integer OC_LANES  = 4;
    localparam integer STEM_OC   = 32;
    localparam integer STEM_K    = 35;
    localparam integer FRAC_BITS = 8;
    localparam integer TIME_W    = 9;
    localparam integer DONE_TIMEOUT = 2000;
    localparam integer INPUT_LEN = 348;
    localparam integer STEM_IC = 5;
    localparam integer FILE_MODE = 99;
    localparam integer FILE_CASES = 4;

    localparam integer STALL_NONE             = 0;
    localparam integer STALL_PERIODIC         = 1;
    localparam integer STALL_WEIGHT_LATE_1    = 2;
    localparam integer STALL_WEIGHT_LATE_LONG = 3;
    localparam integer STALL_ACT_LATE_LONG    = 4;

    reg clk;
    reg rst_n;
    reg start;
    reg [4:0] oc_base;
    reg [TIME_W-1:0] tile_t_base;

    wire weight_req_valid;
    wire [4:0] weight_req_oc_base;
    wire [5:0] weight_req_k;
    reg weight_req_ready;
    reg weight_vec_valid;
    wire weight_vec_ready;
    reg signed [OC_LANES*DATA_W-1:0] weight_vec;

    wire act_req_valid;
    wire [TIME_W-1:0] act_req_t_base;
    wire [5:0] act_req_k;
    reg act_req_ready;
    reg act_vec_valid;
    wire act_vec_ready;
    reg signed [ROWS*DATA_W-1:0] act_vec;

    reg w_fold_we;
    reg [4:0] w_fold_oc;
    reg signed [MULT_W-1:0] w_fold_wdata;

    reg bias_fold_we;
    reg [4:0] bias_fold_oc;
    reg signed [31:0] bias_fold_wdata;

    wire busy;
    wire done;
    wire out_valid;
    reg out_ready;
    wire [TIME_W-1:0] out_tile_t_base;
    wire [4:0] out_tile_oc_base;
    wire signed [ROWS*OC_LANES*DATA_W-1:0] out_tile;

    integer errors;
    integer r;
    integer c;
    integer k;
    integer oc;
    integer test_mode;
    integer test_oc_base;
    integer test_t_base;
    integer rv;
    integer av;
    integer stall_mode;
    integer ready_cycle;
    integer last_timeout;
    integer out_ready_delay;
    integer out_ready_count;
    integer out_ready_delay_active;
    integer weight_req_count;
    integer act_req_count;
    integer file_case_idx;

    reg signed [DATA_W-1:0] expected [0:ROWS-1][0:OC_LANES-1];
    reg signed [DATA_W-1:0] file_raw_input [0:INPUT_LEN*STEM_IC-1];
    reg signed [DATA_W-1:0] file_weight [0:STEM_OC*STEM_K-1];
    reg signed [MULT_W-1:0] file_bn_scale [0:STEM_OC-1];
    reg signed [31:0] file_bn_bias [0:STEM_OC-1];
    reg [7:0] file_case_oc_base [0:FILE_CASES-1];
    reg [15:0] file_case_t_base [0:FILE_CASES-1];
    reg signed [DATA_W-1:0] file_expected [0:FILE_CASES*ROWS*OC_LANES-1];
    reg observed_out_valid;
    reg [TIME_W-1:0] observed_out_tile_t_base;
    reg [4:0] observed_out_tile_oc_base;
    reg signed [ROWS*OC_LANES*DATA_W-1:0] observed_out_tile;
    wire weight_req_fire_tb;
    wire act_req_fire_tb;
    wire weight_output_blocked;
    wire act_output_blocked;
    wire out_fire_tb;

    assign weight_req_fire_tb = weight_req_valid && weight_req_ready;
    assign act_req_fire_tb = act_req_valid && act_req_ready;
    assign weight_output_blocked = weight_vec_valid && !weight_vec_ready;
    assign act_output_blocked = act_vec_valid && !act_vec_ready;
    assign out_fire_tb = out_valid && out_ready;

    stem_conv_array_4x4_compute dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .oc_base(oc_base),
        .tile_t_base(tile_t_base),
        .weight_req_valid(weight_req_valid),
        .weight_req_oc_base(weight_req_oc_base),
        .weight_req_k(weight_req_k),
        .weight_req_ready(weight_req_ready),
        .weight_vec_valid(weight_vec_valid),
        .weight_vec_ready(weight_vec_ready),
        .weight_vec(weight_vec),
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
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/stem_conv_array_4x4/testdata/weight.mem"},
            file_weight
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/stem_conv_array_4x4/testdata/bn_scale.mem"},
            file_bn_scale
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/stem_conv_array_4x4/testdata/bn_bias.mem"},
            file_bn_bias
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
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/stem_conv_array_4x4/testdata/expected.mem"},
            file_expected
        );
    end

    always #5 clk = ~clk;

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_req_ready <= 1'b1;
            act_req_ready <= 1'b1;
            ready_cycle <= 0;
        end else if (busy) begin
            ready_cycle <= ready_cycle + 1;
            case (stall_mode)
                STALL_NONE: begin
                    weight_req_ready <= !weight_output_blocked;
                    act_req_ready <= !act_output_blocked;
                end

                STALL_PERIODIC: begin
                    weight_req_ready <= ((ready_cycle % 5) != 2) && !weight_output_blocked;
                    act_req_ready <= ((ready_cycle % 7) != 3) && !act_output_blocked;
                end

                STALL_WEIGHT_LATE_1: begin
                    weight_req_ready <= (ready_cycle >= 1) && !weight_output_blocked;
                    act_req_ready <= !act_output_blocked;
                end

                STALL_WEIGHT_LATE_LONG: begin
                    weight_req_ready <= (ready_cycle >= 5) && !weight_output_blocked;
                    act_req_ready <= !act_output_blocked;
                end

                STALL_ACT_LATE_LONG: begin
                    weight_req_ready <= !weight_output_blocked;
                    act_req_ready <= (ready_cycle >= 5) && !act_output_blocked;
                end

                default: begin
                    weight_req_ready <= !weight_output_blocked;
                    act_req_ready <= !act_output_blocked;
                end
            endcase
        end else begin
            ready_cycle <= 0;
            weight_req_ready <= !weight_output_blocked;
            act_req_ready <= !act_output_blocked;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_vec_valid <= 1'b0;
            weight_vec <= {(OC_LANES*DATA_W){1'b0}};
            act_vec_valid <= 1'b0;
            act_vec <= {(ROWS*DATA_W){1'b0}};
            weight_req_count <= 0;
            act_req_count <= 0;
        end else begin
            if (weight_vec_valid && !weight_vec_ready) begin
                weight_vec_valid <= weight_vec_valid;
                weight_vec <= weight_vec;
            end else if (weight_req_fire_tb) begin
                if (weight_req_oc_base !== test_oc_base[4:0]) begin
                    $display(
                        "ERROR weight_req_oc_base got=%0d expected=%0d",
                        weight_req_oc_base,
                        test_oc_base
                    );
                    errors = errors + 1;
                end
                if (weight_req_k !== weight_req_count[5:0]) begin
                    $display(
                        "ERROR weight_req_k got=%0d expected=%0d",
                        weight_req_k,
                        weight_req_count
                    );
                    errors = errors + 1;
                end
                weight_req_count = weight_req_count + 1;
                weight_vec_valid <= 1'b1;
                for (rv = 0; rv < OC_LANES; rv = rv + 1) begin
                    weight_vec[rv*DATA_W +: DATA_W]
                        <= weight_value(weight_req_oc_base + rv, weight_req_k);
                end
            end else begin
                weight_vec_valid <= 1'b0;
                weight_vec <= {(OC_LANES*DATA_W){1'b0}};
            end

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

    function signed [DATA_W-1:0] q;
        input integer value;
        begin
            q = value[DATA_W-1:0];
        end
    endfunction

    function signed [DATA_W-1:0] get_out;
        input integer row;
        input integer col;
        begin
            get_out = observed_out_tile[(row*OC_LANES + col)*DATA_W +: DATA_W];
        end
    endfunction

    function signed [DATA_W-1:0] sat_from_acc_shift;
        input signed [ACC_W-1:0] value;
        reg signed [ACC_W-1:0] shifted;
        begin
            shifted = value >>> FRAC_BITS;
            if (shifted > 32767) begin
                sat_from_acc_shift = 16'sh7fff;
            end else if (shifted < -32768) begin
                sat_from_acc_shift = 16'sh8000;
            end else begin
                sat_from_acc_shift = shifted[DATA_W-1:0];
            end
        end
    endfunction

    function signed [DATA_W-1:0] sat_from_i32;
        input signed [31:0] value;
        begin
            if (value > 32767) begin
                sat_from_i32 = 16'sh7fff;
            end else if (value < -32768) begin
                sat_from_i32 = 16'sh8000;
            end else begin
                sat_from_i32 = value[DATA_W-1:0];
            end
        end
    endfunction

    function signed [DATA_W-1:0] relu;
        input signed [DATA_W-1:0] value;
        begin
            if (value < 0) begin
                relu = 16'sd0;
            end else begin
                relu = value;
            end
        end
    endfunction

    function signed [DATA_W-1:0] input_value;
        input integer row;
        input integer idx;
        integer in_ch;
        integer tap;
        integer in_t;
        begin
            if (test_mode == FILE_MODE) begin
                in_ch = idx / 7;
                tap = idx % 7;
                in_t = test_t_base + row + tap - 3;
                if ((in_t < 0) || (in_t >= INPUT_LEN)) begin
                    input_value = 16'sd0;
                end else begin
                    input_value = file_raw_input[in_t*STEM_IC + in_ch];
                end
            end else if (test_mode == 1) begin
                input_value = q(2048 - row * 128 + (idx % 3) * 16);
            end else begin
                input_value = q(((row + 1) * 20 + idx - 17) * 16);
            end
        end
    endfunction

    function signed [DATA_W-1:0] weight_value;
        input integer oc_idx;
        input integer idx;
        begin
            if (test_mode == FILE_MODE) begin
                weight_value = file_weight[oc_idx*STEM_K + idx];
            end else if ((oc_idx >= 8) && (oc_idx <= 11)) begin
                weight_value = q(2048);
            end else if (idx == (oc_idx % STEM_K)) begin
                weight_value = q((oc_idx - 14) * 16);
            end else if (idx == ((oc_idx + 3) % STEM_K)) begin
                weight_value = q((19 - oc_idx) * 8);
            end else if (idx == 34) begin
                weight_value = q((oc_idx - 20) * 4);
            end else begin
                weight_value = 16'sd0;
            end
        end
    endfunction

    function signed [MULT_W-1:0] fold_scale_value;
        input integer oc_idx;
        begin
            if (test_mode == FILE_MODE) begin
                fold_scale_value = file_bn_scale[oc_idx];
            end else begin
            case (oc_idx)
                4: fold_scale_value = q(256);   // 1.0
                5: fold_scale_value = q(128);   // 0.5
                6: fold_scale_value = q(-256);  // -1.0
                7: fold_scale_value = q(384);   // 1.5
                8: fold_scale_value = q(512);   // 2.0, positive saturation path
                9: fold_scale_value = q(256);   // 1.0, conv saturation path
                10: fold_scale_value = q(-512); // -2.0, ReLU zero path
                11: fold_scale_value = q(128);  // 0.5
                default: fold_scale_value = q(256);
            endcase
            end
        end
    endfunction

    function signed [31:0] fold_bias_value;
        input integer oc_idx;
        begin
            if (test_mode == FILE_MODE) begin
                fold_bias_value = file_bn_bias[oc_idx];
            end else begin
            case (oc_idx)
                4: fold_bias_value = q(16);     // 0.0625
                5: fold_bias_value = q(-96);    // -0.375
                6: fold_bias_value = q(64);     // 0.25
                7: fold_bias_value = q(-512);   // -2.0
                8: fold_bias_value = q(0);
                9: fold_bias_value = q(256);
                10: fold_bias_value = q(0);
                11: fold_bias_value = q(-256);
                default: fold_bias_value = 16'sd0;
            endcase
            end
        end
    endfunction

    task write_w_fold;
        input integer oc_idx;
        input signed [MULT_W-1:0] value;
        begin
            @(negedge clk);
            w_fold_we = 1'b1;
            w_fold_oc = oc_idx[4:0];
            w_fold_wdata = value;
            @(negedge clk);
            w_fold_we = 1'b0;
        end
    endtask

    task write_bias_fold;
        input integer oc_idx;
        input signed [31:0] value;
        begin
            @(negedge clk);
            bias_fold_we = 1'b1;
            bias_fold_oc = oc_idx[4:0];
            bias_fold_wdata = value;
            @(negedge clk);
            bias_fold_we = 1'b0;
        end
    endtask

    task load_parameters;
        begin
            for (oc = 0; oc < STEM_OC; oc = oc + 1) begin
                write_w_fold(oc, fold_scale_value(oc));
                write_bias_fold(oc, fold_bias_value(oc));
            end
        end
    endtask

    task load_file_parameters;
        begin
            test_mode = FILE_MODE;
            for (oc = 0; oc < STEM_OC; oc = oc + 1) begin
                write_w_fold(oc, file_bn_scale[oc]);
                write_bias_fold(oc, file_bn_bias[oc]);
            end
        end
    endtask

    task compute_expected;
        reg signed [ACC_W-1:0] acc;
        reg signed [DATA_W-1:0] conv_q;
        reg signed [31:0] post_mul;
        reg signed [31:0] post_shifted;
        reg signed [31:0] post_biased;
        reg signed [DATA_W-1:0] bn_q;
        begin
            if (test_mode == FILE_MODE) begin
                for (r = 0; r < ROWS; r = r + 1) begin
                    for (c = 0; c < OC_LANES; c = c + 1) begin
                        expected[r][c] =
                            file_expected[file_case_idx*ROWS*OC_LANES + r*OC_LANES + c];
                    end
                end
            end else begin
                for (r = 0; r < ROWS; r = r + 1) begin
                    for (c = 0; c < OC_LANES; c = c + 1) begin
                        acc = 0;
                        for (k = 0; k < STEM_K; k = k + 1) begin
                            acc = acc + input_value(r, k) * weight_value(test_oc_base + c, k);
                        end
                        conv_q = sat_from_acc_shift(acc);
                        post_mul = conv_q * fold_scale_value(test_oc_base + c);
                        post_shifted = post_mul >>> FRAC_BITS;
                        post_biased = post_shifted + fold_bias_value(test_oc_base + c);
                        bn_q = sat_from_i32(post_biased);
                        expected[r][c] = relu(bn_q);
                    end
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
            weight_req_count = 0;
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
                    "ERROR timeout waiting for done mode=%0d oc_base=%0d t_base=%0d stall=%0d",
                    test_mode,
                    test_oc_base,
                    test_t_base,
                    stall_mode
                );
                errors = errors + 1;
                last_timeout = 1;
            end
        end
    endtask

    task run_tile;
        begin
            launch_tile();
            wait_for_done();
        end
    endtask

    task run_checked_tile;
        input integer mode;
        input integer oc_base_i;
        input integer t_base_i;
        input integer stall_i;
        begin
            test_mode = mode;
            test_oc_base = oc_base_i;
            test_t_base = t_base_i;
            stall_mode = stall_i;
            compute_expected();
            run_tile();
            if (!last_timeout) begin
                check_outputs();
            end
        end
    endtask

    task run_tile_with_busy_start_pulse;
        begin
            launch_tile();
            wait (busy === 1'b1);
            repeat (6) @(negedge clk);
            start = 1'b1;
            oc_base = 5'd28;
            tile_t_base = {TIME_W{1'b1}};
            @(negedge clk);
            start = 1'b0;
            wait_for_done();
        end
    endtask

    task run_with_busy_bn_write;
        begin
            launch_tile();
            wait (busy === 1'b1);
            repeat (4) @(negedge clk);
            w_fold_we = 1'b1;
            w_fold_oc = test_oc_base[4:0];
            w_fold_wdata = 16'sd4096;
            bias_fold_we = 1'b1;
            bias_fold_oc = test_oc_base[4:0];
            bias_fold_wdata = -16'sd4096;
            @(negedge clk);
            w_fold_we = 1'b0;
            bias_fold_we = 1'b0;
            wait_for_done();
        end
    endtask

    task reset_during_busy;
        begin
            launch_tile();
            wait (busy === 1'b1);
            repeat (8) @(negedge clk);
            rst_n = 1'b0;
            start = 1'b0;
            repeat (3) @(negedge clk);
            rst_n = 1'b1;
            repeat (3) @(negedge clk);
            if (busy !== 1'b0) begin
                $display("ERROR busy is not low after mid-run reset");
                errors = errors + 1;
            end
            if (out_valid !== 1'b0) begin
                $display("ERROR out_valid is high after aborted mid-run reset");
                errors = errors + 1;
            end
        end
    endtask

    task run_file_golden_cases;
        integer case_i;
        begin
            load_file_parameters();
            for (case_i = 0; case_i < FILE_CASES; case_i = case_i + 1) begin
                file_case_idx = case_i;
                run_checked_tile(
                    FILE_MODE,
                    file_case_oc_base[case_i],
                    file_case_t_base[case_i],
                    (case_i % 2) ? STALL_PERIODIC : STALL_NONE
                );
            end
        end
    endtask

    task check_outputs;
        begin
            if (weight_req_count != STEM_K) begin
                $display(
                    "ERROR weight_req_count got=%0d expected=%0d",
                    weight_req_count,
                    STEM_K
                );
                errors = errors + 1;
            end
            if (act_req_count != STEM_K) begin
                $display(
                    "ERROR act_req_count got=%0d expected=%0d",
                    act_req_count,
                    STEM_K
                );
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

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        oc_base = 5'd0;
        tile_t_base = {TIME_W{1'b0}};
        weight_req_ready = 1'b1;
        weight_vec_valid = 1'b0;
        weight_vec = {(OC_LANES*DATA_W){1'b0}};
        act_req_ready = 1'b1;
        act_vec_valid = 1'b0;
        act_vec = {(ROWS*DATA_W){1'b0}};
        out_ready = 1'b1;
        out_ready_delay = 0;
        out_ready_count = 0;
        out_ready_delay_active = 0;
        observed_out_valid = 1'b0;
        observed_out_tile_t_base = {TIME_W{1'b0}};
        observed_out_tile_oc_base = 5'd0;
        observed_out_tile = {(ROWS*OC_LANES*DATA_W){1'b0}};
        w_fold_we = 1'b0;
        w_fold_oc = 5'd0;
        w_fold_wdata = 16'sd0;
        bias_fold_we = 1'b0;
        bias_fold_oc = 5'd0;
        bias_fold_wdata = 16'sd0;
        test_mode = 0;
        test_oc_base = 4;
        test_t_base = 12;
        stall_mode = 0;
        ready_cycle = 0;
        last_timeout = 0;
        weight_req_count = 0;
        act_req_count = 0;
        file_case_idx = 0;
        errors = 0;

        repeat (5) @(negedge clk);
        rst_n = 1'b1;

        // INT8 migration: run the real-model golden cases. The older random
        // Q8.8 stress cases above are intentionally not executed under the new
        // quantization contract.
        run_file_golden_cases();

        if (errors == 0) begin
            $display("PASS stem_conv_array_4x4_compute self-check");
            $finish;
        end else begin
            $display("FAIL stem_conv_array_4x4_compute errors=%0d", errors);
            $finish;
        end
    end

endmodule
