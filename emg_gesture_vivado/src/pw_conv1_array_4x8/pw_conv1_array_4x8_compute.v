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
// The 4x8 array is reused internally for all eight output-channel groups:
//   oc_base = 0, 8, 16, ..., 56
// For each group the module emits one pooled output tile:
//   out_pool_t_base = tile_t_base / 2
//   out_oc_base     = oc_base
//   out_tile[(pool_row*OC_LANES + col)*DATA_W +: DATA_W]
//
// The module requests a precise input tile before issuing activation requests.
// input_tile_req_ready must mean the upstream dw1_to_pw1 row packer has four
// consecutive high-resolution rows, input_tile_req_t_base..+3, with all 32
// channels valid and can keep them stable for this PW1 job.
//
// The row packer should implement the readiness rule:
//   row_full[t] = &valid_group[t][7:0]
//   input_tile_req_ready = row_full[input_tile_req_t_base]
//                       && row_full[input_tile_req_t_base+1]
//                       && row_full[input_tile_req_t_base+2]
//                       && row_full[input_tile_req_t_base+3]
// For the baseline scheduler, tile_t_base must be a multiple of 4 and the
// downstream pool rows are:
//   pool_t_base = tile_t_base / 2
//
// Runtime activation and weight access are both request/response streams:
//   act_vec    = {A[tile_t_base+3][k], ..., A[tile_t_base+0][k]}
//   weight_vec = {W[oc_base+7][k], ..., W[oc_base+0][k]}
// Requests for the same k may be accepted in different cycles. req_k advances
// only after both request sides have accepted that k. Response streams must
// return exactly one vector per accepted request, in request order.
//
// Folded BN parameters are kept locally:
//   w_fold_mem[64], bias_fold_mem[64]
//
// Fused compute order:
//   PW1 conv -> folded BN -> ReLU -> MaxPool1d(kernel=2,stride=2)
// MaxPool is registered in a separate STATE_POOL cycle. The output tile has two
// low-resolution rows x eight output channels:
//   out_tile[(pool_row*OC_LANES + col)*DATA_W +: DATA_W]
//
// The output side uses valid/ready. out_valid remains asserted until the
// downstream pool_to_dw2 writer accepts the tile with out_valid && out_ready.
// done pulses only after the final oc_base=56 tile is accepted.

module pw_conv1_array_4x8_compute #(
    parameter integer DATA_W     = 16,
    parameter integer ACC_W      = 48,
    parameter integer ROWS       = 4,
    parameter integer POOL_ROWS  = 2,
    parameter integer OC_LANES   = 8,
    parameter integer PW1_IC     = 32,
    parameter integer PW1_OC     = 64,
    parameter integer FRAC_BITS  = 8,
    parameter integer TIME_W     = 9,
    parameter BN_SCALE_INIT_FILE = {`PROJECT_ROOT, "/weight_data/pw1/bn_scale.mem"},
    parameter BN_BIAS_INIT_FILE  = {`PROJECT_ROOT, "/weight_data/pw1/bn_bias.mem"}
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
    input  wire signed [DATA_W-1:0] w_fold_wdata,

    input  wire bias_fold_we,
    input  wire [5:0] bias_fold_oc,
    input  wire signed [DATA_W-1:0] bias_fold_wdata,

    input  wire out_ready,
    output reg busy,
    output reg done,
    output reg out_valid,
    output reg [TIME_W-1:0] out_pool_t_base,
    output reg [5:0] out_oc_base,
    output reg out_last_group,
    output reg signed [POOL_ROWS*OC_LANES*DATA_W-1:0] out_tile
);

    localparam integer FLUSH_CYCLES = ROWS + OC_LANES - 2;
    localparam integer REQ_W        = (PW1_IC <= 1) ? 1 : $clog2(PW1_IC + 1);
    localparam integer DRAIN_W      = (FLUSH_CYCLES <= 1) ? 1 : $clog2(FLUSH_CYCLES + 1);

    localparam [2:0] STATE_IDLE  = 3'd0;
    localparam [2:0] STATE_WAIT  = 3'd1;
    localparam [2:0] STATE_MAC   = 3'd2;
    localparam [2:0] STATE_POST0 = 3'd3;
    localparam [2:0] STATE_POST1 = 3'd4;
    localparam [2:0] STATE_POOL  = 3'd5;
    localparam [2:0] STATE_DONE  = 3'd6;
    localparam [2:0] STATE_CLEAR = 3'd7;

    reg [2:0] state;
    reg [5:0] oc_base_reg;
    reg [TIME_W-1:0] tile_t_base_reg;
    reg [REQ_W-1:0] req_k;
    reg [REQ_W-1:0] recv_k;
    reg [DRAIN_W-1:0] drain_count;
    reg weight_req_sent;
    reg act_req_sent;

    reg weight_hold_valid;
    reg signed [OC_LANES*DATA_W-1:0] weight_hold_data;
    reg act_hold_valid;
    reg signed [ROWS*DATA_W-1:0] act_hold_data;

    reg signed [DATA_W-1:0] w_fold_mem [0:PW1_OC-1];
    reg signed [DATA_W-1:0] bias_fold_mem [0:PW1_OC-1];

    initial begin
        $readmemh(BN_SCALE_INIT_FILE, w_fold_mem);
        $readmemh(BN_BIAS_INIT_FILE, bias_fold_mem);
    end

    reg signed [DATA_W-1:0] a_delay [0:ROWS-1][0:ROWS-1];
    reg signed [DATA_W-1:0] w_delay [0:OC_LANES-1][0:OC_LANES-1];
    reg signed [DATA_W-1:0] pool_reg [0:POOL_ROWS-1][0:OC_LANES-1];

    wire [5:0] oc_index [0:OC_LANES-1];
    wire signed [DATA_W-1:0] raw_a [0:ROWS-1];
    wire signed [DATA_W-1:0] raw_w [0:OC_LANES-1];
    wire signed [DATA_W-1:0] a_left [0:ROWS-1];
    wire signed [DATA_W-1:0] w_top [0:OC_LANES-1];

    wire signed [DATA_W-1:0] a_bus [0:ROWS-1][0:OC_LANES];
    wire signed [DATA_W-1:0] w_bus [0:ROWS][0:OC_LANES-1];
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
    wire flush_valid;
    wire mac_step_en;
    wire pe_clear;
    wire pe_mac_en;
    wire pe_post0_en;
    wire pe_post1_en;
    wire bn_write_en;
    wire input_tile_req_fire;
    wire last_oc_group;
    wire signed [OC_LANES*DATA_W-1:0] feed_weight_vec;
    wire signed [ROWS*DATA_W-1:0] feed_act_vec;

    integer i;
    integer j;
    integer s;

    assign request_pending = (state == STATE_MAC) && (req_k < PW1_IC);

    assign weight_req_valid = request_pending && !weight_req_sent;
    assign weight_req_oc_base = oc_base_reg;
    assign weight_req_k = req_k[5:0];

    assign act_req_valid = request_pending && !act_req_sent;
    assign act_req_t_base = tile_t_base_reg;
    assign act_req_k = req_k[5:0];

    assign weight_req_fire = weight_req_valid && weight_req_ready;
    assign act_req_fire = act_req_valid && act_req_ready;
    assign request_pair_done = request_pending
        && (weight_req_sent || weight_req_fire)
        && (act_req_sent || act_req_fire);

    assign can_accept_resp = (state == STATE_MAC) && (recv_k < PW1_IC);
    assign weight_vec_ready = can_accept_resp && !weight_hold_valid;
    assign act_vec_ready = can_accept_resp && !act_hold_valid;
    assign weight_vec_fire = weight_vec_valid && weight_vec_ready;
    assign act_vec_fire = act_vec_valid && act_vec_ready;
    assign weight_avail = weight_hold_valid || weight_vec_fire;
    assign act_avail = act_hold_valid || act_vec_fire;
    assign feed_valid = can_accept_resp && weight_avail && act_avail;
    assign flush_valid = (state == STATE_MAC) && (recv_k == PW1_IC);
    assign mac_step_en = feed_valid || flush_valid;

    assign feed_weight_vec = weight_hold_valid ? weight_hold_data : weight_vec;
    assign feed_act_vec = act_hold_valid ? act_hold_data : act_vec;

    assign input_tile_req_valid = ((state == STATE_IDLE) && start)
        || (state == STATE_WAIT);
    assign input_tile_req_t_base = ((state == STATE_IDLE) && start)
        ? tile_t_base
        : tile_t_base_reg;
    assign input_tile_req_fire = input_tile_req_valid && input_tile_req_ready;

    assign last_oc_group = (oc_base_reg == (PW1_OC - OC_LANES));

    assign pe_clear = input_tile_req_fire || (state == STATE_CLEAR);
    assign pe_mac_en = mac_step_en;
    assign pe_post0_en = (state == STATE_POST0);
    assign pe_post1_en = (state == STATE_POST1);
    assign bn_write_en = (state == STATE_IDLE) && !start;

    genvar gc;
    generate
        for (gc = 0; gc < OC_LANES; gc = gc + 1) begin : GEN_OC_INDEX
            assign oc_index[gc] = oc_base_reg + gc[5:0];
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
            assign raw_a[gr] = feed_valid
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
                pw_conv1_systolic_pe #(
                    .DATA_W(DATA_W),
                    .ACC_W(ACC_W),
                    .FRAC_BITS(FRAC_BITS)
                ) u_pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .clear(pe_clear),
                    .mac_en(pe_mac_en),
                    .post0_en(pe_post0_en),
                    .post1_en(pe_post1_en),
                    .a_in(a_bus[pr][pc]),
                    .w_in(w_bus[pr][pc]),
                    .bn_scale(w_fold_mem[oc_index[pc]]),
                    .bn_bias(bias_fold_mem[oc_index[pc]]),
                    .a_out(a_bus[pr][pc+1]),
                    .w_out(w_bus[pr+1][pc]),
                    .post_out(post_bus[pr][pc])
                );
            end
        end
    endgenerate

    always @(posedge clk) begin
        if (bn_write_en && w_fold_we) begin
            w_fold_mem[w_fold_oc] <= w_fold_wdata;
        end
        if (bn_write_en && bias_fold_we) begin
            bias_fold_mem[bias_fold_oc] <= bias_fold_wdata;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_hold_valid <= 1'b0;
            weight_hold_data <= {(OC_LANES*DATA_W){1'b0}};
            act_hold_valid <= 1'b0;
            act_hold_data <= {(ROWS*DATA_W){1'b0}};
        end else if (pe_clear || (state != STATE_MAC)) begin
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
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < POOL_ROWS; i = i + 1) begin
                for (j = 0; j < OC_LANES; j = j + 1) begin
                    pool_reg[i][j] <= {DATA_W{1'b0}};
                end
            end
        end else if (state == STATE_POOL) begin
            for (j = 0; j < OC_LANES; j = j + 1) begin
                pool_reg[0][j] <= signed_max(post_bus[0][j], post_bus[1][j]);
                pool_reg[1][j] <= signed_max(post_bus[2][j], post_bus[3][j]);
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            oc_base_reg <= 6'd0;
            tile_t_base_reg <= {TIME_W{1'b0}};
            req_k <= {REQ_W{1'b0}};
            recv_k <= {REQ_W{1'b0}};
            drain_count <= {DRAIN_W{1'b0}};
            weight_req_sent <= 1'b0;
            act_req_sent <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
            out_valid <= 1'b0;
            out_pool_t_base <= {TIME_W{1'b0}};
            out_oc_base <= 6'd0;
            out_last_group <= 1'b0;
            out_tile <= {(POOL_ROWS*OC_LANES*DATA_W){1'b0}};
        end else begin
            done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    out_valid <= 1'b0;
                    out_last_group <= 1'b0;
                    req_k <= {REQ_W{1'b0}};
                    recv_k <= {REQ_W{1'b0}};
                    drain_count <= {DRAIN_W{1'b0}};
                    weight_req_sent <= 1'b0;
                    act_req_sent <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        oc_base_reg <= 6'd0;
                        tile_t_base_reg <= tile_t_base;
                        state <= input_tile_req_ready ? STATE_MAC : STATE_WAIT;
                    end
                end

                STATE_WAIT: begin
                    busy <= 1'b1;
                    if (input_tile_req_ready) begin
                        state <= STATE_MAC;
                    end
                end

                STATE_CLEAR: begin
                    busy <= 1'b1;
                    out_valid <= 1'b0;
                    out_last_group <= 1'b0;
                    req_k <= {REQ_W{1'b0}};
                    recv_k <= {REQ_W{1'b0}};
                    drain_count <= {DRAIN_W{1'b0}};
                    weight_req_sent <= 1'b0;
                    act_req_sent <= 1'b0;
                    state <= STATE_MAC;
                end

                STATE_MAC: begin
                    busy <= 1'b1;
                    if (request_pair_done) begin
                        req_k <= req_k + 1'b1;
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
                        recv_k <= recv_k + 1'b1;
                    end else if (flush_valid) begin
                        if (drain_count == FLUSH_CYCLES-1) begin
                            drain_count <= {DRAIN_W{1'b0}};
                            state <= STATE_POST0;
                        end else begin
                            drain_count <= drain_count + 1'b1;
                        end
                    end
                end

                STATE_POST0: begin
                    state <= STATE_POST1;
                end

                STATE_POST1: begin
                    state <= STATE_POOL;
                end

                STATE_POOL: begin
                    state <= STATE_DONE;
                end

                STATE_DONE: begin
                    busy <= 1'b1;
                    if (!out_valid) begin
                        for (i = 0; i < POOL_ROWS; i = i + 1) begin
                            for (j = 0; j < OC_LANES; j = j + 1) begin
                                out_tile[(i*OC_LANES + j)*DATA_W +: DATA_W]
                                    <= pool_reg[i][j];
                            end
                        end
                        out_pool_t_base <= tile_t_base_reg >> 1;
                        out_oc_base <= oc_base_reg;
                        out_last_group <= last_oc_group;
                        out_valid <= 1'b1;
                    end else if (out_ready) begin
                        out_valid <= 1'b0;
                        if (last_oc_group) begin
                            done <= 1'b1;
                            busy <= 1'b0;
                            state <= STATE_IDLE;
                        end else begin
                            oc_base_reg <= oc_base_reg + OC_LANES[5:0];
                            state <= STATE_CLEAR;
                        end
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
    parameter integer DATA_W    = 16,
    parameter integer ACC_W     = 48,
    parameter integer FRAC_BITS = 8
) (
    input  wire clk,
    input  wire rst_n,
    input  wire clear,
    input  wire mac_en,
    input  wire post0_en,
    input  wire post1_en,

    input  wire signed [DATA_W-1:0] a_in,
    input  wire signed [DATA_W-1:0] w_in,
    input  wire signed [DATA_W-1:0] bn_scale,
    input  wire signed [DATA_W-1:0] bn_bias,

    output reg signed [DATA_W-1:0] a_out,
    output reg signed [DATA_W-1:0] w_out,
    output reg signed [DATA_W-1:0] post_out
);

    reg signed [ACC_W-1:0] acc;
    reg signed [31:0] bn_mul;

    wire signed [DATA_W-1:0] conv_q;
    wire signed [DATA_W-1:0] mul_a;
    wire signed [DATA_W-1:0] mul_b;
    (* use_dsp = "yes" *) wire signed [31:0] mul_p;

    reg signed [31:0] post_shifted;
    reg signed [31:0] post_biased;
    reg signed [DATA_W-1:0] bn_q;

    assign conv_q = sat_q8_8_from_acc_shift(acc);
    assign mul_a = post0_en ? conv_q : a_in;
    assign mul_b = post0_en ? bn_scale : w_in;
    assign mul_p = $signed(mul_a) * $signed(mul_b);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= {ACC_W{1'b0}};
            bn_mul <= 32'sd0;
            post_shifted <= 32'sd0;
            post_biased <= 32'sd0;
            bn_q <= {DATA_W{1'b0}};
            a_out <= {DATA_W{1'b0}};
            w_out <= {DATA_W{1'b0}};
            post_out <= {DATA_W{1'b0}};
        end else if (clear) begin
            acc <= {ACC_W{1'b0}};
            bn_mul <= 32'sd0;
            post_shifted <= 32'sd0;
            post_biased <= 32'sd0;
            bn_q <= {DATA_W{1'b0}};
            a_out <= {DATA_W{1'b0}};
            w_out <= {DATA_W{1'b0}};
            post_out <= {DATA_W{1'b0}};
        end else begin
            if (mac_en) begin
                acc <= acc + $signed({{(ACC_W-32){mul_p[31]}}, mul_p});
                a_out <= a_in;
                w_out <= w_in;
            end

            if (post0_en) begin
                bn_mul <= mul_p;
            end

            if (post1_en) begin
                post_shifted = bn_mul >>> FRAC_BITS;
                post_biased = post_shifted + $signed({{(32-DATA_W){bn_bias[DATA_W-1]}}, bn_bias});
                bn_q = sat_q8_8_from_32(post_biased);
                post_out <= bn_q[DATA_W-1] ? {DATA_W{1'b0}} : bn_q;
            end
        end
    end

    function signed [DATA_W-1:0] sat_q8_8_from_acc_shift;
        input signed [ACC_W-1:0] value;
        reg signed [ACC_W-1:0] shifted;
        begin
            shifted = value >>> FRAC_BITS;
            if (shifted > $signed({1'b0, {(DATA_W-1){1'b1}}})) begin
                sat_q8_8_from_acc_shift = {1'b0, {(DATA_W-1){1'b1}}};
            end else if (shifted < $signed({1'b1, {(DATA_W-1){1'b0}}})) begin
                sat_q8_8_from_acc_shift = {1'b1, {(DATA_W-1){1'b0}}};
            end else begin
                sat_q8_8_from_acc_shift = shifted[DATA_W-1:0];
            end
        end
    endfunction

    function signed [DATA_W-1:0] sat_q8_8_from_32;
        input signed [31:0] value;
        begin
            if (value > $signed({1'b0, {(DATA_W-1){1'b1}}})) begin
                sat_q8_8_from_32 = {1'b0, {(DATA_W-1){1'b1}}};
            end else if (value < $signed({1'b1, {(DATA_W-1){1'b0}}})) begin
                sat_q8_8_from_32 = {1'b1, {(DATA_W-1){1'b0}}};
            end else begin
                sat_q8_8_from_32 = value[DATA_W-1:0];
            end
        end
    endfunction

endmodule
