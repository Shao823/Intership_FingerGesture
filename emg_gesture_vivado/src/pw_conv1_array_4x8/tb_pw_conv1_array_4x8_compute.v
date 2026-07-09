`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_pw_conv1_array_4x8_compute;

    localparam integer DATA_W     = 16;
    localparam integer ACC_W      = 48;
    localparam integer ROWS       = 4;
    localparam integer POOL_ROWS  = 2;
    localparam integer OC_LANES   = 8;
    localparam integer PW1_IC     = 32;
    localparam integer PW1_OC     = 64;
    localparam integer OC_GROUPS  = PW1_OC / OC_LANES;
    localparam integer FRAC_BITS  = 8;
    localparam integer TIME_W     = 9;
    localparam integer TIMEOUT    = 4000;
    localparam integer INPUT_LEN  = 348;
    localparam integer POOL_LEN   = 174;
    localparam integer FILE_MODE  = 99;
    localparam integer FILE_CASES = 4;

    localparam integer READY_NONE     = 0;
    localparam integer READY_PERIODIC = 1;
    localparam integer READY_LATE     = 2;

    localparam integer OUT_READY_NONE     = 0;
    localparam integer OUT_READY_DELAY    = 1;
    localparam integer OUT_READY_PERIODIC = 2;
    localparam integer OUT_READY_LONG     = 3;

    localparam integer RESP_ONE_CYCLE  = 0;
    localparam integer RESP_ZERO_CYCLE = 1;

    reg clk;
    reg rst_n;
    reg start;
    reg [5:0] oc_base;
    reg [TIME_W-1:0] tile_t_base;

    wire input_tile_req_valid;
    wire [TIME_W-1:0] input_tile_req_t_base;
    wire input_tile_req_ready;
    reg row_packer_ready;
    reg [TIME_W-1:0] ready_tile_t_base;

    wire weight_req_valid;
    wire [5:0] weight_req_oc_base;
    wire [5:0] weight_req_k;
    reg weight_req_ready;
    wire weight_vec_valid;
    wire weight_vec_ready;
    wire signed [OC_LANES*DATA_W-1:0] weight_vec;
    reg weight_vec_valid_reg;
    reg signed [OC_LANES*DATA_W-1:0] weight_vec_reg;

    wire act_req_valid;
    wire [TIME_W-1:0] act_req_t_base;
    wire [5:0] act_req_k;
    reg act_req_ready;
    wire act_vec_valid;
    wire act_vec_ready;
    wire signed [ROWS*DATA_W-1:0] act_vec;
    reg act_vec_valid_reg;
    reg signed [ROWS*DATA_W-1:0] act_vec_reg;

    reg w_fold_we;
    reg [5:0] w_fold_oc;
    reg signed [DATA_W-1:0] w_fold_wdata;

    reg bias_fold_we;
    reg [5:0] bias_fold_oc;
    reg signed [DATA_W-1:0] bias_fold_wdata;

    reg out_ready;
    wire busy;
    wire done;
    wire out_valid;
    wire [TIME_W-1:0] out_pool_t_base;
    wire [5:0] out_oc_base;
    wire out_last_group;
    wire signed [POOL_ROWS*OC_LANES*DATA_W-1:0] out_tile;

    integer errors;
    integer oc;
    integer k;
    integer row;
    integer col;
    integer test_mode;
    integer test_oc_base;
    integer test_t_base;
    integer test_input_delay;
    integer weight_ready_mode;
    integer act_ready_mode;
    integer out_ready_mode;
    integer resp_mode;
    integer weight_ready_cycle;
    integer act_ready_cycle;
    integer out_ready_cycle;
    integer weight_req_count;
    integer act_req_count;
    integer tile_req_count;
    integer output_count;
    integer last_timeout;
    integer rv_lane;

    reg signed [DATA_W-1:0] file_input [0:INPUT_LEN*PW1_IC-1];
    reg signed [DATA_W-1:0] file_weight [0:PW1_OC*PW1_IC-1];
    reg signed [DATA_W-1:0] file_bn_scale [0:PW1_OC-1];
    reg signed [DATA_W-1:0] file_bn_bias [0:PW1_OC-1];
    reg signed [DATA_W-1:0] file_expected_pool [0:POOL_LEN*PW1_OC-1];
    reg [15:0] file_case_t_base [0:FILE_CASES-1];

    wire weight_req_fire_tb;
    wire act_req_fire_tb;
    wire input_tile_req_fire_tb;
    wire weight_vec_blocked;
    wire act_vec_blocked;
    wire out_fire_tb;

    assign weight_req_fire_tb = weight_req_valid && weight_req_ready;
    assign act_req_fire_tb = act_req_valid && act_req_ready;
    assign input_tile_req_fire_tb = input_tile_req_valid && input_tile_req_ready;
    assign weight_vec_blocked = weight_vec_valid && !weight_vec_ready;
    assign act_vec_blocked = act_vec_valid && !act_vec_ready;
    assign out_fire_tb = out_valid && out_ready;
    assign input_tile_req_ready = row_packer_ready
        && (input_tile_req_t_base == ready_tile_t_base);

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
        ? make_act_vec(test_mode, act_req_t_base, act_req_k)
        : act_vec_reg;

    pw_conv1_array_4x8_compute #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .ROWS(ROWS),
        .POOL_ROWS(POOL_ROWS),
        .OC_LANES(OC_LANES),
        .PW1_IC(PW1_IC),
        .PW1_OC(PW1_OC),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .oc_base(oc_base),
        .tile_t_base(tile_t_base),
        .input_tile_req_valid(input_tile_req_valid),
        .input_tile_req_t_base(input_tile_req_t_base),
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
        .out_pool_t_base(out_pool_t_base),
        .out_oc_base(out_oc_base),
        .out_last_group(out_last_group),
        .out_tile(out_tile)
    );

    initial begin
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv1_array_4x8/testdata/input.mem"},
            file_input
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv1_array_4x8/testdata/weight.mem"},
            file_weight
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv1_array_4x8/testdata/bn_scale.mem"},
            file_bn_scale
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv1_array_4x8/testdata/bn_bias.mem"},
            file_bn_bias
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv1_array_4x8/testdata/expected_pool.mem"},
            file_expected_pool
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv1_array_4x8/testdata/case_t_base.mem"},
            file_case_t_base
        );
    end

    always #5 clk = ~clk;

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
                act_vec_reg <= make_act_vec(test_mode, act_req_t_base, act_req_k);
            end else begin
                act_vec_valid_reg <= 1'b0;
                act_vec_reg <= {(ROWS*DATA_W){1'b0}};
            end
        end
    end

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_ready <= 1'b1;
            out_ready_cycle <= 0;
        end else if (out_valid) begin
            out_ready_cycle <= out_ready_cycle + 1;
            case (out_ready_mode)
                OUT_READY_NONE: begin
                    out_ready <= 1'b1;
                end
                OUT_READY_DELAY: begin
                    out_ready <= (out_ready_cycle >= 5);
                end
                OUT_READY_PERIODIC: begin
                    out_ready <= ((out_ready_cycle % 4) != 1);
                end
                OUT_READY_LONG: begin
                    out_ready <= (out_ready_cycle >= 35);
                end
                default: begin
                    out_ready <= 1'b1;
                end
            endcase
        end else begin
            out_ready_cycle <= 0;
            out_ready <= 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_req_count <= 0;
            act_req_count <= 0;
            tile_req_count <= 0;
        end else begin
            if (input_tile_req_valid) begin
                if (input_tile_req_t_base !== test_t_base[TIME_W-1:0]) begin
                    $display(
                        "ERROR input_tile_req_t_base got=%0d expected=%0d",
                        input_tile_req_t_base,
                        test_t_base
                    );
                    errors = errors + 1;
                end
            end
            if (input_tile_req_fire_tb) begin
                tile_req_count <= tile_req_count + 1;
            end
            if (weight_req_fire_tb) begin
                check_weight_request();
                weight_req_count <= weight_req_count + 1;
            end
            if (act_req_fire_tb) begin
                check_act_request();
                act_req_count <= act_req_count + 1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_count <= 0;
        end else if (out_fire_tb) begin
            check_output_tile();
            output_count <= output_count + 1;
        end
    end

    function signed [DATA_W-1:0] q;
        input integer value;
        begin
            q = value[DATA_W-1:0];
        end
    endfunction

    function signed [DATA_W-1:0] act_value;
        input integer mode;
        input integer t_idx;
        input integer ch_idx;
        integer v;
        begin
            if (mode == FILE_MODE) begin
                act_value = file_input[t_idx*PW1_IC + ch_idx];
            end else if (mode == 1) begin
                v = ((t_idx % 9) - 4) * 10 + ((ch_idx % 11) - 5) * 6;
                act_value = q(v);
            end else begin
                v = 80 + ((t_idx % 7) - 3) * 9 - ((ch_idx % 5) * 11);
                act_value = q(v);
            end
        end
    endfunction

    function signed [DATA_W-1:0] weight_value;
        input integer oc_idx;
        input integer ch_idx;
        integer v;
        begin
            if (test_mode == FILE_MODE) begin
                weight_value = file_weight[oc_idx*PW1_IC + ch_idx];
            end else if ((oc_idx >= 56) && (ch_idx[1:0] == 2'd0)) begin
                v = 48 - (oc_idx % 3) * 8;
                weight_value = q(v);
            end else begin
                v = ((oc_idx % 9) - 4) * 6 + ((ch_idx % 5) - 2) * 7;
                weight_value = q(v);
            end
        end
    endfunction

    function signed [DATA_W-1:0] bn_scale_value;
        input integer oc_idx;
        begin
            if (test_mode == FILE_MODE) begin
                bn_scale_value = file_bn_scale[oc_idx];
            end else begin
            case (oc_idx % 4)
                0: bn_scale_value = q(256);
                1: bn_scale_value = q(384);
                2: bn_scale_value = q(-256);
                default: bn_scale_value = q(512);
            endcase
            end
        end
    endfunction

    function signed [DATA_W-1:0] bn_bias_value;
        input integer oc_idx;
        begin
            if (test_mode == FILE_MODE) begin
                bn_bias_value = file_bn_bias[oc_idx];
            end else begin
                bn_bias_value = q(((oc_idx % 7) - 3) * 32);
            end
        end
    endfunction

    function signed [ROWS*DATA_W-1:0] make_act_vec;
        input integer mode;
        input integer t_base_i;
        input integer k_idx;
        integer local_row;
        begin
            make_act_vec = {(ROWS*DATA_W){1'b0}};
            for (local_row = 0; local_row < ROWS; local_row = local_row + 1) begin
                make_act_vec[local_row*DATA_W +: DATA_W]
                    = act_value(mode, t_base_i + local_row, k_idx);
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

    function signed [DATA_W-1:0] get_out_lane;
        input integer pool_row;
        input integer lane_idx;
        begin
            get_out_lane = out_tile[(pool_row*OC_LANES + lane_idx)*DATA_W +: DATA_W];
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

    function signed [DATA_W-1:0] relu_value;
        input signed [DATA_W-1:0] value;
        begin
            relu_value = value[DATA_W-1] ? 16'sd0 : value;
        end
    endfunction

    function signed [DATA_W-1:0] max_signed;
        input signed [DATA_W-1:0] a;
        input signed [DATA_W-1:0] b;
        begin
            max_signed = (a >= b) ? a : b;
        end
    endfunction

    function signed [DATA_W-1:0] expected_relu;
        input integer mode;
        input integer t_idx;
        input integer oc_idx;
        integer local_k;
        reg signed [31:0] prod;
        reg signed [ACC_W-1:0] acc;
        reg signed [DATA_W-1:0] conv_q;
        reg signed [31:0] bn_mul;
        reg signed [31:0] shifted;
        reg signed [31:0] biased;
        reg signed [DATA_W-1:0] bn_q;
        begin
            acc = 0;
            for (local_k = 0; local_k < PW1_IC; local_k = local_k + 1) begin
                prod = act_value(mode, t_idx, local_k)
                    * weight_value(oc_idx, local_k);
                acc = acc + $signed({{(ACC_W-32){prod[31]}}, prod});
            end

            conv_q = sat_from_acc_shift(acc);
            bn_mul = conv_q * bn_scale_value(oc_idx);
            shifted = bn_mul >>> FRAC_BITS;
            biased = shifted + bn_bias_value(oc_idx);
            bn_q = sat_from_32(biased);
            expected_relu = relu_value(bn_q);
        end
    endfunction

    function signed [DATA_W-1:0] expected_pool_value;
        input integer mode;
        input integer high_t_base;
        input integer pool_row;
        input integer oc_idx;
        reg signed [DATA_W-1:0] a;
        reg signed [DATA_W-1:0] b;
        begin
            if (mode == FILE_MODE) begin
                expected_pool_value =
                    file_expected_pool[((high_t_base >> 1) + pool_row)*PW1_OC + oc_idx];
            end else begin
                a = expected_relu(mode, high_t_base + pool_row*2, oc_idx);
                b = expected_relu(mode, high_t_base + pool_row*2 + 1, oc_idx);
                expected_pool_value = max_signed(a, b);
            end
        end
    endfunction

    task write_bn;
        input integer oc_idx;
        begin
            @(negedge clk);
            w_fold_we = 1'b1;
            w_fold_oc = oc_idx[5:0];
            w_fold_wdata = bn_scale_value(oc_idx);
            bias_fold_we = 1'b1;
            bias_fold_oc = oc_idx[5:0];
            bias_fold_wdata = bn_bias_value(oc_idx);
            @(negedge clk);
            w_fold_we = 1'b0;
            bias_fold_we = 1'b0;
        end
    endtask

    task load_bn;
        begin
            for (oc = 0; oc < PW1_OC; oc = oc + 1) begin
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

    task check_weight_request;
        integer expected_group;
        integer expected_oc_base;
        integer expected_k;
        begin
            expected_group = weight_req_count / PW1_IC;
            expected_oc_base = expected_group * OC_LANES;
            expected_k = weight_req_count % PW1_IC;

            if (weight_req_oc_base !== expected_oc_base[5:0]) begin
                $display(
                    "ERROR weight_req_oc_base got=%0d expected=%0d count=%0d",
                    weight_req_oc_base,
                    expected_oc_base,
                    weight_req_count
                );
                errors = errors + 1;
            end
            if (weight_req_k !== expected_k[5:0]) begin
                $display(
                    "ERROR weight_req_k got=%0d expected=%0d count=%0d",
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
            expected_k = act_req_count % PW1_IC;

            if (act_req_t_base !== test_t_base[TIME_W-1:0]) begin
                $display(
                    "ERROR act_req_t_base got=%0d expected=%0d",
                    act_req_t_base,
                    test_t_base
                );
                errors = errors + 1;
            end
            if (act_req_k !== expected_k[5:0]) begin
                $display(
                    "ERROR act_req_k got=%0d expected=%0d count=%0d",
                    act_req_k,
                    expected_k,
                    act_req_count
                );
                errors = errors + 1;
            end
        end
    endtask

    task check_output_tile;
        reg signed [DATA_W-1:0] expected;
        integer expected_pool_t_base;
        integer expected_oc_base;
        begin
            expected_pool_t_base = test_t_base >> 1;
            expected_oc_base = output_count * OC_LANES;

            if (out_pool_t_base !== expected_pool_t_base[TIME_W-1:0]) begin
                $display(
                    "ERROR out_pool_t_base got=%0d expected=%0d",
                    out_pool_t_base,
                    expected_pool_t_base
                );
                errors = errors + 1;
            end

            if (out_oc_base !== expected_oc_base[5:0]) begin
                $display(
                    "ERROR out_oc_base got=%0d expected=%0d output_count=%0d",
                    out_oc_base,
                    expected_oc_base,
                    output_count
                );
                errors = errors + 1;
            end
            if (out_last_group !== (output_count == OC_GROUPS-1)) begin
                $display(
                    "ERROR out_last_group got=%0d expected=%0d",
                    out_last_group,
                    (output_count == OC_GROUPS-1)
                );
                errors = errors + 1;
            end

            for (row = 0; row < POOL_ROWS; row = row + 1) begin
                for (col = 0; col < OC_LANES; col = col + 1) begin
                    expected = expected_pool_value(
                        test_mode,
                        test_t_base,
                        row,
                        expected_oc_base + col
                    );
                    if (get_out_lane(row, col) !== expected) begin
                        $display(
                            "ERROR pool_row=%0d col=%0d oc=%0d got=%0d expected=%0d",
                            row,
                            col,
                            expected_oc_base + col,
                            $signed(get_out_lane(row, col)),
                            $signed(expected)
                        );
                        errors = errors + 1;
                    end
                end
            end
        end
    endtask

    task launch;
        begin
            @(negedge clk);
            start = 1'b1;
            oc_base = test_oc_base[5:0];
            tile_t_base = test_t_base[TIME_W-1:0];
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_done;
        integer timeout;
        begin
            timeout = 0;
            last_timeout = 0;
            while ((done !== 1'b1) && (timeout < TIMEOUT)) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end

            if (done !== 1'b1) begin
                $display(
                    "ERROR timeout mode=%0d oc_base=%0d t_base=%0d",
                    test_mode,
                    test_oc_base,
                    test_t_base
                );
                errors = errors + 1;
                last_timeout = 1;
            end
        end
    endtask

    task run_checked;
        input integer mode_i;
        input integer oc_base_i;
        input integer t_base_i;
        input integer input_delay_i;
        input integer weight_ready_mode_i;
        input integer act_ready_mode_i;
        input integer resp_mode_i;
        input integer out_ready_mode_i;
        begin
            test_mode = mode_i;
            test_oc_base = oc_base_i;
            test_t_base = t_base_i;
            test_input_delay = input_delay_i;
            weight_ready_mode = weight_ready_mode_i;
            act_ready_mode = act_ready_mode_i;
            resp_mode = resp_mode_i;
            out_ready_mode = out_ready_mode_i;
            weight_req_count = 0;
            act_req_count = 0;
            tile_req_count = 0;
            output_count = 0;
            ready_tile_t_base = t_base_i[TIME_W-1:0];
            row_packer_ready = (input_delay_i == 0);

            launch();

            if (input_delay_i > 0) begin
                repeat (input_delay_i) begin
                    @(posedge clk);
                    #1;
                    if (weight_req_valid || act_req_valid) begin
                        $display(
                            "ERROR PW1 requested data before input tile ready t_base=%0d",
                            test_t_base
                        );
                        errors = errors + 1;
                    end
                    @(negedge clk);
                end
                row_packer_ready = 1'b1;
            end

            wait_done();

            if (!last_timeout) begin
                if (tile_req_count != 1) begin
                    $display(
                        "ERROR tile_req_count got=%0d expected=1",
                        tile_req_count
                    );
                    errors = errors + 1;
                end
                if (weight_req_count != OC_GROUPS * PW1_IC) begin
                    $display(
                        "ERROR weight_req_count got=%0d expected=%0d",
                        weight_req_count,
                        OC_GROUPS * PW1_IC
                    );
                    errors = errors + 1;
                end
                if (act_req_count != PW1_IC) begin
                    $display(
                        "ERROR act_req_count got=%0d expected=%0d",
                        act_req_count,
                        PW1_IC
                    );
                    errors = errors + 1;
                end
                if (output_count != OC_GROUPS) begin
                    $display(
                        "ERROR output_count got=%0d expected=%0d",
                        output_count,
                        OC_GROUPS
                    );
                    errors = errors + 1;
                end
            end

            row_packer_ready = 1'b1;
            ready_tile_t_base = test_t_base[TIME_W-1:0];
        end
    endtask

    task run_with_busy_start_pulse;
        begin
            test_mode = 0;
            test_oc_base = 24;
            test_t_base = 80;
            weight_ready_mode = READY_NONE;
            act_ready_mode = READY_NONE;
            resp_mode = RESP_ONE_CYCLE;
            out_ready_mode = OUT_READY_NONE;
            weight_req_count = 0;
            act_req_count = 0;
            tile_req_count = 0;
            output_count = 0;
            row_packer_ready = 1'b1;
            ready_tile_t_base = test_t_base[TIME_W-1:0];

            launch();

            repeat (3) @(negedge clk);
            start = 1'b1;
            oc_base = 6'd56;
            tile_t_base = 9'd344;
            @(negedge clk);
            start = 1'b0;

            wait_done();
            if (!last_timeout && (output_count != OC_GROUPS)) begin
                $display(
                    "ERROR busy-start output_count got=%0d expected=%0d",
                    output_count,
                    OC_GROUPS
                );
                errors = errors + 1;
            end
        end
    endtask

    task run_with_busy_bn_write;
        begin
            test_mode = 1;
            test_oc_base = 32;
            test_t_base = 84;
            weight_ready_mode = READY_NONE;
            act_ready_mode = READY_NONE;
            resp_mode = RESP_ONE_CYCLE;
            out_ready_mode = OUT_READY_NONE;
            weight_req_count = 0;
            act_req_count = 0;
            tile_req_count = 0;
            output_count = 0;
            row_packer_ready = 1'b1;
            ready_tile_t_base = test_t_base[TIME_W-1:0];

            launch();

            @(negedge clk);
            w_fold_we = 1'b1;
            w_fold_oc = test_oc_base[5:0];
            w_fold_wdata = 16'sd4096;
            bias_fold_we = 1'b1;
            bias_fold_oc = test_oc_base[5:0];
            bias_fold_wdata = 16'sd4096;
            @(negedge clk);
            w_fold_we = 1'b0;
            bias_fold_we = 1'b0;

            wait_done();
            if (!last_timeout && (output_count != OC_GROUPS)) begin
                $display(
                    "ERROR busy-bn output_count got=%0d expected=%0d",
                    output_count,
                    OC_GROUPS
                );
                errors = errors + 1;
            end
        end
    endtask

    task reset_during_busy;
        begin
            test_mode = 0;
            test_oc_base = 40;
            test_t_base = 88;
            weight_ready_mode = READY_PERIODIC;
            act_ready_mode = READY_LATE;
            resp_mode = RESP_ONE_CYCLE;
            out_ready_mode = OUT_READY_DELAY;
            weight_req_count = 0;
            act_req_count = 0;
            tile_req_count = 0;
            output_count = 0;
            row_packer_ready = 1'b1;
            ready_tile_t_base = test_t_base[TIME_W-1:0];

            launch();

            repeat (5) @(negedge clk);
            rst_n = 1'b0;
            start = 1'b0;
            w_fold_we = 1'b0;
            bias_fold_we = 1'b0;
            #1;
            if (busy !== 1'b0) begin
                $display("ERROR PW1 busy is not low after mid-run reset");
                errors = errors + 1;
            end
            if (out_valid !== 1'b0) begin
                $display("ERROR PW1 out_valid is high after mid-run reset");
                errors = errors + 1;
            end

            repeat (2) @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

    task run_with_wrong_tile_ready_first;
        begin
            test_mode = 1;
            test_oc_base = 48;
            test_t_base = 96;
            weight_ready_mode = READY_NONE;
            act_ready_mode = READY_NONE;
            resp_mode = RESP_ONE_CYCLE;
            out_ready_mode = OUT_READY_NONE;
            weight_req_count = 0;
            act_req_count = 0;
            tile_req_count = 0;
            output_count = 0;
            row_packer_ready = 1'b1;
            ready_tile_t_base = 9'd100;

            launch();

            repeat (6) begin
                @(posedge clk);
                #1;
                if (weight_req_valid || act_req_valid) begin
                    $display(
                        "ERROR PW1 requested data while only wrong tile was ready"
                    );
                    errors = errors + 1;
                end
                @(negedge clk);
            end

            ready_tile_t_base = test_t_base[TIME_W-1:0];

            wait_done();
            if (!last_timeout && (output_count != OC_GROUPS)) begin
                $display(
                    "ERROR wrong-tile output_count got=%0d expected=%0d",
                    output_count,
                    OC_GROUPS
                );
                errors = errors + 1;
            end
        end
    endtask

    task run_file_golden_cases;
        integer case_i;
        begin
            load_file_bn();
            for (case_i = 0; case_i < FILE_CASES; case_i = case_i + 1) begin
                run_checked(
                    FILE_MODE,
                    0,
                    file_case_t_base[case_i],
                    case_i,
                    (case_i % 2) ? READY_PERIODIC : READY_NONE,
                    (case_i % 2) ? READY_NONE : READY_PERIODIC,
                    (case_i == 1) ? RESP_ZERO_CYCLE : RESP_ONE_CYCLE,
                    (case_i == 2) ? OUT_READY_PERIODIC : OUT_READY_NONE
                );
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        row_packer_ready = 1'b1;
        ready_tile_t_base = {TIME_W{1'b0}};
        oc_base = 6'd0;
        tile_t_base = {TIME_W{1'b0}};
        weight_req_ready = 1'b1;
        weight_vec_valid_reg = 1'b0;
        weight_vec_reg = {(OC_LANES*DATA_W){1'b0}};
        act_req_ready = 1'b1;
        act_vec_valid_reg = 1'b0;
        act_vec_reg = {(ROWS*DATA_W){1'b0}};
        w_fold_we = 1'b0;
        w_fold_oc = 6'd0;
        w_fold_wdata = 16'sd0;
        bias_fold_we = 1'b0;
        bias_fold_oc = 6'd0;
        bias_fold_wdata = 16'sd0;
        out_ready = 1'b1;
        errors = 0;
        test_mode = 0;
        test_oc_base = 0;
        test_t_base = 0;
        test_input_delay = 0;
        weight_ready_mode = READY_NONE;
        act_ready_mode = READY_NONE;
        out_ready_mode = OUT_READY_NONE;
        resp_mode = RESP_ONE_CYCLE;
        weight_ready_cycle = 0;
        act_ready_cycle = 0;
        out_ready_cycle = 0;
        weight_req_count = 0;
        act_req_count = 0;
        tile_req_count = 0;
        output_count = 0;
        last_timeout = 0;

        repeat (5) @(negedge clk);
        rst_n = 1'b1;

        load_bn();

        // Basic 1-cycle response, no stalls. One start must emit all 8
        // output-channel groups for the requested 4-row input tile.
        run_checked(0, 0, 0, 0, READY_NONE, READY_NONE, RESP_ONE_CYCLE, OUT_READY_NONE);

        // Start before the row packer has a complete 4-row input tile.
        run_checked(1, 8, 4, 6, READY_NONE, READY_NONE, RESP_ONE_CYCLE, OUT_READY_NONE);

        // Independent request-side backpressure.
        run_checked(
            0,
            16,
            8,
            0,
            READY_PERIODIC,
            READY_LATE,
            RESP_ONE_CYCLE,
            OUT_READY_NONE
        );

        // Combinational activation/weight sources: req and response fire together.
        run_checked(1, 24, 12, 0, READY_NONE, READY_NONE, RESP_ZERO_CYCLE, OUT_READY_NONE);

        // Output backpressure: out_valid must hold the pooled tile.
        run_checked(0, 32, 16, 0, READY_NONE, READY_NONE, RESP_ONE_CYCLE, OUT_READY_DELAY);

        // Long output backpressure: out_valid must hold for 35+ cycles and
        // done must not pulse before out_ready accepts the tile.
        run_checked(1, 40, 18, 0, READY_NONE, READY_NONE, RESP_ONE_CYCLE, OUT_READY_LONG);

        // A row packer may have some tile ready, but PW1 must wait for the
        // exact requested tile_t_base.
        run_with_wrong_tile_ready_first();

        // The legacy oc_base input is ignored by the full-channel PW1 job.
        // These repeated starts use different external oc_base values but each
        // job must still internally emit oc_base=0,8,...,56.
        for (oc = 0; oc < PW1_OC; oc = oc + OC_LANES) begin
            run_checked(1, oc, 20, 0, READY_NONE, READY_NONE, RESP_ONE_CYCLE, OUT_READY_NONE);
        end

        // Last aligned high-resolution PW1 tile: pool output base should be 172.
        run_checked(0, 56, 344, 0, READY_LATE, READY_PERIODIC, RESP_ONE_CYCLE, OUT_READY_PERIODIC);

        // Back-to-back jobs, no reset between them.
        run_checked(0, 0, 24, 0, READY_NONE, READY_NONE, RESP_ONE_CYCLE, OUT_READY_NONE);
        run_checked(1, 8, 28, 0, READY_PERIODIC, READY_NONE, RESP_ONE_CYCLE, OUT_READY_NONE);

        // Stray start during MAC must be ignored.
        run_with_busy_start_pulse();

        // Runtime BN writes are ignored; active job keeps preloaded BN params.
        run_with_busy_bn_write();

        // Mid-run reset aborts active tile and leaves the core reusable.
        reset_during_busy();
        load_bn();
        run_checked(0, 16, 92, 0, READY_NONE, READY_NONE, RESP_ONE_CYCLE, OUT_READY_NONE);

        run_file_golden_cases();

        if (errors == 0) begin
            $display("PASS pw_conv1_array_4x8 self-check");
            $finish;
        end else begin
            $display("FAIL pw_conv1_array_4x8 errors=%0d", errors);
            $finish;
        end
    end

endmodule
