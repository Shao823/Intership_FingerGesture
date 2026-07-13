`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_pw_conv2_array_4x12;

    localparam integer DATA_W     = 16;
    localparam integer ACC_W      = 48;
    localparam integer ROWS       = 4;
    localparam integer OC_LANES   = 12;
    localparam integer PW2_IC     = 64;
    localparam integer PW2_OC     = 96;
    localparam integer OC_GROUPS  = PW2_OC / OC_LANES;
    localparam integer GAP_LEN    = 174;
    localparam integer FRAC_BITS  = 8;
    localparam integer TIME_W     = 8;
    localparam integer INPUT_LEN  = 174;
    localparam integer TIMEOUT    = 20000;

    localparam integer READY_NONE     = 0;
    localparam integer READY_PERIODIC = 1;
    localparam integer READY_LATE     = 2;

    reg clk;
    reg rst_n;
    reg start;
    reg gap_clear;
    reg [TIME_W-1:0] tile_t_base;
    reg [ROWS-1:0] row_valid_mask;

    wire input_tile_req_valid;
    wire [TIME_W-1:0] input_tile_req_t_base;
    wire [ROWS-1:0] input_tile_req_row_valid_mask;
    reg input_tile_req_ready;

    wire act_req_valid;
    wire [TIME_W-1:0] act_req_t_base;
    wire [6:0] act_req_k;
    wire [ROWS-1:0] act_req_row_valid_mask;
    reg act_req_ready;
    wire act_vec_valid;
    wire act_vec_ready;
    wire signed [ROWS*DATA_W-1:0] act_vec;
    reg act_vec_valid_reg;
    reg signed [ROWS*DATA_W-1:0] act_vec_reg;

    reg w_fold_we;
    reg [6:0] w_fold_oc;
    reg signed [DATA_W-1:0] w_fold_wdata;

    reg bias_fold_we;
    reg [6:0] bias_fold_oc;
    reg signed [DATA_W-1:0] bias_fold_wdata;

    wire busy;
    wire done;
    wire gap_frame_done;
    wire [8:0] gap_count;
    wire signed [PW2_OC*ACC_W-1:0] gap_sum_vec;

    wire input_tile_req_fire_tb;
    wire act_req_fire_tb;
    wire act_vec_fire_tb;
    wire act_vec_blocked;
    wire weight_req_fire_tb;

    integer errors;
    integer test_tile_t_base;
    integer test_row_valid_mask;
    integer input_delay;
    integer act_ready_mode;
    integer act_ready_cycle;
    integer input_wait_cycle;
    integer tile_req_count;
    integer weight_req_count;
    integer act_req_count;
    integer act_resp_count;
    integer last_timeout;
    integer last_cycle_count;
    integer expected_gap_count;
    integer oc;
    integer k;
    integer row;
    integer t;

    reg signed [ACC_W-1:0] expected_gap_sum [0:PW2_OC-1];
    reg signed [DATA_W-1:0] file_input [0:INPUT_LEN*PW2_IC-1];
    reg [OC_LANES*DATA_W-1:0] packed_weight_mem [0:OC_GROUPS*PW2_IC-1];
    reg signed [DATA_W-1:0] bn_scale_mem [0:PW2_OC-1];
    reg signed [DATA_W-1:0] bn_bias_mem [0:PW2_OC-1];

    assign input_tile_req_fire_tb = input_tile_req_valid && input_tile_req_ready;
    assign act_req_fire_tb = act_req_valid && act_req_ready;
    assign act_vec_fire_tb = act_vec_valid && act_vec_ready;
    assign act_vec_blocked = act_vec_valid && !act_vec_ready;
    assign weight_req_fire_tb = dut.weight_req_valid && dut.weight_req_ready;

    assign act_vec_valid = act_vec_valid_reg;
    assign act_vec = act_vec_reg;

    pw_conv2_array_4x12 #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .ROWS(ROWS),
        .OC_LANES(OC_LANES),
        .PW2_IC(PW2_IC),
        .PW2_OC(PW2_OC),
        .GAP_LEN(GAP_LEN),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .gap_clear(gap_clear),
        .tile_t_base(tile_t_base),
        .row_valid_mask(row_valid_mask),
        .input_tile_req_valid(input_tile_req_valid),
        .input_tile_req_t_base(input_tile_req_t_base),
        .input_tile_req_row_valid_mask(input_tile_req_row_valid_mask),
        .input_tile_req_ready(input_tile_req_ready),
        .act_req_valid(act_req_valid),
        .act_req_t_base(act_req_t_base),
        .act_req_k(act_req_k),
        .act_req_row_valid_mask(act_req_row_valid_mask),
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
        .busy(busy),
        .done(done),
        .gap_frame_done(gap_frame_done),
        .gap_count(gap_count),
        .gap_sum_vec(gap_sum_vec)
    );

    initial begin
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv2_array_4x12/testdata/input.mem"},
            file_input
        );
        $readmemh({`PROJECT_ROOT, "/weight_data/pw2/weight_packed.mem"}, packed_weight_mem);
        $readmemh({`PROJECT_ROOT, "/weight_data/pw2/bn_scale.mem"}, bn_scale_mem);
        $readmemh({`PROJECT_ROOT, "/weight_data/pw2/bn_bias.mem"}, bn_bias_mem);
    end

    always #5 clk = ~clk;

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_tile_req_ready <= 1'b0;
            input_wait_cycle <= 0;
        end else if (input_tile_req_valid) begin
            input_wait_cycle <= input_wait_cycle + 1;
            input_tile_req_ready <= (input_wait_cycle >= input_delay);
        end else begin
            input_wait_cycle <= 0;
            input_tile_req_ready <= 1'b0;
        end
    end

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_req_ready <= 1'b1;
            act_ready_cycle <= 0;
        end else if (busy) begin
            act_ready_cycle <= act_ready_cycle + 1;
            case (act_ready_mode)
                READY_NONE: begin
                    act_req_ready <= !act_vec_blocked;
                end

                READY_PERIODIC: begin
                    act_req_ready <= ((act_ready_cycle % 5) != 1)
                        && !act_vec_blocked;
                end

                READY_LATE: begin
                    act_req_ready <= (act_ready_cycle >= 3)
                        && !act_vec_blocked;
                end

                default: begin
                    act_req_ready <= !act_vec_blocked;
                end
            endcase
        end else begin
            act_ready_cycle <= 0;
            act_req_ready <= !act_vec_blocked;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_vec_valid_reg <= 1'b0;
            act_vec_reg <= {(ROWS*DATA_W){1'b0}};
        end else if (act_vec_valid_reg && !act_vec_ready) begin
            act_vec_valid_reg <= act_vec_valid_reg;
            act_vec_reg <= act_vec_reg;
        end else if (act_req_fire_tb) begin
            act_vec_valid_reg <= 1'b1;
            act_vec_reg <= make_act_vec(
                act_req_t_base,
                act_req_k,
                act_req_row_valid_mask
            );
        end else begin
            act_vec_valid_reg <= 1'b0;
            act_vec_reg <= {(ROWS*DATA_W){1'b0}};
        end
    end

    always @(posedge clk) begin
        if (rst_n && input_tile_req_valid) begin
            if (input_tile_req_t_base !== test_tile_t_base[TIME_W-1:0]) begin
                $display(
                    "ERROR PW2 top input_tile_req_t_base got=%0d expected=%0d",
                    input_tile_req_t_base,
                    test_tile_t_base
                );
                errors = errors + 1;
            end
            if (input_tile_req_row_valid_mask !== test_row_valid_mask[ROWS-1:0]) begin
                $display(
                    "ERROR PW2 top input row mask got=%b expected=%b",
                    input_tile_req_row_valid_mask,
                    test_row_valid_mask[ROWS-1:0]
                );
                errors = errors + 1;
            end
        end

        if (rst_n && input_tile_req_fire_tb) begin
            tile_req_count = tile_req_count + 1;
        end
        if (rst_n && weight_req_fire_tb) begin
            check_weight_request();
            weight_req_count = weight_req_count + 1;
        end
        if (rst_n && act_req_fire_tb) begin
            check_act_request();
            act_req_count = act_req_count + 1;
        end
        if (rst_n && act_vec_fire_tb) begin
            act_resp_count = act_resp_count + 1;
        end
    end

    function signed [ACC_W-1:0] extend_to_acc;
        input signed [DATA_W-1:0] value;
        begin
            extend_to_acc = $signed({{(ACC_W-DATA_W){value[DATA_W-1]}}, value});
        end
    endfunction

    function signed [ACC_W-1:0] get_gap_value;
        input integer oc_idx;
        begin
            get_gap_value = gap_sum_vec[oc_idx*ACC_W +: ACC_W];
        end
    endfunction

    function [8:0] valid_row_count_tb;
        input [ROWS-1:0] mask_i;
        integer local_row;
        begin
            valid_row_count_tb = 9'd0;
            for (local_row = 0; local_row < ROWS; local_row = local_row + 1) begin
                if (mask_i[local_row]) begin
                    valid_row_count_tb = valid_row_count_tb + 9'd1;
                end
            end
        end
    endfunction

    function signed [DATA_W-1:0] input_value;
        input integer t_idx;
        input integer k_idx;
        begin
            input_value = file_input[t_idx*PW2_IC + k_idx];
        end
    endfunction

    function signed [DATA_W-1:0] weight_value;
        input integer oc_idx;
        input integer k_idx;
        integer group_i;
        integer lane_i;
        reg [OC_LANES*DATA_W-1:0] packed_word;
        begin
            group_i = oc_idx / OC_LANES;
            lane_i = oc_idx % OC_LANES;
            packed_word = packed_weight_mem[group_i*PW2_IC + k_idx];
            weight_value = packed_word[lane_i*DATA_W +: DATA_W];
        end
    endfunction

    function signed [ROWS*DATA_W-1:0] make_act_vec;
        input integer t_base_i;
        input integer k_idx;
        input [ROWS-1:0] mask_i;
        integer local_row;
        begin
            make_act_vec = {(ROWS*DATA_W){1'b0}};
            for (local_row = 0; local_row < ROWS; local_row = local_row + 1) begin
                if (mask_i[local_row]) begin
                    make_act_vec[local_row*DATA_W +: DATA_W]
                        = input_value(t_base_i + local_row, k_idx);
                end else begin
                    make_act_vec[local_row*DATA_W +: DATA_W] = {DATA_W{1'b0}};
                end
            end
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

    function signed [DATA_W-1:0] sat_from_32;
        input signed [31:0] value;
        begin
            if (value > 32767) begin
                sat_from_32 = 16'sh7fff;
            end else if (value < -32768) begin
                sat_from_32 = 16'sh8000;
            end else begin
                sat_from_32 = value[DATA_W-1:0];
            end
        end
    endfunction

    function signed [DATA_W-1:0] expected_value;
        input integer t_base_i;
        input integer row_idx;
        input integer oc_idx;
        input [ROWS-1:0] mask_i;
        integer local_k;
        reg signed [ACC_W-1:0] acc;
        reg signed [DATA_W-1:0] conv_q;
        reg signed [31:0] bn_mul;
        reg signed [31:0] bn_shifted;
        reg signed [31:0] bn_biased;
        reg signed [DATA_W-1:0] bn_q;
        reg signed [DATA_W-1:0] bias_q;
        begin
            if (!mask_i[row_idx]) begin
                expected_value = {DATA_W{1'b0}};
            end else begin
                acc = 0;
                for (local_k = 0; local_k < PW2_IC; local_k = local_k + 1) begin
                    acc = acc
                        + input_value(t_base_i + row_idx, local_k)
                        * weight_value(oc_idx, local_k);
                end
                conv_q = sat_from_acc_shift(acc);
                bn_mul = conv_q * bn_scale_mem[oc_idx];
                bn_shifted = bn_mul >>> FRAC_BITS;
                bias_q = bn_bias_mem[oc_idx];
                bn_biased = bn_shifted
                    + $signed({{(32-DATA_W){bias_q[DATA_W-1]}}, bias_q});
                bn_q = sat_from_32(bn_biased);
                expected_value = bn_q[DATA_W-1] ? {DATA_W{1'b0}} : bn_q;
            end
        end
    endfunction

    task reset_expected_gap;
        begin
            expected_gap_count = 0;
            for (oc = 0; oc < PW2_OC; oc = oc + 1) begin
                expected_gap_sum[oc] = {ACC_W{1'b0}};
            end
        end
    endtask

    task clear_gap_accumulator;
        begin
            @(negedge clk);
            gap_clear = 1'b1;
            start = 1'b0;
            @(negedge clk);
            gap_clear = 1'b0;
            repeat (1) @(negedge clk);
        end
    endtask

    task add_expected_gap;
        input integer tile_t_base_i;
        input [ROWS-1:0] mask_i;
        reg signed [DATA_W-1:0] expected;
        begin
            for (oc = 0; oc < PW2_OC; oc = oc + 1) begin
                for (row = 0; row < ROWS; row = row + 1) begin
                    if (mask_i[row]) begin
                        expected = expected_value(tile_t_base_i, row, oc, mask_i);
                        expected_gap_sum[oc] =
                            expected_gap_sum[oc] + extend_to_acc(expected);
                    end
                end
            end
            expected_gap_count = expected_gap_count + valid_row_count_tb(mask_i);
        end
    endtask

    task check_gap_state;
        input integer expected_count_i;
        input integer expected_frame_done_i;
        begin
            if (gap_count !== expected_count_i[8:0]) begin
                $display(
                    "ERROR PW2 top gap_count got=%0d expected=%0d",
                    gap_count,
                    expected_count_i
                );
                errors = errors + 1;
            end
            if (gap_frame_done !== expected_frame_done_i[0]) begin
                $display(
                    "ERROR PW2 top gap_frame_done got=%0d expected=%0d",
                    gap_frame_done,
                    expected_frame_done_i[0]
                );
                errors = errors + 1;
            end

            for (oc = 0; oc < PW2_OC; oc = oc + 1) begin
                if (get_gap_value(oc) !== expected_gap_sum[oc]) begin
                    $display(
                        "ERROR PW2 top gap_sum oc=%0d got=%0d expected=%0d",
                        oc,
                        $signed(get_gap_value(oc)),
                        $signed(expected_gap_sum[oc])
                    );
                    errors = errors + 1;
                end
            end
        end
    endtask

    task check_weight_request;
        integer expected_group;
        integer expected_oc_base;
        integer expected_k;
        begin
            expected_group = weight_req_count / PW2_IC;
            expected_oc_base = expected_group * OC_LANES;
            expected_k = weight_req_count % PW2_IC;

            if (dut.weight_req_oc_base !== expected_oc_base[6:0]) begin
                $display(
                    "ERROR PW2 top weight_req_oc_base got=%0d expected=%0d count=%0d",
                    dut.weight_req_oc_base,
                    expected_oc_base,
                    weight_req_count
                );
                errors = errors + 1;
            end
            if (dut.weight_req_k !== expected_k[6:0]) begin
                $display(
                    "ERROR PW2 top weight_req_k got=%0d expected=%0d count=%0d",
                    dut.weight_req_k,
                    expected_k,
                    weight_req_count
                );
                errors = errors + 1;
            end
        end
    endtask

    task check_act_request;
        integer expected_k;
        begin
            expected_k = act_req_count % PW2_IC;

            if (act_req_t_base !== test_tile_t_base[TIME_W-1:0]) begin
                $display(
                    "ERROR PW2 top act_req_t_base got=%0d expected=%0d",
                    act_req_t_base,
                    test_tile_t_base
                );
                errors = errors + 1;
            end
            if (act_req_k !== expected_k[6:0]) begin
                $display(
                    "ERROR PW2 top act_req_k got=%0d expected=%0d count=%0d",
                    act_req_k,
                    expected_k,
                    act_req_count
                );
                errors = errors + 1;
            end
            if (act_req_row_valid_mask !== test_row_valid_mask[ROWS-1:0]) begin
                $display(
                    "ERROR PW2 top act_req_row_valid_mask got=%b expected=%b",
                    act_req_row_valid_mask,
                    test_row_valid_mask[ROWS-1:0]
                );
                errors = errors + 1;
            end
        end
    endtask

    task launch;
        begin
            @(negedge clk);
            tile_req_count = 0;
            weight_req_count = 0;
            act_req_count = 0;
            act_resp_count = 0;
            start = 1'b1;
            tile_t_base = test_tile_t_base[TIME_W-1:0];
            row_valid_mask = test_row_valid_mask[ROWS-1:0];
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_done;
        integer timeout;
        begin
            timeout = 0;
            last_timeout = 0;
            last_cycle_count = 0;
            while ((done !== 1'b1) && (timeout < TIMEOUT)) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end
            last_cycle_count = timeout;

            if (done !== 1'b1) begin
                $display(
                    "ERROR PW2 top timeout tile=%0d mask=%b",
                    test_tile_t_base,
                    test_row_valid_mask[ROWS-1:0]
                );
                errors = errors + 1;
                last_timeout = 1;
            end
        end
    endtask

    task run_gap_job_ext;
        input integer tile_t_base_i;
        input [ROWS-1:0] row_valid_mask_i;
        input integer input_delay_i;
        input integer act_ready_mode_i;
        input integer clear_before_i;
        input integer expect_frame_done_i;
        integer wait_step;
        begin
            if (clear_before_i) begin
                clear_gap_accumulator();
                reset_expected_gap();
            end

            test_tile_t_base = tile_t_base_i;
            test_row_valid_mask = row_valid_mask_i;
            input_delay = input_delay_i;
            act_ready_mode = act_ready_mode_i;

            launch();

            for (wait_step = 0; wait_step < input_delay_i; wait_step = wait_step + 1) begin
                @(posedge clk);
                #1;
                if (dut.weight_req_valid || act_req_valid) begin
                    $display("ERROR PW2 top requested data before input tile ready");
                    errors = errors + 1;
                end
            end

            wait_done();
            if (!last_timeout) begin
                add_expected_gap(tile_t_base_i, row_valid_mask_i);

                if (tile_req_count != 1) begin
                    $display("ERROR PW2 top tile_req_count got=%0d expected=1",
                        tile_req_count);
                    errors = errors + 1;
                end
                if (weight_req_count != OC_GROUPS * PW2_IC) begin
                    $display(
                        "ERROR PW2 top weight_req_count got=%0d expected=%0d",
                        weight_req_count,
                        OC_GROUPS * PW2_IC
                    );
                    errors = errors + 1;
                end
                if (act_req_count != PW2_IC) begin
                    $display(
                        "ERROR PW2 top act_req_count got=%0d expected=%0d",
                        act_req_count,
                        PW2_IC
                    );
                    errors = errors + 1;
                end
                if (act_resp_count != PW2_IC) begin
                    $display(
                        "ERROR PW2 top act_resp_count got=%0d expected=%0d",
                        act_resp_count,
                        PW2_IC
                    );
                    errors = errors + 1;
                end
                if (dut.u_weight.u_ctrl.invalid_req_count != 0) begin
                    $display(
                        "ERROR PW2 top weight invalid_req_count=%0d",
                        dut.u_weight.u_ctrl.invalid_req_count
                    );
                    errors = errors + 1;
                end

                check_gap_state(expected_gap_count, expect_frame_done_i);
            end
        end
    endtask

    task run_full_frame_gap;
        begin
            clear_gap_accumulator();
            reset_expected_gap();

            for (t = 0; t <= 168; t = t + 4) begin
                run_gap_job_ext(t, 4'b1111, 0, READY_NONE, 0, 0);
            end

            run_gap_job_ext(172, 4'b0011, 0, READY_NONE, 0, 1);
        end
    endtask

    task check_autoload_inputs;
        begin
            if ((^file_input[0]) === 1'bx) begin
                $display("ERROR PW2 top input.mem did not load");
                errors = errors + 1;
            end
            if ((^packed_weight_mem[0]) === 1'bx) begin
                $display("ERROR PW2 top weight_packed.mem did not load");
                errors = errors + 1;
            end
            if ((^bn_scale_mem[0]) === 1'bx) begin
                $display("ERROR PW2 top bn_scale.mem did not load");
                errors = errors + 1;
            end
            if ((^bn_bias_mem[0]) === 1'bx) begin
                $display("ERROR PW2 top bn_bias.mem did not load");
                errors = errors + 1;
            end
            if (dut.u_compute.w_fold_mem[0] !== bn_scale_mem[0]) begin
                $display(
                    "ERROR PW2 top BN scale autoload mismatch got=%h expected=%h",
                    dut.u_compute.w_fold_mem[0],
                    bn_scale_mem[0]
                );
                errors = errors + 1;
            end
            if (dut.u_compute.bias_fold_mem[0] !== bn_bias_mem[0]) begin
                $display(
                    "ERROR PW2 top BN bias autoload mismatch got=%h expected=%h",
                    dut.u_compute.bias_fold_mem[0],
                    bn_bias_mem[0]
                );
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        gap_clear = 1'b0;
        tile_t_base = {TIME_W{1'b0}};
        row_valid_mask = 4'b1111;
        input_tile_req_ready = 1'b0;
        act_req_ready = 1'b1;
        act_vec_valid_reg = 1'b0;
        act_vec_reg = {(ROWS*DATA_W){1'b0}};
        w_fold_we = 1'b0;
        w_fold_oc = 7'd0;
        w_fold_wdata = 16'sd0;
        bias_fold_we = 1'b0;
        bias_fold_oc = 7'd0;
        bias_fold_wdata = 16'sd0;
        errors = 0;
        test_tile_t_base = 0;
        test_row_valid_mask = 4'b1111;
        input_delay = 0;
        act_ready_mode = READY_NONE;
        act_ready_cycle = 0;
        input_wait_cycle = 0;
        tile_req_count = 0;
        weight_req_count = 0;
        act_req_count = 0;
        act_resp_count = 0;
        last_timeout = 0;
        last_cycle_count = 0;
        reset_expected_gap();

        repeat (8) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        check_autoload_inputs();

        run_gap_job_ext(0, 4'b1111, 0, READY_NONE, 1, 0);
        $display(
            "INFO PW2 top no-stall tile cycles=%0d weight_req=%0d act_req=%0d",
            last_cycle_count,
            weight_req_count,
            act_req_count
        );

        run_gap_job_ext(12, 4'b1111, 4, READY_NONE, 1, 0);
        run_gap_job_ext(24, 4'b1111, 0, READY_PERIODIC, 1, 0);
        run_gap_job_ext(172, 4'b0011, 0, READY_LATE, 1, 0);

        clear_gap_accumulator();
        reset_expected_gap();
        run_gap_job_ext(88, 4'b1111, 0, READY_NONE, 0, 0);
        run_gap_job_ext(92, 4'b1111, 2, READY_PERIODIC, 0, 0);
        run_gap_job_ext(172, 4'b0011, 0, READY_NONE, 0, 0);

        run_full_frame_gap();

        if (errors == 0) begin
            $display("PASS pw_conv2_array_4x12 top self-check");
            $finish;
        end else begin
            $display("FAIL pw_conv2_array_4x12 top errors=%0d", errors);
            $finish;
        end
    end

endmodule
