`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_pw_conv2_array_4x12_compute;

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
    localparam integer TIMEOUT    = 20000;
    localparam integer INPUT_LEN  = 174;
    localparam integer FILE_MODE  = 99;
    localparam integer FILE_CASES = 4;

    localparam integer READY_NONE     = 0;
    localparam integer READY_PERIODIC = 1;
    localparam integer READY_LATE     = 2;

    localparam integer RESP_ONE_CYCLE  = 0;
    localparam integer RESP_ZERO_CYCLE = 1;

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

    wire weight_req_valid;
    wire [6:0] weight_req_oc_base;
    wire [6:0] weight_req_k;
    reg weight_req_ready;
    wire weight_vec_valid;
    wire weight_vec_ready;
    wire signed [OC_LANES*DATA_W-1:0] weight_vec;
    reg weight_vec_valid_reg;
    reg signed [OC_LANES*DATA_W-1:0] weight_vec_reg;

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

    integer errors;
    integer test_mode;
    integer test_tile_t_base;
    integer test_row_valid_mask;
    integer input_delay;
    integer weight_ready_mode;
    integer act_ready_mode;
    integer resp_mode;
    integer weight_ready_cycle;
    integer act_ready_cycle;
    integer input_wait_cycle;
    integer weight_req_count;
    integer act_req_count;
    integer last_timeout;
    integer last_cycle_count;
    integer expected_gap_count;
    integer oc;
    integer k;
    integer row;
    integer col;
    integer file_case_idx;

    reg signed [ACC_W-1:0] expected_gap_sum [0:PW2_OC-1];
    reg signed [DATA_W-1:0] file_input [0:INPUT_LEN*PW2_IC-1];
    reg signed [DATA_W-1:0] file_weight [0:PW2_OC*PW2_IC-1];
    reg signed [DATA_W-1:0] file_bn_scale [0:PW2_OC-1];
    reg signed [DATA_W-1:0] file_bn_bias [0:PW2_OC-1];
    reg [15:0] file_case_t_base [0:FILE_CASES-1];
    reg [7:0] file_case_row_valid_mask [0:FILE_CASES-1];
    reg signed [ACC_W-1:0] file_expected_tile_sum [0:FILE_CASES*PW2_OC-1];

    wire input_tile_req_fire_tb;
    wire weight_req_fire_tb;
    wire act_req_fire_tb;
    wire weight_vec_blocked;
    wire act_vec_blocked;

    assign input_tile_req_fire_tb = input_tile_req_valid && input_tile_req_ready;
    assign weight_req_fire_tb = weight_req_valid && weight_req_ready;
    assign act_req_fire_tb = act_req_valid && act_req_ready;
    assign weight_vec_blocked = weight_vec_valid && !weight_vec_ready;
    assign act_vec_blocked = act_vec_valid && !act_vec_ready;

    assign weight_vec_valid = (resp_mode == RESP_ZERO_CYCLE)
        ? weight_req_fire_tb
        : weight_vec_valid_reg;
    assign weight_vec = (resp_mode == RESP_ZERO_CYCLE)
        ? make_weight_vec(weight_req_oc_base, weight_req_k)
        : weight_vec_reg;

    assign act_vec_valid = (resp_mode == RESP_ZERO_CYCLE)
        ? act_req_fire_tb
        : act_vec_valid_reg;
    assign act_vec = (resp_mode == RESP_ZERO_CYCLE)
        ? make_act_vec(test_mode, act_req_t_base, act_req_k, act_req_row_valid_mask)
        : act_vec_reg;

    pw_conv2_array_4x12_compute #(
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
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv2_array_4x12/testdata/weight.mem"},
            file_weight
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv2_array_4x12/testdata/bn_scale.mem"},
            file_bn_scale
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv2_array_4x12/testdata/bn_bias.mem"},
            file_bn_bias
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv2_array_4x12/testdata/case_t_base.mem"},
            file_case_t_base
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv2_array_4x12/testdata/case_row_valid_mask.mem"},
            file_case_row_valid_mask
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv2_array_4x12/testdata/expected_tile_sum.mem"},
            file_expected_tile_sum
        );
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
            weight_req_ready <= 1'b1;
            weight_ready_cycle <= 0;
        end else if (busy) begin
            weight_ready_cycle <= weight_ready_cycle + 1;
            case (weight_ready_mode)
                READY_NONE: begin
                    weight_req_ready <= !weight_vec_blocked;
                end

                READY_PERIODIC: begin
                    weight_req_ready <= ((weight_ready_cycle % 6) != 2)
                        && !weight_vec_blocked;
                end

                READY_LATE: begin
                    weight_req_ready <= (weight_ready_cycle >= 4)
                        && !weight_vec_blocked;
                end

                default: begin
                    weight_req_ready <= !weight_vec_blocked;
                end
            endcase
        end else begin
            weight_ready_cycle <= 0;
            weight_req_ready <= !weight_vec_blocked;
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
            weight_vec_valid_reg <= 1'b0;
            weight_vec_reg <= {(OC_LANES*DATA_W){1'b0}};
        end else begin
            if (resp_mode == RESP_ZERO_CYCLE) begin
                weight_vec_valid_reg <= 1'b0;
                weight_vec_reg <= {(OC_LANES*DATA_W){1'b0}};
            end else if (weight_vec_valid_reg && !weight_vec_ready) begin
                weight_vec_valid_reg <= weight_vec_valid_reg;
                weight_vec_reg <= weight_vec_reg;
            end else if (weight_req_fire_tb) begin
                weight_vec_valid_reg <= 1'b1;
                weight_vec_reg <= make_weight_vec(weight_req_oc_base, weight_req_k);
            end else begin
                weight_vec_valid_reg <= 1'b0;
                weight_vec_reg <= {(OC_LANES*DATA_W){1'b0}};
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_vec_valid_reg <= 1'b0;
            act_vec_reg <= {(ROWS*DATA_W){1'b0}};
        end else begin
            if (resp_mode == RESP_ZERO_CYCLE) begin
                act_vec_valid_reg <= 1'b0;
                act_vec_reg <= {(ROWS*DATA_W){1'b0}};
            end else if (act_vec_valid_reg && !act_vec_ready) begin
                act_vec_valid_reg <= act_vec_valid_reg;
                act_vec_reg <= act_vec_reg;
            end else if (act_req_fire_tb) begin
                act_vec_valid_reg <= 1'b1;
                act_vec_reg <= make_act_vec(
                    test_mode,
                    act_req_t_base,
                    act_req_k,
                    act_req_row_valid_mask
                );
            end else begin
                act_vec_valid_reg <= 1'b0;
                act_vec_reg <= {(ROWS*DATA_W){1'b0}};
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n && input_tile_req_valid) begin
            if (input_tile_req_t_base !== test_tile_t_base[TIME_W-1:0]) begin
                $display(
                    "ERROR PW2 input_tile_req_t_base got=%0d expected=%0d",
                    input_tile_req_t_base,
                    test_tile_t_base
                );
                errors = errors + 1;
            end
            if (input_tile_req_row_valid_mask !== test_row_valid_mask[ROWS-1:0]) begin
                $display(
                    "ERROR PW2 input row mask got=%b expected=%b",
                    input_tile_req_row_valid_mask,
                    test_row_valid_mask[ROWS-1:0]
                );
                errors = errors + 1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n && weight_req_fire_tb) begin
            check_weight_request();
            weight_req_count = weight_req_count + 1;
        end
        if (rst_n && act_req_fire_tb) begin
            check_act_request();
            act_req_count = act_req_count + 1;
        end
    end

    function signed [DATA_W-1:0] q;
        input integer value;
        begin
            q = value[DATA_W-1:0];
        end
    endfunction

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
        input integer mode;
        input integer t_idx;
        input integer k_idx;
        begin
            if (mode == FILE_MODE) begin
                input_value = file_input[t_idx*PW2_IC + k_idx];
            end else if (mode == 1) begin
                input_value = q(512 - (t_idx % 5) * 24 + ((k_idx % 13) - 6) * 7);
            end else begin
                input_value = q(((t_idx % 9) - 4) * 13 + ((k_idx % 11) - 5) * 9);
            end
        end
    endfunction

    function signed [DATA_W-1:0] weight_value;
        input integer oc_idx;
        input integer k_idx;
        begin
            if (test_mode == FILE_MODE) begin
                weight_value = file_weight[oc_idx*PW2_IC + k_idx];
            end else begin
                weight_value = q(((oc_idx % 17) - 8) * 5 + ((k_idx % 7) - 3) * 4);
            end
        end
    endfunction

    function signed [DATA_W-1:0] w_fold_value;
        input integer oc_idx;
        begin
            if (test_mode == FILE_MODE) begin
                w_fold_value = file_bn_scale[oc_idx];
            end else begin
                w_fold_value = q(256 + (oc_idx % 4) * 12);
            end
        end
    endfunction

    function signed [DATA_W-1:0] bias_fold_value;
        input integer oc_idx;
        begin
            if (test_mode == FILE_MODE) begin
                bias_fold_value = file_bn_bias[oc_idx];
            end else begin
                bias_fold_value = q(((oc_idx % 9) - 4) * 18);
            end
        end
    endfunction

    function signed [OC_LANES*DATA_W-1:0] make_weight_vec;
        input integer oc_base_i;
        input integer k_idx;
        integer local_col;
        begin
            make_weight_vec = {(OC_LANES*DATA_W){1'b0}};
            for (local_col = 0; local_col < OC_LANES; local_col = local_col + 1) begin
                make_weight_vec[local_col*DATA_W +: DATA_W]
                    = weight_value(oc_base_i + local_col, k_idx);
            end
        end
    endfunction

    function signed [ROWS*DATA_W-1:0] make_act_vec;
        input integer mode;
        input integer t_base_i;
        input integer k_idx;
        input [ROWS-1:0] mask_i;
        integer local_row;
        begin
            make_act_vec = {(ROWS*DATA_W){1'b0}};
            for (local_row = 0; local_row < ROWS; local_row = local_row + 1) begin
                if (mask_i[local_row]) begin
                    make_act_vec[local_row*DATA_W +: DATA_W]
                        = input_value(mode, t_base_i + local_row, k_idx);
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
        input integer mode;
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
                        + input_value(mode, t_base_i + row_idx, local_k)
                        * weight_value(oc_idx, local_k);
                end
                conv_q = sat_from_acc_shift(acc);
                bn_mul = conv_q * w_fold_value(oc_idx);
                bn_shifted = bn_mul >>> FRAC_BITS;
                bias_q = bias_fold_value(oc_idx);
                bn_biased = bn_shifted
                    + $signed({{(32-DATA_W){bias_q[DATA_W-1]}}, bias_q});
                bn_q = sat_from_32(bn_biased);
                expected_value = bn_q[DATA_W-1] ? {DATA_W{1'b0}} : bn_q;
            end
        end
    endfunction

    task write_bn;
        input integer oc_idx;
        begin
            @(negedge clk);
            w_fold_we = 1'b1;
            w_fold_oc = oc_idx[6:0];
            w_fold_wdata = w_fold_value(oc_idx);
            bias_fold_we = 1'b1;
            bias_fold_oc = oc_idx[6:0];
            bias_fold_wdata = bias_fold_value(oc_idx);
            @(negedge clk);
            w_fold_we = 1'b0;
            bias_fold_we = 1'b0;
        end
    endtask

    task load_bn;
        begin
            for (oc = 0; oc < PW2_OC; oc = oc + 1) begin
                write_bn(oc);
            end
        end
    endtask

    task load_file_bn;
        begin
            test_mode = FILE_MODE;
            load_bn();
        end
    endtask

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
        input integer mode;
        input integer tile_t_base_i;
        input [ROWS-1:0] mask_i;
        reg signed [DATA_W-1:0] expected;
        begin
            if (mode == FILE_MODE) begin
                for (oc = 0; oc < PW2_OC; oc = oc + 1) begin
                    expected_gap_sum[oc] = expected_gap_sum[oc]
                        + file_expected_tile_sum[file_case_idx*PW2_OC + oc];
                end
            end else begin
                for (oc = 0; oc < PW2_OC; oc = oc + 1) begin
                    for (row = 0; row < ROWS; row = row + 1) begin
                        if (mask_i[row]) begin
                            expected = expected_value(
                                mode,
                                tile_t_base_i,
                                row,
                                oc,
                                mask_i
                            );
                            expected_gap_sum[oc] =
                                expected_gap_sum[oc] + extend_to_acc(expected);
                        end
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
                    "ERROR PW2 gap_count got=%0d expected=%0d",
                    gap_count,
                    expected_count_i
                );
                errors = errors + 1;
            end
            if (gap_frame_done !== expected_frame_done_i[0]) begin
                $display(
                    "ERROR PW2 gap_frame_done got=%0d expected=%0d",
                    gap_frame_done,
                    expected_frame_done_i[0]
                );
                errors = errors + 1;
            end

            for (oc = 0; oc < PW2_OC; oc = oc + 1) begin
                if (get_gap_value(oc) !== expected_gap_sum[oc]) begin
                    $display(
                        "ERROR PW2 gap_sum oc=%0d got=%0d expected=%0d",
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

            if (weight_req_oc_base !== expected_oc_base[6:0]) begin
                $display(
                    "ERROR PW2 weight_req_oc_base got=%0d expected=%0d count=%0d",
                    weight_req_oc_base,
                    expected_oc_base,
                    weight_req_count
                );
                errors = errors + 1;
            end
            if (weight_req_k !== expected_k[6:0]) begin
                $display(
                    "ERROR PW2 weight_req_k got=%0d expected=%0d count=%0d",
                    weight_req_k,
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
                    "ERROR PW2 act_req_t_base got=%0d expected=%0d",
                    act_req_t_base,
                    test_tile_t_base
                );
                errors = errors + 1;
            end
            if (act_req_k !== expected_k[6:0]) begin
                $display(
                    "ERROR PW2 act_req_k got=%0d expected=%0d count=%0d",
                    act_req_k,
                    expected_k,
                    act_req_count
                );
                errors = errors + 1;
            end
            if (act_req_row_valid_mask !== test_row_valid_mask[ROWS-1:0]) begin
                $display(
                    "ERROR PW2 act_req_row_valid_mask got=%b expected=%b",
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
            weight_req_count = 0;
            act_req_count = 0;
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
                    "ERROR PW2 timeout mode=%0d tile=%0d mask=%b",
                    test_mode,
                    test_tile_t_base,
                    test_row_valid_mask[ROWS-1:0]
                );
                errors = errors + 1;
                last_timeout = 1;
            end
        end
    endtask

    task run_gap_job_ext;
        input integer mode;
        input integer tile_t_base_i;
        input [ROWS-1:0] row_valid_mask_i;
        input integer input_delay_i;
        input integer weight_ready_mode_i;
        input integer act_ready_mode_i;
        input integer resp_mode_i;
        input integer clear_before_i;
        input integer expect_frame_done_i;
        integer wait_step;
        begin
            if (clear_before_i) begin
                clear_gap_accumulator();
                reset_expected_gap();
            end

            test_mode = mode;
            test_tile_t_base = tile_t_base_i;
            test_row_valid_mask = row_valid_mask_i;
            input_delay = input_delay_i;
            weight_ready_mode = weight_ready_mode_i;
            act_ready_mode = act_ready_mode_i;
            resp_mode = resp_mode_i;

            launch();

            for (wait_step = 0; wait_step < input_delay_i; wait_step = wait_step + 1) begin
                @(posedge clk);
                #1;
                if (weight_req_valid || act_req_valid) begin
                    $display("ERROR PW2 requested data before input tile ready");
                    errors = errors + 1;
                end
            end

            wait_done();
            if (!last_timeout) begin
                add_expected_gap(mode, tile_t_base_i, row_valid_mask_i);

                if (weight_req_count != OC_GROUPS * PW2_IC) begin
                    $display(
                        "ERROR PW2 weight_req_count got=%0d expected=%0d",
                        weight_req_count,
                        OC_GROUPS * PW2_IC
                    );
                    errors = errors + 1;
                end
                if (act_req_count != PW2_IC) begin
                    $display(
                        "ERROR PW2 act_req_count got=%0d expected=%0d",
                        act_req_count,
                        PW2_IC
                    );
                    errors = errors + 1;
                end

                check_gap_state(expected_gap_count, expect_frame_done_i);
            end
        end
    endtask

    task run_gap_job;
        input integer mode;
        input integer tile_t_base_i;
        input [ROWS-1:0] row_valid_mask_i;
        input integer input_delay_i;
        input integer weight_ready_mode_i;
        input integer act_ready_mode_i;
        begin
            run_gap_job_ext(
                mode,
                tile_t_base_i,
                row_valid_mask_i,
                input_delay_i,
                weight_ready_mode_i,
                act_ready_mode_i,
                RESP_ONE_CYCLE,
                1,
                0
            );
        end
    endtask

    task run_with_busy_start_pulse;
        begin
            clear_gap_accumulator();
            reset_expected_gap();

            test_mode = 0;
            test_tile_t_base = 64;
            test_row_valid_mask = 4'b1111;
            input_delay = 0;
            weight_ready_mode = READY_NONE;
            act_ready_mode = READY_NONE;
            resp_mode = RESP_ONE_CYCLE;

            launch();

            repeat (8) @(negedge clk);
            start = 1'b1;
            tile_t_base = 8'd120;
            row_valid_mask = 4'b0011;
            @(negedge clk);
            start = 1'b0;

            wait_done();
            if (!last_timeout) begin
                add_expected_gap(0, 64, 4'b1111);
                check_gap_state(expected_gap_count, 0);
            end
        end
    endtask

    task run_with_busy_bn_write;
        begin
            clear_gap_accumulator();
            reset_expected_gap();

            test_mode = 1;
            test_tile_t_base = 72;
            test_row_valid_mask = 4'b1111;
            input_delay = 0;
            weight_ready_mode = READY_NONE;
            act_ready_mode = READY_NONE;
            resp_mode = RESP_ONE_CYCLE;

            launch();

            repeat (4) @(negedge clk);
            w_fold_we = 1'b1;
            w_fold_oc = 7'd12;
            w_fold_wdata = 16'sd4096;
            bias_fold_we = 1'b1;
            bias_fold_oc = 7'd12;
            bias_fold_wdata = -16'sd4096;
            @(negedge clk);
            w_fold_we = 1'b0;
            bias_fold_we = 1'b0;

            wait_done();
            if (!last_timeout) begin
                add_expected_gap(1, 72, 4'b1111);
                check_gap_state(expected_gap_count, 0);
            end
        end
    endtask

    task reset_during_busy;
        begin
            test_mode = 0;
            test_tile_t_base = 80;
            test_row_valid_mask = 4'b1111;
            input_delay = 0;
            weight_ready_mode = READY_PERIODIC;
            act_ready_mode = READY_LATE;
            resp_mode = RESP_ONE_CYCLE;

            launch();

            repeat (6) @(negedge clk);
            rst_n = 1'b0;
            start = 1'b0;
            gap_clear = 1'b0;
            w_fold_we = 1'b0;
            bias_fold_we = 1'b0;
            #1;
            if (busy !== 1'b0) begin
                $display("ERROR PW2 busy is not low after mid-run reset");
                errors = errors + 1;
            end
            if (gap_count !== 9'd0) begin
                $display("ERROR PW2 gap_count is not zero after mid-run reset");
                errors = errors + 1;
            end

            repeat (2) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
            reset_expected_gap();
        end
    endtask

    task run_full_frame_gap;
        integer t;
        begin
            clear_gap_accumulator();
            reset_expected_gap();

            for (t = 0; t <= 168; t = t + 4) begin
                run_gap_job_ext(
                    0,
                    t,
                    4'b1111,
                    0,
                    READY_NONE,
                    READY_NONE,
                    RESP_ONE_CYCLE,
                    0,
                    0
                );
            end

            run_gap_job_ext(
                0,
                172,
                4'b0011,
                0,
                READY_NONE,
                READY_NONE,
                RESP_ONE_CYCLE,
                0,
                1
            );
        end
    endtask

    task run_file_golden_cases;
        integer case_i;
        begin
            load_file_bn();
            for (case_i = 0; case_i < FILE_CASES; case_i = case_i + 1) begin
                file_case_idx = case_i;
                run_gap_job_ext(
                    FILE_MODE,
                    file_case_t_base[case_i],
                    file_case_row_valid_mask[case_i][ROWS-1:0],
                    case_i,
                    (case_i % 2) ? READY_PERIODIC : READY_NONE,
                    (case_i % 2) ? READY_NONE : READY_PERIODIC,
                    (case_i == 1) ? RESP_ZERO_CYCLE : RESP_ONE_CYCLE,
                    1,
                    0
                );
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
        weight_req_ready = 1'b1;
        weight_vec_valid_reg = 1'b0;
        weight_vec_reg = {(OC_LANES*DATA_W){1'b0}};
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
        test_mode = 0;
        test_tile_t_base = 0;
        test_row_valid_mask = 4'b1111;
        input_delay = 0;
        weight_ready_mode = READY_NONE;
        act_ready_mode = READY_NONE;
        resp_mode = RESP_ONE_CYCLE;
        weight_ready_cycle = 0;
        act_ready_cycle = 0;
        input_wait_cycle = 0;
        weight_req_count = 0;
        act_req_count = 0;
        last_timeout = 0;
        last_cycle_count = 0;
        file_case_idx = 0;
        reset_expected_gap();

        repeat (5) @(negedge clk);
        rst_n = 1'b1;

        load_bn();

        // Basic full 4-row tile. One start computes and accumulates all 96 channels.
        run_gap_job(0, 0, 4'b1111, 0, READY_NONE, READY_NONE);
        $display(
            "INFO PW2 no-stall tile cycles=%0d weight_req=%0d act_req=%0d",
            last_cycle_count,
            weight_req_count,
            act_req_count
        );

        // PW2 must wait for exact input tile readiness before requesting data.
        run_gap_job(0, 12, 4'b1111, 4, READY_NONE, READY_NONE);

        // Independent weight/activation request backpressure.
        run_gap_job(1, 24, 4'b1111, 0, READY_PERIODIC, READY_LATE);

        // Combinational response mode, covering req and response same-cycle fire.
        run_gap_job_ext(
            0,
            36,
            4'b1111,
            0,
            READY_NONE,
            READY_NONE,
            RESP_ZERO_CYCLE,
            1,
            0
        );

        // Final partial tile for 174 low-resolution rows: only rows 172 and 173 are valid.
        run_gap_job(0, 172, 4'b0011, 0, READY_PERIODIC, READY_NONE);

        // Back-to-back jobs without gap_clear must accumulate into the same 96 sums.
        clear_gap_accumulator();
        reset_expected_gap();
        run_gap_job_ext(0, 88, 4'b1111, 0, READY_NONE, READY_NONE, RESP_ONE_CYCLE, 0, 0);
        run_gap_job_ext(1, 92, 4'b1111, 2, READY_PERIODIC, READY_PERIODIC, RESP_ONE_CYCLE, 0, 0);
        run_gap_job_ext(0, 172, 4'b0011, 0, READY_NONE, READY_NONE, RESP_ONE_CYCLE, 0, 0);

        // A complete 174-row frame should raise gap_frame_done on the final partial tile.
        run_full_frame_gap();

        // A stray start during MAC must be ignored.
        run_with_busy_start_pulse();

        // Runtime folded-BN writes are ignored; active job must use preloaded BN.
        run_with_busy_bn_write();

        // Mid-run reset aborts the active job and leaves the core reusable.
        reset_during_busy();
        load_bn();
        run_gap_job(0, 96, 4'b1111, 0, READY_NONE, READY_NONE);

        run_file_golden_cases();

        if (errors == 0) begin
            $display("PASS pw_conv2_array_4x12_compute GAP self-check");
            $finish;
        end else begin
            $display("FAIL pw_conv2_array_4x12_compute errors=%0d", errors);
            $finish;
        end
    end

endmodule
