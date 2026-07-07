`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_fc_classifier_96_5;

    localparam integer DATA_W        = 16;
    localparam integer GAP_ACC_W     = 48;
    localparam integer ACC_W         = 48;
    localparam integer FC0_IN        = 96;
    localparam integer FC0_OUT       = 96;
    localparam integer FC1_OUT       = 5;
    localparam integer FC0_OUT_LANES = 16;
    localparam integer GAP_LEN       = 174;
    localparam integer FRAC_BITS     = 8;
    localparam integer TIMEOUT       = 5000;

    localparam integer PROFILE_DEFAULT = 0;
    localparam integer PROFILE_TIE     = 1;
    localparam integer PROFILE_FILE    = 99;
    localparam integer FILE_MODE       = 99;
    localparam integer FILE_CASES      = 4;

    reg clk;
    reg rst_n;
    reg start;
    reg [8:0] gap_count;
    reg signed [FC0_IN*GAP_ACC_W-1:0] gap_sum_vec;

    reg fc0_weight_we;
    reg [6:0] fc0_weight_out;
    reg [6:0] fc0_weight_k;
    reg signed [DATA_W-1:0] fc0_weight_wdata;

    reg fc1_weight_we;
    reg [2:0] fc1_weight_out;
    reg [6:0] fc1_weight_k;
    reg signed [DATA_W-1:0] fc1_weight_wdata;

    reg result_ready;
    wire busy;
    wire done;
    wire result_valid;
    wire [2:0] class_idx;
    wire input_count_error;
    wire signed [FC1_OUT*DATA_W-1:0] logits_vec;

    integer errors;
    integer test_mode;
    integer weight_profile;
    integer expected_class;
    integer oc;
    integer k;
    integer cls;
    integer timeout;
    integer file_case_idx;

    reg signed [DATA_W-1:0] expected_avg [0:FC0_IN-1];
    reg signed [DATA_W-1:0] expected_hidden [0:FC0_OUT-1];
    reg signed [DATA_W-1:0] expected_logits [0:FC1_OUT-1];
    reg signed [GAP_ACC_W-1:0] file_gap_sum [0:FILE_CASES*FC0_IN-1];
    reg signed [DATA_W-1:0] file_fc0_weight [0:FC0_OUT*(FC0_IN+1)-1];
    reg signed [DATA_W-1:0] file_fc1_weight [0:FC1_OUT*(FC0_OUT+1)-1];
    reg signed [DATA_W-1:0] file_expected_logits [0:FILE_CASES*FC1_OUT-1];
    reg [7:0] file_expected_class [0:FILE_CASES-1];

    fc_classifier_96_5 #(
        .DATA_W(DATA_W),
        .GAP_ACC_W(GAP_ACC_W),
        .ACC_W(ACC_W),
        .FC0_IN(FC0_IN),
        .FC0_OUT(FC0_OUT),
        .FC1_OUT(FC1_OUT),
        .FC0_OUT_LANES(FC0_OUT_LANES),
        .GAP_LEN(GAP_LEN),
        .FRAC_BITS(FRAC_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .gap_count(gap_count),
        .gap_sum_vec(gap_sum_vec),
        .fc0_weight_we(fc0_weight_we),
        .fc0_weight_out(fc0_weight_out),
        .fc0_weight_k(fc0_weight_k),
        .fc0_weight_wdata(fc0_weight_wdata),
        .fc1_weight_we(fc1_weight_we),
        .fc1_weight_out(fc1_weight_out),
        .fc1_weight_k(fc1_weight_k),
        .fc1_weight_wdata(fc1_weight_wdata),
        .result_ready(result_ready),
        .busy(busy),
        .done(done),
        .result_valid(result_valid),
        .class_idx(class_idx),
        .input_count_error(input_count_error),
        .logits_vec(logits_vec)
    );

    initial begin
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/fc_classifier_96_5/testdata/gap_sum.mem"},
            file_gap_sum
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/fc_classifier_96_5/testdata/fc0_weight.mem"},
            file_fc0_weight
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/fc_classifier_96_5/testdata/fc1_weight.mem"},
            file_fc1_weight
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/fc_classifier_96_5/testdata/expected_logits.mem"},
            file_expected_logits
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/fc_classifier_96_5/testdata/expected_class.mem"},
            file_expected_class
        );
    end

    always #5 clk = ~clk;

    function signed [DATA_W-1:0] q;
        input integer value;
        begin
            q = value[DATA_W-1:0];
        end
    endfunction

    function signed [ACC_W-1:0] bias_to_acc_tb;
        input signed [DATA_W-1:0] value;
        reg signed [ACC_W-1:0] extended;
        begin
            extended = $signed({{(ACC_W-DATA_W){value[DATA_W-1]}}, value});
            bias_to_acc_tb = extended <<< FRAC_BITS;
        end
    endfunction

    function signed [ACC_W-1:0] mul_to_acc_tb;
        input signed [DATA_W-1:0] a;
        input signed [DATA_W-1:0] b;
        reg signed [31:0] product;
        begin
            product = a * b;
            mul_to_acc_tb = $signed({{(ACC_W-32){product[31]}}, product});
        end
    endfunction

    function signed [DATA_W-1:0] sat_gap_avg_tb;
        input signed [GAP_ACC_W-1:0] value;
        begin
            if (value > 32767) begin
                sat_gap_avg_tb = 16'sh7fff;
            end else if (value < -32768) begin
                sat_gap_avg_tb = 16'sh8000;
            end else begin
                sat_gap_avg_tb = value[DATA_W-1:0];
            end
        end
    endfunction

    function signed [DATA_W-1:0] sat_acc_shift_tb;
        input signed [ACC_W-1:0] value;
        reg signed [ACC_W-1:0] shifted;
        begin
            shifted = value >>> FRAC_BITS;
            if (shifted > 32767) begin
                sat_acc_shift_tb = 16'sh7fff;
            end else if (shifted < -32768) begin
                sat_acc_shift_tb = 16'sh8000;
            end else begin
                sat_acc_shift_tb = shifted[DATA_W-1:0];
            end
        end
    endfunction

    function signed [DATA_W-1:0] relu_tb;
        input signed [DATA_W-1:0] value;
        begin
            relu_tb = value[DATA_W-1] ? {DATA_W{1'b0}} : value;
        end
    endfunction

    function signed [GAP_ACC_W-1:0] gap_sum_value;
        input integer mode;
        input integer idx;
        reg signed [GAP_ACC_W-1:0] avg_raw;
        begin
            if (mode == FILE_MODE) begin
                gap_sum_value = file_gap_sum[file_case_idx*FC0_IN + idx];
            end else if (mode == 2) begin
                if ((idx % 8) == 0) begin
                    gap_sum_value = 48'sd6000000;
                end else begin
                    avg_raw = 48'sd40 + (idx % 17) * 48'sd3;
                    gap_sum_value = avg_raw * GAP_LEN + (idx % 11);
                end
            end else if (mode == 1) begin
                avg_raw = 48'sd220 - (idx % 19) * 48'sd7 + (idx % 3);
                gap_sum_value = avg_raw * GAP_LEN + (idx % 5);
            end else begin
                avg_raw = 48'sd24 + (idx % 13) * 48'sd5 + (idx % 4) * 48'sd2;
                gap_sum_value = avg_raw * GAP_LEN + (idx % 7);
            end
        end
    endfunction

    function signed [FC0_IN*GAP_ACC_W-1:0] make_gap_sum_vec;
        input integer mode;
        integer idx;
        begin
            make_gap_sum_vec = {(FC0_IN*GAP_ACC_W){1'b0}};
            for (idx = 0; idx < FC0_IN; idx = idx + 1) begin
                make_gap_sum_vec[idx*GAP_ACC_W +: GAP_ACC_W]
                    = gap_sum_value(mode, idx);
            end
        end
    endfunction

    function signed [DATA_W-1:0] fc0_weight_value;
        input integer profile;
        input integer out_idx;
        input integer k_idx;
        integer v;
        begin
            if (profile == PROFILE_FILE) begin
                fc0_weight_value = file_fc0_weight[out_idx*(FC0_IN+1) + k_idx];
            end else if (profile == PROFILE_TIE) begin
                fc0_weight_value = 16'sd0;
            end else if (k_idx == FC0_IN) begin
                fc0_weight_value = q(((out_idx % 11) - 5) * 20);
            end else begin
                v = ((out_idx % 7) - 3) * ((k_idx % 5) - 2)
                    + ((out_idx + k_idx) % 3) - 1;
                fc0_weight_value = q(v);
            end
        end
    endfunction

    function signed [DATA_W-1:0] fc1_weight_value;
        input integer profile;
        input integer out_idx;
        input integer k_idx;
        integer v;
        begin
            if (profile == PROFILE_FILE) begin
                fc1_weight_value = file_fc1_weight[out_idx*(FC0_OUT+1) + k_idx];
            end else if (profile == PROFILE_TIE) begin
                if (k_idx == FC0_OUT) begin
                    fc1_weight_value = q(300);
                end else begin
                    fc1_weight_value = 16'sd0;
                end
            end else if (k_idx == FC0_OUT) begin
                fc1_weight_value = q(((out_idx % 5) - 2) * 64);
            end else begin
                v = (out_idx + 1) * ((k_idx % 7) - 3)
                    + ((k_idx % 4) - 1) * 2;
                fc1_weight_value = q(v);
            end
        end
    endfunction

    function signed [DATA_W-1:0] get_logit;
        input integer idx;
        begin
            get_logit = logits_vec[idx*DATA_W +: DATA_W];
        end
    endfunction

    task write_fc0_weight;
        input integer out_idx;
        input integer k_idx;
        input signed [DATA_W-1:0] value;
        begin
            @(negedge clk);
            fc0_weight_we = 1'b1;
            fc0_weight_out = out_idx[6:0];
            fc0_weight_k = k_idx[6:0];
            fc0_weight_wdata = value;
            @(negedge clk);
            fc0_weight_we = 1'b0;
        end
    endtask

    task write_fc1_weight;
        input integer out_idx;
        input integer k_idx;
        input signed [DATA_W-1:0] value;
        begin
            @(negedge clk);
            fc1_weight_we = 1'b1;
            fc1_weight_out = out_idx[2:0];
            fc1_weight_k = k_idx[6:0];
            fc1_weight_wdata = value;
            @(negedge clk);
            fc1_weight_we = 1'b0;
        end
    endtask

    task load_weights;
        input integer profile;
        begin
            for (oc = 0; oc < FC0_OUT; oc = oc + 1) begin
                for (k = 0; k <= FC0_IN; k = k + 1) begin
                    write_fc0_weight(oc, k, fc0_weight_value(profile, oc, k));
                end
            end
            for (cls = 0; cls < FC1_OUT; cls = cls + 1) begin
                for (k = 0; k <= FC0_OUT; k = k + 1) begin
                    write_fc1_weight(cls, k, fc1_weight_value(profile, cls, k));
                end
            end
        end
    endtask

    task compute_expected;
        input integer profile;
        input integer mode;
        reg signed [ACC_W-1:0] acc;
        reg signed [DATA_W-1:0] candidate;
        begin
            if (profile == PROFILE_FILE) begin
                for (cls = 0; cls < FC1_OUT; cls = cls + 1) begin
                    expected_logits[cls] =
                        file_expected_logits[file_case_idx*FC1_OUT + cls];
                end
                expected_class = file_expected_class[file_case_idx];
            end else begin
                for (k = 0; k < FC0_IN; k = k + 1) begin
                    expected_avg[k] = sat_gap_avg_tb(gap_sum_value(mode, k) / GAP_LEN);
                end

                for (oc = 0; oc < FC0_OUT; oc = oc + 1) begin
                    acc = bias_to_acc_tb(fc0_weight_value(profile, oc, FC0_IN));
                    for (k = 0; k < FC0_IN; k = k + 1) begin
                        acc = acc + mul_to_acc_tb(
                            expected_avg[k],
                            fc0_weight_value(profile, oc, k)
                        );
                    end
                    expected_hidden[oc] = relu_tb(sat_acc_shift_tb(acc));
                end

                for (cls = 0; cls < FC1_OUT; cls = cls + 1) begin
                    acc = bias_to_acc_tb(fc1_weight_value(profile, cls, FC0_OUT));
                    for (k = 0; k < FC0_OUT; k = k + 1) begin
                        acc = acc + mul_to_acc_tb(
                            expected_hidden[k],
                            fc1_weight_value(profile, cls, k)
                        );
                    end
                    expected_logits[cls] = sat_acc_shift_tb(acc);
                end

                expected_class = 0;
                candidate = expected_logits[0];
                for (cls = 1; cls < FC1_OUT; cls = cls + 1) begin
                    if (expected_logits[cls] > candidate) begin
                        candidate = expected_logits[cls];
                        expected_class = cls;
                    end
                end
            end
        end
    endtask

    task launch;
        input integer mode;
        input integer count_i;
        begin
            @(negedge clk);
            gap_sum_vec = make_gap_sum_vec(mode);
            gap_count = count_i[8:0];
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_result_valid;
        begin
            timeout = 0;
            while ((result_valid !== 1'b1) && (timeout < TIMEOUT)) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end
            if (result_valid !== 1'b1) begin
                $display("ERROR FC timeout waiting result_valid");
                errors = errors + 1;
            end
        end
    endtask

    task wait_done;
        begin
            timeout = 0;
            while ((done !== 1'b1) && (timeout < TIMEOUT)) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end
            if (done !== 1'b1) begin
                $display("ERROR FC timeout waiting done");
                errors = errors + 1;
            end
        end
    endtask

    task check_outputs;
        input integer expect_count_error;
        begin
            if (class_idx !== expected_class[2:0]) begin
                $display(
                    "ERROR FC class_idx got=%0d expected=%0d",
                    class_idx,
                    expected_class
                );
                errors = errors + 1;
            end

            if (input_count_error !== expect_count_error[0]) begin
                $display(
                    "ERROR FC input_count_error got=%0d expected=%0d",
                    input_count_error,
                    expect_count_error[0]
                );
                errors = errors + 1;
            end

            for (cls = 0; cls < FC1_OUT; cls = cls + 1) begin
                if (get_logit(cls) !== expected_logits[cls]) begin
                    $display(
                        "ERROR FC logit class=%0d got=%0d expected=%0d",
                        cls,
                        $signed(get_logit(cls)),
                        $signed(expected_logits[cls])
                    );
                    errors = errors + 1;
                end
            end
        end
    endtask

    task run_checked;
        input integer profile;
        input integer mode;
        input integer count_i;
        input integer ready_delay;
        input integer expect_count_error;
        integer hold_i;
        begin
            compute_expected(profile, mode);
            result_ready = (ready_delay == 0);
            launch(mode, count_i);
            wait_result_valid();

            if (result_valid === 1'b1) begin
                check_outputs(expect_count_error);
                for (hold_i = 0; hold_i < ready_delay; hold_i = hold_i + 1) begin
                    @(posedge clk);
                    #1;
                    if (done === 1'b1) begin
                        $display("ERROR FC done asserted while result_ready low");
                        errors = errors + 1;
                    end
                    if (result_valid !== 1'b1) begin
                        $display("ERROR FC result_valid dropped before ready");
                        errors = errors + 1;
                    end
                    check_outputs(expect_count_error);
                end
                result_ready = 1'b1;
                wait_done();
                @(posedge clk);
                #1;
                if (result_valid !== 1'b0) begin
                    $display("ERROR FC result_valid did not clear after done");
                    errors = errors + 1;
                end
            end
        end
    endtask

    task run_with_busy_start_pulse;
        begin
            compute_expected(PROFILE_DEFAULT, 0);
            result_ready = 1'b1;
            launch(0, GAP_LEN);

            repeat (20) @(negedge clk);
            gap_sum_vec = make_gap_sum_vec(1);
            gap_count = GAP_LEN[8:0];
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            wait_result_valid();
            check_outputs(0);
            wait_done();
        end
    endtask

    task run_with_busy_weight_write;
        begin
            compute_expected(PROFILE_DEFAULT, 1);
            result_ready = 1'b1;
            launch(1, GAP_LEN);

            repeat (25) @(negedge clk);
            fc0_weight_we = 1'b1;
            fc0_weight_out = 7'd0;
            fc0_weight_k = 7'd0;
            fc0_weight_wdata = 16'sd32767;
            fc1_weight_we = 1'b1;
            fc1_weight_out = 3'd0;
            fc1_weight_k = 7'd96;
            fc1_weight_wdata = -16'sd32768;
            @(negedge clk);
            fc0_weight_we = 1'b0;
            fc1_weight_we = 1'b0;

            wait_result_valid();
            check_outputs(0);
            wait_done();
        end
    endtask

    task reset_during_busy;
        begin
            result_ready = 1'b1;
            launch(0, GAP_LEN);

            repeat (18) @(negedge clk);
            rst_n = 1'b0;
            start = 1'b0;
            fc0_weight_we = 1'b0;
            fc1_weight_we = 1'b0;
            #1;
            if (busy !== 1'b0) begin
                $display("ERROR FC busy high after reset");
                errors = errors + 1;
            end
            if (result_valid !== 1'b0) begin
                $display("ERROR FC result_valid high after reset");
                errors = errors + 1;
            end

            repeat (2) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

    task run_file_golden_cases;
        integer case_i;
        begin
            load_weights(PROFILE_FILE);
            for (case_i = 0; case_i < FILE_CASES; case_i = case_i + 1) begin
                file_case_idx = case_i;
                run_checked(
                    PROFILE_FILE,
                    FILE_MODE,
                    GAP_LEN,
                    (case_i % 2) ? 4 : 0,
                    0
                );
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        gap_count = 9'd0;
        gap_sum_vec = {(FC0_IN*GAP_ACC_W){1'b0}};
        fc0_weight_we = 1'b0;
        fc0_weight_out = 7'd0;
        fc0_weight_k = 7'd0;
        fc0_weight_wdata = 16'sd0;
        fc1_weight_we = 1'b0;
        fc1_weight_out = 3'd0;
        fc1_weight_k = 7'd0;
        fc1_weight_wdata = 16'sd0;
        result_ready = 1'b1;
        errors = 0;
        test_mode = 0;
        weight_profile = PROFILE_DEFAULT;
        file_case_idx = 0;

        repeat (5) @(negedge clk);
        rst_n = 1'b1;

        load_weights(PROFILE_DEFAULT);

        // Normal end-to-end FC0/ReLU/FC1/argmax path.
        run_checked(PROFILE_DEFAULT, 0, GAP_LEN, 0, 0);

        // Result backpressure must hold logits and class until accepted.
        run_checked(PROFILE_DEFAULT, 1, GAP_LEN, 8, 0);

        // Large GAP sums cover average saturation and downstream arithmetic.
        run_checked(PROFILE_DEFAULT, 2, GAP_LEN, 0, 0);

        // gap_count is checked for integration with PW2, but division is still /174.
        run_checked(PROFILE_DEFAULT, 0, GAP_LEN-1, 0, 1);

        // A stray start while busy must be ignored.
        run_with_busy_start_pulse();

        // Weight writes while busy must be ignored.
        run_with_busy_weight_write();

        // Mid-run reset aborts the job and leaves the module reusable.
        reset_during_busy();
        load_weights(PROFILE_DEFAULT);
        run_checked(PROFILE_DEFAULT, 0, GAP_LEN, 0, 0);

        // Equal logits must pick the lowest class index.
        load_weights(PROFILE_TIE);
        run_checked(PROFILE_TIE, 1, GAP_LEN, 0, 0);

        run_file_golden_cases();

        if (errors == 0) begin
            $display("PASS fc_classifier_96_5 self-check");
            $finish;
        end else begin
            $display("FAIL fc_classifier_96_5 errors=%0d", errors);
            $finish;
        end
    end

endmodule
