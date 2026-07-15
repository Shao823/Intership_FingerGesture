`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_stem_dw1_pipeline_top #(
    parameter integer DUT_PENDING_DEPTH = 8,
    parameter integer WATERMARK_STRESS_ONLY = 0
);

    localparam integer DATA_W       =  8;
    localparam integer MULT_W     = 16;
    localparam integer ACC_W        = 48;
    localparam integer ROWS         = 4;
    localparam integer OC_LANES     = 4;
    localparam integer STEM_OC      = 32;
    localparam integer STEM_IC      = 5;
    localparam integer INPUT_LEN    = 348;
    localparam integer TIME_W       = 9;
    localparam integer ROWS_W       = 4;
    localparam integer CH_GROUPS    = STEM_OC / OC_LANES;
    localparam integer TILE_COUNT   = (INPUT_LEN + ROWS - 1) / ROWS;
    localparam integer TOTAL_JOBS   = TILE_COUNT * CH_GROUPS;
    localparam integer TOTAL_ROWS   = INPUT_LEN * CH_GROUPS;
    localparam integer N_CASES      = 6;
    localparam integer ACT_TIME_WORDS = (INPUT_LEN + ROWS - 1) / ROWS;
    localparam integer ACT_RAM_DEPTH  = STEM_IC * ACT_TIME_WORDS;
    localparam integer ACT_ADDR_W     = (ACT_RAM_DEPTH <= 1)
        ? 1 : $clog2(ACT_RAM_DEPTH);
    localparam integer TIMEOUT      = 600000;
    localparam integer DUT_PENDING_CNT_W = (DUT_PENDING_DEPTH <= 1)
        ? 1 : $clog2(DUT_PENDING_DEPTH + 1);
    localparam integer LONG_STALL_START_CYCLE = 200;
    localparam integer LONG_STALL_END_CYCLE   = 8000;
    localparam integer MAX_CYCLES_NORMAL      = 36000;
    localparam integer MAX_CYCLES_BACKPRESSURE = 37000;
    localparam integer MAX_CYCLES_LONG_STALL  = 50000;

    localparam integer READY_ALWAYS   = 0;
    localparam integer READY_PERIODIC = 1;
    localparam integer READY_BURSTY   = 2;
    localparam integer READY_LONG_STALL = 3;

    reg clk;
    reg rst_n;
    reg start;

    reg act_wr_en;
    reg [ACT_ADDR_W-1:0] act_wr_addr;
    reg [ROWS*DATA_W-1:0] act_wr_data;
    wire act_wr_ready;

    reg stem_w_fold_we;
    reg [4:0] stem_w_fold_oc;
    reg signed [MULT_W-1:0] stem_w_fold_wdata;
    reg stem_bias_fold_we;
    reg [4:0] stem_bias_fold_oc;
    reg signed [31:0] stem_bias_fold_wdata;

    reg dw1_weight_we;
    reg [4:0] dw1_weight_ch;
    reg [2:0] dw1_weight_tap;
    reg signed [DATA_W-1:0] dw1_weight_wdata;

    reg dw1_out_ready;
    wire dw1_out_valid;
    wire [TIME_W-1:0] dw1_out_t;
    wire [4:0] dw1_out_ch_base;
    wire signed [OC_LANES*DATA_W-1:0] dw1_out_vec;

    wire busy;
    wire done;
    wire stem_busy;
    wire dw1_busy;
    wire buffer_wr_busy;
    wire buffer_rd_busy;
    wire buffer_stem_watermark_stall;
    wire stem_output_stall;
    wire scheduler_pending_full;
    wire [DUT_PENDING_CNT_W-1:0] pending_count_dbg;
    wire [31:0] cycle_count;
    wire [31:0] stem_jobs_started;
    wire [31:0] stem_jobs_done;
    wire [31:0] dw1_jobs_started;
    wire [31:0] dw1_jobs_done;
    wire [31:0] dw1_rows_out;
    wire [31:0] stem_start_blocked_pending_cycles;
    wire [31:0] stem_output_stall_cycles;
    wire [31:0] dw1_output_stall_cycles;
    wire [31:0] buffer_watermark_stall_cycles;
    wire [DUT_PENDING_CNT_W-1:0] max_pending_count;

    integer errors;
    integer current_case;
    integer ready_mode;
    integer ready_cycle;
    integer ready_stall_left;
    integer last_stalled_output_count;
    integer output_count;
    integer stem_tile_count;
    integer timeout;
    integer load_ch;
    integer load_word;
    integer load_addr;
    integer seen_i;
    integer group_i;
    integer lane_i;
    integer out_idx;
    integer expected_idx;
    integer case_error_start;

    reg signed [DATA_W-1:0] file_raw_input [0:N_CASES*INPUT_LEN*STEM_IC-1];
    reg signed [DATA_W-1:0] file_expected_stem [0:N_CASES*INPUT_LEN*STEM_OC-1];
    reg signed [DATA_W-1:0] file_expected_dw1 [0:N_CASES*INPUT_LEN*STEM_OC-1];
    reg seen [0:TOTAL_ROWS-1];
    reg last_valid [0:CH_GROUPS-1];
    reg [TIME_W-1:0] last_out_t [0:CH_GROUPS-1];

    wire out_fire;
    wire stem_fire;

    assign out_fire = dw1_out_valid && dw1_out_ready;
    assign stem_fire = dut.u_stem.out_valid && dut.u_stem.out_ready;

    stem_dw1_pipeline_top #(
        .PENDING_DEPTH(DUT_PENDING_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .act_wr_en(act_wr_en),
        .act_wr_addr(act_wr_addr),
        .act_wr_data(act_wr_data),
        .act_wr_ready(act_wr_ready),
        .stem_w_fold_we(stem_w_fold_we),
        .stem_w_fold_oc(stem_w_fold_oc),
        .stem_w_fold_wdata(stem_w_fold_wdata),
        .stem_bias_fold_we(stem_bias_fold_we),
        .stem_bias_fold_oc(stem_bias_fold_oc),
        .stem_bias_fold_wdata(stem_bias_fold_wdata),
        .dw1_weight_we(dw1_weight_we),
        .dw1_weight_ch(dw1_weight_ch),
        .dw1_weight_tap(dw1_weight_tap),
        .dw1_weight_wdata(dw1_weight_wdata),
        .dw1_out_ready(dw1_out_ready),
        .dw1_out_valid(dw1_out_valid),
        .dw1_out_t(dw1_out_t),
        .dw1_out_ch_base(dw1_out_ch_base),
        .dw1_out_vec(dw1_out_vec),
        .stem_busy(stem_busy),
        .dw1_busy(dw1_busy),
        .buffer_wr_busy(buffer_wr_busy),
        .buffer_rd_busy(buffer_rd_busy),
        .buffer_stem_watermark_stall(buffer_stem_watermark_stall),
        .stem_output_stall(stem_output_stall),
        .scheduler_pending_full(scheduler_pending_full),
        .pending_count_dbg(pending_count_dbg),
        .cycle_count(cycle_count),
        .stem_jobs_started(stem_jobs_started),
        .stem_jobs_done(stem_jobs_done),
        .dw1_jobs_started(dw1_jobs_started),
        .dw1_jobs_done(dw1_jobs_done),
        .dw1_rows_out(dw1_rows_out),
        .stem_start_blocked_pending_cycles(stem_start_blocked_pending_cycles),
        .stem_output_stall_cycles(stem_output_stall_cycles),
        .dw1_output_stall_cycles(dw1_output_stall_cycles),
        .buffer_watermark_stall_cycles(buffer_watermark_stall_cycles),
        .max_pending_count(max_pending_count)
    );

    initial begin
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pipeline/testdata/raw_input.mem"},
            file_raw_input
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pipeline/testdata/stem_expected_full.mem"},
            file_expected_stem
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pipeline/testdata/dw1_expected_full.mem"},
            file_expected_dw1
        );
    end

    always #5 clk = ~clk;

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dw1_out_ready <= 1'b1;
            ready_cycle <= 0;
            ready_stall_left <= 0;
            last_stalled_output_count <= -1;
        end else if (busy) begin
            ready_cycle <= ready_cycle + 1;
            if ((ready_mode == READY_LONG_STALL)
                && (ready_cycle >= LONG_STALL_START_CYCLE)
                && (ready_cycle < LONG_STALL_END_CYCLE)) begin
                dw1_out_ready <= 1'b0;
            end else if (ready_stall_left > 0) begin
                dw1_out_ready <= 1'b0;
                ready_stall_left <= ready_stall_left - 1;
            end else if ((ready_mode == READY_PERIODIC)
                && dw1_out_valid
                && (output_count != last_stalled_output_count)
                && ((output_count % 19) == 5)) begin
                dw1_out_ready <= 1'b0;
                ready_stall_left <= 1;
                last_stalled_output_count <= output_count;
            end else if ((ready_mode == READY_BURSTY)
                && dw1_out_valid
                && (output_count != last_stalled_output_count)
                && ((output_count % 23) == 7)) begin
                dw1_out_ready <= 1'b0;
                ready_stall_left <= 3;
                last_stalled_output_count <= output_count;
            end else begin
                dw1_out_ready <= 1'b1;
            end
        end else begin
            ready_cycle <= 0;
            ready_stall_left <= 0;
            last_stalled_output_count <= -1;
            dw1_out_ready <= 1'b1;
        end
    end

    function signed [DATA_W-1:0] get_out_lane;
        input integer lane;
        begin
            get_out_lane = dw1_out_vec[lane*DATA_W +: DATA_W];
        end
    endfunction

    function signed [DATA_W-1:0] get_stem_lane;
        input integer row;
        input integer lane;
        begin
            get_stem_lane =
                dut.u_stem.out_tile[(row*OC_LANES + lane)*DATA_W +: DATA_W];
        end
    endfunction

    function [ROWS*DATA_W-1:0] pack_activation_word;
        input integer case_idx;
        input integer ch_idx;
        input integer word_idx;
        integer lane;
        integer t_idx;
        begin
            pack_activation_word = {(ROWS*DATA_W){1'b0}};
            for (lane = 0; lane < ROWS; lane = lane + 1) begin
                t_idx = word_idx * ROWS + lane;
                if (t_idx < INPUT_LEN) begin
                    pack_activation_word[lane*DATA_W +: DATA_W]
                        = file_raw_input[
                            case_idx*INPUT_LEN*STEM_IC
                            + t_idx*STEM_IC
                            + ch_idx
                        ];
                end
            end
        end
    endfunction

    task clear_scoreboard;
        begin
            output_count = 0;
            stem_tile_count = 0;
            for (seen_i = 0; seen_i < TOTAL_ROWS; seen_i = seen_i + 1) begin
                seen[seen_i] = 1'b0;
            end
            for (group_i = 0; group_i < CH_GROUPS; group_i = group_i + 1) begin
                last_valid[group_i] = 1'b0;
                last_out_t[group_i] = {TIME_W{1'b0}};
            end
        end
    endtask

    task write_activation_word;
        input integer addr_i;
        input [ROWS*DATA_W-1:0] data_i;
        integer retry_count;
        begin
            retry_count = 0;
            @(negedge clk);
            act_wr_en = 1'b1;
            act_wr_addr = addr_i[ACT_ADDR_W-1:0];
            act_wr_data = data_i;

            while ((act_wr_ready !== 1'b1) && (retry_count < 1000)) begin
                retry_count = retry_count + 1;
                @(negedge clk);
                act_wr_en = 1'b1;
                act_wr_addr = addr_i[ACT_ADDR_W-1:0];
                act_wr_data = data_i;
            end

            if (act_wr_ready !== 1'b1) begin
                $display("ERROR activation RAM write timeout addr=%0d", addr_i);
                errors = errors + 1;
            end
        end
    endtask

    task load_activation_ram;
        input integer case_idx;
        begin
            for (load_ch = 0; load_ch < STEM_IC; load_ch = load_ch + 1) begin
                for (load_word = 0; load_word < ACT_TIME_WORDS; load_word = load_word + 1) begin
                    load_addr = load_ch * ACT_TIME_WORDS + load_word;
                    write_activation_word(
                        load_addr,
                        pack_activation_word(case_idx, load_ch, load_word)
                    );
                end
            end
            @(negedge clk);
            act_wr_en = 1'b0;
            act_wr_addr = {ACT_ADDR_W{1'b0}};
            act_wr_data = {(ROWS*DATA_W){1'b0}};
            repeat (4) @(posedge clk);
        end
    endtask

    task check_stem_tile;
        reg signed [DATA_W-1:0] expected;
        integer row;
        integer lane;
        integer t_idx;
        integer ch_idx;
        integer stem_expected_idx;
        begin
            if (dut.u_stem.out_tile_oc_base[1:0] !== 2'b00) begin
                $display(
                    "ERROR stem unaligned oc_base=%0d",
                    dut.u_stem.out_tile_oc_base
                );
                errors = errors + 1;
            end
            if (dut.u_stem.out_tile_oc_base > (STEM_OC - OC_LANES)) begin
                $display(
                    "ERROR stem oc_base out of range=%0d",
                    dut.u_stem.out_tile_oc_base
                );
                errors = errors + 1;
            end
            if (dut.u_stem.out_tile_t_base > (INPUT_LEN - ROWS)) begin
                $display(
                    "ERROR stem tile_t_base out of range=%0d",
                    dut.u_stem.out_tile_t_base
                );
                errors = errors + 1;
            end

            for (row = 0; row < ROWS; row = row + 1) begin
                t_idx = dut.u_stem.out_tile_t_base + row;
                for (lane = 0; lane < OC_LANES; lane = lane + 1) begin
                    ch_idx = dut.u_stem.out_tile_oc_base + lane;
                    stem_expected_idx = current_case*INPUT_LEN*STEM_OC
                        + t_idx*STEM_OC
                        + ch_idx;
                    expected = file_expected_stem[stem_expected_idx];
                    if (get_stem_lane(row, lane) !== expected) begin
                        $display(
                            "ERROR stem case=%0d t=%0d ch=%0d got=%0d expected=%0d",
                            current_case,
                            t_idx,
                            ch_idx,
                            $signed(get_stem_lane(row, lane)),
                            $signed(expected)
                        );
                        errors = errors + 1;
                    end
                end
            end

            stem_tile_count = stem_tile_count + 1;
        end
    endtask

    task check_output_row;
        reg signed [DATA_W-1:0] expected;
        integer group;
        integer seen_idx;
        begin
            if (dw1_out_ch_base[1:0] !== 2'b00) begin
                $display("ERROR unaligned out_ch_base=%0d", dw1_out_ch_base);
                errors = errors + 1;
            end
            if (dw1_out_ch_base > (STEM_OC - OC_LANES)) begin
                $display("ERROR out_ch_base out of range=%0d", dw1_out_ch_base);
                errors = errors + 1;
            end
            if (dw1_out_t >= INPUT_LEN) begin
                $display("ERROR out_t out of range=%0d", dw1_out_t);
                errors = errors + 1;
            end

            group = dw1_out_ch_base / OC_LANES;
            seen_idx = dw1_out_t * CH_GROUPS + group;

            if (seen[seen_idx]) begin
                $display(
                    "ERROR duplicate output t=%0d ch_base=%0d",
                    dw1_out_t,
                    dw1_out_ch_base
                );
                errors = errors + 1;
            end
            seen[seen_idx] = 1'b1;

            if (last_valid[group] && (dw1_out_t < last_out_t[group])) begin
                $display(
                    "ERROR non-monotonic bank=%0d out_t=%0d previous=%0d",
                    group,
                    dw1_out_t,
                    last_out_t[group]
                );
                errors = errors + 1;
            end
            last_valid[group] = 1'b1;
            last_out_t[group] = dw1_out_t;

            for (lane_i = 0; lane_i < OC_LANES; lane_i = lane_i + 1) begin
                expected_idx = current_case*INPUT_LEN*STEM_OC
                    + dw1_out_t*STEM_OC
                    + dw1_out_ch_base
                    + lane_i;
                expected = file_expected_dw1[expected_idx];
                if (get_out_lane(lane_i) !== expected) begin
                    $display(
                        "ERROR case=%0d t=%0d ch=%0d got=%0d expected=%0d",
                        current_case,
                        dw1_out_t,
                        dw1_out_ch_base + lane_i,
                        $signed(get_out_lane(lane_i)),
                        $signed(expected)
                    );
                    errors = errors + 1;
                end
            end

            output_count = output_count + 1;
        end
    endtask

    always @(posedge clk) begin
        if (rst_n && stem_fire) begin
            check_stem_tile();
        end
        if (rst_n && out_fire) begin
            check_output_row();
        end
    end

    task check_perf_and_stress;
        input integer case_idx;
        input integer ready_mode_i;
        integer cycle_limit;
        begin
            if (ready_mode_i == READY_LONG_STALL) begin
                cycle_limit = MAX_CYCLES_LONG_STALL;
            end else if (ready_mode_i == READY_ALWAYS) begin
                cycle_limit = MAX_CYCLES_NORMAL;
            end else begin
                cycle_limit = MAX_CYCLES_BACKPRESSURE;
            end

            if (cycle_count > cycle_limit) begin
                $display(
                    "ERROR case=%0d cycle_count got=%0d limit=%0d",
                    case_idx,
                    cycle_count,
                    cycle_limit
                );
                errors = errors + 1;
            end

            if ((ready_mode_i == READY_ALWAYS) && (max_pending_count > 2)) begin
                $display(
                    "ERROR case=%0d max_pending_count got=%0d expected <= 2",
                    case_idx,
                    max_pending_count
                );
                errors = errors + 1;
            end

            if (ready_mode_i == READY_LONG_STALL) begin
                if (dw1_output_stall_cycles == 0) begin
                    $display("ERROR long-stall case did not stall DW1 output");
                    errors = errors + 1;
                end

                if (DUT_PENDING_DEPTH < 33) begin
                    if (stem_start_blocked_pending_cycles == 0) begin
                        $display(
                            "ERROR long-stall default-depth case did not hit pending_full"
                        );
                        errors = errors + 1;
                    end
                    if (max_pending_count < (DUT_PENDING_DEPTH - 1)) begin
                        $display(
                            "ERROR long-stall default-depth max_pending got=%0d expected at least %0d",
                            max_pending_count,
                            DUT_PENDING_DEPTH - 1
                        );
                        errors = errors + 1;
                    end
                end else begin
                    if (buffer_watermark_stall_cycles == 0) begin
                        $display(
                            "ERROR long-stall deep-pending case did not hit buffer watermark"
                        );
                        errors = errors + 1;
                    end
                    if (stem_output_stall_cycles == 0) begin
                        $display(
                            "ERROR long-stall deep-pending case did not stall stem output"
                        );
                        errors = errors + 1;
                    end
                end
            end else if (ready_mode_i != READY_ALWAYS) begin
                if (dw1_output_stall_cycles == 0) begin
                    $display(
                        "ERROR backpressure case=%0d did not stall DW1 output",
                        case_idx
                    );
                    errors = errors + 1;
                end
            end
        end
    endtask

    task launch_case;
        input integer case_idx;
        input integer ready_mode_i;
        begin
            current_case = case_idx;
            ready_mode = ready_mode_i;
            ready_cycle = 0;
            ready_stall_left = 0;
            last_stalled_output_count = -1;
            case_error_start = errors;
            clear_scoreboard();

            load_activation_ram(case_idx);

            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            timeout = 0;
            while ((done !== 1'b1) && (timeout < TIMEOUT)) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end

            if (done !== 1'b1) begin
                $display(
                    "ERROR timeout case=%0d ready_mode=%0d outputs=%0d pending=%0d stem_jobs=%0d dw_jobs=%0d",
                    case_idx,
                    ready_mode_i,
                    output_count,
                    pending_count_dbg,
                    stem_jobs_done,
                    dw1_jobs_done
                );
                errors = errors + 1;
            end else begin
                if (stem_tile_count != TOTAL_JOBS) begin
                    $display(
                        "ERROR case=%0d stem_tile_count got=%0d expected=%0d",
                        case_idx,
                        stem_tile_count,
                        TOTAL_JOBS
                    );
                    errors = errors + 1;
                end
                if (output_count != TOTAL_ROWS) begin
                    $display(
                        "ERROR case=%0d output_count got=%0d expected=%0d",
                        case_idx,
                        output_count,
                        TOTAL_ROWS
                    );
                    errors = errors + 1;
                end
                for (out_idx = 0; out_idx < TOTAL_ROWS; out_idx = out_idx + 1) begin
                    if (!seen[out_idx]) begin
                        $display(
                            "ERROR case=%0d missing output t=%0d group=%0d",
                            case_idx,
                            out_idx / CH_GROUPS,
                            out_idx % CH_GROUPS
                        );
                        errors = errors + 1;
                    end
                end

                if (stem_jobs_started != TOTAL_JOBS) begin
                    $display(
                        "ERROR stem_jobs_started got=%0d expected=%0d",
                        stem_jobs_started,
                        TOTAL_JOBS
                    );
                    errors = errors + 1;
                end
                if (stem_jobs_done != TOTAL_JOBS) begin
                    $display(
                        "ERROR stem_jobs_done got=%0d expected=%0d",
                        stem_jobs_done,
                        TOTAL_JOBS
                    );
                    errors = errors + 1;
                end
                if (dw1_jobs_started != TOTAL_JOBS) begin
                    $display(
                        "ERROR dw1_jobs_started got=%0d expected=%0d",
                        dw1_jobs_started,
                        TOTAL_JOBS
                    );
                    errors = errors + 1;
                end
                if (dw1_jobs_done != TOTAL_JOBS) begin
                    $display(
                        "ERROR dw1_jobs_done got=%0d expected=%0d",
                        dw1_jobs_done,
                        TOTAL_JOBS
                    );
                    errors = errors + 1;
                end
                if (dw1_rows_out != TOTAL_ROWS) begin
                    $display(
                        "ERROR dw1_rows_out got=%0d expected=%0d",
                        dw1_rows_out,
                        TOTAL_ROWS
                    );
                    errors = errors + 1;
                end

                if ((ready_mode_i == READY_ALWAYS) && !WATERMARK_STRESS_ONLY) begin
                    if (dw1_output_stall_cycles != 0) begin
                        $display(
                            "ERROR no-backpressure case had DW1 output stalls=%0d",
                            dw1_output_stall_cycles
                        );
                        errors = errors + 1;
                    end
                    if (stem_start_blocked_pending_cycles != 0) begin
                        $display(
                            "ERROR no-backpressure case had pending-full stem stalls=%0d",
                            stem_start_blocked_pending_cycles
                        );
                        errors = errors + 1;
                    end
                    if (stem_output_stall_cycles != 0) begin
                        $display(
                            "ERROR no-backpressure case had stem output stalls=%0d",
                            stem_output_stall_cycles
                        );
                        errors = errors + 1;
                    end
                    if (buffer_watermark_stall_cycles != 0) begin
                        $display(
                            "ERROR no-backpressure case had watermark stalls=%0d",
                            buffer_watermark_stall_cycles
                        );
                        errors = errors + 1;
                    end
                end

                check_perf_and_stress(case_idx, ready_mode_i);

                $display(
                    "CASE %0d mode=%0d cycles=%0d outputs=%0d max_pending=%0d out_stall=%0d pending_stall=%0d stem_out_stall=%0d watermark_stall=%0d errors_delta=%0d",
                    case_idx,
                    ready_mode_i,
                    cycle_count,
                    output_count,
                    max_pending_count,
                    dw1_output_stall_cycles,
                    stem_start_blocked_pending_cycles,
                    stem_output_stall_cycles,
                    buffer_watermark_stall_cycles,
                    errors - case_error_start
                );
            end

            repeat (8) @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        act_wr_en = 1'b0;
        act_wr_addr = {ACT_ADDR_W{1'b0}};
        act_wr_data = {(ROWS*DATA_W){1'b0}};
        stem_w_fold_we = 1'b0;
        stem_w_fold_oc = 5'd0;
        stem_w_fold_wdata = 16'sd0;
        stem_bias_fold_we = 1'b0;
        stem_bias_fold_oc = 5'd0;
        stem_bias_fold_wdata = 16'sd0;
        dw1_weight_we = 1'b0;
        dw1_weight_ch = 5'd0;
        dw1_weight_tap = 3'd0;
        dw1_weight_wdata = 16'sd0;
        dw1_out_ready = 1'b1;
        ready_mode = READY_ALWAYS;
        ready_cycle = 0;
        ready_stall_left = 0;
        last_stalled_output_count = -1;
        current_case = 0;
        output_count = 0;
        errors = 0;
        clear_scoreboard();

        repeat (8) @(negedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        if (WATERMARK_STRESS_ONLY) begin
            launch_case(3, READY_LONG_STALL);
        end else begin
            launch_case(0, READY_ALWAYS);
            launch_case(1, READY_PERIODIC);
            launch_case(2, READY_BURSTY);
            launch_case(3, READY_LONG_STALL);
            launch_case(4, READY_ALWAYS);
            launch_case(5, READY_PERIODIC);
        end

        if (errors == 0) begin
            $display("PASS stem_dw1_pipeline_top integration self-check");
            $finish;
        end else begin
            $display("FAIL stem_dw1_pipeline_top errors=%0d", errors);
            $finish;
        end
    end

endmodule
