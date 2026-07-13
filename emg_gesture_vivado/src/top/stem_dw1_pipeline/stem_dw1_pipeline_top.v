`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

// Integrated stem -> stem_to_dw1 buffer -> DW1 pipeline top.
//
// One start pulse runs the full 348-sample stream:
//   for tile_t_base = 0,4,...,344:
//     for ch_base = 0,4,...,28:
//       run one stem 4x4 tile
//       enqueue one DW1 job for the same time chunk and channel group
//
// Stem and DW1 are decoupled with a small pending-job FIFO. The scheduler may
// launch the next stem tile while DW1 consumes earlier jobs. If DW1 or the
// downstream output stream falls behind, the FIFO eventually fills and new stem
// launches pause. If the lower inter-stage ring itself is the bottleneck,
// buffer_stem_watermark_stall/stem_output_stall expose that directly.

module stem_dw1_pipeline_top #(
    parameter integer DATA_W     = 16,
    parameter integer ACC_W      = 48,
    parameter integer ROWS       = 4,
    parameter integer OC_LANES   = 4,
    parameter integer STEM_OC    = 32,
    parameter integer STEM_K     = 35,
    parameter integer STEM_IC    = 5,
    parameter integer STEM_KERNEL = 7,
    parameter integer STEM_PADDING = 3,
    parameter integer DW_K       = 5,
    parameter integer DW_PAD     = 2,
    parameter integer INPUT_LEN  = 348,
    parameter integer FRAC_BITS  = 8,
    parameter integer TIME_W     = 9,
    parameter integer ROWS_W     = 4,
    parameter integer RING_ROWS  = 16,
    parameter integer PENDING_DEPTH = 8,
    parameter integer BRAM_READ_LATENCY = 1,
    parameter integer CH_GROUPS  = STEM_OC / OC_LANES,
    parameter integer ACT_TIME_WORDS = (INPUT_LEN + ROWS - 1) / ROWS,
    parameter integer ACT_RAM_DEPTH  = STEM_IC * ACT_TIME_WORDS,
    parameter integer ACT_ADDR_W     = (ACT_RAM_DEPTH <= 1)
        ? 1 : $clog2(ACT_RAM_DEPTH),
    parameter integer PENDING_PTR_W  = (PENDING_DEPTH <= 1)
        ? 1 : $clog2(PENDING_DEPTH),
    parameter integer PENDING_CNT_W  = (PENDING_DEPTH <= 1)
        ? 1 : $clog2(PENDING_DEPTH + 1)
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    output reg busy,
    output reg done,

    input  wire act_wr_en,
    input  wire [ACT_ADDR_W-1:0] act_wr_addr,
    input  wire [ROWS*DATA_W-1:0] act_wr_data,
    output wire act_wr_ready,

    input  wire stem_w_fold_we,
    input  wire [4:0] stem_w_fold_oc,
    input  wire signed [DATA_W-1:0] stem_w_fold_wdata,
    input  wire stem_bias_fold_we,
    input  wire [4:0] stem_bias_fold_oc,
    input  wire signed [DATA_W-1:0] stem_bias_fold_wdata,

    input  wire dw1_weight_we,
    input  wire [4:0] dw1_weight_ch,
    input  wire [2:0] dw1_weight_tap,
    input  wire signed [DATA_W-1:0] dw1_weight_wdata,

    input  wire dw1_out_ready,
    output wire dw1_out_valid,
    output wire [TIME_W-1:0] dw1_out_t,
    output wire [4:0] dw1_out_ch_base,
    output wire signed [OC_LANES*DATA_W-1:0] dw1_out_vec,

    output wire stem_busy,
    output wire dw1_busy,
    output wire buffer_wr_busy,
    output wire buffer_rd_busy,
    output wire buffer_stem_watermark_stall,
    output wire stem_output_stall,
    output wire scheduler_pending_full,
    output wire [PENDING_CNT_W-1:0] pending_count_dbg,

    output reg [31:0] cycle_count,
    output reg [31:0] stem_jobs_started,
    output reg [31:0] stem_jobs_done,
    output reg [31:0] dw1_jobs_started,
    output reg [31:0] dw1_jobs_done,
    output reg [31:0] dw1_rows_out,
    output reg [31:0] stem_start_blocked_pending_cycles,
    output reg [31:0] stem_output_stall_cycles,
    output reg [31:0] dw1_output_stall_cycles,
    output reg [31:0] buffer_watermark_stall_cycles,
    output reg [PENDING_CNT_W-1:0] max_pending_count
);

    localparam integer OC_BASE_W = 5;
    localparam [PENDING_CNT_W-1:0] PENDING_DEPTH_COUNT = PENDING_DEPTH;
    localparam [ROWS_W-1:0] ROWS_VALUE = ROWS;
    localparam integer STEM_TO_DW1_SLICE_DEPTH = 4;
    localparam [PENDING_CNT_W-1:0] PENDING_LAUNCH_LIMIT =
        PENDING_DEPTH - STEM_TO_DW1_SLICE_DEPTH;
    localparam integer STEM_OUT_SLICE_W = TIME_W + 5
        + (ROWS * OC_LANES * DATA_W);

    reg buffer_clear;

    reg stem_start;
    reg [4:0] stem_oc_base;
    reg [TIME_W-1:0] stem_tile_t_base;
    wire stem_done;
    wire stem_out_valid;
    wire stem_to_buffer_ready;
    wire [TIME_W-1:0] stem_out_tile_t_base;
    wire [4:0] stem_out_tile_oc_base;
    wire signed [ROWS*OC_LANES*DATA_W-1:0] stem_out_tile;
    wire stem_to_dw1_in_valid;
    wire stem_to_dw1_in_ready;
    wire stem_to_dw1_slice_busy;
    wire [STEM_OUT_SLICE_W-1:0] stem_to_dw1_slice_in;
    wire [STEM_OUT_SLICE_W-1:0] stem_to_dw1_slice_out;
    wire [TIME_W-1:0] stem_to_dw1_out_tile_t_base;
    wire [4:0] stem_to_dw1_out_tile_oc_base;
    wire signed [ROWS*OC_LANES*DATA_W-1:0] stem_to_dw1_out_tile;

    wire dw1_win_req_valid;
    wire [TIME_W-1:0] dw1_win_req_out_t;
    wire [4:0] dw1_win_req_ch_base;
    wire dw1_win_req_ready;
    wire dw1_win_vec_valid;
    wire dw1_win_vec_ready;
    wire signed [DW_K*OC_LANES*DATA_W-1:0] dw1_win_vec;

    reg dw1_start;
    reg [4:0] dw1_ch_base;
    reg [TIME_W-1:0] dw1_input_t_base;
    reg [ROWS_W-1:0] dw1_input_rows;
    reg dw1_final_chunk;
    wire dw1_done;
    wire [TIME_W-1:0] dw1_job_out_t_start;
    wire [TIME_W:0] dw1_job_out_count;

    reg all_stem_issued;
    reg [TIME_W-1:0] next_tile_t_base;
    reg [4:0] next_ch_base;
    reg [TIME_W-1:0] launched_t_base;
    reg [4:0] launched_ch_base;
    reg launched_final_chunk;

    reg [TIME_W-1:0] pending_t_base [0:PENDING_DEPTH-1];
    reg [4:0] pending_ch_base [0:PENDING_DEPTH-1];
    reg pending_final_chunk [0:PENDING_DEPTH-1];
    reg [PENDING_PTR_W-1:0] pending_rd_ptr;
    reg [PENDING_PTR_W-1:0] pending_wr_ptr;
    reg [PENDING_CNT_W-1:0] pending_count;

    wire pending_empty;
    wire pending_launch_room;
    wire stem_issue_now;
    wire dw1_start_now;
    wire pending_push;
    wire pending_pop;
    wire [PENDING_CNT_W-1:0] pending_count_after_pop;
    wire [PENDING_CNT_W-1:0] pending_count_next;
    wire run_complete_now;
    wire dw1_out_fire;

    integer rst_i;

    assign pending_empty = (pending_count == {PENDING_CNT_W{1'b0}});
    assign pending_count_after_pop = pending_count
        - {{(PENDING_CNT_W-1){1'b0}}, pending_pop};
    // Reserve room for stem tiles already accepted into the output slice but not
    // yet enqueued as DW1 jobs.
    assign pending_launch_room = (pending_count_after_pop
        < PENDING_LAUNCH_LIMIT);
    assign scheduler_pending_full = busy && !pending_launch_room;
    assign pending_count_dbg = pending_count;

    assign stem_issue_now = busy
        && !buffer_clear
        && !all_stem_issued
        && !stem_busy
        && !stem_start
        && pending_launch_room;

    assign dw1_start_now = busy
        && !pending_empty
        && !dw1_busy
        && !dw1_start;

    assign stem_to_dw1_slice_in = {
        stem_out_tile_t_base,
        stem_out_tile_oc_base,
        stem_out_tile
    };
    assign {
        stem_to_dw1_out_tile_t_base,
        stem_to_dw1_out_tile_oc_base,
        stem_to_dw1_out_tile
    } = stem_to_dw1_slice_out;

    assign pending_push = busy
        && stem_to_dw1_in_valid
        && stem_to_dw1_in_ready;
    assign pending_pop = dw1_start_now;
    assign pending_count_next = pending_count
        + {{(PENDING_CNT_W-1){1'b0}}, pending_push}
        - {{(PENDING_CNT_W-1){1'b0}}, pending_pop};

    assign dw1_out_fire = dw1_out_valid && dw1_out_ready;
    assign stem_output_stall = stem_out_valid && !stem_to_buffer_ready;

    assign run_complete_now = busy
        && all_stem_issued
        && !stem_busy
        && !stem_start
        && !stem_done
        && pending_empty
        && !dw1_busy
        && !dw1_start
        && !dw1_out_valid
        && !stem_to_dw1_slice_busy
        && !buffer_wr_busy
        && !buffer_rd_busy;

    initial begin
        if ((STEM_OC % OC_LANES) != 0) begin
            $error("stem_dw1_pipeline_top: STEM_OC must be divisible by OC_LANES");
        end
        if (PENDING_DEPTH < 2) begin
            $error("stem_dw1_pipeline_top: PENDING_DEPTH must be >= 2");
        end
        if (PENDING_DEPTH <= STEM_TO_DW1_SLICE_DEPTH) begin
            $error("stem_dw1_pipeline_top: PENDING_DEPTH must exceed stem output slice depth");
        end
    end

    function [PENDING_PTR_W-1:0] next_pending_ptr;
        input [PENDING_PTR_W-1:0] ptr;
        begin
            if (ptr == (PENDING_DEPTH - 1)) begin
                next_pending_ptr = {PENDING_PTR_W{1'b0}};
            end else begin
                next_pending_ptr = ptr + 1'b1;
            end
        end
    endfunction

    function is_final_tile;
        input [TIME_W-1:0] tile_t_base_i;
        begin
            is_final_tile = (tile_t_base_i == (INPUT_LEN - ROWS));
        end
    endfunction

    stem_conv_array_4x4 #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .ROWS(ROWS),
        .OC_LANES(OC_LANES),
        .STEM_OC(STEM_OC),
        .STEM_K(STEM_K),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .STEM_IC(STEM_IC),
        .KERNEL(STEM_KERNEL),
        .PADDING(STEM_PADDING),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .ACT_TIME_WORDS(ACT_TIME_WORDS),
        .ACT_RAM_DEPTH(ACT_RAM_DEPTH),
        .ACT_ADDR_W(ACT_ADDR_W)
    ) u_stem (
        .clk(clk),
        .rst_n(rst_n),
        .start(stem_start),
        .oc_base(stem_oc_base),
        .tile_t_base(stem_tile_t_base),
        .act_wr_en(act_wr_en),
        .act_wr_addr(act_wr_addr),
        .act_wr_data(act_wr_data),
        .act_wr_bank(1'b0),
        .act_rd_bank(1'b0),
        .act_rd_active(busy || start),
        .act_wr_ready(act_wr_ready),
        .w_fold_we(stem_w_fold_we),
        .w_fold_oc(stem_w_fold_oc),
        .w_fold_wdata(stem_w_fold_wdata),
        .bias_fold_we(stem_bias_fold_we),
        .bias_fold_oc(stem_bias_fold_oc),
        .bias_fold_wdata(stem_bias_fold_wdata),
        .out_ready(stem_to_buffer_ready),
        .busy(stem_busy),
        .done(stem_done),
        .out_valid(stem_out_valid),
        .out_tile_t_base(stem_out_tile_t_base),
        .out_tile_oc_base(stem_out_tile_oc_base),
        .out_tile(stem_out_tile)
    );

    emg_stream_fifo_slice #(
        .DATA_W(STEM_OUT_SLICE_W),
        .DEPTH(STEM_TO_DW1_SLICE_DEPTH)
    ) u_stem_to_dw1_ready_slice (
        .clk(clk),
        .rst_n(rst_n),
        .clear(buffer_clear),
        .in_valid(stem_out_valid),
        .in_ready(stem_to_buffer_ready),
        .in_data(stem_to_dw1_slice_in),
        .out_valid(stem_to_dw1_in_valid),
        .out_ready(stem_to_dw1_in_ready),
        .out_data(stem_to_dw1_slice_out),
        .busy(stem_to_dw1_slice_busy)
    );

    stem_to_dw1_buffer_with_ram #(
        .DATA_W(DATA_W),
        .TIME_W(TIME_W),
        .INPUT_LEN(INPUT_LEN),
        .STEM_OC(STEM_OC),
        .ROWS(ROWS),
        .OC_LANES(OC_LANES),
        .DW_K(DW_K),
        .DW_PAD(DW_PAD),
        .RING_ROWS(RING_ROWS),
        .BANKS(CH_GROUPS),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .OC_BASE_W(OC_BASE_W)
    ) u_stem_to_dw1 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(buffer_clear),
        .stem_out_valid(stem_to_dw1_in_valid),
        .stem_out_ready(stem_to_dw1_in_ready),
        .stem_out_tile_t_base(stem_to_dw1_out_tile_t_base),
        .stem_out_tile_oc_base(stem_to_dw1_out_tile_oc_base),
        .stem_out_tile(stem_to_dw1_out_tile),
        .dw1_win_req_valid(dw1_win_req_valid),
        .dw1_win_req_ready(dw1_win_req_ready),
        .dw1_win_req_out_t(dw1_win_req_out_t),
        .dw1_win_req_ch_base(dw1_win_req_ch_base),
        .dw1_win_vec_valid(dw1_win_vec_valid),
        .dw1_win_vec_ready(dw1_win_vec_ready),
        .dw1_win_vec(dw1_win_vec),
        .wr_busy(buffer_wr_busy),
        .rd_busy(buffer_rd_busy),
        .stem_watermark_stall(buffer_stem_watermark_stall)
    );

    dw_conv1_4ch_5tap #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .CHANNELS(STEM_OC),
        .P_CH(OC_LANES),
        .K(DW_K),
        .PAD(DW_PAD),
        .INPUT_LEN(INPUT_LEN),
        .FRAC_BITS(FRAC_BITS),
        .TIME_W(TIME_W),
        .ROWS_W(ROWS_W)
    ) u_dw1 (
        .clk(clk),
        .rst_n(rst_n),
        .start(dw1_start),
        .ch_base(dw1_ch_base),
        .input_t_base(dw1_input_t_base),
        .input_rows(dw1_input_rows),
        .final_chunk(dw1_final_chunk),
        .win_req_valid(dw1_win_req_valid),
        .win_req_out_t(dw1_win_req_out_t),
        .win_req_ch_base(dw1_win_req_ch_base),
        .win_req_ready(dw1_win_req_ready),
        .win_vec_valid(dw1_win_vec_valid),
        .win_vec_ready(dw1_win_vec_ready),
        .win_vec(dw1_win_vec),
        .weight_we(dw1_weight_we),
        .weight_ch(dw1_weight_ch),
        .weight_tap(dw1_weight_tap),
        .weight_wdata(dw1_weight_wdata),
        .out_ready(dw1_out_ready),
        .busy(dw1_busy),
        .done(dw1_done),
        .out_valid(dw1_out_valid),
        .out_t(dw1_out_t),
        .out_ch_base(dw1_out_ch_base),
        .out_vec(dw1_out_vec),
        .job_out_t_start(dw1_job_out_t_start),
        .job_out_count(dw1_job_out_count)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            buffer_clear <= 1'b0;
            stem_start <= 1'b0;
            stem_oc_base <= 5'd0;
            stem_tile_t_base <= {TIME_W{1'b0}};
            dw1_start <= 1'b0;
            dw1_ch_base <= 5'd0;
            dw1_input_t_base <= {TIME_W{1'b0}};
            dw1_input_rows <= ROWS_VALUE;
            dw1_final_chunk <= 1'b0;
            all_stem_issued <= 1'b0;
            next_tile_t_base <= {TIME_W{1'b0}};
            next_ch_base <= 5'd0;
            launched_t_base <= {TIME_W{1'b0}};
            launched_ch_base <= 5'd0;
            launched_final_chunk <= 1'b0;
            pending_rd_ptr <= {PENDING_PTR_W{1'b0}};
            pending_wr_ptr <= {PENDING_PTR_W{1'b0}};
            pending_count <= {PENDING_CNT_W{1'b0}};
            cycle_count <= 32'd0;
            stem_jobs_started <= 32'd0;
            stem_jobs_done <= 32'd0;
            dw1_jobs_started <= 32'd0;
            dw1_jobs_done <= 32'd0;
            dw1_rows_out <= 32'd0;
            stem_start_blocked_pending_cycles <= 32'd0;
            stem_output_stall_cycles <= 32'd0;
            dw1_output_stall_cycles <= 32'd0;
            buffer_watermark_stall_cycles <= 32'd0;
            max_pending_count <= {PENDING_CNT_W{1'b0}};
            for (rst_i = 0; rst_i < PENDING_DEPTH; rst_i = rst_i + 1) begin
                pending_t_base[rst_i] <= {TIME_W{1'b0}};
                pending_ch_base[rst_i] <= 5'd0;
                pending_final_chunk[rst_i] <= 1'b0;
            end
        end else begin
            done <= 1'b0;
            stem_start <= 1'b0;
            dw1_start <= 1'b0;

            if (buffer_clear) begin
                buffer_clear <= 1'b0;
            end

            if (start && !busy) begin
                busy <= 1'b1;
                buffer_clear <= 1'b1;
                all_stem_issued <= 1'b0;
                next_tile_t_base <= {TIME_W{1'b0}};
                next_ch_base <= 5'd0;
                launched_t_base <= {TIME_W{1'b0}};
                launched_ch_base <= 5'd0;
                launched_final_chunk <= 1'b0;
                pending_rd_ptr <= {PENDING_PTR_W{1'b0}};
                pending_wr_ptr <= {PENDING_PTR_W{1'b0}};
                pending_count <= {PENDING_CNT_W{1'b0}};
                cycle_count <= 32'd0;
                stem_jobs_started <= 32'd0;
                stem_jobs_done <= 32'd0;
                dw1_jobs_started <= 32'd0;
                dw1_jobs_done <= 32'd0;
                dw1_rows_out <= 32'd0;
                stem_start_blocked_pending_cycles <= 32'd0;
                stem_output_stall_cycles <= 32'd0;
                dw1_output_stall_cycles <= 32'd0;
                buffer_watermark_stall_cycles <= 32'd0;
                max_pending_count <= {PENDING_CNT_W{1'b0}};
            end else if (busy) begin
                cycle_count <= cycle_count + 1'b1;

                if (!all_stem_issued
                    && !stem_busy
                    && !stem_start
                    && !pending_launch_room) begin
                    stem_start_blocked_pending_cycles
                        <= stem_start_blocked_pending_cycles + 1'b1;
                end
                if (stem_output_stall) begin
                    stem_output_stall_cycles <= stem_output_stall_cycles + 1'b1;
                end
                if (dw1_out_valid && !dw1_out_ready) begin
                    dw1_output_stall_cycles <= dw1_output_stall_cycles + 1'b1;
                end
                if (buffer_stem_watermark_stall) begin
                    buffer_watermark_stall_cycles
                        <= buffer_watermark_stall_cycles + 1'b1;
                end
                if (dw1_out_fire) begin
                    dw1_rows_out <= dw1_rows_out + 1'b1;
                end
                if (dw1_done) begin
                    dw1_jobs_done <= dw1_jobs_done + 1'b1;
                end

                if (stem_issue_now) begin
                    stem_start <= 1'b1;
                    stem_oc_base <= next_ch_base;
                    stem_tile_t_base <= next_tile_t_base;
                    launched_t_base <= next_tile_t_base;
                    launched_ch_base <= next_ch_base;
                    launched_final_chunk <= is_final_tile(next_tile_t_base);
                    stem_jobs_started <= stem_jobs_started + 1'b1;

                    if (next_ch_base == (STEM_OC - OC_LANES)) begin
                        next_ch_base <= 5'd0;
                        if (next_tile_t_base == (INPUT_LEN - ROWS)) begin
                            all_stem_issued <= 1'b1;
                        end else begin
                            next_tile_t_base <= next_tile_t_base + ROWS;
                        end
                    end else begin
                        next_ch_base <= next_ch_base + OC_LANES;
                    end
                end

                if (pending_push) begin
                    pending_t_base[pending_wr_ptr]
                        <= stem_to_dw1_out_tile_t_base;
                    pending_ch_base[pending_wr_ptr]
                        <= stem_to_dw1_out_tile_oc_base;
                    pending_final_chunk[pending_wr_ptr]
                        <= is_final_tile(stem_to_dw1_out_tile_t_base);
                    pending_wr_ptr <= next_pending_ptr(pending_wr_ptr);
                    stem_jobs_done <= stem_jobs_done + 1'b1;
                end

                if (pending_pop) begin
                    dw1_start <= 1'b1;
                    dw1_ch_base <= pending_ch_base[pending_rd_ptr];
                    dw1_input_t_base <= pending_t_base[pending_rd_ptr];
                    dw1_input_rows <= ROWS_VALUE;
                    dw1_final_chunk <= pending_final_chunk[pending_rd_ptr];
                    pending_rd_ptr <= next_pending_ptr(pending_rd_ptr);
                    dw1_jobs_started <= dw1_jobs_started + 1'b1;
                end

                pending_count <= pending_count_next;
                if (pending_count_next > max_pending_count) begin
                    max_pending_count <= pending_count_next;
                end

                if (run_complete_now) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end

endmodule
