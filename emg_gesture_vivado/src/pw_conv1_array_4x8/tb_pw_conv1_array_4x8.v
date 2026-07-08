`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_pw_conv1_array_4x8 #(
    parameter integer BRAM_READ_LATENCY = 1
);

    // Top-level wrapper test:
    // - activation input/cases come from this folder's deterministic testdata;
    // - PW1 weights and folded BN parameters come from weight_data/pw1, matching
    //   blk_mem_gen_pw_conv1_weight and the wrapper's default BN init files.
    //
    // The synthetic testdata/weight.mem, bn_*.mem, and expected_pool.mem files
    // remain for tb_pw_conv1_array_4x8_compute. This wrapper TB intentionally
    // has no external weight stream.

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
    localparam integer INPUT_LEN  = 348;
    localparam integer TOP_CASES  = 9;
    localparam integer DONE_TIMEOUT = 10000;

    localparam integer STALL_NONE     = 0;
    localparam integer STALL_PERIODIC = 1;
    localparam integer STALL_LATE     = 2;

    localparam integer OUT_STALL_NONE     = 0;
    localparam integer OUT_STALL_DELAY    = 1;
    localparam integer OUT_STALL_PERIODIC = 2;
    localparam integer OUT_STALL_LONG     = 3;

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
    integer row;
    integer col;
    integer test_oc_base;
    integer test_t_base;
    integer top_case_idx;
    integer act_stall_mode;
    integer out_stall_mode;
    integer act_ready_cycle;
    integer out_ready_cycle;
    integer act_req_count;
    integer act_resp_count;
    integer weight_req_count;
    integer tile_req_count;
    integer output_count;
    integer last_timeout;
    integer case_i;

    reg signed [DATA_W-1:0] file_input [0:INPUT_LEN*PW1_IC-1];
    reg [15:0] file_top_case_t_base [0:TOP_CASES-1];
    reg signed [DATA_W-1:0] file_expected_top [0:TOP_CASES*POOL_ROWS*PW1_OC-1];
    reg signed [DATA_W-1:0] expected_bn_scale [0:PW1_OC-1];
    reg signed [DATA_W-1:0] expected_bn_bias [0:PW1_OC-1];

    wire input_tile_req_fire_tb;
    wire act_req_fire_tb;
    wire act_vec_fire_tb;
    wire act_vec_blocked;
    wire out_fire_tb;
    wire weight_req_fire_tb;

    assign input_tile_req_ready = row_packer_ready
        && (input_tile_req_t_base == ready_tile_t_base);
    assign input_tile_req_fire_tb = input_tile_req_valid && input_tile_req_ready;
    assign act_req_fire_tb = act_req_valid && act_req_ready;
    assign act_vec_fire_tb = act_vec_valid && act_vec_ready;
    assign act_vec_blocked = act_vec_valid && !act_vec_ready;
    assign out_fire_tb = out_valid && out_ready;
    assign weight_req_fire_tb = dut.weight_req_valid && dut.weight_req_ready;

    assign act_vec_valid = act_vec_valid_reg;
    assign act_vec = act_vec_reg;

    pw_conv1_array_4x8 #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .ROWS(ROWS),
        .POOL_ROWS(POOL_ROWS),
        .OC_LANES(OC_LANES),
        .PW1_IC(PW1_IC),
        .PW1_OC(PW1_OC),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .oc_base(oc_base),
        .tile_t_base(tile_t_base),
        .input_tile_req_valid(input_tile_req_valid),
        .input_tile_req_t_base(input_tile_req_t_base),
        .input_tile_req_ready(input_tile_req_ready),
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
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv1_array_4x8/testdata/top_case_t_base.mem"},
            file_top_case_t_base
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/pw_conv1_array_4x8/testdata/expected_top_checkpoint.mem"},
            file_expected_top
        );
        $readmemh({`PROJECT_ROOT, "/weight_data/pw1/bn_scale.mem"}, expected_bn_scale);
        $readmemh({`PROJECT_ROOT, "/weight_data/pw1/bn_bias.mem"}, expected_bn_bias);
    end

    always #5 clk = ~clk;

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_req_ready <= 1'b1;
            act_ready_cycle <= 0;
        end else if (busy) begin
            act_ready_cycle <= act_ready_cycle + 1;
            case (act_stall_mode)
                STALL_NONE: begin
                    act_req_ready <= !act_vec_blocked;
                end

                STALL_PERIODIC: begin
                    act_req_ready <= ((act_ready_cycle % 5) != 1) && !act_vec_blocked;
                end

                STALL_LATE: begin
                    act_req_ready <= (act_ready_cycle >= 3) && !act_vec_blocked;
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
            act_vec_reg <= make_act_vec(act_req_t_base, act_req_k);
        end else begin
            act_vec_valid_reg <= 1'b0;
            act_vec_reg <= {(ROWS*DATA_W){1'b0}};
        end
    end

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_ready <= 1'b1;
            out_ready_cycle <= 0;
        end else if (out_valid) begin
            out_ready_cycle <= out_ready_cycle + 1;
            case (out_stall_mode)
                OUT_STALL_NONE: begin
                    out_ready <= 1'b1;
                end

                OUT_STALL_DELAY: begin
                    out_ready <= (out_ready_cycle >= 5);
                end

                OUT_STALL_PERIODIC: begin
                    out_ready <= ((out_ready_cycle % 4) != 1);
                end

                OUT_STALL_LONG: begin
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
            tile_req_count <= 0;
            act_req_count <= 0;
            act_resp_count <= 0;
            weight_req_count <= 0;
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

            if (act_req_fire_tb) begin
                check_act_request();
                act_req_count <= act_req_count + 1;
            end

            if (act_vec_fire_tb) begin
                act_resp_count <= act_resp_count + 1;
            end

            if (weight_req_fire_tb) begin
                check_weight_request();
                weight_req_count <= weight_req_count + 1;
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

    function signed [DATA_W-1:0] act_value;
        input integer t_idx;
        input integer ch_idx;
        begin
            act_value = file_input[t_idx*PW1_IC + ch_idx];
        end
    endfunction

    function signed [ROWS*DATA_W-1:0] make_act_vec;
        input integer t_base_i;
        input integer k_idx;
        integer local_row;
        begin
            make_act_vec = {(ROWS*DATA_W){1'b0}};
            for (local_row = 0; local_row < ROWS; local_row = local_row + 1) begin
                make_act_vec[local_row*DATA_W +: DATA_W]
                    = act_value(t_base_i + local_row, k_idx);
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

    function signed [DATA_W-1:0] expected_top_value;
        input integer pool_row;
        input integer oc_idx;
        begin
            expected_top_value =
                file_expected_top[top_case_idx*POOL_ROWS*PW1_OC + pool_row*PW1_OC + oc_idx];
        end
    endfunction

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

    task check_weight_request;
        integer expected_group;
        integer expected_oc_base;
        integer expected_k;
        begin
            expected_group = weight_req_count / PW1_IC;
            expected_oc_base = expected_group * OC_LANES;
            expected_k = weight_req_count % PW1_IC;

            if (dut.weight_req_oc_base !== expected_oc_base[5:0]) begin
                $display(
                    "ERROR internal weight_req_oc_base got=%0d expected=%0d count=%0d",
                    dut.weight_req_oc_base,
                    expected_oc_base,
                    weight_req_count
                );
                errors = errors + 1;
            end
            if (dut.weight_req_k !== expected_k[5:0]) begin
                $display(
                    "ERROR internal weight_req_k got=%0d expected=%0d count=%0d",
                    dut.weight_req_k,
                    expected_k,
                    weight_req_count
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
                    expected = expected_top_value(row, expected_oc_base + col);
                    if (get_out_lane(row, col) !== expected) begin
                        $display(
                            "ERROR case=%0d pool_row=%0d col=%0d oc=%0d got=%0d expected=%0d",
                            top_case_idx,
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
            while ((done !== 1'b1) && (timeout < DONE_TIMEOUT)) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end

            if (done !== 1'b1) begin
                $display(
                    "ERROR timeout case=%0d oc_base=%0d t_base=%0d",
                    top_case_idx,
                    test_oc_base,
                    test_t_base
                );
                errors = errors + 1;
                last_timeout = 1;
            end
        end
    endtask

    task run_checked;
        input integer case_idx_i;
        input integer oc_base_i;
        input integer input_delay_i;
        input integer act_stall_i;
        input integer out_stall_i;
        integer wait_i;
        begin
            top_case_idx = case_idx_i;
            test_oc_base = oc_base_i;
            test_t_base = file_top_case_t_base[case_idx_i];
            act_stall_mode = act_stall_i;
            out_stall_mode = out_stall_i;
            act_req_count = 0;
            act_resp_count = 0;
            weight_req_count = 0;
            tile_req_count = 0;
            output_count = 0;
            ready_tile_t_base = test_t_base[TIME_W-1:0];
            row_packer_ready = (input_delay_i == 0);

            launch();

            if (input_delay_i > 0) begin
                for (wait_i = 0; wait_i < input_delay_i; wait_i = wait_i + 1) begin
                    @(posedge clk);
                    #1;
                    if (dut.weight_req_valid || act_req_valid) begin
                        $display("ERROR PW1 requested data before input tile ready");
                        errors = errors + 1;
                    end
                    @(negedge clk);
                end
                row_packer_ready = 1'b1;
            end

            wait_done();
            if (!last_timeout) begin
                check_job_counters();
            end

            row_packer_ready = 1'b1;
            ready_tile_t_base = test_t_base[TIME_W-1:0];
        end
    endtask

    task check_job_counters;
        begin
            if (tile_req_count != 1) begin
                $display("ERROR tile_req_count got=%0d expected=1", tile_req_count);
                errors = errors + 1;
            end
            if (act_req_count != OC_GROUPS * PW1_IC) begin
                $display(
                    "ERROR act_req_count got=%0d expected=%0d",
                    act_req_count,
                    OC_GROUPS * PW1_IC
                );
                errors = errors + 1;
            end
            if (act_resp_count != OC_GROUPS * PW1_IC) begin
                $display(
                    "ERROR act_resp_count got=%0d expected=%0d",
                    act_resp_count,
                    OC_GROUPS * PW1_IC
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
            if (output_count != OC_GROUPS) begin
                $display(
                    "ERROR output_count got=%0d expected=%0d",
                    output_count,
                    OC_GROUPS
                );
                errors = errors + 1;
            end
            if (dut.u_weight.u_ctrl.invalid_req_count != 0) begin
                $display(
                    "ERROR top weight invalid_req_count=%0d",
                    dut.u_weight.u_ctrl.invalid_req_count
                );
                errors = errors + 1;
            end
        end
    endtask

    task check_autoload_inputs;
        begin
            if ((^file_input[0]) === 1'bx) begin
                $display("ERROR PW1 TB input.mem did not load");
                errors = errors + 1;
            end
            if ((^file_top_case_t_base[0]) === 1'bx) begin
                $display("ERROR PW1 TB top_case_t_base.mem did not load");
                errors = errors + 1;
            end
            if ((^file_expected_top[0]) === 1'bx) begin
                $display("ERROR PW1 TB expected_top_checkpoint.mem did not load");
                errors = errors + 1;
            end
            if ((^expected_bn_scale[0]) === 1'bx) begin
                $display("ERROR PW1 expected bn_scale.mem did not load");
                errors = errors + 1;
            end
            if ((^expected_bn_bias[0]) === 1'bx) begin
                $display("ERROR PW1 expected bn_bias.mem did not load");
                errors = errors + 1;
            end
            if (dut.u_compute.w_fold_mem[0] !== expected_bn_scale[0]) begin
                $display(
                    "ERROR PW1 BN scale autoload mismatch got=%h expected=%h",
                    dut.u_compute.w_fold_mem[0],
                    expected_bn_scale[0]
                );
                errors = errors + 1;
            end
            if (dut.u_compute.bias_fold_mem[0] !== expected_bn_bias[0]) begin
                $display(
                    "ERROR PW1 BN bias autoload mismatch got=%h expected=%h",
                    dut.u_compute.bias_fold_mem[0],
                    expected_bn_bias[0]
                );
                errors = errors + 1;
            end
        end
    endtask

    task run_with_wrong_tile_ready_first;
        begin
            top_case_idx = 6;
            test_oc_base = 48;
            test_t_base = file_top_case_t_base[top_case_idx];
            act_stall_mode = STALL_NONE;
            out_stall_mode = OUT_STALL_NONE;
            act_req_count = 0;
            act_resp_count = 0;
            weight_req_count = 0;
            tile_req_count = 0;
            output_count = 0;
            row_packer_ready = 1'b1;
            ready_tile_t_base = test_t_base[TIME_W-1:0] + 9'd4;

            launch();

            repeat (6) begin
                @(posedge clk);
                #1;
                if (dut.weight_req_valid || act_req_valid) begin
                    $display("ERROR PW1 requested data while only wrong tile was ready");
                    errors = errors + 1;
                end
                @(negedge clk);
            end

            ready_tile_t_base = test_t_base[TIME_W-1:0];
            wait_done();
            if (!last_timeout) begin
                check_job_counters();
            end
        end
    endtask

    task run_with_busy_start_pulse;
        begin
            top_case_idx = 5;
            test_oc_base = 24;
            test_t_base = file_top_case_t_base[top_case_idx];
            act_stall_mode = STALL_NONE;
            out_stall_mode = OUT_STALL_NONE;
            act_req_count = 0;
            act_resp_count = 0;
            weight_req_count = 0;
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
            if (!last_timeout) begin
                check_job_counters();
            end
        end
    endtask

    task reset_during_busy;
        begin
            top_case_idx = 4;
            test_oc_base = 40;
            test_t_base = file_top_case_t_base[top_case_idx];
            act_stall_mode = STALL_PERIODIC;
            out_stall_mode = OUT_STALL_DELAY;
            act_req_count = 0;
            act_resp_count = 0;
            weight_req_count = 0;
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

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        row_packer_ready = 1'b1;
        ready_tile_t_base = {TIME_W{1'b0}};
        oc_base = 6'd0;
        tile_t_base = {TIME_W{1'b0}};
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
        test_oc_base = 0;
        test_t_base = 0;
        top_case_idx = 0;
        act_stall_mode = STALL_NONE;
        out_stall_mode = OUT_STALL_NONE;
        act_ready_cycle = 0;
        out_ready_cycle = 0;
        act_req_count = 0;
        act_resp_count = 0;
        weight_req_count = 0;
        tile_req_count = 0;
        output_count = 0;
        last_timeout = 0;

        repeat (5) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        check_autoload_inputs();

        run_checked(0, 0, 0, STALL_NONE, OUT_STALL_NONE);
        run_checked(1, 8, 6, STALL_NONE, OUT_STALL_NONE);
        run_checked(2, 16, 0, STALL_PERIODIC, OUT_STALL_NONE);
        run_checked(3, 24, 0, STALL_NONE, OUT_STALL_DELAY);

        // Back-to-back jobs, no reset between them.
        run_checked(4, 32, 0, STALL_NONE, OUT_STALL_NONE);
        run_checked(5, 40, 0, STALL_PERIODIC, OUT_STALL_PERIODIC);

        run_with_wrong_tile_ready_first();

        // The legacy oc_base input is ignored by the full-channel PW1 job.
        // Sweep it anyway; every start must still emit oc_base=0,8,...,56.
        for (case_i = 0; case_i < OC_GROUPS; case_i = case_i + 1) begin
            run_checked(2, case_i * OC_LANES, 0, STALL_NONE, OUT_STALL_NONE);
        end

        run_checked(7, 48, 0, STALL_LATE, OUT_STALL_PERIODIC);
        run_checked(8, 56, 0, STALL_PERIODIC, OUT_STALL_LONG);

        run_with_busy_start_pulse();

        reset_during_busy();
        run_checked(0, 16, 0, STALL_NONE, OUT_STALL_NONE);

        if (errors == 0) begin
            $display("PASS pw_conv1_array_4x8 top self-check");
            $finish;
        end else begin
            $display("FAIL pw_conv1_array_4x8 top errors=%0d", errors);
            $finish;
        end
    end

endmodule

`ifdef PW1_MOCK_WEIGHT_ROM
`ifndef PW1_MOCK_ROM_READ_LATENCY
`define PW1_MOCK_ROM_READ_LATENCY 1
`endif

module blk_mem_gen_pw_conv1_weight (
    input  wire clka,
    input  wire ena,
    input  wire [7:0] addra,
    output reg  [127:0] douta
);
    localparam integer READ_LATENCY = `PW1_MOCK_ROM_READ_LATENCY;

    reg [127:0] mem [0:255];
    reg [READ_LATENCY-1:0] en_pipe;
    reg [7:0] addr_pipe [0:READ_LATENCY-1];

    integer init_i;
    integer pipe_i;

    initial begin
        douta = 128'd0;
        en_pipe = {READ_LATENCY{1'b0}};
        for (init_i = 0; init_i < 256; init_i = init_i + 1) begin
            mem[init_i] = {128{1'bx}};
        end
        for (pipe_i = 0; pipe_i < READ_LATENCY; pipe_i = pipe_i + 1) begin
            addr_pipe[pipe_i] = 8'd0;
        end
        $readmemh({`PROJECT_ROOT, "/weight_data/pw1/weight_packed.mem"}, mem);
        #1;
        if ((^mem[0]) === 1'bx) begin
            $display("ERROR PW1 mock weight ROM autoload failed");
            $finish;
        end
    end

    always @(posedge clka) begin
        en_pipe[0] <= ena;
        addr_pipe[0] <= addra;
        for (pipe_i = 1; pipe_i < READ_LATENCY; pipe_i = pipe_i + 1) begin
            en_pipe[pipe_i] <= en_pipe[pipe_i-1];
            addr_pipe[pipe_i] <= addr_pipe[pipe_i-1];
        end
        if (en_pipe[READ_LATENCY-1]) begin
            douta <= mem[addr_pipe[READ_LATENCY-1]];
        end
    end
endmodule
`endif
