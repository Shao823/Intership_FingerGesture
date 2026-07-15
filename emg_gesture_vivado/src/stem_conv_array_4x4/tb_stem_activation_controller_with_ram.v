`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_stem_activation_controller_with_ram;

    localparam integer DATA_W     =  8;
    localparam integer MULT_W     = 16;
    localparam integer ROWS       = 4;
    localparam integer INPUT_LEN  = 348;
    localparam integer STEM_IC    = 5;
    localparam integer KERNEL     = 7;
    localparam integer PADDING    = 3;
    localparam integer TIME_W     = 9;
    localparam integer STEM_K     = STEM_IC * KERNEL;
    localparam integer TIME_WORDS = (INPUT_LEN + ROWS - 1) / ROWS;
    localparam integer RAM_DEPTH  = STEM_IC * TIME_WORDS;
    localparam integer ADDR_W     = (RAM_DEPTH <= 1) ? 1 : $clog2(RAM_DEPTH);
    localparam integer WORD_W     = ROWS * DATA_W;
    localparam integer MAX_REQS   = 768;
    localparam integer TIMEOUT    = 9000;
    // This TB instantiates the generated blk_mem_gen_stem_activation IP, whose
    // current .xci has READ_LATENCY_B=1.
    localparam integer BRAM_READ_LATENCY = 1;

    localparam integer READY_ALWAYS   = 0;
    localparam integer READY_PERIODIC = 1;
    localparam integer READY_HEAD_LOW = 2;

    localparam integer REQ_CONTINUOUS = 0;
    localparam integer REQ_MID_GAP    = 1;

    localparam integer SEQ_ADDRESS_SWEEP = 0;
    localparam integer SEQ_MIXED_WINDOWS = 1;

    reg clk;
    reg rst_n;

    reg act_wr_en;
    reg [ADDR_W-1:0] act_wr_addr;
    reg [WORD_W-1:0] act_wr_data;
    wire act_wr_ready;

    reg act_req_valid;
    reg [TIME_W-1:0] act_req_t_base;
    reg [5:0] act_req_k;
    wire act_req_ready;

    wire act_vec_valid;
    reg act_vec_ready;
    wire signed [WORD_W-1:0] act_vec;

    reg signed [DATA_W-1:0] raw_input [0:INPUT_LEN*STEM_IC-1];
    reg [WORD_W-1:0] expected_queue [0:MAX_REQS-1];
    reg seen_read_addr [0:RAM_DEPTH-1];

    integer errors;
    integer exp_head;
    integer exp_tail;
    integer exp_count;
    integer total_requests;
    integer total_responses;
    integer req_stall_count;
    integer req_gap_count;
    integer read_issue_count;
    integer unique_read_addr_count;
    integer cycle_count;
    integer send_idx;
    integer cover_i;
    integer load_ch;
    integer load_word;
    integer load_addr;

    stem_activation_controller_with_ram #(
        .DATA_W(DATA_W),
        .ROWS(ROWS),
        .INPUT_LEN(INPUT_LEN),
        .STEM_IC(STEM_IC),
        .KERNEL(KERNEL),
        .PADDING(PADDING),
        .TIME_W(TIME_W),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .STEM_K(STEM_K),
        .TIME_WORDS(TIME_WORDS),
        .RAM_DEPTH(RAM_DEPTH),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .act_wr_en(act_wr_en),
        .act_wr_addr(act_wr_addr),
        .act_wr_data(act_wr_data),
        .act_wr_bank(1'b0),
        .act_rd_bank(1'b0),
        .act_rd_active(1'b0),
        .act_wr_ready(act_wr_ready),
        .act_req_valid(act_req_valid),
        .act_req_t_base(act_req_t_base),
        .act_req_k(act_req_k),
        .act_req_ready(act_req_ready),
        .act_vec_valid(act_vec_valid),
        .act_vec_ready(act_vec_ready),
        .act_vec(act_vec)
    );

    initial begin
        clk = 1'b0;
        $readmemh(
            {`PROJECT_ROOT, "/emg_gesture_vivado/src/stem_conv_array_4x4/testdata/raw_input.mem"},
            raw_input
        );
    end

    always #5 clk = ~clk;

    function [WORD_W-1:0] pack_word;
        input integer ch_i;
        input integer word_i;
        integer lane_i;
        integer t_i;
        begin
            pack_word = {WORD_W{1'b0}};
            for (lane_i = 0; lane_i < ROWS; lane_i = lane_i + 1) begin
                t_i = word_i * ROWS + lane_i;
                if (t_i < INPUT_LEN) begin
                    pack_word[lane_i*DATA_W +: DATA_W] = raw_input[t_i*STEM_IC + ch_i];
                end
            end
        end
    endfunction

    function ready_for_cycle;
        input integer ready_mode;
        input integer cycle_i;
        begin
            case (ready_mode)
                READY_ALWAYS: begin
                    ready_for_cycle = 1'b1;
                end

                READY_PERIODIC: begin
                    ready_for_cycle = ((cycle_i % 5) != 2) && ((cycle_i % 13) != 7);
                end

                READY_HEAD_LOW: begin
                    ready_for_cycle = (cycle_i >= 8);
                end

                default: begin
                    ready_for_cycle = 1'b1;
                end
            endcase
        end
    endfunction

    function req_valid_for_cycle;
        input integer req_mode;
        input integer cycle_i;
        begin
            case (req_mode)
                REQ_CONTINUOUS: begin
                    req_valid_for_cycle = 1'b1;
                end

                REQ_MID_GAP: begin
                    req_valid_for_cycle = !((cycle_i >= 9) && (cycle_i < 15));
                end

                default: begin
                    req_valid_for_cycle = 1'b1;
                end
            endcase
        end
    endfunction

    function [TIME_W-1:0] req_t_for_index;
        input integer seq_mode;
        input integer idx;
        integer word_idx;
        integer group;
        begin
            if (seq_mode == SEQ_ADDRESS_SWEEP) begin
                word_idx = idx % TIME_WORDS;
                req_t_for_index = word_idx * ROWS;
            end else begin
                group = (idx / STEM_K) % 6;
                case (group)
                    0: req_t_for_index = 0;
                    1: req_t_for_index = 1;
                    2: req_t_for_index = 37;
                    3: req_t_for_index = 168;
                    4: req_t_for_index = 340;
                    default: req_t_for_index = 344;
                endcase
            end
        end
    endfunction

    function [5:0] req_k_for_index;
        input integer seq_mode;
        input integer idx;
        integer ch_idx;
        begin
            if (seq_mode == SEQ_ADDRESS_SWEEP) begin
                ch_idx = idx / TIME_WORDS;
                req_k_for_index = ch_idx * KERNEL + PADDING;
            end else begin
                req_k_for_index = idx % STEM_K;
            end
        end
    endfunction

    function [WORD_W-1:0] expected_vec_for;
        input integer t_base_i;
        input integer k_i;
        integer row_i;
        integer ch_i;
        integer tap_i;
        integer in_t_i;
        reg [DATA_W-1:0] sample_i;
        begin
            expected_vec_for = {WORD_W{1'b0}};
            if (k_i < STEM_K) begin
                ch_i = k_i / KERNEL;
                tap_i = k_i - (ch_i * KERNEL);
                for (row_i = 0; row_i < ROWS; row_i = row_i + 1) begin
                    in_t_i = t_base_i + row_i + tap_i - PADDING;
                    sample_i = {DATA_W{1'b0}};
                    if ((in_t_i >= 0) && (in_t_i < INPUT_LEN)) begin
                        sample_i = raw_input[in_t_i*STEM_IC + ch_i];
                    end
                    expected_vec_for[row_i*DATA_W +: DATA_W] = sample_i;
                end
            end
        end
    endfunction

    task clear_scoreboard;
        begin
            exp_head = 0;
            exp_tail = 0;
            exp_count = 0;
            total_requests = 0;
            total_responses = 0;
            req_stall_count = 0;
            req_gap_count = 0;
            read_issue_count = 0;
            unique_read_addr_count = 0;
            for (cover_i = 0; cover_i < RAM_DEPTH; cover_i = cover_i + 1) begin
                seen_read_addr[cover_i] = 1'b0;
            end
        end
    endtask

    task reset_dut;
        begin
            rst_n = 1'b0;
            act_req_valid = 1'b0;
            act_req_t_base = {TIME_W{1'b0}};
            act_req_k = 6'd0;
            act_vec_ready = 1'b0;
            clear_scoreboard();

            repeat (5) @(posedge clk);
            @(negedge clk);
            rst_n = 1'b1;
            act_vec_ready = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    task write_activation_ram;
        begin
            for (load_ch = 0; load_ch < STEM_IC; load_ch = load_ch + 1) begin
                for (load_word = 0; load_word < TIME_WORDS; load_word = load_word + 1) begin
                    load_addr = load_ch * TIME_WORDS + load_word;
                    @(negedge clk);
                    act_wr_en = 1'b1;
                    act_wr_addr = load_addr[ADDR_W-1:0];
                    act_wr_data = pack_word(load_ch, load_word);
                    if (act_wr_ready !== 1'b1) begin
                        $display("ERROR activation RAM write port not ready");
                        errors = errors + 1;
                    end
                end
            end
            @(negedge clk);
            act_wr_en = 1'b0;
            act_wr_addr = {ADDR_W{1'b0}};
            act_wr_data = {WORD_W{1'b0}};
            repeat (4) @(posedge clk);
        end
    endtask

    task push_expected;
        input [TIME_W-1:0] t_base_i;
        input [5:0] k_i;
        begin
            expected_queue[exp_tail] = expected_vec_for(t_base_i, k_i);
            exp_tail = exp_tail + 1;
            exp_count = exp_count + 1;
            total_requests = total_requests + 1;
        end
    endtask

    task pop_and_check_response;
        begin
            if (exp_count <= 0) begin
                $display("ERROR activation RAM response with empty expected queue");
                errors = errors + 1;
            end else begin
                if (act_vec !== expected_queue[exp_head]) begin
                    $display(
                        "ERROR activation RAM vec mismatch response=%0d got=%h expected=%h",
                        total_responses,
                        act_vec,
                        expected_queue[exp_head]
                    );
                    errors = errors + 1;
                end
                exp_head = exp_head + 1;
                exp_count = exp_count - 1;
                total_responses = total_responses + 1;
            end
        end
    endtask

    task record_read_issue;
        begin
            if (dut.u_ctrl.ram0_issue) begin
                read_issue_count = read_issue_count + 1;
                if (dut.ram0_en !== 1'b1) begin
                    $display("ERROR activation IP ram0_en not asserted on read issue");
                    errors = errors + 1;
                end
                if (dut.ram0_addr >= RAM_DEPTH) begin
                    $display("ERROR activation IP ram0_addr out of range got=%0d", dut.ram0_addr);
                    errors = errors + 1;
                end else if (!seen_read_addr[dut.ram0_addr]) begin
                    seen_read_addr[dut.ram0_addr] = 1'b1;
                    unique_read_addr_count = unique_read_addr_count + 1;
                end
            end
            if (dut.u_ctrl.ram1_issue) begin
                read_issue_count = read_issue_count + 1;
                if (dut.ram1_en !== 1'b1) begin
                    $display("ERROR activation IP ram1_en not asserted on read issue");
                    errors = errors + 1;
                end
                if (dut.ram1_addr >= RAM_DEPTH) begin
                    $display("ERROR activation IP ram1_addr out of range got=%0d", dut.ram1_addr);
                    errors = errors + 1;
                end else if (!seen_read_addr[dut.ram1_addr]) begin
                    seen_read_addr[dut.ram1_addr] = 1'b1;
                    unique_read_addr_count = unique_read_addr_count + 1;
                end
            end
        end
    endtask

    task run_sequence;
        input integer seq_mode;
        input integer request_count;
        input integer ready_mode;
        input integer req_mode;
        input integer expect_req_stall;
        input integer expect_req_gap;
        input integer expect_all_addr_cover;
        input [8*64-1:0] label;
        begin
            clear_scoreboard();
            send_idx = 0;
            cycle_count = 0;

            while ((total_responses < request_count) && (cycle_count < TIMEOUT)) begin
                @(negedge clk);

                act_vec_ready = ready_for_cycle(ready_mode, cycle_count);
                if (send_idx < request_count) begin
                    act_req_valid = req_valid_for_cycle(req_mode, cycle_count);
                    act_req_t_base = req_t_for_index(seq_mode, send_idx);
                    act_req_k = req_k_for_index(seq_mode, send_idx);
                    if (!act_req_valid) begin
                        req_gap_count = req_gap_count + 1;
                    end
                end else begin
                    act_req_valid = 1'b0;
                    act_req_t_base = {TIME_W{1'b0}};
                    act_req_k = 6'd0;
                end

                #1;
                record_read_issue();

                if (act_vec_valid && act_vec_ready) begin
                    pop_and_check_response();
                end

                if (act_req_valid && act_req_ready) begin
                    push_expected(act_req_t_base, act_req_k);
                    send_idx = send_idx + 1;
                end else if (act_req_valid) begin
                    req_stall_count = req_stall_count + 1;
                end

                cycle_count = cycle_count + 1;
            end

            @(negedge clk);
            act_req_valid = 1'b0;
            act_vec_ready = 1'b1;

            if (cycle_count >= TIMEOUT) begin
                $display("ERROR timeout in %0s", label);
                errors = errors + 1;
            end
            if (total_requests != request_count) begin
                $display("ERROR %0s requests got=%0d expected=%0d",
                    label, total_requests, request_count);
                errors = errors + 1;
            end
            if (total_responses != request_count) begin
                $display("ERROR %0s responses got=%0d expected=%0d",
                    label, total_responses, request_count);
                errors = errors + 1;
            end
            if (exp_count != 0) begin
                $display("ERROR %0s expected queue not empty count=%0d", label, exp_count);
                errors = errors + 1;
            end
            if (expect_req_stall && (req_stall_count == 0)) begin
                $display("ERROR %0s expected controller request stalls but saw none", label);
                errors = errors + 1;
            end
            if (!expect_req_stall && (req_stall_count != 0)) begin
                $display("ERROR %0s unexpected request stalls=%0d", label, req_stall_count);
                errors = errors + 1;
            end
            if (expect_req_gap && (req_gap_count == 0)) begin
                $display("ERROR %0s expected req_valid gaps but saw none", label);
                errors = errors + 1;
            end
            if (!expect_req_gap && (req_gap_count != 0)) begin
                $display("ERROR %0s unexpected req_valid gaps=%0d", label, req_gap_count);
                errors = errors + 1;
            end
            if (read_issue_count < request_count) begin
                $display("ERROR %0s read issues got=%0d expected at least %0d",
                    label, read_issue_count, request_count);
                errors = errors + 1;
            end
            if (expect_all_addr_cover && (unique_read_addr_count != RAM_DEPTH)) begin
                $display("ERROR %0s unique read addresses got=%0d expected=%0d",
                    label, unique_read_addr_count, RAM_DEPTH);
                errors = errors + 1;
            end
            if (dut.u_ctrl.invalid_req_count != 0) begin
                $display(
                    "ERROR %0s unexpected invalid_req_count=%0d",
                    label,
                    dut.u_ctrl.invalid_req_count
                );
                errors = errors + 1;
            end

            $display(
                "INFO ACT IP L%0d %0s requests=%0d responses=%0d cycles=%0d req_stalls=%0d req_gaps=%0d read_issues=%0d unique_reads=%0d",
                BRAM_READ_LATENCY,
                label,
                total_requests,
                total_responses,
                cycle_count,
                req_stall_count,
                req_gap_count,
                read_issue_count,
                unique_read_addr_count
            );
        end
    endtask

    task send_invalid_request;
        input [TIME_W-1:0] invalid_t_base;
        input [5:0] invalid_k;
        integer timeout;
        begin
            @(negedge clk);
            act_vec_ready = 1'b1;
            act_req_valid = 1'b1;
            act_req_t_base = invalid_t_base;
            act_req_k = invalid_k;
            #1;
            if (act_req_ready !== 1'b1) begin
                $display("ERROR invalid activation RAM request was not accepted");
                errors = errors + 1;
            end
            @(negedge clk);
            act_req_valid = 1'b0;
            act_req_t_base = {TIME_W{1'b0}};
            act_req_k = 6'd0;

            timeout = 0;
            while ((act_vec_valid !== 1'b1) && (timeout < 40)) begin
                @(negedge clk);
                #1;
                record_read_issue();
                timeout = timeout + 1;
            end
            if (act_vec_valid === 1'b1) begin
                @(negedge clk);
            end else begin
                $display("ERROR timeout waiting for invalid activation RAM response");
                errors = errors + 1;
            end
        end
    endtask

    task run_invalid_request_case;
        integer invalid_before;
        integer invalid_after;
        begin
            clear_scoreboard();
            invalid_before = dut.u_ctrl.invalid_req_count;
            send_invalid_request(9'd0, 6'd35);
            send_invalid_request(9'd345, 6'd3);
            invalid_after = dut.u_ctrl.invalid_req_count;
            if ((invalid_after - invalid_before) != 2) begin
                $display(
                    "ERROR activation RAM invalid_req_count delta got=%0d expected=2",
                    invalid_after - invalid_before
                );
                errors = errors + 1;
            end
            $display(
                "INFO ACT IP invalid_request_case invalid_delta=%0d",
                invalid_after - invalid_before
            );
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 1'b0;
        act_wr_en = 1'b0;
        act_wr_addr = {ADDR_W{1'b0}};
        act_wr_data = {WORD_W{1'b0}};
        act_req_valid = 1'b0;
        act_req_t_base = {TIME_W{1'b0}};
        act_req_k = 6'd0;
        act_vec_ready = 1'b0;

        repeat (5) @(negedge clk);
        rst_n = 1'b1;
        write_activation_ram();

        reset_dut();
        run_sequence(
            SEQ_ADDRESS_SWEEP,
            RAM_DEPTH,
            READY_ALWAYS,
            REQ_CONTINUOUS,
            0,
            0,
            1,
            "all_435_addresses_aligned"
        );

        reset_dut();
        run_sequence(
            SEQ_MIXED_WINDOWS,
            STEM_K * 6,
            READY_PERIODIC,
            REQ_CONTINUOUS,
            1,
            0,
            0,
            "padding_unaligned_periodic_ready"
        );

        reset_dut();
        run_sequence(
            SEQ_MIXED_WINDOWS,
            80,
            READY_ALWAYS,
            REQ_MID_GAP,
            0,
            1,
            0,
            "request_valid_mid_gap"
        );

        reset_dut();
        run_sequence(
            SEQ_MIXED_WINDOWS,
            40,
            READY_HEAD_LOW,
            REQ_CONTINUOUS,
            1,
            0,
            0,
            "head_response_backpressure"
        );

        reset_dut();
        run_invalid_request_case();

        if (errors == 0) begin
            $display("PASS tb_stem_activation_controller_with_ram");
        end else begin
            $display("FAIL tb_stem_activation_controller_with_ram errors=%0d", errors);
            $finish;
        end
        $finish;
    end

endmodule
