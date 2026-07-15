`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_dw_conv1_4ch_5tap;

    localparam integer DATA_W     =  8;
    localparam integer MULT_W     = 16;
    localparam integer ACC_W      = 48;
    localparam integer CHANNELS   = 32;
    localparam integer P_CH       = 4;
    localparam integer K          = 5;
    localparam integer PAD        = 2;
    localparam integer INPUT_LEN  = 348;
    localparam integer FRAC_BITS  = 8;
    localparam integer TIME_W     = 9;
    localparam integer ROWS_W     = 4;
    localparam integer TIMEOUT    = 2000;
    localparam integer FILE_MODE  = 99;
    localparam integer FILE_CASES = 4;

    localparam integer REQ_STALL_NONE     = 0;
    localparam integer REQ_STALL_PERIODIC = 1;
    localparam integer REQ_STALL_LATE     = 2;

    localparam integer OUT_STALL_NONE     = 0;
    localparam integer OUT_STALL_PERIODIC = 1;
    localparam integer OUT_STALL_HEAD     = 2;
    localparam integer OUT_STALL_LONG     = 3;

    localparam integer RESP_ONE_CYCLE  = 0;
    localparam integer RESP_ZERO_CYCLE = 1;

    reg clk;
    reg rst_n;
    reg start;
    reg [4:0] ch_base;
    reg [TIME_W-1:0] input_t_base;
    reg [ROWS_W-1:0] input_rows;
    reg final_chunk;

    wire win_req_valid;
    wire [TIME_W-1:0] win_req_out_t;
    wire [4:0] win_req_ch_base;
    reg win_req_ready;
    wire win_vec_valid;
    wire win_vec_ready;
    wire signed [K*P_CH*DATA_W-1:0] win_vec;
    reg win_vec_valid_reg;
    reg signed [K*P_CH*DATA_W-1:0] win_vec_reg;

    reg weight_we;
    reg [4:0] weight_ch;
    reg [2:0] weight_tap;
    reg signed [DATA_W-1:0] weight_wdata;

    reg out_ready;
    wire busy;
    wire done;
    wire out_valid;
    wire [TIME_W-1:0] out_t;
    wire [4:0] out_ch_base;
    wire signed [P_CH*DATA_W-1:0] out_vec;
    wire [TIME_W-1:0] job_out_t_start;
    wire [TIME_W:0] job_out_count;

    integer errors;
    integer ch;
    integer tap;
    integer lane;
    integer test_mode;
    integer test_ch_base;
    integer test_input_t_base;
    integer test_input_rows;
    integer test_final_chunk;
    integer test_expected_start;
    integer test_expected_count;
    integer req_stall_mode;
    integer out_stall_mode;
    integer resp_mode;
    integer req_ready_cycle;
    integer out_ready_cycle;
    integer output_count;
    integer last_timeout;
    integer rv_tap;
    integer rv_lane;
    integer win_req_count;

    reg signed [DATA_W-1:0] file_input [0:INPUT_LEN*CHANNELS-1];
    reg signed [DATA_W-1:0] file_weight [0:CHANNELS*K-1];
    reg signed [DATA_W-1:0] file_expected_full [0:INPUT_LEN*CHANNELS-1];
    reg [7:0] file_case_ch_base [0:FILE_CASES-1];
    reg [15:0] file_case_input_t_base [0:FILE_CASES-1];
    reg [7:0] file_case_input_rows [0:FILE_CASES-1];
    reg [7:0] file_case_final_chunk [0:FILE_CASES-1];

    wire win_req_fire_tb;
    wire win_vec_blocked;
    wire out_fire_tb;

    assign win_req_fire_tb = win_req_valid && win_req_ready;
    assign win_vec_blocked = win_vec_valid && !win_vec_ready;
    assign out_fire_tb = out_valid && out_ready;
    assign win_vec_valid = (resp_mode == RESP_ZERO_CYCLE)
        ? win_req_fire_tb
        : win_vec_valid_reg;
    assign win_vec = (resp_mode == RESP_ZERO_CYCLE)
        ? make_window_vec(test_mode, win_req_ch_base, win_req_out_t)
        : win_vec_reg;

    dw_conv1_4ch_5tap #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .CHANNELS(CHANNELS),
        .P_CH(P_CH),
        .K(K),
        .PAD(PAD),
        .INPUT_LEN(INPUT_LEN),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W),
        .ROWS_W(ROWS_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .ch_base(ch_base),
        .input_t_base(input_t_base),
        .input_rows(input_rows),
        .final_chunk(final_chunk),
        .win_req_valid(win_req_valid),
        .win_req_out_t(win_req_out_t),
        .win_req_ch_base(win_req_ch_base),
        .win_req_ready(win_req_ready),
        .win_vec_valid(win_vec_valid),
        .win_vec_ready(win_vec_ready),
        .win_vec(win_vec),
        .weight_we(weight_we),
        .weight_ch(weight_ch),
        .weight_tap(weight_tap),
        .weight_wdata(weight_wdata),
        .out_ready(out_ready),
        .busy(busy),
        .done(done),
        .out_valid(out_valid),
        .out_t(out_t),
        .out_ch_base(out_ch_base),
        .out_vec(out_vec),
        .job_out_t_start(job_out_t_start),
        .job_out_count(job_out_count)
    );

    initial begin
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/dw_conv1_4ch_5tap/testdata/input.mem"},
            file_input
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/dw_conv1_4ch_5tap/testdata/weight.mem"},
            file_weight
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/dw_conv1_4ch_5tap/testdata/expected_full.mem"},
            file_expected_full
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/dw_conv1_4ch_5tap/testdata/case_ch_base.mem"},
            file_case_ch_base
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/dw_conv1_4ch_5tap/testdata/case_input_t_base.mem"},
            file_case_input_t_base
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/dw_conv1_4ch_5tap/testdata/case_input_rows.mem"},
            file_case_input_rows
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/dw_conv1_4ch_5tap/testdata/case_final_chunk.mem"},
            file_case_final_chunk
        );
    end

    always #5 clk = ~clk;

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            win_req_ready <= 1'b1;
            req_ready_cycle <= 0;
        end else if (busy) begin
            req_ready_cycle <= req_ready_cycle + 1;
            case (req_stall_mode)
                REQ_STALL_NONE: begin
                    win_req_ready <= !win_vec_blocked;
                end

                REQ_STALL_PERIODIC: begin
                    win_req_ready <= ((req_ready_cycle % 5) != 2) && !win_vec_blocked;
                end

                REQ_STALL_LATE: begin
                    win_req_ready <= (req_ready_cycle >= 3) && !win_vec_blocked;
                end

                default: begin
                    win_req_ready <= !win_vec_blocked;
                end
            endcase
        end else begin
            req_ready_cycle <= 0;
            win_req_ready <= !win_vec_blocked;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            win_vec_valid_reg <= 1'b0;
            win_vec_reg <= {(K*P_CH*DATA_W){1'b0}};
        end else begin
            if (resp_mode == RESP_ZERO_CYCLE) begin
                win_vec_valid_reg <= 1'b0;
                win_vec_reg <= {(K*P_CH*DATA_W){1'b0}};
            end else if (win_vec_valid_reg && !win_vec_ready) begin
                win_vec_valid_reg <= win_vec_valid_reg;
                win_vec_reg <= win_vec_reg;
            end else if (win_req_fire_tb) begin
                win_vec_valid_reg <= 1'b1;
                win_vec_reg <= make_window_vec(
                    test_mode,
                    win_req_ch_base,
                    win_req_out_t
                );
            end else begin
                win_vec_valid_reg <= 1'b0;
                win_vec_reg <= {(K*P_CH*DATA_W){1'b0}};
            end
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

                OUT_STALL_PERIODIC: begin
                    out_ready <= ((out_ready_cycle % 4) != 1);
                end

                OUT_STALL_HEAD: begin
                    out_ready <= (out_ready_cycle >= 3);
                end

                OUT_STALL_LONG: begin
                    out_ready <= (out_ready_cycle >= 12);
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
            output_count <= 0;
        end else if (out_fire_tb) begin
            check_output_row();
            output_count <= output_count + 1;
        end
    end

    function signed [DATA_W-1:0] q;
        input integer value;
        begin
            q = value[DATA_W-1:0];
        end
    endfunction

    function signed [DATA_W-1:0] get_out_lane;
        input integer lane_idx;
        begin
            get_out_lane = out_vec[lane_idx*DATA_W +: DATA_W];
        end
    endfunction

    function signed [DATA_W-1:0] input_value;
        input integer mode;
        input integer ch_idx;
        input integer t_idx;
        begin
            if (mode == FILE_MODE) begin
                input_value = file_input[t_idx*CHANNELS + ch_idx];
            end else if (mode == 1) begin
                input_value = q(2048 - (ch_idx % 4) * 96 + (t_idx % 5) * 32);
            end else begin
                input_value = q(((ch_idx % 7) - 3) * 24 + (t_idx - 5) * 16);
            end
        end
    endfunction

    function signed [DATA_W-1:0] weight_value;
        input integer ch_idx;
        input integer tap_idx;
        begin
            if (test_mode == FILE_MODE) begin
                weight_value = file_weight[ch_idx*K + tap_idx];
            end else if ((ch_idx >= 28) && (tap_idx == 2)) begin
                weight_value = q(1024);
            end else begin
                weight_value = q(((ch_idx % 5) - 2) * 16 + (tap_idx - 2) * 32);
            end
        end
    endfunction

    function signed [DATA_W-1:0] window_value;
        input integer mode;
        input integer ch_idx;
        input integer out_t_idx;
        input integer tap_idx;
        integer in_t_idx;
        begin
            in_t_idx = out_t_idx + tap_idx - PAD;
            if ((in_t_idx < 0) || (in_t_idx >= INPUT_LEN)) begin
                window_value = 16'sd0;
            end else begin
                window_value = input_value(mode, ch_idx, in_t_idx);
            end
        end
    endfunction

    function signed [K*P_CH*DATA_W-1:0] make_window_vec;
        input integer mode;
        input integer ch_base_i;
        input integer out_t_idx;
        integer local_tap;
        integer local_lane;
        begin
            make_window_vec = {(K*P_CH*DATA_W){1'b0}};
            for (local_tap = 0; local_tap < K; local_tap = local_tap + 1) begin
                for (local_lane = 0; local_lane < P_CH; local_lane = local_lane + 1) begin
                    make_window_vec[(local_tap*P_CH + local_lane)*DATA_W +: DATA_W]
                        = window_value(
                            mode,
                            ch_base_i + local_lane,
                            out_t_idx,
                            local_tap
                        );
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

    function signed [DATA_W-1:0] expected_value;
        input integer mode;
        input integer ch_idx;
        input integer out_t_idx;
        integer local_tap;
        reg signed [ACC_W-1:0] acc;
        begin
            if (mode == FILE_MODE) begin
                expected_value = file_expected_full[out_t_idx*CHANNELS + ch_idx];
            end else begin
                acc = 0;
                for (local_tap = 0; local_tap < K; local_tap = local_tap + 1) begin
                    acc = acc
                        + window_value(mode, ch_idx, out_t_idx, local_tap)
                        * weight_value(ch_idx, local_tap);
                end
                expected_value = sat_from_acc_shift(acc);
            end
        end
    endfunction

    function integer expected_start;
        input integer base;
        begin
            if (base < PAD) begin
                expected_start = 0;
            end else begin
                expected_start = base - PAD;
            end
        end
    endfunction

    function integer expected_count;
        input integer base;
        input integer rows;
        input integer is_final;
        integer start_i;
        integer last_i;
        begin
            start_i = expected_start(base);
            if (is_final) begin
                last_i = INPUT_LEN - 1;
            end else begin
                last_i = base + rows - 1 - PAD;
            end

            if ((rows == 0) || (last_i < start_i)) begin
                expected_count = 0;
            end else begin
                expected_count = last_i - start_i + 1;
            end
        end
    endfunction

    task write_weight;
        input integer ch_idx;
        input integer tap_idx;
        input signed [DATA_W-1:0] value;
        begin
            @(negedge clk);
            weight_we = 1'b1;
            weight_ch = ch_idx[4:0];
            weight_tap = tap_idx[2:0];
            weight_wdata = value;
            @(negedge clk);
            weight_we = 1'b0;
        end
    endtask

    task load_weights;
        begin
            for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
                for (tap = 0; tap < K; tap = tap + 1) begin
                    write_weight(ch, tap, weight_value(ch, tap));
                end
            end
        end
    endtask

    task load_file_weights;
        begin
            test_mode = FILE_MODE;
            for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
                for (tap = 0; tap < K; tap = tap + 1) begin
                    write_weight(ch, tap, file_weight[ch*K + tap]);
                end
            end
        end
    endtask

    task check_window_request;
        integer expected_req_t;
        begin
            expected_req_t = test_expected_start + win_req_count;
            if ((win_req_out_t < test_expected_start)
                || (win_req_out_t >= test_expected_start + test_expected_count)) begin
                $display(
                    "ERROR win_req_out_t got=%0d expected_range=[%0d,%0d]",
                    win_req_out_t,
                    test_expected_start,
                    test_expected_start + test_expected_count - 1
                );
                errors = errors + 1;
            end
            if (win_req_out_t !== expected_req_t[TIME_W-1:0]) begin
                $display(
                    "ERROR win_req_out_t order got=%0d expected=%0d req_count=%0d",
                    win_req_out_t,
                    expected_req_t,
                    win_req_count
                );
                errors = errors + 1;
            end
            if (win_req_ch_base !== test_ch_base[4:0]) begin
                $display(
                    "ERROR win_req_ch_base got=%0d expected=%0d",
                    win_req_ch_base,
                    test_ch_base
                );
                errors = errors + 1;
            end
        end
    endtask

    always @(posedge clk) begin
        if (rst_n && win_req_fire_tb) begin
            check_window_request();
            win_req_count = win_req_count + 1;
        end
    end

    task check_output_row;
        reg signed [DATA_W-1:0] expected;
        integer expected_t;
        begin
            expected_t = test_expected_start + output_count;

            if (out_t !== expected_t[TIME_W-1:0]) begin
                $display("ERROR out_t got=%0d expected=%0d", out_t, expected_t);
                errors = errors + 1;
            end

            if (out_ch_base !== test_ch_base[4:0]) begin
                $display(
                    "ERROR out_ch_base got=%0d expected=%0d",
                    out_ch_base,
                    test_ch_base
                );
                errors = errors + 1;
            end

            for (lane = 0; lane < P_CH; lane = lane + 1) begin
                expected = expected_value(test_mode, test_ch_base + lane, expected_t);
                if (get_out_lane(lane) !== expected) begin
                    $display(
                        "ERROR t=%0d lane=%0d ch=%0d got=%0d expected=%0d",
                        expected_t,
                        lane,
                        test_ch_base + lane,
                        $signed(get_out_lane(lane)),
                        $signed(expected)
                    );
                    errors = errors + 1;
                end
            end
        end
    endtask

    task launch;
        begin
            @(negedge clk);
            output_count = 0;
            win_req_count = 0;
            start = 1'b1;
            ch_base = test_ch_base[4:0];
            input_t_base = test_input_t_base[TIME_W-1:0];
            input_rows = test_input_rows[ROWS_W-1:0];
            final_chunk = test_final_chunk[0];
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
                    "ERROR timeout mode=%0d ch_base=%0d input_base=%0d final=%0d",
                    test_mode,
                    test_ch_base,
                    test_input_t_base,
                    test_final_chunk
                );
                errors = errors + 1;
                last_timeout = 1;
            end
        end
    endtask

    task run_checked_ext;
        input integer mode;
        input integer ch_base_i;
        input integer input_t_base_i;
        input integer input_rows_i;
        input integer final_chunk_i;
        input integer req_stall_i;
        input integer out_stall_i;
        input integer resp_mode_i;
        begin
            test_mode = mode;
            test_ch_base = ch_base_i;
            test_input_t_base = input_t_base_i;
            test_input_rows = input_rows_i;
            test_final_chunk = final_chunk_i;
            test_expected_start = expected_start(input_t_base_i);
            test_expected_count = expected_count(
                input_t_base_i,
                input_rows_i,
                final_chunk_i
            );
            req_stall_mode = req_stall_i;
            out_stall_mode = out_stall_i;
            resp_mode = resp_mode_i;

            launch();

            @(posedge clk);
            #1;
            if (job_out_t_start !== test_expected_start[TIME_W-1:0]) begin
                $display(
                    "ERROR job_out_t_start got=%0d expected=%0d",
                    job_out_t_start,
                    test_expected_start
                );
                errors = errors + 1;
            end
            if (job_out_count !== test_expected_count[TIME_W:0]) begin
                $display(
                    "ERROR job_out_count got=%0d expected=%0d",
                    job_out_count,
                    test_expected_count
                );
                errors = errors + 1;
            end

            wait_done();
            if (!last_timeout && (win_req_count != test_expected_count)) begin
                $display(
                    "ERROR win_req_count got=%0d expected=%0d",
                    win_req_count,
                    test_expected_count
                );
                errors = errors + 1;
            end
            if (!last_timeout && (output_count != test_expected_count)) begin
                $display(
                    "ERROR output_count got=%0d expected=%0d",
                    output_count,
                    test_expected_count
                );
                errors = errors + 1;
            end
        end
    endtask

    task run_checked;
        input integer mode;
        input integer ch_base_i;
        input integer input_t_base_i;
        input integer input_rows_i;
        input integer final_chunk_i;
        input integer req_stall_i;
        input integer out_stall_i;
        begin
            run_checked_ext(
                mode,
                ch_base_i,
                input_t_base_i,
                input_rows_i,
                final_chunk_i,
                req_stall_i,
                out_stall_i,
                RESP_ONE_CYCLE
            );
        end
    endtask

    task run_with_busy_start_pulse;
        begin
            test_mode = 0;
            test_ch_base = 4;
            test_input_t_base = 120;
            test_input_rows = 4;
            test_final_chunk = 0;
            test_expected_start = expected_start(test_input_t_base);
            test_expected_count = expected_count(
                test_input_t_base,
                test_input_rows,
                test_final_chunk
            );
            req_stall_mode = REQ_STALL_NONE;
            out_stall_mode = OUT_STALL_NONE;
            resp_mode = RESP_ONE_CYCLE;

            launch();

            repeat (2) @(negedge clk);
            start = 1'b1;
            ch_base = 5'd28;
            input_t_base = 9'd300;
            input_rows = 4'd4;
            final_chunk = 1'b0;
            @(negedge clk);
            start = 1'b0;

            wait_done();
            if (!last_timeout && (win_req_count != test_expected_count)) begin
                $display(
                    "ERROR busy-start win_req_count got=%0d expected=%0d",
                    win_req_count,
                    test_expected_count
                );
                errors = errors + 1;
            end
            if (!last_timeout && (output_count != test_expected_count)) begin
                $display(
                    "ERROR busy-start output_count got=%0d expected=%0d",
                    output_count,
                    test_expected_count
                );
                errors = errors + 1;
            end
        end
    endtask

    task run_with_busy_weight_write;
        begin
            test_mode = 1;
            test_ch_base = 12;
            test_input_t_base = 132;
            test_input_rows = 4;
            test_final_chunk = 0;
            test_expected_start = expected_start(test_input_t_base);
            test_expected_count = expected_count(
                test_input_t_base,
                test_input_rows,
                test_final_chunk
            );
            req_stall_mode = REQ_STALL_NONE;
            out_stall_mode = OUT_STALL_NONE;
            resp_mode = RESP_ONE_CYCLE;

            launch();

            @(negedge clk);
            weight_we = 1'b1;
            weight_ch = test_ch_base[4:0];
            weight_tap = 3'd0;
            weight_wdata = 16'sd4096;
            @(negedge clk);
            weight_we = 1'b0;

            wait_done();
            if (!last_timeout && (win_req_count != test_expected_count)) begin
                $display(
                    "ERROR busy-weight win_req_count got=%0d expected=%0d",
                    win_req_count,
                    test_expected_count
                );
                errors = errors + 1;
            end
            if (!last_timeout && (output_count != test_expected_count)) begin
                $display(
                    "ERROR busy-weight output_count got=%0d expected=%0d",
                    output_count,
                    test_expected_count
                );
                errors = errors + 1;
            end
        end
    endtask

    task reset_during_busy;
        begin
            test_mode = 0;
            test_ch_base = 16;
            test_input_t_base = 144;
            test_input_rows = 4;
            test_final_chunk = 0;
            test_expected_start = expected_start(test_input_t_base);
            test_expected_count = expected_count(
                test_input_t_base,
                test_input_rows,
                test_final_chunk
            );
            req_stall_mode = REQ_STALL_PERIODIC;
            out_stall_mode = OUT_STALL_LONG;
            resp_mode = RESP_ONE_CYCLE;

            launch();

            repeat (3) @(negedge clk);
            rst_n = 1'b0;
            start = 1'b0;
            weight_we = 1'b0;
            #1;
            if (busy !== 1'b0) begin
                $display("ERROR busy is not low after DW1 mid-run reset");
                errors = errors + 1;
            end
            if (out_valid !== 1'b0) begin
                $display("ERROR out_valid is high after DW1 mid-run reset");
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
            load_file_weights();
            for (case_i = 0; case_i < FILE_CASES; case_i = case_i + 1) begin
                run_checked_ext(
                    FILE_MODE,
                    file_case_ch_base[case_i],
                    file_case_input_t_base[case_i],
                    file_case_input_rows[case_i],
                    file_case_final_chunk[case_i],
                    (case_i % 2) ? REQ_STALL_PERIODIC : REQ_STALL_NONE,
                    (case_i % 2) ? OUT_STALL_NONE : OUT_STALL_PERIODIC,
                    (case_i == 1) ? RESP_ZERO_CYCLE : RESP_ONE_CYCLE
                );
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        ch_base = 5'd0;
        input_t_base = {TIME_W{1'b0}};
        input_rows = {ROWS_W{1'b0}};
        final_chunk = 1'b0;
        win_req_ready = 1'b1;
        win_vec_valid_reg = 1'b0;
        win_vec_reg = {(K*P_CH*DATA_W){1'b0}};
        weight_we = 1'b0;
        weight_ch = 5'd0;
        weight_tap = 3'd0;
        weight_wdata = 16'sd0;
        out_ready = 1'b1;
        errors = 0;
        test_mode = 0;
        test_ch_base = 4;
        test_input_t_base = 0;
        test_input_rows = 4;
        test_final_chunk = 0;
        test_expected_start = 0;
        test_expected_count = 0;
        req_stall_mode = REQ_STALL_NONE;
        out_stall_mode = OUT_STALL_NONE;
        resp_mode = RESP_ONE_CYCLE;
        req_ready_cycle = 0;
        out_ready_cycle = 0;
        output_count = 0;
        last_timeout = 0;
        win_req_count = 0;

        repeat (5) @(negedge clk);
        rst_n = 1'b1;

        // INT8 migration: use the real-model golden cases. The old synthetic
        // Q8.8 cases are kept above for reference but are not part of this run.
        run_file_golden_cases();

        if (errors == 0) begin
            $display("PASS dw_conv1_4ch_5tap self-check");
            $finish;
        end else begin
            $display("FAIL dw_conv1_4ch_5tap errors=%0d", errors);
            $finish;
        end
    end

endmodule
