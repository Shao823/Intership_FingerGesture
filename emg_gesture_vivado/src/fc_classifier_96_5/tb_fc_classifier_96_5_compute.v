`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_fc_classifier_96_5_compute;

    localparam integer DATA_W        =  8;
    localparam integer MULT_W     = 16;
    localparam integer GAP_ACC_W     = 48;
    localparam integer ACC_W         = 48;
    localparam integer FC0_IN        = 96;
    localparam integer FC0_OUT       = 96;
    localparam integer FC1_OUT       = 5;
    localparam integer FC0_OUT_LANES = 16;
    localparam integer GAP_LEN       = 174;
    localparam integer FRAC_BITS     = 8;
    localparam integer FILE_CASES    = 10;
    localparam integer TIMEOUT       = 12000;

    reg clk;
    reg rst_n;
    reg start;
    reg [8:0] gap_count;
    reg signed [FC0_IN*GAP_ACC_W-1:0] gap_sum_vec;

    wire weight_req_valid;
    wire weight_req_layer;
    wire [6:0] weight_req_oc_base;
    wire [6:0] weight_req_k;
    wire weight_req_ready;
    reg weight_vec_valid;
    wire weight_vec_ready;
    reg signed [FC0_OUT_LANES*DATA_W-1:0] weight_vec;

    reg result_ready;
    wire busy;
    wire done;
    wire result_valid;
    wire [2:0] class_idx;
    wire input_count_error;
    wire signed [FC1_OUT*DATA_W-1:0] logits_vec;

    integer errors;
    integer current_case;
    integer case_i;
    integer cls;
    integer timeout;
    integer hold_i;

    reg signed [GAP_ACC_W-1:0] file_gap_sum [0:FILE_CASES*FC0_IN-1];
    reg signed [DATA_W-1:0] file_fc0_weight [0:FC0_OUT*(FC0_IN+1)-1];
    reg signed [DATA_W-1:0] file_fc1_weight [0:FC1_OUT*(FC0_OUT+1)-1];
    reg signed [DATA_W-1:0] file_expected_logits [0:FILE_CASES*FC1_OUT-1];
    reg [7:0] file_expected_class [0:FILE_CASES-1];

    assign weight_req_ready = !weight_vec_valid;

    fc_classifier_96_5_compute #(
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
        .weight_req_valid(weight_req_valid),
        .weight_req_layer(weight_req_layer),
        .weight_req_oc_base(weight_req_oc_base),
        .weight_req_k(weight_req_k),
        .weight_req_ready(weight_req_ready),
        .weight_vec_valid(weight_vec_valid),
        .weight_vec_ready(weight_vec_ready),
        .weight_vec(weight_vec),
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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_vec_valid <= 1'b0;
            weight_vec <= {(FC0_OUT_LANES*DATA_W){1'b0}};
        end else begin
            if (weight_vec_valid && weight_vec_ready) begin
                weight_vec_valid <= 1'b0;
            end
            if (!weight_vec_valid && weight_req_valid) begin
                weight_vec <= pack_weight_word(
                    weight_req_layer,
                    weight_req_oc_base,
                    weight_req_k
                );
                weight_vec_valid <= 1'b1;
            end
        end
    end

    function [FC0_OUT_LANES*DATA_W-1:0] pack_weight_word;
        input layer_i;
        input [6:0] oc_base_i;
        input [6:0] k_i;
        integer lane;
        integer out_idx;
        begin
            pack_weight_word = {(FC0_OUT_LANES*DATA_W){1'b0}};
            if (layer_i) begin
                for (lane = 0; lane < FC0_OUT_LANES; lane = lane + 1) begin
                    if (lane < FC1_OUT) begin
                        pack_weight_word[lane*DATA_W +: DATA_W]
                            = file_fc1_weight[lane*(FC0_OUT+1) + k_i];
                    end
                end
            end else begin
                for (lane = 0; lane < FC0_OUT_LANES; lane = lane + 1) begin
                    out_idx = oc_base_i + lane;
                    if (out_idx < FC0_OUT) begin
                        pack_weight_word[lane*DATA_W +: DATA_W]
                            = file_fc0_weight[out_idx*(FC0_IN+1) + k_i];
                    end
                end
            end
        end
    endfunction

    function signed [DATA_W-1:0] get_logit;
        input integer idx;
        begin
            get_logit = logits_vec[idx*DATA_W +: DATA_W];
        end
    endfunction

    task drive_idle_inputs;
        begin
            start = 1'b0;
            gap_count = 9'd0;
            gap_sum_vec = {(FC0_IN*GAP_ACC_W){1'b0}};
            result_ready = 1'b1;
        end
    endtask

    task load_gap_case;
        input integer case_idx;
        integer ch;
        begin
            gap_sum_vec = {(FC0_IN*GAP_ACC_W){1'b0}};
            for (ch = 0; ch < FC0_IN; ch = ch + 1) begin
                gap_sum_vec[ch*GAP_ACC_W +: GAP_ACC_W]
                    = file_gap_sum[case_idx*FC0_IN + ch];
            end
        end
    endtask

    task launch_case;
        input integer case_idx;
        input integer count_i;
        begin
            @(negedge clk);
            current_case = case_idx;
            load_gap_case(case_idx);
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
                $display("ERROR FC compute timeout waiting result_valid case=%0d", current_case);
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
                $display("ERROR FC compute timeout waiting done case=%0d", current_case);
                errors = errors + 1;
            end
        end
    endtask

    task check_outputs;
        input integer expect_count_error;
        begin
            if (class_idx !== file_expected_class[current_case][2:0]) begin
                $display(
                    "ERROR FC compute class case=%0d got=%0d expected=%0d",
                    current_case,
                    class_idx,
                    file_expected_class[current_case]
                );
                errors = errors + 1;
            end
            if (input_count_error !== expect_count_error[0]) begin
                $display(
                    "ERROR FC compute count_error case=%0d got=%0d expected=%0d",
                    current_case,
                    input_count_error,
                    expect_count_error[0]
                );
                errors = errors + 1;
            end
            for (cls = 0; cls < FC1_OUT; cls = cls + 1) begin
                if (get_logit(cls) !== file_expected_logits[current_case*FC1_OUT + cls]) begin
                    $display(
                        "ERROR FC compute logit case=%0d class=%0d got=%0d expected=%0d",
                        current_case,
                        cls,
                        $signed(get_logit(cls)),
                        $signed(file_expected_logits[current_case*FC1_OUT + cls])
                    );
                    errors = errors + 1;
                end
            end
        end
    endtask

    task run_checked;
        input integer case_idx;
        input integer count_i;
        input integer ready_delay;
        input integer expect_count_error;
        begin
            result_ready = (ready_delay == 0);
            launch_case(case_idx, count_i);
            wait_result_valid();
            if (result_valid === 1'b1) begin
                check_outputs(expect_count_error);
                for (hold_i = 0; hold_i < ready_delay; hold_i = hold_i + 1) begin
                    @(posedge clk);
                    #1;
                    if (done === 1'b1) begin
                        $display("ERROR FC compute done while result_ready low");
                        errors = errors + 1;
                    end
                    if (result_valid !== 1'b1) begin
                        $display("ERROR FC compute result_valid dropped before ready");
                        errors = errors + 1;
                    end
                    check_outputs(expect_count_error);
                end
                result_ready = 1'b1;
                wait_done();
                @(posedge clk);
                #1;
                if (result_valid !== 1'b0) begin
                    $display("ERROR FC compute result_valid did not clear");
                    errors = errors + 1;
                end
            end
            repeat (4) @(posedge clk);
        end
    endtask

    task run_busy_start_ignored;
        begin
            result_ready = 1'b1;
            launch_case(0, GAP_LEN);
            repeat (30) @(negedge clk);
            load_gap_case(1);
            gap_count = GAP_LEN[8:0];
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            wait_result_valid();
            check_outputs(0);
            wait_done();
            repeat (4) @(posedge clk);
        end
    endtask

    task reset_during_busy;
        begin
            result_ready = 1'b1;
            launch_case(2, GAP_LEN);
            repeat (40) @(negedge clk);
            rst_n = 1'b0;
            drive_idle_inputs();
            #1;
            if (busy !== 1'b0) begin
                $display("ERROR FC compute busy high after reset");
                errors = errors + 1;
            end
            if (result_valid !== 1'b0) begin
                $display("ERROR FC compute result_valid high after reset");
                errors = errors + 1;
            end
            repeat (4) @(negedge clk);
            rst_n = 1'b1;
            repeat (4) @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        errors = 0;
        current_case = 0;
        drive_idle_inputs();

        repeat (8) @(negedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        for (case_i = 0; case_i < FILE_CASES; case_i = case_i + 1) begin
            run_checked(case_i, GAP_LEN, case_i % 5, 0);
        end

        run_checked(0, GAP_LEN - 1, 0, 1);
        run_busy_start_ignored();
        reset_during_busy();
        run_checked(3, GAP_LEN, 2, 0);

        if (errors == 0) begin
            $display("PASS fc_classifier_96_5_compute self-check");
            $finish;
        end else begin
            $display("FAIL fc_classifier_96_5_compute errors=%0d", errors);
            $fatal(1);
        end
    end

endmodule
