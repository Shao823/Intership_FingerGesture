`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

// LightCNN1D PW2 pointwise Conv1d 4x12 output-stationary systolic tile.
//
// One start pulse computes all PW2 output-channel groups for one low-resolution
// input time tile:
//   input:  4 low-resolution DW2 rows x 64 channels
//   output: 4 low-resolution PW2 rows x 96 channels
//
// The 4x12 array is reused internally for all eight output-channel groups:
//   oc_base = 0, 12, 24, ..., 84
// For each group the module accumulates the post-BN/ReLU result directly into
// GAP sums:
//   gap_sum[oc_base + col] += post_relu[row][col] for each valid row
//
// The module requests a precise input tile before issuing activation/weight
// requests. input_tile_req_ready must mean the upstream dw2_to_pw2 row packer
// has the requested rows, all 64 channels valid for each asserted row in
// row_valid_mask, and can keep them readable while this job runs.
//
// Runtime activation and weight access are request/response streams:
//   act_vec    = {A[tile_t_base+3][k], ..., A[tile_t_base+0][k]}
//   weight_vec = {W[oc_base+11][k], ..., W[oc_base+0][k]}
// Requests for the same k may be accepted in different cycles. req_k advances
// only after both sides have accepted that k. Response streams must return
// exactly one vector per accepted request, in request order.
//
// Fused compute order:
//   PW2 conv -> folded BN -> ReLU
//
// row_valid_mask supports the final partial low-resolution tile. For normal
// tiles it should be 4'b1111. For the default 174-row stream, the final partial
// tile at tile_t_base=172 should use 4'b0011. Invalid rows are not accumulated.
//
// Deprecated debug tile stream, kept as interface reference only:
//   input  wire out_ready
//   output reg  out_valid
//   output reg  [TIME_W-1:0] out_tile_t_base
//   output reg  [6:0] out_tile_oc_base
//   output reg  [ROWS-1:0] out_row_valid_mask
//   output reg  out_last_group
//   output reg  signed [ROWS*OC_LANES*DATA_W-1:0] out_tile

module pw_conv2_array_4x12_compute #(
    parameter integer DATA_W     =  8,
    parameter integer MULT_W     = 16,
    parameter integer ACC_W      = 48,
    parameter integer ROWS       = 4,
    parameter integer OC_LANES   = 12,
    parameter integer PW2_IC     = 64,
    parameter integer PW2_OC     = 96,
    parameter integer GAP_LEN    = 174,
    parameter integer FRAC_BITS  = 8,
    parameter integer TIME_W     = 8,
    parameter BIAS_INIT_FILE     = {`PROJECT_ROOT, "/weight_data/pw2/bias_int32.mem"},
    parameter MULT_INIT_FILE     = {`PROJECT_ROOT, "/weight_data/pw2/multiplier_q15.mem"},
    parameter SHIFT_INIT_FILE    = {`PROJECT_ROOT, "/weight_data/pw2/right_shift.mem"}
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    input  wire gap_clear,
    input  wire [TIME_W-1:0] tile_t_base,
    input  wire [ROWS-1:0] row_valid_mask,

    output wire input_tile_req_valid,
    output wire [TIME_W-1:0] input_tile_req_t_base,
    output wire [ROWS-1:0] input_tile_req_row_valid_mask,
    input  wire input_tile_req_ready,

    output wire weight_req_valid,
    output wire [6:0] weight_req_oc_base,
    output wire [6:0] weight_req_k,
    input  wire weight_req_ready,
    input  wire weight_vec_valid,
    output wire weight_vec_ready,
    input  wire signed [OC_LANES*DATA_W-1:0] weight_vec,

    output wire act_req_valid,
    output wire [TIME_W-1:0] act_req_t_base,
    output wire [6:0] act_req_k,
    output wire [ROWS-1:0] act_req_row_valid_mask,
    input  wire act_req_ready,
    input  wire act_vec_valid,
    output wire act_vec_ready,
    input  wire signed [ROWS*DATA_W-1:0] act_vec,

    input  wire w_fold_we,
    input  wire [6:0] w_fold_oc,
    input  wire signed [MULT_W-1:0] w_fold_wdata,

    input  wire bias_fold_we,
    input  wire [6:0] bias_fold_oc,
    input  wire signed [31:0] bias_fold_wdata,

    output reg busy,
    output reg done,
    output reg gap_frame_done,
    output reg [8:0] gap_count,
    output wire signed [PW2_OC*ACC_W-1:0] gap_sum_vec
);

    localparam integer OC_GROUPS    = PW2_OC / OC_LANES;
    localparam integer TOTAL_MACS   = OC_GROUPS * PW2_IC;
    localparam integer FLUSH_CYCLES = ROWS + OC_LANES - 2;
    localparam integer REQ_W        = (PW2_IC <= 1) ? 1 : $clog2(PW2_IC + 1);
    localparam integer TOTAL_W      = (TOTAL_MACS <= 1) ? 1 : $clog2(TOTAL_MACS + 1);
    localparam integer GROUP_W      = (OC_GROUPS <= 1) ? 1 : $clog2(OC_GROUPS + 1);
    localparam integer DRAIN_W      = (FLUSH_CYCLES <= 1) ? 1 : $clog2(FLUSH_CYCLES + 1);
    localparam integer META_STAGES  = FLUSH_CYCLES + 1;
    localparam [8:0] GAP_TARGET     = GAP_LEN[8:0];

    localparam [1:0] STATE_IDLE = 2'd0;
    localparam [1:0] STATE_WAIT = 2'd1;
    localparam [1:0] STATE_RUN  = 2'd2;

    reg [1:0] state;
    reg [TIME_W-1:0] tile_t_base_reg;
    reg [ROWS-1:0] row_valid_mask_reg;
    reg [TOTAL_W-1:0] req_count;
    reg [TOTAL_W-1:0] recv_count;
    reg [DRAIN_W-1:0] drain_count;
    reg weight_req_sent;
    reg act_req_sent;

    reg weight_hold_valid;
    reg signed [OC_LANES*DATA_W-1:0] weight_hold_data;
    reg act_hold_valid;
    reg signed [ROWS*DATA_W-1:0] act_hold_data;
    reg act_cache_valid;
    reg signed [ROWS*DATA_W-1:0] act_cache [0:PW2_IC-1];

    reg signed [31:0] bias_int32_mem [0:PW2_OC-1];
    reg signed [MULT_W-1:0] multiplier_q15_mem [0:PW2_OC-1];
    reg [7:0] right_shift_mem [0:PW2_OC-1];

    initial begin
        $readmemh(BIAS_INIT_FILE, bias_int32_mem);
        $readmemh(MULT_INIT_FILE, multiplier_q15_mem);
        $readmemh(SHIFT_INIT_FILE, right_shift_mem);
    end

    reg signed [ACC_W-1:0] gap_sum_mem [0:PW2_OC-1];

    reg signed [DATA_W-1:0] a_delay [0:ROWS-1][0:ROWS-1];
    reg signed [DATA_W-1:0] w_delay [0:OC_LANES-1][0:OC_LANES-1];
    reg [GROUP_W-1:0] meta_group_d [0:META_STAGES-1];
    reg meta_valid_d [0:META_STAGES-1];
    reg meta_first_d [0:META_STAGES-1];
    reg meta_last_d [0:META_STAGES-1];
    reg [GROUP_W-1:0] post_group_reg [0:ROWS-1][0:OC_LANES-1];

    wire [GROUP_W-1:0] req_group;
    wire [REQ_W-1:0] req_k_idx;
    wire [GROUP_W-1:0] recv_group;
    wire [REQ_W-1:0] recv_k_idx;
    wire request_needs_act;
    wire act_side_done;
    wire feed_uses_cache;
    wire drain_active;
    wire final_post_valid;

    wire [GROUP_W-1:0] pe_mac_group [0:ROWS-1][0:OC_LANES-1];
    wire pe_mac_valid [0:ROWS-1][0:OC_LANES-1];
    wire pe_mac_first [0:ROWS-1][0:OC_LANES-1];
    wire pe_mac_last [0:ROWS-1][0:OC_LANES-1];
    wire [6:0] pe_oc_index [0:ROWS-1][0:OC_LANES-1];
    wire signed [DATA_W-1:0] raw_a [0:ROWS-1];
    wire signed [DATA_W-1:0] raw_w [0:OC_LANES-1];
    wire signed [DATA_W-1:0] a_left [0:ROWS-1];
    wire signed [DATA_W-1:0] w_top [0:OC_LANES-1];

    wire signed [DATA_W-1:0] a_bus [0:ROWS-1][0:OC_LANES];
    wire signed [DATA_W-1:0] w_bus [0:ROWS][0:OC_LANES-1];
    wire pe_post_valid [0:ROWS-1][0:OC_LANES-1];
    wire signed [DATA_W-1:0] post_bus [0:ROWS-1][0:OC_LANES-1];

    wire request_pending;
    wire weight_req_fire;
    wire act_req_fire;
    wire request_pair_done;
    wire can_accept_resp;
    wire weight_vec_fire;
    wire act_vec_fire;
    wire weight_avail;
    wire act_avail;
    wire feed_valid;
    wire mac_step_en;
    wire pe_clear;
    wire bn_write_en;
    wire input_tile_req_fire;
    wire signed [OC_LANES*DATA_W-1:0] feed_weight_vec;
    wire signed [ROWS*DATA_W-1:0] feed_act_vec;

    integer i;
    integer j;
    integer s;
    integer g;

    assign req_group = req_count / PW2_IC;
    assign req_k_idx = req_count % PW2_IC;
    assign recv_group = recv_count / PW2_IC;
    assign recv_k_idx = recv_count % PW2_IC;

    assign request_pending = (state == STATE_RUN) && (req_count < TOTAL_MACS);
    assign request_needs_act = (req_count < PW2_IC);

    assign weight_req_valid = request_pending && !weight_req_sent;
    assign weight_req_oc_base = req_group * OC_LANES;
    assign weight_req_k = req_k_idx[6:0];

    assign act_req_valid = request_pending
        && request_needs_act
        && !act_req_sent;
    assign act_req_t_base = tile_t_base_reg;
    assign act_req_k = req_k_idx[6:0];
    assign act_req_row_valid_mask = row_valid_mask_reg;

    assign weight_req_fire = weight_req_valid && weight_req_ready;
    assign act_req_fire = act_req_valid && act_req_ready;
    assign act_side_done = !request_needs_act || act_req_sent || act_req_fire;
    assign request_pair_done = request_pending
        && (weight_req_sent || weight_req_fire)
        && act_side_done;

    assign can_accept_resp = (state == STATE_RUN) && (recv_count < TOTAL_MACS);
    assign feed_uses_cache = (recv_group != {GROUP_W{1'b0}});
    assign weight_vec_ready = can_accept_resp && !weight_hold_valid;
    assign act_vec_ready = (state == STATE_RUN)
        && (recv_count < PW2_IC)
        && !act_hold_valid;
    assign weight_vec_fire = weight_vec_valid && weight_vec_ready;
    assign act_vec_fire = act_vec_valid && act_vec_ready;
    assign weight_avail = weight_hold_valid || weight_vec_fire;
    assign act_avail = feed_uses_cache
        ? act_cache_valid
        : (act_hold_valid || act_vec_fire);
    assign feed_valid = can_accept_resp && weight_avail && act_avail;
    assign drain_active = (state == STATE_RUN)
        && (recv_count == TOTAL_MACS)
        && (drain_count < FLUSH_CYCLES);
    assign mac_step_en = feed_valid || drain_active;

    assign feed_weight_vec = weight_hold_valid ? weight_hold_data : weight_vec;
    assign feed_act_vec = feed_uses_cache
        ? act_cache[recv_k_idx]
        : (act_hold_valid ? act_hold_data : act_vec);

    assign input_tile_req_valid = ((state == STATE_IDLE) && start)
        || (state == STATE_WAIT);
    assign input_tile_req_t_base = ((state == STATE_IDLE) && start)
        ? tile_t_base
        : tile_t_base_reg;
    assign input_tile_req_row_valid_mask = ((state == STATE_IDLE) && start)
        ? row_valid_mask
        : row_valid_mask_reg;
    assign input_tile_req_fire = input_tile_req_valid && input_tile_req_ready;

    assign pe_clear = input_tile_req_fire;
    assign bn_write_en = (state == STATE_IDLE) && !start;
    assign final_post_valid =
        pe_post_valid[ROWS-1][OC_LANES-1]
        && (post_group_reg[ROWS-1][OC_LANES-1] == (OC_GROUPS - 1));

    genvar gs;
    generate
        for (gs = 0; gs < PW2_OC; gs = gs + 1) begin : GEN_GAP_SUM_VEC
            assign gap_sum_vec[gs*ACC_W +: ACC_W] = gap_sum_mem[gs];
        end
    endgenerate

    function [8:0] valid_row_count;
        input [ROWS-1:0] mask;
        integer idx;
        begin
            valid_row_count = 9'd0;
            for (idx = 0; idx < ROWS; idx = idx + 1) begin
                if (mask[idx]) begin
                    valid_row_count = valid_row_count + 9'd1;
                end
            end
        end
    endfunction

    genvar gc;
    generate
        for (gc = 0; gc < OC_LANES; gc = gc + 1) begin : GEN_W_BOUNDARY
            assign raw_w[gc] = feed_valid
                ? feed_weight_vec[gc*DATA_W +: DATA_W]
                : {DATA_W{1'b0}};
            assign w_top[gc] = (gc == 0) ? raw_w[gc] : w_delay[gc][gc-1];
            assign w_bus[0][gc] = w_top[gc];
        end
    endgenerate

    genvar gr;
    generate
        for (gr = 0; gr < ROWS; gr = gr + 1) begin : GEN_A_LEFT
            assign raw_a[gr] = (feed_valid && row_valid_mask_reg[gr])
                ? feed_act_vec[gr*DATA_W +: DATA_W]
                : {DATA_W{1'b0}};
            assign a_left[gr] = (gr == 0) ? raw_a[gr] : a_delay[gr][gr-1];
            assign a_bus[gr][0] = a_left[gr];
        end
    endgenerate

    genvar pr;
    genvar pc;
    generate
        for (pr = 0; pr < ROWS; pr = pr + 1) begin : GEN_PE_ROW
            for (pc = 0; pc < OC_LANES; pc = pc + 1) begin : GEN_PE_COL
                if ((pr + pc) == 0) begin : GEN_META_DIRECT
                    assign pe_mac_valid[pr][pc] = feed_valid;
                    assign pe_mac_first[pr][pc] =
                        feed_valid && (recv_k_idx == {REQ_W{1'b0}});
                    assign pe_mac_last[pr][pc] =
                        feed_valid && (recv_k_idx == (PW2_IC - 1));
                    assign pe_mac_group[pr][pc] = recv_group;
                end else begin : GEN_META_DELAYED
                    assign pe_mac_valid[pr][pc] = meta_valid_d[pr+pc-1];
                    assign pe_mac_first[pr][pc] = meta_first_d[pr+pc-1];
                    assign pe_mac_last[pr][pc] = meta_last_d[pr+pc-1];
                    assign pe_mac_group[pr][pc] = meta_group_d[pr+pc-1];
                end
                assign pe_oc_index[pr][pc] =
                    (pe_mac_group[pr][pc] * OC_LANES) + pc[6:0];

                pw_conv2_systolic_pe #(
                    .DATA_W(DATA_W),
                    .MULT_W(MULT_W),
                    .ACC_W(ACC_W),
                    .FRAC_BITS(FRAC_BITS)
                ) u_pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .clear(pe_clear),
                    .mac_en(mac_step_en),
                    .mac_valid(pe_mac_valid[pr][pc]),
                    .mac_first(pe_mac_first[pr][pc]),
                    .mac_last(pe_mac_last[pr][pc]),
                    .a_in(a_bus[pr][pc]),
                    .w_in(w_bus[pr][pc]),
                    .bias_int32(bias_int32_mem[pe_oc_index[pr][pc]]),
                    .multiplier_q15(multiplier_q15_mem[pe_oc_index[pr][pc]]),
                    .right_shift(right_shift_mem[pe_oc_index[pr][pc]]),
                    .a_out(a_bus[pr][pc+1]),
                    .w_out(w_bus[pr+1][pc]),
                    .post_valid(pe_post_valid[pr][pc]),
                    .post_out(post_bus[pr][pc])
                );
            end
        end
    endgenerate

    always @(posedge clk) begin
        if (bn_write_en && w_fold_we) begin
            multiplier_q15_mem[w_fold_oc] <= w_fold_wdata;
        end
        if (bn_write_en && bias_fold_we) begin
            bias_int32_mem[bias_fold_oc] <= bias_fold_wdata;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_hold_valid <= 1'b0;
            weight_hold_data <= {(OC_LANES*DATA_W){1'b0}};
            act_hold_valid <= 1'b0;
            act_hold_data <= {(ROWS*DATA_W){1'b0}};
        end else if (pe_clear || (state != STATE_RUN)) begin
            weight_hold_valid <= 1'b0;
            weight_hold_data <= {(OC_LANES*DATA_W){1'b0}};
            act_hold_valid <= 1'b0;
            act_hold_data <= {(ROWS*DATA_W){1'b0}};
        end else if (feed_valid) begin
            weight_hold_valid <= 1'b0;
            weight_hold_data <= {(OC_LANES*DATA_W){1'b0}};
            act_hold_valid <= 1'b0;
            act_hold_data <= {(ROWS*DATA_W){1'b0}};
        end else begin
            if (weight_vec_fire) begin
                weight_hold_valid <= 1'b1;
                weight_hold_data <= weight_vec;
            end
            if (act_vec_fire) begin
                act_hold_valid <= 1'b1;
                act_hold_data <= act_vec;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_cache_valid <= 1'b0;
        end else if (pe_clear) begin
            act_cache_valid <= 1'b0;
        end else if (feed_valid && (recv_group == {GROUP_W{1'b0}})) begin
            act_cache[recv_k_idx] <= feed_act_vec;
            if (recv_k_idx == (PW2_IC - 1)) begin
                act_cache_valid <= 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ROWS; i = i + 1) begin
                for (s = 0; s < ROWS; s = s + 1) begin
                    a_delay[i][s] <= {DATA_W{1'b0}};
                end
            end
            for (j = 0; j < OC_LANES; j = j + 1) begin
                for (s = 0; s < OC_LANES; s = s + 1) begin
                    w_delay[j][s] <= {DATA_W{1'b0}};
                end
            end
            for (s = 0; s < META_STAGES; s = s + 1) begin
                meta_valid_d[s] <= 1'b0;
                meta_first_d[s] <= 1'b0;
                meta_last_d[s] <= 1'b0;
                meta_group_d[s] <= {GROUP_W{1'b0}};
            end
        end else if (pe_clear) begin
            for (i = 0; i < ROWS; i = i + 1) begin
                for (s = 0; s < ROWS; s = s + 1) begin
                    a_delay[i][s] <= {DATA_W{1'b0}};
                end
            end
            for (j = 0; j < OC_LANES; j = j + 1) begin
                for (s = 0; s < OC_LANES; s = s + 1) begin
                    w_delay[j][s] <= {DATA_W{1'b0}};
                end
            end
            for (s = 0; s < META_STAGES; s = s + 1) begin
                meta_valid_d[s] <= 1'b0;
                meta_first_d[s] <= 1'b0;
                meta_last_d[s] <= 1'b0;
                meta_group_d[s] <= {GROUP_W{1'b0}};
            end
        end else if (mac_step_en) begin
            for (i = 0; i < ROWS; i = i + 1) begin
                a_delay[i][0] <= raw_a[i];
                for (s = 1; s < ROWS; s = s + 1) begin
                    a_delay[i][s] <= a_delay[i][s-1];
                end
            end
            for (j = 0; j < OC_LANES; j = j + 1) begin
                w_delay[j][0] <= raw_w[j];
                for (s = 1; s < OC_LANES; s = s + 1) begin
                    w_delay[j][s] <= w_delay[j][s-1];
                end
            end

            meta_valid_d[0] <= feed_valid;
            meta_first_d[0] <= feed_valid && (recv_k_idx == {REQ_W{1'b0}});
            meta_last_d[0] <= feed_valid && (recv_k_idx == (PW2_IC - 1));
            meta_group_d[0] <= recv_group;
            for (s = 1; s < META_STAGES; s = s + 1) begin
                meta_valid_d[s] <= meta_valid_d[s-1];
                meta_first_d[s] <= meta_first_d[s-1];
                meta_last_d[s] <= meta_last_d[s-1];
                meta_group_d[s] <= meta_group_d[s-1];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            tile_t_base_reg <= {TIME_W{1'b0}};
            row_valid_mask_reg <= {ROWS{1'b0}};
            req_count <= {TOTAL_W{1'b0}};
            recv_count <= {TOTAL_W{1'b0}};
            drain_count <= {DRAIN_W{1'b0}};
            weight_req_sent <= 1'b0;
            act_req_sent <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
            gap_frame_done <= 1'b0;
            gap_count <= 9'd0;
            for (g = 0; g < PW2_OC; g = g + 1) begin
                gap_sum_mem[g] <= {ACC_W{1'b0}};
            end
            for (i = 0; i < ROWS; i = i + 1) begin
                for (j = 0; j < OC_LANES; j = j + 1) begin
                    post_group_reg[i][j] <= {GROUP_W{1'b0}};
                end
            end
        end else if (gap_clear) begin
            state <= STATE_IDLE;
            tile_t_base_reg <= {TIME_W{1'b0}};
            row_valid_mask_reg <= {ROWS{1'b0}};
            req_count <= {TOTAL_W{1'b0}};
            recv_count <= {TOTAL_W{1'b0}};
            drain_count <= {DRAIN_W{1'b0}};
            weight_req_sent <= 1'b0;
            act_req_sent <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
            gap_frame_done <= 1'b0;
            gap_count <= 9'd0;
            for (g = 0; g < PW2_OC; g = g + 1) begin
                gap_sum_mem[g] <= {ACC_W{1'b0}};
            end
            for (i = 0; i < ROWS; i = i + 1) begin
                for (j = 0; j < OC_LANES; j = j + 1) begin
                    post_group_reg[i][j] <= {GROUP_W{1'b0}};
                end
            end
        end else begin
            done <= 1'b0;

            for (i = 0; i < ROWS; i = i + 1) begin
                for (j = 0; j < OC_LANES; j = j + 1) begin
                    if (mac_step_en
                        && pe_mac_valid[i][j]
                        && pe_mac_last[i][j]) begin
                        post_group_reg[i][j] <= pe_mac_group[i][j];
                    end

                    if (pe_post_valid[i][j] && row_valid_mask_reg[i]) begin
                        gap_sum_mem[(post_group_reg[i][j] * OC_LANES) + j]
                            <= gap_sum_mem[(post_group_reg[i][j] * OC_LANES) + j]
                            + $signed({{(ACC_W-DATA_W){post_bus[i][j][DATA_W-1]}},
                                post_bus[i][j]});
                    end
                end
            end

            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    gap_frame_done <= 1'b0;
                    req_count <= {TOTAL_W{1'b0}};
                    recv_count <= {TOTAL_W{1'b0}};
                    drain_count <= {DRAIN_W{1'b0}};
                    weight_req_sent <= 1'b0;
                    act_req_sent <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        tile_t_base_reg <= tile_t_base;
                        row_valid_mask_reg <= row_valid_mask;
                        state <= input_tile_req_ready ? STATE_RUN : STATE_WAIT;
                    end
                end

                STATE_WAIT: begin
                    busy <= 1'b1;
                    if (input_tile_req_ready) begin
                        state <= STATE_RUN;
                    end
                end

                STATE_RUN: begin
                    busy <= 1'b1;

                    if (request_pair_done) begin
                        req_count <= req_count + 1'b1;
                        weight_req_sent <= 1'b0;
                        act_req_sent <= 1'b0;
                    end else begin
                        if (weight_req_fire) begin
                            weight_req_sent <= 1'b1;
                        end
                        if (act_req_fire) begin
                            act_req_sent <= 1'b1;
                        end
                    end

                    if (feed_valid) begin
                        recv_count <= recv_count + 1'b1;
                    end else if (drain_active) begin
                        drain_count <= drain_count + 1'b1;
                    end

                    if (final_post_valid) begin
                        gap_count <= gap_count + valid_row_count(row_valid_mask_reg);
                        gap_frame_done <= (
                            gap_count + valid_row_count(row_valid_mask_reg)
                        ) == GAP_TARGET;
                        done <= 1'b1;
                        busy <= 1'b0;
                        state <= STATE_IDLE;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                    busy <= 1'b0;
                end
            endcase
        end
    end

endmodule

module pw_conv2_systolic_pe #(
    parameter integer DATA_W    =  8,
    parameter integer MULT_W    = 16,
    parameter integer ACC_W     = 48,
    parameter integer FRAC_BITS = 8
) (
    input  wire clk,
    input  wire rst_n,
    input  wire clear,
    input  wire mac_en,
    input  wire mac_valid,
    input  wire mac_first,
    input  wire mac_last,

    input  wire signed [DATA_W-1:0] a_in,
    input  wire signed [DATA_W-1:0] w_in,
    input  wire signed [31:0] bias_int32,
    input  wire signed [MULT_W-1:0] multiplier_q15,
    input  wire [7:0] right_shift,

    output reg signed [DATA_W-1:0] a_out,
    output reg signed [DATA_W-1:0] w_out,
    output reg post_valid,
    output reg signed [DATA_W-1:0] post_out
);

    reg signed [ACC_W-1:0] acc;

    (* use_dsp = "yes" *) wire signed [31:0] mac_mul_p;
    wire signed [ACC_W-1:0] mac_product_ext;
    wire signed [ACC_W-1:0] acc_next;
    reg signed [ACC_W-1:0] acc_with_bias;

    assign mac_mul_p = $signed(a_in) * $signed(w_in);
    assign mac_product_ext = $signed({{(ACC_W-32){mac_mul_p[31]}}, mac_mul_p});
    assign acc_next = mac_first ? mac_product_ext : (acc + mac_product_ext);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= {ACC_W{1'b0}};
            acc_with_bias <= {ACC_W{1'b0}};
            a_out <= {DATA_W{1'b0}};
            w_out <= {DATA_W{1'b0}};
            post_valid <= 1'b0;
            post_out <= {DATA_W{1'b0}};
        end else if (clear) begin
            acc <= {ACC_W{1'b0}};
            acc_with_bias <= {ACC_W{1'b0}};
            a_out <= {DATA_W{1'b0}};
            w_out <= {DATA_W{1'b0}};
            post_valid <= 1'b0;
            post_out <= {DATA_W{1'b0}};
        end else begin
            post_valid <= 1'b0;

            if (mac_en) begin
                a_out <= a_in;
                w_out <= w_in;
                if (mac_valid) begin
                    acc <= acc_next;
                    if (mac_last) begin
                        acc_with_bias = acc_next + $signed({
                            {(ACC_W-32){bias_int32[31]}},
                            bias_int32
                        });
                        post_out <= relu_int8(
                            saturate_int8(
                                requant_q15(acc_with_bias, multiplier_q15, right_shift)
                            )
                        );
                        post_valid <= 1'b1;
                    end
                end
            end
        end
    end

    function signed [DATA_W-1:0] saturate_int8;
        input signed [ACC_W-1:0] value;
        begin
            if (value > 127) begin
                saturate_int8 = 8'sh7F;
            end else if (value < -127) begin
                saturate_int8 = -8'sd127;
            end else begin
                saturate_int8 = value[DATA_W-1:0];
            end
        end
    endfunction

    function signed [ACC_W-1:0] requant_q15;
        input signed [ACC_W-1:0] value;
        input signed [MULT_W-1:0] multiplier;
        input [7:0] shift;
        reg signed [63:0] product;
        reg [63:0] magnitude;
        reg [63:0] rounded_mag;
        reg [63:0] round_offset;
        reg signed [63:0] rounded;
        begin
            product = $signed(value) * $signed(multiplier);
            magnitude = product[63] ? (~product + 64'd1) : product;
            round_offset = (shift == 0) ? 64'd0 : (64'd1 << (shift - 1));
            rounded_mag = (magnitude + round_offset) >> shift;
            rounded = product[63] ? -$signed(rounded_mag) : $signed(rounded_mag);
            requant_q15 = rounded[ACC_W-1:0];
        end
    endfunction

    function signed [DATA_W-1:0] relu_int8;
        input signed [DATA_W-1:0] value;
        begin
            relu_int8 = value[DATA_W-1] ? {DATA_W{1'b0}} : value;
        end
    endfunction

endmodule
