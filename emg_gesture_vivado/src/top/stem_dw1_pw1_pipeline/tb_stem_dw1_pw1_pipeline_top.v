`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_stem_dw1_pw1_pipeline_top #(
    parameter integer DUT_PENDING_DEPTH = 8,
    parameter integer DEBUG_PROGRESS = 0,
    parameter integer DEBUG_INTERVAL = 50000,
    parameter integer RUN_PENDING2_STRESS_ONLY = 0,
    parameter integer RUN_CONTINUOUS_START_CASE = 1,
    parameter integer RUN_MID_RESET_CASE = 1,
    parameter integer MID_RESET_ACTIVE_CYCLES = 1200
);

    localparam integer DATA_W       =  8;
    localparam integer MULT_W     = 16;
    localparam integer ACC_W        = 48;
    localparam integer ROWS         = 4;
    localparam integer POOL_ROWS    = 2;
    localparam integer STEM_OC_LANES = 4;
    localparam integer PW1_OC_LANES = 8;
    localparam integer STEM_OC      = 32;
    localparam integer PW1_OC       = 64;
    localparam integer STEM_IC      = 5;
    localparam integer INPUT_LEN    = 348;
    localparam integer POOL_LEN     = INPUT_LEN / 2;
    localparam integer TIME_W       = 9;
    localparam integer CH_GROUPS    = STEM_OC / STEM_OC_LANES;
    localparam integer PW1_GROUPS   = PW1_OC / PW1_OC_LANES;
    localparam integer TILE_COUNT   = (INPUT_LEN + ROWS - 1) / ROWS;
    localparam integer TOTAL_STEM_JOBS = TILE_COUNT * CH_GROUPS;
    localparam integer TOTAL_DW1_ROWS  = INPUT_LEN * CH_GROUPS;
    localparam integer TOTAL_PW1_TILES = TILE_COUNT;
    localparam integer TOTAL_PW1_OUT_TILES = TILE_COUNT * PW1_GROUPS;
    localparam integer N_CASES      = 6;
    localparam integer ACT_TIME_WORDS = (INPUT_LEN + ROWS - 1) / ROWS;
    localparam integer ACT_RAM_DEPTH  = STEM_IC * ACT_TIME_WORDS;
    localparam integer ACT_ADDR_W     = (ACT_RAM_DEPTH <= 1)
        ? 1 : $clog2(ACT_RAM_DEPTH);
    localparam integer DUT_PENDING_CNT_W = (DUT_PENDING_DEPTH <= 1)
        ? 1 : $clog2(DUT_PENDING_DEPTH + 1);
    localparam integer TIMEOUT      = 900000;
    localparam integer LONG_STALL_START_CYCLE = 600;
    localparam integer LONG_STALL_END_CYCLE   = 11000;
    localparam integer MAX_CYCLES_NORMAL      = 48000;
    localparam integer MAX_CYCLES_BACKPRESSURE = 85000;
    localparam integer MAX_CYCLES_LONG_STALL  = 130000;
    localparam integer MAX_CYCLES_PENDING2_STRESS = 260000;

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

    reg pw1_w_fold_we;
    reg [5:0] pw1_w_fold_oc;
    reg signed [MULT_W-1:0] pw1_w_fold_wdata;
    reg pw1_bias_fold_we;
    reg [5:0] pw1_bias_fold_oc;
    reg signed [31:0] pw1_bias_fold_wdata;

    reg pw1_out_ready;
    wire pw1_out_valid;
    wire [TIME_W-1:0] pw1_out_pool_t_base;
    wire [5:0] pw1_out_oc_base;
    wire pw1_out_last_group;
    wire signed [POOL_ROWS*PW1_OC_LANES*DATA_W-1:0] pw1_out_tile;

    wire busy;
    wire done;
    wire stem_busy;
    wire dw1_busy;
    wire pw1_busy;
    wire stem_to_dw1_wr_busy;
    wire stem_to_dw1_rd_busy;
    wire stem_to_dw1_watermark_stall;
    wire dw1_to_pw1_wr_busy;
    wire dw1_to_pw1_rd_busy;
    wire dw1_to_pw1_tile_cache_valid;
    wire dw1_to_pw1_overwrite_stall;
    wire stem_output_stall;
    wire dw1_output_stall;
    wire pw1_input_wait;
    wire pw1_output_stall;
    wire scheduler_pending_full;
    wire [DUT_PENDING_CNT_W-1:0] pending_count_dbg;
    wire [31:0] cycle_count;
    wire [31:0] stem_jobs_started;
    wire [31:0] stem_jobs_done;
    wire [31:0] dw1_jobs_started;
    wire [31:0] dw1_jobs_done;
    wire [31:0] dw1_rows_out;
    wire [31:0] pw1_tiles_started;
    wire [31:0] pw1_tiles_done;
    wire [31:0] pw1_output_tiles;
    wire [31:0] stem_start_blocked_pending_cycles;
    wire [31:0] stem_output_stall_cycles;
    wire [31:0] dw1_output_stall_cycles;
    wire [31:0] stem_to_dw1_watermark_stall_cycles;
    wire [31:0] dw1_to_pw1_overwrite_stall_cycles;
    wire [31:0] pw1_input_wait_cycles;
    wire [31:0] pw1_output_stall_cycles;
    wire [DUT_PENDING_CNT_W-1:0] max_pending_count;

    integer errors;
    integer current_case;
    integer ready_mode;
    integer ready_cycle;
    integer ready_stall_left;
    integer last_stalled_output_count;
    integer stem_tile_count;
    integer dw1_output_count;
    integer pw1_output_count;
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
    integer case_i;

    reg signed [DATA_W-1:0] file_raw_input [0:N_CASES*INPUT_LEN*STEM_IC-1];
    reg signed [DATA_W-1:0] file_expected_stem [0:N_CASES*INPUT_LEN*STEM_OC-1];
    reg signed [DATA_W-1:0] file_expected_dw1 [0:N_CASES*INPUT_LEN*STEM_OC-1];
    reg signed [DATA_W-1:0] file_expected_pw1 [0:N_CASES*POOL_LEN*PW1_OC-1];
    reg seen_dw1 [0:TOTAL_DW1_ROWS-1];
    reg last_valid [0:CH_GROUPS-1];
    reg [TIME_W-1:0] last_out_t [0:CH_GROUPS-1];

    wire stem_fire;
    wire dw1_fire;
    wire pw1_fire;

    assign stem_fire = dut.u_stem.out_valid && dut.u_stem.out_ready;
    assign dw1_fire = dut.u_dw1.out_valid && dut.u_dw1.out_ready;
    assign pw1_fire = pw1_out_valid && pw1_out_ready;

    stem_dw1_pw1_pipeline_top #(
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
        .pw1_w_fold_we(pw1_w_fold_we),
        .pw1_w_fold_oc(pw1_w_fold_oc),
        .pw1_w_fold_wdata(pw1_w_fold_wdata),
        .pw1_bias_fold_we(pw1_bias_fold_we),
        .pw1_bias_fold_oc(pw1_bias_fold_oc),
        .pw1_bias_fold_wdata(pw1_bias_fold_wdata),
        .pw1_out_ready(pw1_out_ready),
        .pw1_out_valid(pw1_out_valid),
        .pw1_out_pool_t_base(pw1_out_pool_t_base),
        .pw1_out_oc_base(pw1_out_oc_base),
        .pw1_out_last_group(pw1_out_last_group),
        .pw1_out_tile(pw1_out_tile),
        .stem_busy(stem_busy),
        .dw1_busy(dw1_busy),
        .pw1_busy(pw1_busy),
        .stem_to_dw1_wr_busy(stem_to_dw1_wr_busy),
        .stem_to_dw1_rd_busy(stem_to_dw1_rd_busy),
        .stem_to_dw1_watermark_stall(stem_to_dw1_watermark_stall),
        .dw1_to_pw1_wr_busy(dw1_to_pw1_wr_busy),
        .dw1_to_pw1_rd_busy(dw1_to_pw1_rd_busy),
        .dw1_to_pw1_tile_cache_valid(dw1_to_pw1_tile_cache_valid),
        .dw1_to_pw1_overwrite_stall(dw1_to_pw1_overwrite_stall),
        .stem_output_stall(stem_output_stall),
        .dw1_output_stall(dw1_output_stall),
        .pw1_input_wait(pw1_input_wait),
        .pw1_output_stall(pw1_output_stall),
        .scheduler_pending_full(scheduler_pending_full),
        .pending_count_dbg(pending_count_dbg),
        .cycle_count(cycle_count),
        .stem_jobs_started(stem_jobs_started),
        .stem_jobs_done(stem_jobs_done),
        .dw1_jobs_started(dw1_jobs_started),
        .dw1_jobs_done(dw1_jobs_done),
        .dw1_rows_out(dw1_rows_out),
        .pw1_tiles_started(pw1_tiles_started),
        .pw1_tiles_done(pw1_tiles_done),
        .pw1_output_tiles(pw1_output_tiles),
        .stem_start_blocked_pending_cycles(stem_start_blocked_pending_cycles),
        .stem_output_stall_cycles(stem_output_stall_cycles),
        .dw1_output_stall_cycles(dw1_output_stall_cycles),
        .stem_to_dw1_watermark_stall_cycles(stem_to_dw1_watermark_stall_cycles),
        .dw1_to_pw1_overwrite_stall_cycles(dw1_to_pw1_overwrite_stall_cycles),
        .pw1_input_wait_cycles(pw1_input_wait_cycles),
        .pw1_output_stall_cycles(pw1_output_stall_cycles),
        .max_pending_count(max_pending_count)
    );

    initial begin
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_pipeline/testdata/raw_input.mem"},
            file_raw_input
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_pipeline/testdata/stem_expected_full.mem"},
            file_expected_stem
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_pipeline/testdata/dw1_expected_full.mem"},
            file_expected_dw1
        );
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_pipeline/testdata/pw1_expected_pool.mem"},
            file_expected_pw1
        );
    end

    always #5 clk = ~clk;

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pw1_out_ready <= 1'b1;
            ready_cycle <= 0;
            ready_stall_left <= 0;
            last_stalled_output_count <= -1;
        end else if (busy) begin
            ready_cycle <= ready_cycle + 1;
            if ((ready_mode == READY_LONG_STALL)
                && (ready_cycle >= LONG_STALL_START_CYCLE)
                && (ready_cycle < LONG_STALL_END_CYCLE)) begin
                pw1_out_ready <= 1'b0;
            end else if (ready_stall_left > 0) begin
                pw1_out_ready <= 1'b0;
                ready_stall_left <= ready_stall_left - 1;
            end else if ((ready_mode == READY_PERIODIC)
                && pw1_out_valid
                && (pw1_output_count != last_stalled_output_count)
                && ((pw1_output_count % 17) == 3)) begin
                pw1_out_ready <= 1'b0;
                ready_stall_left <= 1;
                last_stalled_output_count <= pw1_output_count;
            end else if ((ready_mode == READY_BURSTY)
                && pw1_out_valid
                && (pw1_output_count != last_stalled_output_count)
                && ((pw1_output_count % 29) == 11)) begin
                pw1_out_ready <= 1'b0;
                ready_stall_left <= 4;
                last_stalled_output_count <= pw1_output_count;
            end else begin
                pw1_out_ready <= 1'b1;
            end
        end else begin
            ready_cycle <= 0;
            ready_stall_left <= 0;
            last_stalled_output_count <= -1;
            pw1_out_ready <= 1'b1;
        end
    end

    function signed [DATA_W-1:0] get_stem_lane;
        input integer row;
        input integer lane;
        begin
            get_stem_lane =
                dut.u_stem.out_tile[(row*STEM_OC_LANES + lane)*DATA_W +: DATA_W];
        end
    endfunction

    function signed [DATA_W-1:0] get_dw1_lane;
        input integer lane;
        begin
            get_dw1_lane = dut.u_dw1.out_vec[lane*DATA_W +: DATA_W];
        end
    endfunction

    function signed [DATA_W-1:0] get_pw1_lane;
        input integer pool_row;
        input integer lane;
        begin
            get_pw1_lane =
                pw1_out_tile[(pool_row*PW1_OC_LANES + lane)*DATA_W +: DATA_W];
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
            stem_tile_count = 0;
            dw1_output_count = 0;
            pw1_output_count = 0;
            for (seen_i = 0; seen_i < TOTAL_DW1_ROWS; seen_i = seen_i + 1) begin
                seen_dw1[seen_i] = 1'b0;
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
                $display("ERROR stem unaligned oc_base=%0d", dut.u_stem.out_tile_oc_base);
                errors = errors + 1;
            end
            if (dut.u_stem.out_tile_t_base > (INPUT_LEN - ROWS)) begin
                $display("ERROR stem tile_t_base out of range=%0d", dut.u_stem.out_tile_t_base);
                errors = errors + 1;
            end

            for (row = 0; row < ROWS; row = row + 1) begin
                t_idx = dut.u_stem.out_tile_t_base + row;
                for (lane = 0; lane < STEM_OC_LANES; lane = lane + 1) begin
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

    task check_dw1_row;
        reg signed [DATA_W-1:0] expected;
        integer group;
        integer seen_idx;
        begin
            if (dut.u_dw1.out_ch_base[1:0] !== 2'b00) begin
                $display("ERROR DW1 unaligned out_ch_base=%0d", dut.u_dw1.out_ch_base);
                errors = errors + 1;
            end
            if (dut.u_dw1.out_t >= INPUT_LEN) begin
                $display("ERROR DW1 out_t out of range=%0d", dut.u_dw1.out_t);
                errors = errors + 1;
            end

            group = dut.u_dw1.out_ch_base / STEM_OC_LANES;
            seen_idx = dut.u_dw1.out_t * CH_GROUPS + group;
            if (seen_dw1[seen_idx]) begin
                $display(
                    "ERROR duplicate DW1 output t=%0d ch_base=%0d",
                    dut.u_dw1.out_t,
                    dut.u_dw1.out_ch_base
                );
                errors = errors + 1;
            end
            seen_dw1[seen_idx] = 1'b1;

            if (last_valid[group] && (dut.u_dw1.out_t < last_out_t[group])) begin
                $display(
                    "ERROR non-monotonic DW1 bank=%0d out_t=%0d previous=%0d",
                    group,
                    dut.u_dw1.out_t,
                    last_out_t[group]
                );
                errors = errors + 1;
            end
            last_valid[group] = 1'b1;
            last_out_t[group] = dut.u_dw1.out_t;

            for (lane_i = 0; lane_i < STEM_OC_LANES; lane_i = lane_i + 1) begin
                expected_idx = current_case*INPUT_LEN*STEM_OC
                    + dut.u_dw1.out_t*STEM_OC
                    + dut.u_dw1.out_ch_base
                    + lane_i;
                expected = file_expected_dw1[expected_idx];
                if (get_dw1_lane(lane_i) !== expected) begin
                    $display(
                        "ERROR DW1 case=%0d t=%0d ch=%0d got=%0d expected=%0d",
                        current_case,
                        dut.u_dw1.out_t,
                        dut.u_dw1.out_ch_base + lane_i,
                        $signed(get_dw1_lane(lane_i)),
                        $signed(expected)
                    );
                    errors = errors + 1;
                end
            end

            dw1_output_count = dw1_output_count + 1;
        end
    endtask

    task check_pw1_tile;
        reg signed [DATA_W-1:0] expected;
        integer expected_pool_t_base;
        integer expected_oc_base;
        integer pool_row;
        integer lane;
        integer pool_t;
        integer oc;
        begin
            expected_pool_t_base = (pw1_output_count / PW1_GROUPS) * POOL_ROWS;
            expected_oc_base = (pw1_output_count % PW1_GROUPS) * PW1_OC_LANES;

            if (pw1_out_pool_t_base !== expected_pool_t_base[TIME_W-1:0]) begin
                $display(
                    "ERROR PW1 pool_t_base got=%0d expected=%0d output_count=%0d",
                    pw1_out_pool_t_base,
                    expected_pool_t_base,
                    pw1_output_count
                );
                errors = errors + 1;
            end
            if (pw1_out_oc_base !== expected_oc_base[5:0]) begin
                $display(
                    "ERROR PW1 oc_base got=%0d expected=%0d output_count=%0d",
                    pw1_out_oc_base,
                    expected_oc_base,
                    pw1_output_count
                );
                errors = errors + 1;
            end
            if (pw1_out_last_group !== ((pw1_output_count % PW1_GROUPS) == (PW1_GROUPS - 1))) begin
                $display("ERROR PW1 last_group mismatch output_count=%0d", pw1_output_count);
                errors = errors + 1;
            end

            for (pool_row = 0; pool_row < POOL_ROWS; pool_row = pool_row + 1) begin
                pool_t = pw1_out_pool_t_base + pool_row;
                for (lane = 0; lane < PW1_OC_LANES; lane = lane + 1) begin
                    oc = pw1_out_oc_base + lane;
                    expected_idx = current_case*POOL_LEN*PW1_OC
                        + pool_t*PW1_OC
                        + oc;
                    expected = file_expected_pw1[expected_idx];
                    if (get_pw1_lane(pool_row, lane) !== expected) begin
                        $display(
                            "ERROR PW1 case=%0d pool_t=%0d oc=%0d got=%0d expected=%0d",
                            current_case,
                            pool_t,
                            oc,
                            $signed(get_pw1_lane(pool_row, lane)),
                            $signed(expected)
                        );
                        errors = errors + 1;
                    end
                end
            end

            pw1_output_count = pw1_output_count + 1;
        end
    endtask

    always @(posedge clk) begin
        if (rst_n && stem_fire) begin
            check_stem_tile();
        end
        if (rst_n && dw1_fire) begin
            check_dw1_row();
        end
        if (rst_n && pw1_fire) begin
            check_pw1_tile();
        end
    end

    task check_perf_and_stress;
        input integer case_idx;
        input integer ready_mode_i;
        integer cycle_limit;
        begin
            if ((ready_mode_i == READY_LONG_STALL) && (DUT_PENDING_DEPTH <= 2)) begin
                cycle_limit = MAX_CYCLES_PENDING2_STRESS;
            end else if (ready_mode_i == READY_LONG_STALL) begin
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

            if (ready_mode_i == READY_ALWAYS) begin
                if (pw1_output_stall_cycles != 0) begin
                    $display(
                        "ERROR no-backpressure case had PW1 output stalls=%0d",
                        pw1_output_stall_cycles
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
                // DW1 can still pause locally while dw1_to_pw1_buffer serializes
                // accepted rows into RAM. That must not propagate into the stem
                // scheduler or buffer overwrite/watermark counters.
                if (stem_to_dw1_watermark_stall_cycles != 0) begin
                    $display(
                        "ERROR no-backpressure case had stem_to_dw1 watermark stalls=%0d",
                        stem_to_dw1_watermark_stall_cycles
                    );
                    errors = errors + 1;
                end
                if (dw1_to_pw1_overwrite_stall_cycles != 0) begin
                    $display(
                        "ERROR no-backpressure case had dw1_to_pw1 overwrite stalls=%0d",
                        dw1_to_pw1_overwrite_stall_cycles
                    );
                    errors = errors + 1;
                end
            end else begin
                if (pw1_output_stall_cycles == 0) begin
                    $display("ERROR output-backpressure case did not stall PW1 output");
                    errors = errors + 1;
                end
            end

            if (ready_mode_i == READY_LONG_STALL) begin
                if (DUT_PENDING_DEPTH <= 2) begin
                    if (stem_start_blocked_pending_cycles == 0) begin
                        $display(
                            "ERROR pending-depth-2 long-stall case did not hit pending_full"
                        );
                        errors = errors + 1;
                    end
                    if (max_pending_count < (DUT_PENDING_DEPTH - 1)) begin
                        $display(
                            "ERROR pending-depth-2 long-stall max_pending got=%0d expected at least %0d",
                            max_pending_count,
                            DUT_PENDING_DEPTH - 1
                        );
                        errors = errors + 1;
                    end
                end
                if ((dw1_output_stall_cycles == 0)
                    && (stem_start_blocked_pending_cycles == 0)
                    && (stem_output_stall_cycles == 0)
                    && (dw1_to_pw1_overwrite_stall_cycles == 0)) begin
                    $display("ERROR long-stall case did not propagate any upstream pressure");
                    errors = errors + 1;
                end
            end
        end
    endtask

    task launch_case_with_start_hold;
        input integer case_idx;
        input integer ready_mode_i;
        input integer start_hold_cycles;
        integer hold_cycles;
        begin
            hold_cycles = start_hold_cycles;
            if (hold_cycles < 1) begin
                hold_cycles = 1;
            end

            current_case = case_idx;
            ready_mode = ready_mode_i;
            ready_cycle = 0;
            ready_stall_left = 0;
            last_stalled_output_count = -1;
            case_error_start = errors;
            clear_scoreboard();

            if (DEBUG_PROGRESS) begin
                $display("DBG case=%0d begin load mode=%0d", case_idx, ready_mode_i);
            end
            load_activation_ram(case_idx);
            if (DEBUG_PROGRESS) begin
                $display("DBG case=%0d load done", case_idx);
            end

            @(negedge clk);
            start = 1'b1;
            repeat (hold_cycles) @(negedge clk);
            start = 1'b0;
            if (DEBUG_PROGRESS) begin
                $display(
                    "DBG case=%0d start issued hold_cycles=%0d",
                    case_idx,
                    hold_cycles
                );
            end

            timeout = 0;
            while ((done !== 1'b1) && (timeout < TIMEOUT)) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
                if (DEBUG_PROGRESS && ((timeout % DEBUG_INTERVAL) == 0)) begin
                    $display(
                        "DBG case=%0d tmo=%0d cycles=%0d stem=%0d/%0d dw_jobs=%0d/%0d dw_rows=%0d pw1_tiles=%0d/%0d pw1_out=%0d pending=%0d busy s/d/p=%0d/%0d/%0d waits pw1=%0d outstall=%0d",
                        case_idx,
                        timeout,
                        cycle_count,
                        stem_jobs_done,
                        stem_jobs_started,
                        dw1_jobs_done,
                        dw1_jobs_started,
                        dw1_rows_out,
                        pw1_tiles_done,
                        pw1_tiles_started,
                        pw1_output_tiles,
                        pending_count_dbg,
                        stem_busy,
                        dw1_busy,
                        pw1_busy,
                        pw1_input_wait_cycles,
                        pw1_output_stall_cycles
                    );
                end
            end

            if (done !== 1'b1) begin
                $display(
                    "ERROR timeout case=%0d mode=%0d pw1_out=%0d dw1_out=%0d pending=%0d pw1_tiles=%0d",
                    case_idx,
                    ready_mode_i,
                    pw1_output_count,
                    dw1_output_count,
                    pending_count_dbg,
                    pw1_tiles_done
                );
                errors = errors + 1;
            end else begin
                if (stem_tile_count != TOTAL_STEM_JOBS) begin
                    $display(
                        "ERROR stem_tile_count got=%0d expected=%0d",
                        stem_tile_count,
                        TOTAL_STEM_JOBS
                    );
                    errors = errors + 1;
                end
                if (dw1_output_count != TOTAL_DW1_ROWS) begin
                    $display(
                        "ERROR DW1 output_count got=%0d expected=%0d",
                        dw1_output_count,
                        TOTAL_DW1_ROWS
                    );
                    errors = errors + 1;
                end
                if (pw1_output_count != TOTAL_PW1_OUT_TILES) begin
                    $display(
                        "ERROR PW1 output_count got=%0d expected=%0d",
                        pw1_output_count,
                        TOTAL_PW1_OUT_TILES
                    );
                    errors = errors + 1;
                end
                for (out_idx = 0; out_idx < TOTAL_DW1_ROWS; out_idx = out_idx + 1) begin
                    if (!seen_dw1[out_idx]) begin
                        $display(
                            "ERROR case=%0d missing DW1 output t=%0d group=%0d",
                            case_idx,
                            out_idx / CH_GROUPS,
                            out_idx % CH_GROUPS
                        );
                        errors = errors + 1;
                    end
                end

                if (stem_jobs_started != TOTAL_STEM_JOBS) begin
                    $display("ERROR stem_jobs_started got=%0d expected=%0d", stem_jobs_started, TOTAL_STEM_JOBS);
                    errors = errors + 1;
                end
                if (stem_jobs_done != TOTAL_STEM_JOBS) begin
                    $display("ERROR stem_jobs_done got=%0d expected=%0d", stem_jobs_done, TOTAL_STEM_JOBS);
                    errors = errors + 1;
                end
                if (dw1_jobs_started != TOTAL_STEM_JOBS) begin
                    $display("ERROR dw1_jobs_started got=%0d expected=%0d", dw1_jobs_started, TOTAL_STEM_JOBS);
                    errors = errors + 1;
                end
                if (dw1_jobs_done != TOTAL_STEM_JOBS) begin
                    $display("ERROR dw1_jobs_done got=%0d expected=%0d", dw1_jobs_done, TOTAL_STEM_JOBS);
                    errors = errors + 1;
                end
                if (dw1_rows_out != TOTAL_DW1_ROWS) begin
                    $display("ERROR dw1_rows_out got=%0d expected=%0d", dw1_rows_out, TOTAL_DW1_ROWS);
                    errors = errors + 1;
                end
                if (pw1_tiles_started != TOTAL_PW1_TILES) begin
                    $display("ERROR pw1_tiles_started got=%0d expected=%0d", pw1_tiles_started, TOTAL_PW1_TILES);
                    errors = errors + 1;
                end
                if (pw1_tiles_done != TOTAL_PW1_TILES) begin
                    $display("ERROR pw1_tiles_done got=%0d expected=%0d", pw1_tiles_done, TOTAL_PW1_TILES);
                    errors = errors + 1;
                end
                if (pw1_output_tiles != TOTAL_PW1_OUT_TILES) begin
                    $display("ERROR pw1_output_tiles got=%0d expected=%0d", pw1_output_tiles, TOTAL_PW1_OUT_TILES);
                    errors = errors + 1;
                end

                check_perf_and_stress(case_idx, ready_mode_i);

                $display(
                    "CASE %0d mode=%0d cycles=%0d pw1_outputs=%0d dw1_outputs=%0d max_pending=%0d pw1_wait=%0d pw1_out_stall=%0d dw1_stall=%0d pending_stall=%0d stem_out_stall=%0d s2d_watermark=%0d d2p_overwrite=%0d errors_delta=%0d",
                    case_idx,
                    ready_mode_i,
                    cycle_count,
                    pw1_output_count,
                    dw1_output_count,
                    max_pending_count,
                    pw1_input_wait_cycles,
                    pw1_output_stall_cycles,
                    dw1_output_stall_cycles,
                    stem_start_blocked_pending_cycles,
                    stem_output_stall_cycles,
                    stem_to_dw1_watermark_stall_cycles,
                    dw1_to_pw1_overwrite_stall_cycles,
                    errors - case_error_start
                );
            end

            repeat (8) @(posedge clk);
        end
    endtask

    task launch_case;
        input integer case_idx;
        input integer ready_mode_i;
        begin
            launch_case_with_start_hold(case_idx, ready_mode_i, 1);
        end
    endtask

    task drive_idle_inputs;
        begin
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
            pw1_w_fold_we = 1'b0;
            pw1_w_fold_oc = 6'd0;
            pw1_w_fold_wdata = 16'sd0;
            pw1_bias_fold_we = 1'b0;
            pw1_bias_fold_oc = 6'd0;
            pw1_bias_fold_wdata = 16'sd0;
            pw1_out_ready = 1'b1;
            ready_cycle = 0;
            ready_stall_left = 0;
            last_stalled_output_count = -1;
        end
    endtask

    task run_mid_reset_case;
        input integer case_idx;
        input integer ready_mode_i;
        input integer active_cycles;
        integer reset_cycle;
        integer reset_error_start;
        begin
            reset_error_start = errors;
            current_case = case_idx;
            ready_mode = ready_mode_i;
            ready_cycle = 0;
            ready_stall_left = 0;
            last_stalled_output_count = -1;
            clear_scoreboard();

            $display(
                "INFO mid-reset case=%0d mode=%0d active_cycles=%0d begin",
                case_idx,
                ready_mode_i,
                active_cycles
            );

            load_activation_ram(case_idx);

            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            for (reset_cycle = 0; reset_cycle < active_cycles; reset_cycle = reset_cycle + 1) begin
                @(posedge clk);
                #1;
                if (done === 1'b1) begin
                    $display(
                        "ERROR mid-reset case completed before reset injection cycle=%0d",
                        reset_cycle
                    );
                    errors = errors + 1;
                    reset_cycle = active_cycles;
                end
            end

            if (busy !== 1'b1) begin
                $display("ERROR mid-reset case expected DUT busy before reset");
                errors = errors + 1;
            end

            @(negedge clk);
            rst_n = 1'b0;
            drive_idle_inputs();
            repeat (6) @(negedge clk);
            #1;

            if (busy !== 1'b0) begin
                $display("ERROR mid-reset did not clear busy");
                errors = errors + 1;
            end
            if (done !== 1'b0) begin
                $display("ERROR mid-reset left done asserted");
                errors = errors + 1;
            end
            if (pending_count_dbg !== {DUT_PENDING_CNT_W{1'b0}}) begin
                $display(
                    "ERROR mid-reset did not clear pending_count got=%0d",
                    pending_count_dbg
                );
                errors = errors + 1;
            end

            rst_n = 1'b1;
            repeat (4) @(posedge clk);

            $display(
                "INFO mid-reset recovery case=%0d errors_delta=%0d",
                case_idx,
                errors - reset_error_start
            );
            launch_case(case_idx, ready_mode_i);
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
        pw1_w_fold_we = 1'b0;
        pw1_w_fold_oc = 6'd0;
        pw1_w_fold_wdata = 16'sd0;
        pw1_bias_fold_we = 1'b0;
        pw1_bias_fold_oc = 6'd0;
        pw1_bias_fold_wdata = 16'sd0;
        pw1_out_ready = 1'b1;
        ready_mode = READY_ALWAYS;
        ready_cycle = 0;
        ready_stall_left = 0;
        last_stalled_output_count = -1;
        current_case = 0;
        errors = 0;
        clear_scoreboard();

        repeat (8) @(negedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        if (RUN_PENDING2_STRESS_ONLY) begin
            if (DUT_PENDING_DEPTH != 2) begin
                $display(
                    "INFO RUN_PENDING2_STRESS_ONLY set with DUT_PENDING_DEPTH=%0d",
                    DUT_PENDING_DEPTH
                );
            end
            launch_case(3, READY_LONG_STALL);
        end else begin
            launch_case(0, READY_ALWAYS);
            launch_case(1, READY_PERIODIC);
            launch_case(2, READY_BURSTY);
            launch_case(3, READY_LONG_STALL);
            launch_case(4, READY_PERIODIC);
            launch_case(5, READY_ALWAYS);

            if (RUN_CONTINUOUS_START_CASE) begin
                launch_case_with_start_hold(0, READY_ALWAYS, 3);
            end

            if (RUN_MID_RESET_CASE) begin
                run_mid_reset_case(5, READY_ALWAYS, MID_RESET_ACTIVE_CYCLES);
            end
        end

        if (errors == 0) begin
            $display("PASS stem_dw1_pw1_pipeline_top integration self-check");
            $finish;
        end else begin
            $display("FAIL stem_dw1_pw1_pipeline_top errors=%0d", errors);
            $finish;
        end
    end

endmodule
