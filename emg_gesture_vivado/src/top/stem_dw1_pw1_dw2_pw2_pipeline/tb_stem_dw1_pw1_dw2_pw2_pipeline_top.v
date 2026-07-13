`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_stem_dw1_pw1_dw2_pw2_pipeline_top #(
    parameter integer DUT_PENDING_DEPTH = 8,
    parameter integer DUT_DW2_PENDING_DEPTH = 32,
    parameter integer RUN_CASE_LIMIT = 20,
    parameter integer RUN_CONTINUOUS_START_CASE = 1,
    parameter integer RUN_MID_RESET_CASE = 1,
    parameter integer MID_RESET_ACTIVE_CYCLES = 2500,
    parameter integer DEBUG_PROGRESS = 0,
    parameter integer DEBUG_INTERVAL = 50000
);

    localparam integer DATA_W       = 16;
    localparam integer ACC_W        = 48;
    localparam integer ROWS         = 4;
    localparam integer POOL_ROWS    = 2;
    localparam integer STEM_OC_LANES = 4;
    localparam integer PW1_OC_LANES = 8;
    localparam integer PW2_OC_LANES = 12;
    localparam integer CH_LANES     = 4;
    localparam integer STEM_OC      = 32;
    localparam integer PW1_OC       = 64;
    localparam integer PW2_OC       = 96;
    localparam integer FC_CLASSES   = 5;
    localparam integer STEM_IC      = 5;
    localparam integer INPUT_LEN    = 348;
    localparam integer POOL_LEN     = INPUT_LEN / 2;
    localparam integer TIME_W       = 9;
    localparam integer LOW_TIME_W   = 8;
    localparam integer CH_GROUPS    = STEM_OC / STEM_OC_LANES;
    localparam integer PW1_GROUPS   = PW1_OC / PW1_OC_LANES;
    localparam integer DW2_GROUPS   = PW1_OC / CH_LANES;
    localparam integer STEM_TILE_COUNT = (INPUT_LEN + ROWS - 1) / ROWS;
    localparam integer PW2_TILE_COUNT = (POOL_LEN + ROWS - 1) / ROWS;
    localparam integer TOTAL_STEM_JOBS = STEM_TILE_COUNT * CH_GROUPS;
    localparam integer TOTAL_DW1_ROWS  = INPUT_LEN * CH_GROUPS;
    localparam integer TOTAL_PW1_TILES = STEM_TILE_COUNT;
    localparam integer TOTAL_PW1_OUT_TILES = STEM_TILE_COUNT * PW1_GROUPS;
    localparam integer TOTAL_DW2_JOBS = TOTAL_PW1_OUT_TILES;
    localparam integer TOTAL_DW2_ROWS = POOL_LEN * DW2_GROUPS;
    localparam integer N_CASES      = 20;
    localparam integer ACT_TIME_WORDS = (INPUT_LEN + ROWS - 1) / ROWS;
    localparam integer ACT_RAM_DEPTH  = STEM_IC * ACT_TIME_WORDS;
    localparam integer ACT_ADDR_W     = (ACT_RAM_DEPTH <= 1)
        ? 1 : $clog2(ACT_RAM_DEPTH);
    localparam integer DUT_PENDING_CNT_W = (DUT_PENDING_DEPTH <= 1)
        ? 1 : $clog2(DUT_PENDING_DEPTH + 1);
    localparam integer DUT_DW2_PENDING_CNT_W = (DUT_DW2_PENDING_DEPTH <= 1)
        ? 1 : $clog2(DUT_DW2_PENDING_DEPTH + 1);
    localparam integer TIMEOUT = 900000;

    reg clk;
    reg rst_n;
    reg start;

    reg act_wr_en;
    reg [ACT_ADDR_W-1:0] act_wr_addr;
    reg [ROWS*DATA_W-1:0] act_wr_data;
    wire act_wr_ready;

    reg stem_w_fold_we;
    reg [4:0] stem_w_fold_oc;
    reg signed [DATA_W-1:0] stem_w_fold_wdata;
    reg stem_bias_fold_we;
    reg [4:0] stem_bias_fold_oc;
    reg signed [DATA_W-1:0] stem_bias_fold_wdata;

    reg dw1_weight_we;
    reg [4:0] dw1_weight_ch;
    reg [2:0] dw1_weight_tap;
    reg signed [DATA_W-1:0] dw1_weight_wdata;

    reg pw1_w_fold_we;
    reg [5:0] pw1_w_fold_oc;
    reg signed [DATA_W-1:0] pw1_w_fold_wdata;
    reg pw1_bias_fold_we;
    reg [5:0] pw1_bias_fold_oc;
    reg signed [DATA_W-1:0] pw1_bias_fold_wdata;

    reg dw2_weight_we;
    reg [5:0] dw2_weight_ch;
    reg [2:0] dw2_weight_tap;
    reg signed [DATA_W-1:0] dw2_weight_wdata;

    reg pw2_w_fold_we;
    reg [6:0] pw2_w_fold_oc;
    reg signed [DATA_W-1:0] pw2_w_fold_wdata;
    reg pw2_bias_fold_we;
    reg [6:0] pw2_bias_fold_oc;
    reg signed [DATA_W-1:0] pw2_bias_fold_wdata;

    wire busy;
    wire done;
    wire gap_frame_done;
    wire [8:0] gap_count;
    wire signed [PW2_OC*ACC_W-1:0] gap_sum_vec;
    wire fc_busy;
    wire fc_result_valid;
    wire [2:0] fc_class_idx;
    wire fc_input_count_error;
    wire signed [FC_CLASSES*DATA_W-1:0] fc_logits_vec;

    wire stem_busy;
    wire dw1_busy;
    wire pw1_busy;
    wire dw2_busy;
    wire pw2_busy;
    wire stem_to_dw1_wr_busy;
    wire stem_to_dw1_rd_busy;
    wire stem_to_dw1_watermark_stall;
    wire dw1_to_pw1_wr_busy;
    wire dw1_to_pw1_rd_busy;
    wire dw1_to_pw1_tile_cache_valid;
    wire dw1_to_pw1_overwrite_stall;
    wire pw1_to_dw2_wr_busy;
    wire pw1_to_dw2_rd_busy;
    wire pw1_to_dw2_overwrite_stall;
    wire dw2_to_pw2_wr_busy;
    wire dw2_to_pw2_rd_busy;
    wire dw2_to_pw2_tile_cache_valid;
    wire dw2_to_pw2_overwrite_stall;
    wire stem_output_stall;
    wire dw1_output_stall;
    wire dw2_output_stall;
    wire pw1_input_wait;
    wire pw1_output_stall;
    wire pw2_input_wait;
    wire scheduler_dw1_pending_full;
    wire scheduler_dw2_pending_full;
    wire [DUT_PENDING_CNT_W-1:0] dw1_pending_count_dbg;
    wire [DUT_DW2_PENDING_CNT_W-1:0] dw2_pending_count_dbg;

    wire [31:0] cycle_count;
    wire [31:0] stem_jobs_started;
    wire [31:0] stem_jobs_done;
    wire [31:0] dw1_jobs_started;
    wire [31:0] dw1_jobs_done;
    wire [31:0] dw1_rows_out;
    wire [31:0] pw1_tiles_started;
    wire [31:0] pw1_tiles_done;
    wire [31:0] pw1_output_tiles;
    wire [31:0] dw2_jobs_started;
    wire [31:0] dw2_jobs_done;
    wire [31:0] dw2_rows_out;
    wire [31:0] pw2_tiles_started;
    wire [31:0] pw2_tiles_done;
    wire [31:0] fc_jobs_started;
    wire [31:0] fc_jobs_done;
    wire [31:0] stem_start_blocked_pending_cycles;
    wire [31:0] stem_output_stall_cycles;
    wire [31:0] dw1_output_stall_cycles;
    wire [31:0] dw2_output_stall_cycles;
    wire [31:0] stem_to_dw1_watermark_stall_cycles;
    wire [31:0] dw1_to_pw1_overwrite_stall_cycles;
    wire [31:0] pw1_to_dw2_overwrite_stall_cycles;
    wire [31:0] dw2_to_pw2_overwrite_stall_cycles;
    wire [31:0] pw1_input_wait_cycles;
    wire [31:0] pw1_output_stall_cycles;
    wire [31:0] pw2_input_wait_cycles;
    wire [DUT_PENDING_CNT_W-1:0] max_dw1_pending_count;
    wire [DUT_DW2_PENDING_CNT_W-1:0] max_dw2_pending_count;

    integer errors;
    integer current_case;
    integer case_error_start;
    integer case_i;
    integer case_limit;
    integer timeout;
    integer load_ch;
    integer load_word;
    integer load_addr;
    integer seen_i;
    integer lane_i;
    integer out_idx;
    integer expected_idx;
    integer group_i;
    integer cls_i;

    integer stem_tile_count;
    integer dw1_output_count;
    integer pw1_output_count;
    integer dw2_output_count;

    reg signed [DATA_W-1:0] file_raw_input [0:N_CASES*INPUT_LEN*STEM_IC-1];
    reg signed [DATA_W-1:0] file_expected_stem [0:N_CASES*INPUT_LEN*STEM_OC-1];
    reg signed [DATA_W-1:0] file_expected_dw1 [0:N_CASES*INPUT_LEN*STEM_OC-1];
    reg signed [DATA_W-1:0] file_expected_pw1 [0:N_CASES*POOL_LEN*PW1_OC-1];
    reg signed [DATA_W-1:0] file_expected_dw2 [0:N_CASES*POOL_LEN*PW1_OC-1];
    reg signed [ACC_W-1:0] file_expected_gap [0:N_CASES*PW2_OC-1];
    reg signed [DATA_W-1:0] file_expected_fc_logits [0:N_CASES*FC_CLASSES-1];
    reg [7:0] file_expected_fc_class [0:N_CASES-1];
    reg seen_dw1 [0:TOTAL_DW1_ROWS-1];
    reg seen_dw2 [0:TOTAL_DW2_ROWS-1];

    wire stem_fire;
    wire dw1_fire;
    wire pw1_fire;
    wire dw2_fire;

    assign stem_fire = dut.stem_out_valid && dut.stem_to_buffer_ready;
    assign dw1_fire = dut.dw1_mid_out_valid && dut.dw1_mid_out_ready;
    assign pw1_fire = dut.pw1_out_valid && dut.pw1_out_ready;
    assign dw2_fire = dut.dw2_mid_out_valid && dut.dw2_mid_out_ready;

    stem_dw1_pw1_dw2_pw2_pipeline_top #(
        .PENDING_DEPTH(DUT_PENDING_DEPTH),
        .DW2_PENDING_DEPTH(DUT_DW2_PENDING_DEPTH)
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
        .dw2_weight_we(dw2_weight_we),
        .dw2_weight_ch(dw2_weight_ch),
        .dw2_weight_tap(dw2_weight_tap),
        .dw2_weight_wdata(dw2_weight_wdata),
        .pw2_w_fold_we(pw2_w_fold_we),
        .pw2_w_fold_oc(pw2_w_fold_oc),
        .pw2_w_fold_wdata(pw2_w_fold_wdata),
        .pw2_bias_fold_we(pw2_bias_fold_we),
        .pw2_bias_fold_oc(pw2_bias_fold_oc),
        .pw2_bias_fold_wdata(pw2_bias_fold_wdata),
        .gap_frame_done(gap_frame_done),
        .gap_count(gap_count),
        .gap_sum_vec(gap_sum_vec),
        .fc_result_ready(1'b1),
        .fc_busy(fc_busy),
        .fc_result_valid(fc_result_valid),
        .fc_class_idx(fc_class_idx),
        .fc_input_count_error(fc_input_count_error),
        .fc_logits_vec(fc_logits_vec),
        .stem_busy(stem_busy),
        .dw1_busy(dw1_busy),
        .pw1_busy(pw1_busy),
        .dw2_busy(dw2_busy),
        .pw2_busy(pw2_busy),
        .stem_to_dw1_wr_busy(stem_to_dw1_wr_busy),
        .stem_to_dw1_rd_busy(stem_to_dw1_rd_busy),
        .stem_to_dw1_watermark_stall(stem_to_dw1_watermark_stall),
        .dw1_to_pw1_wr_busy(dw1_to_pw1_wr_busy),
        .dw1_to_pw1_rd_busy(dw1_to_pw1_rd_busy),
        .dw1_to_pw1_tile_cache_valid(dw1_to_pw1_tile_cache_valid),
        .dw1_to_pw1_overwrite_stall(dw1_to_pw1_overwrite_stall),
        .pw1_to_dw2_wr_busy(pw1_to_dw2_wr_busy),
        .pw1_to_dw2_rd_busy(pw1_to_dw2_rd_busy),
        .pw1_to_dw2_overwrite_stall(pw1_to_dw2_overwrite_stall),
        .dw2_to_pw2_wr_busy(dw2_to_pw2_wr_busy),
        .dw2_to_pw2_rd_busy(dw2_to_pw2_rd_busy),
        .dw2_to_pw2_tile_cache_valid(dw2_to_pw2_tile_cache_valid),
        .dw2_to_pw2_overwrite_stall(dw2_to_pw2_overwrite_stall),
        .stem_output_stall(stem_output_stall),
        .dw1_output_stall(dw1_output_stall),
        .dw2_output_stall(dw2_output_stall),
        .pw1_input_wait(pw1_input_wait),
        .pw1_output_stall(pw1_output_stall),
        .pw2_input_wait(pw2_input_wait),
        .scheduler_dw1_pending_full(scheduler_dw1_pending_full),
        .scheduler_dw2_pending_full(scheduler_dw2_pending_full),
        .dw1_pending_count_dbg(dw1_pending_count_dbg),
        .dw2_pending_count_dbg(dw2_pending_count_dbg),
        .cycle_count(cycle_count),
        .stem_jobs_started(stem_jobs_started),
        .stem_jobs_done(stem_jobs_done),
        .dw1_jobs_started(dw1_jobs_started),
        .dw1_jobs_done(dw1_jobs_done),
        .dw1_rows_out(dw1_rows_out),
        .pw1_tiles_started(pw1_tiles_started),
        .pw1_tiles_done(pw1_tiles_done),
        .pw1_output_tiles(pw1_output_tiles),
        .dw2_jobs_started(dw2_jobs_started),
        .dw2_jobs_done(dw2_jobs_done),
        .dw2_rows_out(dw2_rows_out),
        .pw2_tiles_started(pw2_tiles_started),
        .pw2_tiles_done(pw2_tiles_done),
        .fc_jobs_started(fc_jobs_started),
        .fc_jobs_done(fc_jobs_done),
        .stem_start_blocked_pending_cycles(stem_start_blocked_pending_cycles),
        .stem_output_stall_cycles(stem_output_stall_cycles),
        .dw1_output_stall_cycles(dw1_output_stall_cycles),
        .dw2_output_stall_cycles(dw2_output_stall_cycles),
        .stem_to_dw1_watermark_stall_cycles(stem_to_dw1_watermark_stall_cycles),
        .dw1_to_pw1_overwrite_stall_cycles(dw1_to_pw1_overwrite_stall_cycles),
        .pw1_to_dw2_overwrite_stall_cycles(pw1_to_dw2_overwrite_stall_cycles),
        .dw2_to_pw2_overwrite_stall_cycles(dw2_to_pw2_overwrite_stall_cycles),
        .pw1_input_wait_cycles(pw1_input_wait_cycles),
        .pw1_output_stall_cycles(pw1_output_stall_cycles),
        .pw2_input_wait_cycles(pw2_input_wait_cycles),
        .max_dw1_pending_count(max_dw1_pending_count),
        .max_dw2_pending_count(max_dw2_pending_count)
    );

    initial begin
        $readmemh({`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_dw2_pw2_pipeline/testdata/raw_input.mem"}, file_raw_input);
        $readmemh({`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_dw2_pw2_pipeline/testdata/stem_expected_full.mem"}, file_expected_stem);
        $readmemh({`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_dw2_pw2_pipeline/testdata/dw1_expected_full.mem"}, file_expected_dw1);
        $readmemh({`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_dw2_pw2_pipeline/testdata/pw1_expected_pool.mem"}, file_expected_pw1);
        $readmemh({`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_dw2_pw2_pipeline/testdata/dw2_expected_full.mem"}, file_expected_dw2);
        $readmemh({`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_dw2_pw2_pipeline/testdata/pw2_gap_sum.mem"}, file_expected_gap);
        $readmemh({`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_dw2_pw2_pipeline/testdata/fc_expected_logits.mem"}, file_expected_fc_logits);
        $readmemh({`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_dw2_pw2_pipeline/testdata/fc_expected_class.mem"}, file_expected_fc_class);
    end

    always #5 clk = ~clk;

    function signed [DATA_W-1:0] get_stem_lane;
        input integer row;
        input integer lane;
        begin
            get_stem_lane =
                dut.stem_out_tile[(row*STEM_OC_LANES + lane)*DATA_W +: DATA_W];
        end
    endfunction

    function signed [DATA_W-1:0] get_dw1_lane;
        input integer lane;
        begin
            get_dw1_lane = dut.dw1_mid_out_vec[lane*DATA_W +: DATA_W];
        end
    endfunction

    function signed [DATA_W-1:0] get_pw1_lane;
        input integer pool_row;
        input integer lane;
        begin
            get_pw1_lane =
                dut.pw1_out_tile[(pool_row*PW1_OC_LANES + lane)*DATA_W +: DATA_W];
        end
    endfunction

    function signed [DATA_W-1:0] get_dw2_lane;
        input integer lane;
        begin
            get_dw2_lane = dut.dw2_mid_out_vec[lane*DATA_W +: DATA_W];
        end
    endfunction

    function signed [ACC_W-1:0] get_gap_lane;
        input integer oc;
        begin
            get_gap_lane = gap_sum_vec[oc*ACC_W +: ACC_W];
        end
    endfunction

    function signed [DATA_W-1:0] get_fc_logit;
        input integer cls;
        begin
            get_fc_logit = fc_logits_vec[cls*DATA_W +: DATA_W];
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
            dw2_output_count = 0;
            for (seen_i = 0; seen_i < TOTAL_DW1_ROWS; seen_i = seen_i + 1) begin
                seen_dw1[seen_i] = 1'b0;
            end
            for (seen_i = 0; seen_i < TOTAL_DW2_ROWS; seen_i = seen_i + 1) begin
                seen_dw2[seen_i] = 1'b0;
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
        begin
            for (row = 0; row < ROWS; row = row + 1) begin
                t_idx = dut.stem_out_tile_t_base + row;
                for (lane = 0; lane < STEM_OC_LANES; lane = lane + 1) begin
                    ch_idx = dut.stem_out_tile_oc_base + lane;
                    expected_idx = current_case*INPUT_LEN*STEM_OC
                        + t_idx*STEM_OC + ch_idx;
                    expected = file_expected_stem[expected_idx];
                    if (get_stem_lane(row, lane) !== expected) begin
                        $display("ERROR stem case=%0d t=%0d ch=%0d got=%0d expected=%0d",
                            current_case, t_idx, ch_idx,
                            $signed(get_stem_lane(row, lane)), $signed(expected));
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
            group = dut.dw1_mid_out_ch_base / STEM_OC_LANES;
            seen_idx = dut.dw1_mid_out_t * CH_GROUPS + group;
            if (seen_dw1[seen_idx]) begin
                $display("ERROR duplicate DW1 output t=%0d ch_base=%0d",
                    dut.dw1_mid_out_t, dut.dw1_mid_out_ch_base);
                errors = errors + 1;
            end
            seen_dw1[seen_idx] = 1'b1;

            for (lane_i = 0; lane_i < STEM_OC_LANES; lane_i = lane_i + 1) begin
                expected_idx = current_case*INPUT_LEN*STEM_OC
                    + dut.dw1_mid_out_t*STEM_OC
                    + dut.dw1_mid_out_ch_base + lane_i;
                expected = file_expected_dw1[expected_idx];
                if (get_dw1_lane(lane_i) !== expected) begin
                    $display("ERROR DW1 case=%0d t=%0d ch=%0d got=%0d expected=%0d",
                        current_case, dut.dw1_mid_out_t,
                        dut.dw1_mid_out_ch_base + lane_i,
                        $signed(get_dw1_lane(lane_i)), $signed(expected));
                    errors = errors + 1;
                end
            end
            dw1_output_count = dw1_output_count + 1;
        end
    endtask

    task check_pw1_tile;
        reg signed [DATA_W-1:0] expected;
        integer pool_row;
        integer lane;
        integer pool_t;
        integer oc;
        begin
            for (pool_row = 0; pool_row < POOL_ROWS; pool_row = pool_row + 1) begin
                pool_t = dut.pw1_out_pool_t_base + pool_row;
                for (lane = 0; lane < PW1_OC_LANES; lane = lane + 1) begin
                    oc = dut.pw1_out_oc_base + lane;
                    expected_idx = current_case*POOL_LEN*PW1_OC
                        + pool_t*PW1_OC + oc;
                    expected = file_expected_pw1[expected_idx];
                    if (get_pw1_lane(pool_row, lane) !== expected) begin
                        $display("ERROR PW1 case=%0d pool_t=%0d oc=%0d got=%0d expected=%0d",
                            current_case, pool_t, oc,
                            $signed(get_pw1_lane(pool_row, lane)), $signed(expected));
                        errors = errors + 1;
                    end
                end
            end
            pw1_output_count = pw1_output_count + 1;
        end
    endtask

    task check_dw2_row;
        reg signed [DATA_W-1:0] expected;
        integer group;
        integer seen_idx;
        begin
            group = dut.dw2_mid_out_ch_base / CH_LANES;
            seen_idx = dut.dw2_mid_out_t * DW2_GROUPS + group;
            if (seen_dw2[seen_idx]) begin
                $display("ERROR duplicate DW2 output t=%0d ch_base=%0d",
                    dut.dw2_mid_out_t, dut.dw2_mid_out_ch_base);
                errors = errors + 1;
            end
            seen_dw2[seen_idx] = 1'b1;

            for (lane_i = 0; lane_i < CH_LANES; lane_i = lane_i + 1) begin
                expected_idx = current_case*POOL_LEN*PW1_OC
                    + dut.dw2_mid_out_t*PW1_OC
                    + dut.dw2_mid_out_ch_base + lane_i;
                expected = file_expected_dw2[expected_idx];
                if (get_dw2_lane(lane_i) !== expected) begin
                    $display("ERROR DW2 case=%0d t=%0d ch=%0d got=%0d expected=%0d",
                        current_case, dut.dw2_mid_out_t,
                        dut.dw2_mid_out_ch_base + lane_i,
                        $signed(get_dw2_lane(lane_i)), $signed(expected));
                    errors = errors + 1;
                end
            end
            dw2_output_count = dw2_output_count + 1;
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
        if (rst_n && dw2_fire) begin
            check_dw2_row();
        end
    end

    task check_gap;
        reg signed [ACC_W-1:0] expected;
        integer oc;
        begin
            if (gap_count !== POOL_LEN[8:0]) begin
                $display("ERROR gap_count got=%0d expected=%0d", gap_count, POOL_LEN);
                errors = errors + 1;
            end
            for (oc = 0; oc < PW2_OC; oc = oc + 1) begin
                expected_idx = current_case*PW2_OC + oc;
                expected = file_expected_gap[expected_idx];
                if (get_gap_lane(oc) !== expected) begin
                    $display("ERROR GAP case=%0d oc=%0d got=%0d expected=%0d",
                        current_case, oc, $signed(get_gap_lane(oc)), $signed(expected));
                    errors = errors + 1;
                end
            end
        end
    endtask

    task check_fc_result;
        reg signed [DATA_W-1:0] expected_logit;
        begin
            if (fc_class_idx !== file_expected_fc_class[current_case][2:0]) begin
                $display("ERROR FC class case=%0d got=%0d expected=%0d",
                    current_case, fc_class_idx, file_expected_fc_class[current_case]);
                errors = errors + 1;
            end
            if (fc_input_count_error !== 1'b0) begin
                $display("ERROR FC input_count_error case=%0d", current_case);
                errors = errors + 1;
            end
            for (cls_i = 0; cls_i < FC_CLASSES; cls_i = cls_i + 1) begin
                expected_logit =
                    file_expected_fc_logits[current_case*FC_CLASSES + cls_i];
                if (get_fc_logit(cls_i) !== expected_logit) begin
                    $display("ERROR FC logit case=%0d cls=%0d got=%0d expected=%0d",
                        current_case,
                        cls_i,
                        $signed(get_fc_logit(cls_i)),
                        $signed(expected_logit));
                    errors = errors + 1;
                end
            end
        end
    endtask

    task check_final_counts;
        begin
            if (stem_tile_count != TOTAL_STEM_JOBS) begin
                $display("ERROR stem_tile_count got=%0d expected=%0d", stem_tile_count, TOTAL_STEM_JOBS);
                errors = errors + 1;
            end
            if (dw1_output_count != TOTAL_DW1_ROWS) begin
                $display("ERROR DW1 output_count got=%0d expected=%0d", dw1_output_count, TOTAL_DW1_ROWS);
                errors = errors + 1;
            end
            if (pw1_output_count != TOTAL_PW1_OUT_TILES) begin
                $display("ERROR PW1 output_count got=%0d expected=%0d", pw1_output_count, TOTAL_PW1_OUT_TILES);
                errors = errors + 1;
            end
            if (dw2_output_count != TOTAL_DW2_ROWS) begin
                $display("ERROR DW2 output_count got=%0d expected=%0d", dw2_output_count, TOTAL_DW2_ROWS);
                errors = errors + 1;
            end

            for (out_idx = 0; out_idx < TOTAL_DW1_ROWS; out_idx = out_idx + 1) begin
                if (!seen_dw1[out_idx]) begin
                    $display("ERROR missing DW1 output t=%0d group=%0d",
                        out_idx / CH_GROUPS, out_idx % CH_GROUPS);
                    errors = errors + 1;
                end
            end
            for (out_idx = 0; out_idx < TOTAL_DW2_ROWS; out_idx = out_idx + 1) begin
                if (!seen_dw2[out_idx]) begin
                    $display("ERROR missing DW2 output t=%0d group=%0d",
                        out_idx / DW2_GROUPS, out_idx % DW2_GROUPS);
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
            if (dw2_jobs_started != TOTAL_DW2_JOBS) begin
                $display("ERROR dw2_jobs_started got=%0d expected=%0d", dw2_jobs_started, TOTAL_DW2_JOBS);
                errors = errors + 1;
            end
            if (dw2_jobs_done != TOTAL_DW2_JOBS) begin
                $display("ERROR dw2_jobs_done got=%0d expected=%0d", dw2_jobs_done, TOTAL_DW2_JOBS);
                errors = errors + 1;
            end
            if (dw2_rows_out != TOTAL_DW2_ROWS) begin
                $display("ERROR dw2_rows_out got=%0d expected=%0d", dw2_rows_out, TOTAL_DW2_ROWS);
                errors = errors + 1;
            end
            if (pw2_tiles_started != PW2_TILE_COUNT) begin
                $display("ERROR pw2_tiles_started got=%0d expected=%0d", pw2_tiles_started, PW2_TILE_COUNT);
                errors = errors + 1;
            end
            if (pw2_tiles_done != PW2_TILE_COUNT) begin
                $display("ERROR pw2_tiles_done got=%0d expected=%0d", pw2_tiles_done, PW2_TILE_COUNT);
                errors = errors + 1;
            end
            if (fc_jobs_started != 1) begin
                $display("ERROR fc_jobs_started got=%0d expected=1", fc_jobs_started);
                errors = errors + 1;
            end
            if (fc_jobs_done != 1) begin
                $display("ERROR fc_jobs_done got=%0d expected=1", fc_jobs_done);
                errors = errors + 1;
            end
            if (dw1_to_pw1_overwrite_stall_cycles != 0
                || pw1_to_dw2_overwrite_stall_cycles != 0
                || dw2_to_pw2_overwrite_stall_cycles != 0) begin
                $display("ERROR overwrite stalls d1p1=%0d p1d2=%0d d2p2=%0d",
                    dw1_to_pw1_overwrite_stall_cycles,
                    pw1_to_dw2_overwrite_stall_cycles,
                    dw2_to_pw2_overwrite_stall_cycles);
                errors = errors + 1;
            end
        end
    endtask

    task launch_case_with_start_hold;
        input integer case_idx;
        input integer start_hold_cycles;
        integer hold_cycles;
        begin
            hold_cycles = start_hold_cycles;
            if (hold_cycles < 1) begin
                hold_cycles = 1;
            end

            current_case = case_idx;
            case_error_start = errors;
            clear_scoreboard();
            load_activation_ram(case_idx);

            @(negedge clk);
            start = 1'b1;
            repeat (hold_cycles) @(negedge clk);
            start = 1'b0;

            timeout = 0;
            while ((done !== 1'b1) && (timeout < TIMEOUT)) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
                if (DEBUG_PROGRESS && ((timeout % DEBUG_INTERVAL) == 0)) begin
                    $display(
                        "DBG case=%0d timeout=%0d cycles=%0d s=%0d/%0d d1=%0d/%0d p1=%0d/%0d p1out=%0d d2=%0d/%0d d2out=%0d p2=%0d/%0d dw1pend=%0d dw2pend=%0d waits p1=%0d p2=%0d",
                        case_idx,
                        timeout,
                        cycle_count,
                        stem_jobs_done,
                        stem_jobs_started,
                        dw1_jobs_done,
                        dw1_jobs_started,
                        pw1_tiles_done,
                        pw1_tiles_started,
                        pw1_output_tiles,
                        dw2_jobs_done,
                        dw2_jobs_started,
                        dw2_rows_out,
                        pw2_tiles_done,
                        pw2_tiles_started,
                        dw1_pending_count_dbg,
                        dw2_pending_count_dbg,
                        pw1_input_wait_cycles,
                        pw2_input_wait_cycles
                    );
                end
            end

            if (done !== 1'b1) begin
                $display(
                    "ERROR timeout case=%0d cycles=%0d p2=%0d/%0d gap_count=%0d dw2=%0d/%0d d2pend=%0d",
                    case_idx,
                    cycle_count,
                    pw2_tiles_done,
                    pw2_tiles_started,
                    gap_count,
                    dw2_jobs_done,
                    dw2_jobs_started,
                    dw2_pending_count_dbg
                );
                errors = errors + 1;
            end else begin
                check_final_counts();
                check_gap();
                check_fc_result();
                $display(
                    "CASE %0d cycles=%0d gap_count=%0d class=%0d stem=%0d dw1_rows=%0d pw1_out=%0d dw2_rows=%0d pw2_tiles=%0d fc=%0d/%0d max_dw1_pending=%0d max_dw2_pending=%0d waits p1=%0d p2=%0d stalls d1=%0d d2=%0d errors_delta=%0d",
                    case_idx,
                    cycle_count,
                    gap_count,
                    fc_class_idx,
                    stem_tile_count,
                    dw1_output_count,
                    pw1_output_count,
                    dw2_output_count,
                    pw2_tiles_done,
                    fc_jobs_done,
                    fc_jobs_started,
                    max_dw1_pending_count,
                    max_dw2_pending_count,
                    pw1_input_wait_cycles,
                    pw2_input_wait_cycles,
                    dw1_output_stall_cycles,
                    dw2_output_stall_cycles,
                    errors - case_error_start
                );
            end

            repeat (8) @(posedge clk);
        end
    endtask

    task launch_case;
        input integer case_idx;
        begin
            launch_case_with_start_hold(case_idx, 1);
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
            dw2_weight_we = 1'b0;
            dw2_weight_ch = 6'd0;
            dw2_weight_tap = 3'd0;
            dw2_weight_wdata = 16'sd0;
            pw2_w_fold_we = 1'b0;
            pw2_w_fold_oc = 7'd0;
            pw2_w_fold_wdata = 16'sd0;
            pw2_bias_fold_we = 1'b0;
            pw2_bias_fold_oc = 7'd0;
            pw2_bias_fold_wdata = 16'sd0;
        end
    endtask

    task run_mid_reset_case;
        input integer case_idx;
        integer reset_cycle;
        integer reset_error_start;
        begin
            reset_error_start = errors;
            current_case = case_idx;
            clear_scoreboard();
            $display("INFO mid-reset case=%0d active_cycles=%0d begin",
                case_idx, MID_RESET_ACTIVE_CYCLES);

            load_activation_ram(case_idx);
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            for (reset_cycle = 0;
                 reset_cycle < MID_RESET_ACTIVE_CYCLES;
                 reset_cycle = reset_cycle + 1) begin
                @(posedge clk);
                #1;
                if (done === 1'b1) begin
                    $display("ERROR mid-reset completed before reset cycle=%0d", reset_cycle);
                    errors = errors + 1;
                    reset_cycle = MID_RESET_ACTIVE_CYCLES;
                end
            end

            if (busy !== 1'b1) begin
                $display("ERROR mid-reset expected busy before reset");
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
            if (dw1_pending_count_dbg !== {DUT_PENDING_CNT_W{1'b0}}) begin
                $display("ERROR mid-reset dw1_pending_count got=%0d", dw1_pending_count_dbg);
                errors = errors + 1;
            end
            if (dw2_pending_count_dbg !== {DUT_DW2_PENDING_CNT_W{1'b0}}) begin
                $display("ERROR mid-reset dw2_pending_count got=%0d", dw2_pending_count_dbg);
                errors = errors + 1;
            end

            rst_n = 1'b1;
            repeat (4) @(posedge clk);
            $display("INFO mid-reset recovery case=%0d errors_delta=%0d",
                case_idx, errors - reset_error_start);
            launch_case(case_idx);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        errors = 0;
        current_case = 0;
        drive_idle_inputs();
        clear_scoreboard();

        repeat (10) @(negedge clk);
        rst_n = 1'b1;
        repeat (8) @(posedge clk);

        case_limit = RUN_CASE_LIMIT;
        if (case_limit > N_CASES) begin
            case_limit = N_CASES;
        end

        for (case_i = 0; case_i < case_limit; case_i = case_i + 1) begin
            launch_case(case_i);
        end

        if (RUN_CONTINUOUS_START_CASE) begin
            $display("INFO continuous-start hold case begin");
            launch_case_with_start_hold(0, 8);
        end

        if (RUN_MID_RESET_CASE) begin
            run_mid_reset_case((case_limit > 1) ? 1 : 0);
        end

        if (errors == 0) begin
            $display("PASS tb_stem_dw1_pw1_dw2_pw2_pipeline_top");
        end else begin
            $display("FAIL tb_stem_dw1_pw1_dw2_pw2_pipeline_top errors=%0d", errors);
            $fatal(1);
        end

        $finish;
    end

endmodule

`ifndef USE_REAL_IP

module blk_mem_gen_stem_weight (
    input wire clka,
    input wire ena,
    input wire [8:0] addra,
    output reg [63:0] douta
);
    reg [63:0] mem [0:279];
    reg [8:0] addra_d;
    reg ena_d;
    initial begin
        ena_d = 1'b0;
        $readmemh({`PROJECT_ROOT, "/weight_data/stem/weight_packed.mem"}, mem);
    end
    always @(posedge clka) begin
        if (ena) begin
            addra_d <= addra;
        end
        if (ena_d) begin
            douta <= mem[addra_d];
        end
        ena_d <= ena;
    end
endmodule

module blk_mem_gen_pw_conv1_weight (
    input wire clka,
    input wire ena,
    input wire [7:0] addra,
    output reg [127:0] douta
);
    reg [127:0] mem [0:255];
    reg [7:0] addra_d;
    reg ena_d;
    initial begin
        ena_d = 1'b0;
        $readmemh({`PROJECT_ROOT, "/weight_data/pw1/weight_packed.mem"}, mem);
    end
    always @(posedge clka) begin
        if (ena) begin
            addra_d <= addra;
        end
        if (ena_d) begin
            douta <= mem[addra_d];
        end
        ena_d <= ena;
    end
endmodule

module blk_mem_gen_pw_conv2_weight (
    input wire clka,
    input wire ena,
    input wire [8:0] addra,
    output reg [191:0] douta
);
    reg [191:0] mem [0:511];
    reg [8:0] addra_d;
    reg ena_d;
    initial begin
        ena_d = 1'b0;
        $readmemh({`PROJECT_ROOT, "/weight_data/pw2/weight_packed.mem"}, mem);
    end
    always @(posedge clka) begin
        if (ena) begin
            addra_d <= addra;
        end
        if (ena_d) begin
            douta <= mem[addra_d];
        end
        ena_d <= ena;
    end
endmodule

module blk_mem_gen_stem_activation (
    input wire clka,
    input wire ena,
    input wire [0:0] wea,
    input wire [8:0] addra,
    input wire [63:0] dina,
    output reg [63:0] douta,
    input wire clkb,
    input wire enb,
    input wire [0:0] web,
    input wire [8:0] addrb,
    input wire [63:0] dinb,
    output reg [63:0] doutb
);
    reg [63:0] mem [0:511];
    reg [8:0] addra_d;
    reg [8:0] addrb_d;
    reg ena_d;
    reg enb_d;
    initial begin
        ena_d = 1'b0;
        enb_d = 1'b0;
    end
    always @(posedge clka) begin
        if (ena) begin
            if (wea[0]) begin
                mem[addra] <= dina;
            end
            addra_d <= addra;
        end
        if (ena_d) begin
            douta <= mem[addra_d];
        end
        ena_d <= ena;
    end
    always @(posedge clkb) begin
        if (enb) begin
            if (web[0]) begin
                mem[addrb] <= dinb;
            end
            addrb_d <= addrb;
        end
        if (enb_d) begin
            doutb <= mem[addrb_d];
        end
        enb_d <= enb;
    end
endmodule

module blk_mem_gen_stem_to_dw_conv1 (
    input wire clka,
    input wire ena,
    input wire [0:0] wea,
    input wire [6:0] addra,
    input wire [63:0] dina,
    output reg [63:0] douta,
    input wire clkb,
    input wire enb,
    input wire [0:0] web,
    input wire [6:0] addrb,
    input wire [63:0] dinb,
    output reg [63:0] doutb
);
    reg [63:0] mem [0:127];
    reg [6:0] addra_d;
    reg [6:0] addrb_d;
    reg ena_d;
    reg enb_d;
    initial begin
        ena_d = 1'b0;
        enb_d = 1'b0;
    end
    always @(posedge clka) begin
        if (ena) begin
            if (wea[0]) begin
                mem[addra] <= dina;
            end
            addra_d <= addra;
        end
        if (ena_d) begin
            douta <= mem[addra_d];
        end
        ena_d <= ena;
    end
    always @(posedge clkb) begin
        if (enb) begin
            if (web[0]) begin
                mem[addrb] <= dinb;
            end
            addrb_d <= addrb;
        end
        if (enb_d) begin
            doutb <= mem[addrb_d];
        end
        enb_d <= enb;
    end
endmodule

module blk_mem_gen_dw_to_pw_conv1 (
    input wire clka,
    input wire ena,
    input wire [0:0] wea,
    input wire [6:0] addra,
    input wire [63:0] dina,
    output reg [63:0] douta,
    input wire clkb,
    input wire enb,
    input wire [0:0] web,
    input wire [6:0] addrb,
    input wire [63:0] dinb,
    output reg [63:0] doutb
);
    reg [63:0] mem [0:127];
    reg [6:0] addra_d;
    reg [6:0] addrb_d;
    reg ena_d;
    reg enb_d;
    initial begin
        ena_d = 1'b0;
        enb_d = 1'b0;
    end
    always @(posedge clka) begin
        if (ena) begin
            if (wea[0]) begin
                mem[addra] <= dina;
            end
            addra_d <= addra;
        end
        if (ena_d) begin
            douta <= mem[addra_d];
        end
        ena_d <= ena;
    end
    always @(posedge clkb) begin
        if (enb) begin
            if (web[0]) begin
                mem[addrb] <= dinb;
            end
            addrb_d <= addrb;
        end
        if (enb_d) begin
            doutb <= mem[addrb_d];
        end
        enb_d <= enb;
    end
endmodule

module blk_mem_gen_pw_to_dw_conv2 (
    input wire clka,
    input wire ena,
    input wire [0:0] wea,
    input wire [7:0] addra,
    input wire [63:0] dina,
    output reg [63:0] douta,
    input wire clkb,
    input wire enb,
    input wire [0:0] web,
    input wire [7:0] addrb,
    input wire [63:0] dinb,
    output reg [63:0] doutb
);
    reg [63:0] mem [0:255];
    reg [7:0] addra_d;
    reg [7:0] addrb_d;
    reg ena_d;
    reg enb_d;
    initial begin
        ena_d = 1'b0;
        enb_d = 1'b0;
    end
    always @(posedge clka) begin
        if (ena) begin
            if (wea[0]) begin
                mem[addra] <= dina;
            end
            addra_d <= addra;
        end
        if (ena_d) begin
            douta <= mem[addra_d];
        end
        ena_d <= ena;
    end
    always @(posedge clkb) begin
        if (enb) begin
            if (web[0]) begin
                mem[addrb] <= dinb;
            end
            addrb_d <= addrb;
        end
        if (enb_d) begin
            doutb <= mem[addrb_d];
        end
        enb_d <= enb;
    end
endmodule

module blk_mem_gen_dw_to_pw_conv2 (
    input wire clka,
    input wire ena,
    input wire [0:0] wea,
    input wire [7:0] addra,
    input wire [63:0] dina,
    output reg [63:0] douta,
    input wire clkb,
    input wire enb,
    input wire [0:0] web,
    input wire [7:0] addrb,
    input wire [63:0] dinb,
    output reg [63:0] doutb
);
    reg [63:0] mem [0:255];
    reg [7:0] addra_d;
    reg [7:0] addrb_d;
    reg ena_d;
    reg enb_d;
    initial begin
        ena_d = 1'b0;
        enb_d = 1'b0;
    end
    always @(posedge clka) begin
        if (ena) begin
            if (wea[0]) begin
                mem[addra] <= dina;
            end
            addra_d <= addra;
        end
        if (ena_d) begin
            douta <= mem[addra_d];
        end
        ena_d <= ena;
    end
    always @(posedge clkb) begin
        if (enb) begin
            if (web[0]) begin
                mem[addrb] <= dinb;
            end
            addrb_d <= addrb;
        end
        if (enb_d) begin
            doutb <= mem[addrb_d];
        end
        enb_d <= enb;
    end
endmodule

module blk_mem_gen_fc_weight (
    input wire clka,
    input wire ena,
    input wire [9:0] addra,
    output reg [255:0] douta
);
    reg [255:0] mem [0:678];
    reg [9:0] addra_d;
    reg ena_d;

    initial begin
        ena_d = 1'b0;
        $readmemh({`PROJECT_ROOT, "/weight_data/fc/weight_packed_256.mem"}, mem);
    end

    always @(posedge clka) begin
        if (ena) begin
            addra_d <= addra;
        end
        if (ena_d) begin
            douta <= mem[addra_d];
        end
        ena_d <= ena;
    end
endmodule

`endif
