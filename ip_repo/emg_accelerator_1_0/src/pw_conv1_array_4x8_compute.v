`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

// LightCNN1D PW1 pointwise Conv1d 4x8 output-stationary systolic tile.
//
// One start pulse computes all PW1 output-channel groups for four
// high-resolution DW1 rows:
//   input:  4 high-resolution rows x 32 channels
//   output: 2 pooled low-resolution rows x 64 channels
//
// The 4x8 systolic array is fed continuously for all eight output-channel
// groups. A global input stream of 256 vectors is interpreted as:
//   global_idx = oc_group * 32 + k
//   oc_base    = oc_group * 8
//   k          = 0..31
//
// Per-PE valid/first/last/group metadata is delayed by row+column to match the
// activation/weight skew through the systolic array. Each PE clears its local
// accumulator on k=0 and launches its independent BN/ReLU pipeline on k=31.
// MaxPool is collected from the PE post_valid wavefront, so the array no longer
// pays a 10-cycle drain/post/pool penalty for every oc group.

module pw_conv1_array_4x8_compute #(
    parameter integer DATA_W     =  8,
    parameter integer MULT_W     = 16,
    parameter integer ACC_W      = 48,
    parameter integer ROWS       = 4,
    parameter integer POOL_ROWS  = 2,
    parameter integer OC_LANES   = 8,
    parameter integer PW1_IC     = 32,
    parameter integer PW1_OC     = 64,
    parameter integer FRAC_BITS  = 8,
    parameter integer TIME_W     = 9,
    parameter BIAS_INIT_FILE     = {`PROJECT_ROOT, "/weight_data/pw1/bias_int32.mem"},
    parameter MULT_INIT_FILE     = {`PROJECT_ROOT, "/weight_data/pw1/multiplier_q15.mem"},
    parameter SHIFT_INIT_FILE    = {`PROJECT_ROOT, "/weight_data/pw1/right_shift.mem"}
) (
    input  wire clk,
    input  wire rst_n,

    input  wire start,
    // Retained for interface compatibility; full-channel jobs ignore this input
    // and always sweep oc_base = 0, 8, ..., 56 internally.
    input  wire [5:0] oc_base,
    input  wire [TIME_W-1:0] tile_t_base,

    output wire input_tile_req_valid,
    output wire [TIME_W-1:0] input_tile_req_t_base,
    input  wire input_tile_req_ready,

    output wire weight_req_valid,
    output wire [5:0] weight_req_oc_base,
    output wire [5:0] weight_req_k,
    input  wire weight_req_ready,
    input  wire weight_vec_valid,
    output wire weight_vec_ready,
    input  wire signed [OC_LANES*DATA_W-1:0] weight_vec,

    output wire act_req_valid,
    output wire [TIME_W-1:0] act_req_t_base,
    output wire [5:0] act_req_k,
    input  wire act_req_ready,
    input  wire act_vec_valid,
    output wire act_vec_ready,
    input  wire signed [ROWS*DATA_W-1:0] act_vec,

    input  wire w_fold_we,
    input  wire [5:0] w_fold_oc,
    input  wire signed [MULT_W-1:0] w_fold_wdata,

    input  wire bias_fold_we,
    input  wire [5:0] bias_fold_oc,
    input  wire signed [31:0] bias_fold_wdata,

    input  wire out_ready,
    output reg busy,
    output reg done,
    output reg out_valid,
    output reg [TIME_W-1:0] out_pool_t_base,
    output reg [5:0] out_oc_base,
    output reg out_last_group,
    output reg signed [POOL_ROWS*OC_LANES*DATA_W-1:0] out_tile
);

    localparam integer OC_GROUPS   = PW1_OC / OC_LANES;
    localparam integer TOTAL_MACS  = OC_GROUPS * PW1_IC;
    localparam integer FLUSH_CYCLES = ROWS + OC_LANES - 2;
    localparam integer REQ_W       = (PW1_IC <= 1) ? 1 : $clog2(PW1_IC + 1);
    localparam integer TOTAL_W     = (TOTAL_MACS <= 1) ? 1 : $clog2(TOTAL_MACS + 1);
    localparam integer GROUP_W     = (OC_GROUPS <= 1) ? 1 : $clog2(OC_GROUPS + 1);
    localparam integer DRAIN_W     = (FLUSH_CYCLES <= 1) ? 1 : $clog2(FLUSH_CYCLES + 1);
    localparam integer META_STAGES = FLUSH_CYCLES + 1;
    localparam integer OUT_TILE_W  = POOL_ROWS * OC_LANES * DATA_W;

    localparam [1:0] STATE_IDLE = 2'd0;
    localparam [1:0] STATE_WAIT = 2'd1;
    localparam [1:0] STATE_RUN  = 2'd2;

    reg [1:0] state;
    reg [TIME_W-1:0] tile_t_base_reg;
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
    (* ram_style = "registers" *) reg signed [ROWS*DATA_W-1:0] act_cache [0:PW1_IC-1];

    reg signed [31:0] bias_int32_mem [0:PW1_OC-1];
    reg signed [MULT_W-1:0] multiplier_q15_mem [0:PW1_OC-1];
    reg [7:0] right_shift_mem [0:PW1_OC-1];

    initial begin
        $readmemh(BIAS_INIT_FILE, bias_int32_mem);
        $readmemh(MULT_INIT_FILE, multiplier_q15_mem);
        $readmemh(SHIFT_INIT_FILE, right_shift_mem);
    end

    reg signed [DATA_W-1:0] a_delay [0:ROWS-1][0:ROWS-1];
    reg signed [DATA_W-1:0] w_delay [0:OC_LANES-1][0:OC_LANES-1];

    reg meta_valid_d [0:META_STAGES-1];
    reg meta_first_d [0:META_STAGES-1];
    reg meta_last_d [0:META_STAGES-1];
    reg [GROUP_W-1:0] meta_group_d [0:META_STAGES-1];

    reg [GROUP_W-1:0] post_group_reg [0:ROWS-1][0:OC_LANES-1];
    reg signed [DATA_W-1:0] pool_pair_hold [0:OC_GROUPS-1][0:POOL_ROWS-1][0:OC_LANES-1];
    reg pool_pair_valid [0:OC_GROUPS-1][0:POOL_ROWS-1][0:OC_LANES-1];
    reg [OUT_TILE_W-1:0] out_buf_data [0:OC_GROUPS-1];
    reg out_buf_valid [0:OC_GROUPS-1];
    reg [GROUP_W-1:0] emit_group;

    wire [GROUP_W-1:0] req_group;
    wire [REQ_W-1:0] req_k_idx;
    wire [GROUP_W-1:0] recv_group;
    wire [REQ_W-1:0] recv_k_idx;
    wire request_pending;
    wire request_needs_act;
    wire weight_req_fire;
    wire act_req_fire;
    wire act_side_done;
    wire request_pair_done;
    wire can_accept_resp;
    wire feed_uses_cache;
    wire weight_vec_fire;
    wire act_vec_fire;
    wire weight_avail;
    wire act_avail;
    wire feed_valid;
    wire drain_active;
    wire mac_step_en;
    wire input_tile_req_fire;
    wire pe_clear;
    wire out_fire;
    wire [GROUP_W-1:0] emit_group_after_fire;
    wire can_load_out;
    wire signed [OC_LANES*DATA_W-1:0] feed_weight_vec;
    wire signed [ROWS*DATA_W-1:0] feed_act_vec;

    wire signed [DATA_W-1:0] raw_a [0:ROWS-1];
    wire signed [DATA_W-1:0] raw_w [0:OC_LANES-1];
    wire signed [DATA_W-1:0] a_left [0:ROWS-1];
    wire signed [DATA_W-1:0] w_top [0:OC_LANES-1];
    wire signed [DATA_W-1:0] a_bus [0:ROWS-1][0:OC_LANES];
    wire signed [DATA_W-1:0] w_bus [0:ROWS][0:OC_LANES-1];
    wire pe_mac_valid [0:ROWS-1][0:OC_LANES-1];
    wire pe_mac_first [0:ROWS-1][0:OC_LANES-1];
    wire pe_mac_last [0:ROWS-1][0:OC_LANES-1];
    wire [GROUP_W-1:0] pe_mac_group [0:ROWS-1][0:OC_LANES-1];
    wire [5:0] pe_oc_index [0:ROWS-1][0:OC_LANES-1];
    wire pe_post_valid [0:ROWS-1][0:OC_LANES-1];
    wire signed [DATA_W-1:0] pe_post_out [0:ROWS-1][0:OC_LANES-1];

    integer i;
    integer j;
    integer s;
    integer g;
    integer pool_r;
    integer pool_c;
    integer pool_g;
    integer pool_pair_idx;
    integer act_cache_i;
    reg signed [DATA_W-1:0] pooled_sample;

    assign req_group = req_count / PW1_IC;
    assign req_k_idx = req_count % PW1_IC;
    assign recv_group = recv_count / PW1_IC;
    assign recv_k_idx = recv_count % PW1_IC;

    assign request_pending = (state == STATE_RUN) && (req_count < TOTAL_MACS);
    assign request_needs_act = (req_count < PW1_IC);

    assign weight_req_valid = request_pending && !weight_req_sent;
    assign weight_req_oc_base = req_group * OC_LANES;
    assign weight_req_k = req_k_idx[5:0];

    assign act_req_valid = request_pending
        && request_needs_act
        && !act_req_sent;
    assign act_req_t_base = tile_t_base_reg;
    assign act_req_k = req_k_idx[5:0];

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
        && (recv_count < PW1_IC)
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
    assign input_tile_req_fire = input_tile_req_valid && input_tile_req_ready;
    assign pe_clear = input_tile_req_fire;

    assign out_fire = out_valid && out_ready;
    assign emit_group_after_fire = (out_fire && !out_last_group)
        ? (emit_group + 1'b1)
        : emit_group;
    assign can_load_out = (state == STATE_RUN)
        && (!out_valid || out_fire)
        && !(out_fire && out_last_group);

    assign raw_a[0] = feed_valid ? feed_act_vec[0*DATA_W +: DATA_W] : {DATA_W{1'b0}};
    assign raw_a[1] = feed_valid ? feed_act_vec[1*DATA_W +: DATA_W] : {DATA_W{1'b0}};
    assign raw_a[2] = feed_valid ? feed_act_vec[2*DATA_W +: DATA_W] : {DATA_W{1'b0}};
    assign raw_a[3] = feed_valid ? feed_act_vec[3*DATA_W +: DATA_W] : {DATA_W{1'b0}};

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
        for (gr = 0; gr < ROWS; gr = gr + 1) begin : GEN_A_BOUNDARY
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
                        feed_valid && (recv_k_idx == (PW1_IC - 1));
                    assign pe_mac_group[pr][pc] = recv_group;
                end else begin : GEN_META_DELAYED
                    assign pe_mac_valid[pr][pc] = meta_valid_d[pr+pc-1];
                    assign pe_mac_first[pr][pc] = meta_first_d[pr+pc-1];
                    assign pe_mac_last[pr][pc] = meta_last_d[pr+pc-1];
                    assign pe_mac_group[pr][pc] = meta_group_d[pr+pc-1];
                end
                assign pe_oc_index[pr][pc] =
                    (pe_mac_group[pr][pc] * OC_LANES) + pc[5:0];

                pw_conv1_systolic_pe #(
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
                    .post_out(pe_post_out[pr][pc])
                );
            end
        end
    endgenerate

    always @(posedge clk) begin
        if ((state == STATE_IDLE) && !start) begin
            if (w_fold_we) begin
                multiplier_q15_mem[w_fold_oc] <= w_fold_wdata;
            end
            if (bias_fold_we) begin
                bias_int32_mem[bias_fold_oc] <= bias_fold_wdata;
            end
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
        end else begin
            if (feed_valid
                && (recv_group == {GROUP_W{1'b0}})
                && (recv_k_idx == (PW1_IC - 1))) begin
                act_cache_valid <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (feed_valid && (recv_group == {GROUP_W{1'b0}})) begin
            for (act_cache_i = 0;
                 act_cache_i < PW1_IC;
                 act_cache_i = act_cache_i + 1) begin
                if (recv_k_idx == act_cache_i) begin
                    act_cache[act_cache_i] <= feed_act_vec;
                end
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
            meta_last_d[0] <= feed_valid && (recv_k_idx == (PW1_IC - 1));
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
            req_count <= {TOTAL_W{1'b0}};
            recv_count <= {TOTAL_W{1'b0}};
            drain_count <= {DRAIN_W{1'b0}};
            weight_req_sent <= 1'b0;
            act_req_sent <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
            out_valid <= 1'b0;
            out_pool_t_base <= {TIME_W{1'b0}};
            out_oc_base <= 6'd0;
            out_last_group <= 1'b0;
            out_tile <= {OUT_TILE_W{1'b0}};
            emit_group <= {GROUP_W{1'b0}};
            for (g = 0; g < OC_GROUPS; g = g + 1) begin
                out_buf_valid[g] <= 1'b0;
                out_buf_data[g] <= {OUT_TILE_W{1'b0}};
                for (i = 0; i < POOL_ROWS; i = i + 1) begin
                    for (j = 0; j < OC_LANES; j = j + 1) begin
                        pool_pair_hold[g][i][j] <= {DATA_W{1'b0}};
                        pool_pair_valid[g][i][j] <= 1'b0;
                    end
                end
            end
            for (i = 0; i < ROWS; i = i + 1) begin
                for (j = 0; j < OC_LANES; j = j + 1) begin
                    post_group_reg[i][j] <= {GROUP_W{1'b0}};
                end
            end
        end else begin
            done <= 1'b0;

            for (pool_r = 0; pool_r < ROWS; pool_r = pool_r + 1) begin
                for (pool_c = 0; pool_c < OC_LANES; pool_c = pool_c + 1) begin
                    if (mac_step_en
                        && pe_mac_valid[pool_r][pool_c]
                        && pe_mac_last[pool_r][pool_c]) begin
                        post_group_reg[pool_r][pool_c] <= pe_mac_group[pool_r][pool_c];
                    end

                    if (pe_post_valid[pool_r][pool_c]) begin
                        pool_g = post_group_reg[pool_r][pool_c];
                        pool_pair_idx = pool_r / 2;
                        if (!pool_pair_valid[pool_g][pool_pair_idx][pool_c]) begin
                            pool_pair_hold[pool_g][pool_pair_idx][pool_c]
                                <= pe_post_out[pool_r][pool_c];
                            pool_pair_valid[pool_g][pool_pair_idx][pool_c]
                                <= 1'b1;
                        end else begin
                            pooled_sample = signed_max(
                                pool_pair_hold[pool_g][pool_pair_idx][pool_c],
                                pe_post_out[pool_r][pool_c]
                            );
                            out_buf_data[pool_g][
                                (pool_pair_idx*OC_LANES + pool_c)*DATA_W
                                +: DATA_W
                            ] <= pooled_sample;
                            pool_pair_hold[pool_g][pool_pair_idx][pool_c]
                                <= pooled_sample;
                            pool_pair_valid[pool_g][pool_pair_idx][pool_c]
                                <= 1'b0;
                            if ((pool_pair_idx == (POOL_ROWS - 1))
                                && (pool_c == (OC_LANES - 1))) begin
                                out_buf_valid[pool_g] <= 1'b1;
                            end
                        end
                    end
                end
            end

            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    out_valid <= 1'b0;
                    out_last_group <= 1'b0;
                    req_count <= {TOTAL_W{1'b0}};
                    recv_count <= {TOTAL_W{1'b0}};
                    drain_count <= {DRAIN_W{1'b0}};
                    weight_req_sent <= 1'b0;
                    act_req_sent <= 1'b0;
                    emit_group <= {GROUP_W{1'b0}};
                    if (start) begin
                        busy <= 1'b1;
                        tile_t_base_reg <= tile_t_base;
                        for (g = 0; g < OC_GROUPS; g = g + 1) begin
                            out_buf_valid[g] <= 1'b0;
                            for (i = 0; i < POOL_ROWS; i = i + 1) begin
                                for (j = 0; j < OC_LANES; j = j + 1) begin
                                    pool_pair_valid[g][i][j] <= 1'b0;
                                end
                            end
                        end
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

                    if (out_fire) begin
                        out_valid <= 1'b0;
                        if (out_last_group) begin
                            done <= 1'b1;
                            busy <= 1'b0;
                            state <= STATE_IDLE;
                        end else begin
                            emit_group <= emit_group + 1'b1;
                        end
                    end

                    if (can_load_out && out_buf_valid[emit_group_after_fire]) begin
                        out_tile <= out_buf_data[emit_group_after_fire];
                        out_pool_t_base <= tile_t_base_reg >> 1;
                        out_oc_base <= emit_group_after_fire * OC_LANES;
                        out_last_group <= (emit_group_after_fire == (OC_GROUPS - 1));
                        out_valid <= 1'b1;
                        out_buf_valid[emit_group_after_fire] <= 1'b0;
                        emit_group <= emit_group_after_fire;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                    busy <= 1'b0;
                    out_valid <= 1'b0;
                end
            endcase
        end
    end

    function signed [DATA_W-1:0] signed_max;
        input signed [DATA_W-1:0] a;
        input signed [DATA_W-1:0] b;
        begin
            signed_max = (a >= b) ? a : b;
        end
    endfunction

endmodule

module pw_conv1_systolic_pe #(
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
    reg post_stage0_valid;
    reg signed [ACC_W-1:0] post_stage0_acc;
    reg signed [MULT_W-1:0] post_stage0_multiplier;
    reg [7:0] post_stage0_shift;
    reg post_stage1_valid;
    reg signed [63:0] post_stage1_product;
    reg [7:0] post_stage1_shift;

    assign mac_mul_p = $signed(a_in) * $signed(w_in);
    assign mac_product_ext = $signed({{(ACC_W-32){mac_mul_p[31]}}, mac_mul_p});
    assign acc_next = mac_first ? mac_product_ext : (acc + mac_product_ext);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= {ACC_W{1'b0}};
            a_out <= {DATA_W{1'b0}};
            w_out <= {DATA_W{1'b0}};
            post_valid <= 1'b0;
            post_out <= {DATA_W{1'b0}};
            post_stage0_valid <= 1'b0;
            post_stage0_acc <= {ACC_W{1'b0}};
            post_stage0_multiplier <= {MULT_W{1'b0}};
            post_stage0_shift <= 8'd0;
            post_stage1_valid <= 1'b0;
            post_stage1_product <= 64'sd0;
            post_stage1_shift <= 8'd0;
        end else if (clear) begin
            acc <= {ACC_W{1'b0}};
            a_out <= {DATA_W{1'b0}};
            w_out <= {DATA_W{1'b0}};
            post_valid <= 1'b0;
            post_out <= {DATA_W{1'b0}};
            post_stage0_valid <= 1'b0;
            post_stage0_acc <= {ACC_W{1'b0}};
            post_stage0_multiplier <= {MULT_W{1'b0}};
            post_stage0_shift <= 8'd0;
            post_stage1_valid <= 1'b0;
            post_stage1_product <= 64'sd0;
            post_stage1_shift <= 8'd0;
        end else begin
            post_valid <= 1'b0;
            post_stage0_valid <= 1'b0;
            post_stage1_valid <= post_stage0_valid;

            if (post_stage0_valid) begin
                post_stage1_product
                    <= $signed(post_stage0_acc) * $signed(post_stage0_multiplier);
                post_stage1_shift <= post_stage0_shift;
            end

            if (post_stage1_valid) begin
                post_out <= relu_int8(
                    saturate_int8(
                        requant_product_q15(post_stage1_product, post_stage1_shift)
                    )
                );
                post_valid <= 1'b1;
            end

            if (mac_en) begin
                a_out <= a_in;
                w_out <= w_in;
                if (mac_valid) begin
                    acc <= acc_next;
                    if (mac_last) begin
                        post_stage0_acc <= acc_next + $signed({
                            {(ACC_W-32){bias_int32[31]}},
                            bias_int32
                        });
                        post_stage0_multiplier <= multiplier_q15;
                        post_stage0_shift <= right_shift;
                        post_stage0_valid <= 1'b1;
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

    function signed [ACC_W-1:0] requant_product_q15;
        input signed [63:0] product;
        input [7:0] shift;
        reg [63:0] magnitude;
        reg [63:0] rounded_mag;
        reg [63:0] round_offset;
        reg signed [63:0] rounded;
        begin
            magnitude = product[63] ? (~product + 64'd1) : product;
            round_offset = (shift == 0) ? 64'd0 : (64'd1 << (shift - 1));
            rounded_mag = (magnitude + round_offset) >> shift;
            rounded = product[63] ? -$signed(rounded_mag) : $signed(rounded_mag);
            requant_product_q15 = rounded[ACC_W-1:0];
        end
    endfunction

    function signed [DATA_W-1:0] relu_int8;
        input signed [DATA_W-1:0] value;
        begin
            relu_int8 = value[DATA_W-1] ? {DATA_W{1'b0}} : value;
        end
    endfunction

endmodule
