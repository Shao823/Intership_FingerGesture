`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_stem_weight_controller #(
    parameter integer BRAM_READ_LATENCY = 1
);

    localparam integer DATA_W     = 16;
    localparam integer OC_LANES   = 4;
    localparam integer STEM_OC    = 32;
    localparam integer STEM_K     = 35;
    localparam integer WORD_W     = DATA_W * OC_LANES;
    localparam integer ROM_DEPTH  = STEM_OC / OC_LANES * STEM_K;
    localparam integer ADDR_W     = (ROM_DEPTH <= 1) ? 1 : $clog2(ROM_DEPTH);
    localparam integer MAX_REQS   = 512;
    localparam integer TIMEOUT    = 2000;

    localparam integer READY_ALWAYS   = 0;
    localparam integer READY_PERIODIC = 1;
    localparam integer READY_HEAD_LOW = 2;

    localparam integer REQ_CONTINUOUS = 0;
    localparam integer REQ_MID_GAP    = 1;

    reg clk;
    reg rst_n;

    reg weight_req_valid;
    reg [4:0] weight_req_oc_base;
    reg [5:0] weight_req_k;
    wire weight_req_ready;

    wire weight_vec_valid;
    reg weight_vec_ready;
    wire signed [WORD_W-1:0] weight_vec;

    wire rom_en;
    wire [ADDR_W-1:0] rom_addr;
    reg [WORD_W-1:0] rom_dout;

    reg [WORD_W-1:0] rom_mem [0:ROM_DEPTH-1];
    reg [WORD_W-1:0] expected_queue [0:MAX_REQS-1];
    reg [BRAM_READ_LATENCY-1:0] rom_en_pipe;
    reg [ADDR_W-1:0] rom_addr_pipe [0:BRAM_READ_LATENCY-1];

    integer errors;
    integer exp_head;
    integer exp_tail;
    integer exp_count;
    integer total_requests;
    integer total_responses;
    integer req_stall_count;
    integer req_gap_count;
    integer cycle_count;
    integer send_idx;
    integer addr;
    integer pipe_i;

    stem_weight_controller #(
        .DATA_W(DATA_W),
        .OC_LANES(OC_LANES),
        .STEM_OC(STEM_OC),
        .STEM_K(STEM_K),
        .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .weight_req_valid(weight_req_valid),
        .weight_req_oc_base(weight_req_oc_base),
        .weight_req_k(weight_req_k),
        .weight_req_ready(weight_req_ready),
        .weight_vec_valid(weight_vec_valid),
        .weight_vec_ready(weight_vec_ready),
        .weight_vec(weight_vec),
        .rom_en(rom_en),
        .rom_addr(rom_addr),
        .rom_dout(rom_dout)
    );

    initial begin
        $readmemh({`PROJECT_ROOT, "/weight_data/stem/weight_packed.mem"}, rom_mem);
    end

    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;

    always @(posedge clk) begin
        rom_en_pipe[0] <= rom_en;
        rom_addr_pipe[0] <= rom_addr;
        for (pipe_i = 1; pipe_i < BRAM_READ_LATENCY; pipe_i = pipe_i + 1) begin
            rom_en_pipe[pipe_i] <= rom_en_pipe[pipe_i-1];
            rom_addr_pipe[pipe_i] <= rom_addr_pipe[pipe_i-1];
        end
        if (rom_en_pipe[BRAM_READ_LATENCY-1]) begin
            rom_dout <= rom_mem[rom_addr_pipe[BRAM_READ_LATENCY-1]];
        end
    end

    function integer calc_addr;
        input [4:0] oc_base_i;
        input [5:0] k_i;
        begin
            calc_addr = (oc_base_i >> 2) * STEM_K + k_i;
        end
    endfunction

    function [4:0] req_oc_for_index;
        input integer idx;
        integer group;
        begin
            group = (idx / STEM_K) % (STEM_OC / OC_LANES);
            req_oc_for_index = group * OC_LANES;
        end
    endfunction

    function [5:0] req_k_for_index;
        input integer idx;
        begin
            req_k_for_index = idx % STEM_K;
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
                    ready_for_cycle = ((cycle_i % 7) != 3) && ((cycle_i % 11) != 5);
                end

                READY_HEAD_LOW: begin
                    ready_for_cycle = (cycle_i >= 6);
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
                    req_valid_for_cycle = !((cycle_i >= 8) && (cycle_i < 13));
                end

                default: begin
                    req_valid_for_cycle = 1'b1;
                end
            endcase
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
        end
    endtask

    task reset_dut;
        begin
            rst_n = 1'b0;
            weight_req_valid = 1'b0;
            weight_req_oc_base = 5'd0;
            weight_req_k = 6'd0;
            weight_vec_ready = 1'b0;
            rom_dout = {WORD_W{1'b0}};
            rom_en_pipe = {BRAM_READ_LATENCY{1'b0}};
            for (pipe_i = 0; pipe_i < BRAM_READ_LATENCY; pipe_i = pipe_i + 1) begin
                rom_addr_pipe[pipe_i] = {ADDR_W{1'b0}};
            end
            clear_scoreboard();

            repeat (5) @(posedge clk);
            @(negedge clk);
            rst_n = 1'b1;
            weight_vec_ready = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    task push_expected;
        input [4:0] oc_base_i;
        input [5:0] k_i;
        begin
            addr = calc_addr(oc_base_i, k_i);
            if (addr < 0 || addr >= ROM_DEPTH) begin
                $display("ERROR request address out of range: oc_base=%0d k=%0d addr=%0d",
                    oc_base_i, k_i, addr);
                errors = errors + 1;
            end else begin
                if (rom_en !== 1'b1) begin
                    $display("ERROR rom_en not asserted for accepted request");
                    errors = errors + 1;
                end
                if (rom_addr !== addr[ADDR_W-1:0]) begin
                    $display("ERROR rom_addr got=%0d expected=%0d oc_base=%0d k=%0d",
                        rom_addr, addr, oc_base_i, k_i);
                    errors = errors + 1;
                end
                expected_queue[exp_tail] = rom_mem[addr];
                exp_tail = exp_tail + 1;
                exp_count = exp_count + 1;
                total_requests = total_requests + 1;
            end
        end
    endtask

    task pop_and_check_response;
        begin
            if (exp_count <= 0) begin
                $display("ERROR response with empty expected queue");
                errors = errors + 1;
            end else begin
                if (weight_vec !== expected_queue[exp_head]) begin
                    $display("ERROR weight_vec mismatch at response %0d got=%h expected=%h",
                        total_responses, weight_vec, expected_queue[exp_head]);
                    errors = errors + 1;
                end
                exp_head = exp_head + 1;
                exp_count = exp_count - 1;
                total_responses = total_responses + 1;
            end
        end
    endtask

    task run_sequence;
        input integer request_count;
        input integer ready_mode;
        input integer req_mode;
        input integer expect_req_stall;
        input integer expect_req_gap;
        input [8*64-1:0] label;
        begin
            clear_scoreboard();
            send_idx = 0;
            cycle_count = 0;

            while ((total_responses < request_count) && (cycle_count < TIMEOUT)) begin
                @(negedge clk);

                weight_vec_ready = ready_for_cycle(ready_mode, cycle_count);
                if (send_idx < request_count) begin
                    weight_req_valid = req_valid_for_cycle(req_mode, cycle_count);
                    weight_req_oc_base = req_oc_for_index(send_idx);
                    weight_req_k = req_k_for_index(send_idx);
                    if (!weight_req_valid) begin
                        req_gap_count = req_gap_count + 1;
                    end
                end else begin
                    weight_req_valid = 1'b0;
                    weight_req_oc_base = 5'd0;
                    weight_req_k = 6'd0;
                end

                #1;

                if (weight_vec_valid && weight_vec_ready) begin
                    pop_and_check_response();
                end

                if (weight_req_valid && weight_req_ready) begin
                    push_expected(weight_req_oc_base, weight_req_k);
                    send_idx = send_idx + 1;
                end else if (weight_req_valid) begin
                    req_stall_count = req_stall_count + 1;
                end

                cycle_count = cycle_count + 1;
            end

            @(negedge clk);
            weight_req_valid = 1'b0;
            weight_vec_ready = 1'b1;

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
                $display("ERROR %0s expected request backpressure but saw none", label);
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
            if (dut.invalid_req_count != 0) begin
                $display(
                    "ERROR %0s unexpected invalid_req_count=%0d",
                    label,
                    dut.invalid_req_count
                );
                errors = errors + 1;
            end

            $display(
                "INFO L%0d %0s requests=%0d responses=%0d cycles=%0d req_stalls=%0d req_gaps=%0d",
                BRAM_READ_LATENCY,
                label,
                total_requests,
                total_responses,
                cycle_count,
                req_stall_count,
                req_gap_count
            );
        end
    endtask

    task send_invalid_request;
        input [4:0] invalid_oc_base;
        input [5:0] invalid_k;
        begin
            @(negedge clk);
            weight_vec_ready = 1'b1;
            weight_req_valid = 1'b1;
            weight_req_oc_base = invalid_oc_base;
            weight_req_k = invalid_k;
            #1;
            if (weight_req_ready !== 1'b1) begin
                $display("ERROR invalid request was not accepted for debug check");
                errors = errors + 1;
            end
            @(negedge clk);
            weight_req_valid = 1'b0;
            weight_req_oc_base = 5'd0;
            weight_req_k = 6'd0;
            repeat (5) @(posedge clk);
        end
    endtask

    task run_invalid_request_case;
        integer invalid_before;
        integer invalid_after;
        begin
            clear_scoreboard();
            invalid_before = dut.invalid_req_count;
            send_invalid_request(5'd5, 6'd0);
            send_invalid_request(5'd0, 6'd35);
            invalid_after = dut.invalid_req_count;
            if ((invalid_after - invalid_before) != 2) begin
                $display(
                    "ERROR invalid_req_count delta got=%0d expected=2",
                    invalid_after - invalid_before
                );
                errors = errors + 1;
            end
            $display("INFO invalid_request_case invalid_delta=%0d", invalid_after - invalid_before);
        end
    endtask

    initial begin
        errors = 0;
        reset_dut();

        run_sequence(70, READY_ALWAYS, REQ_CONTINUOUS, 0, 0, "pipeline_ready_always");

        reset_dut();
        run_sequence(
            ROM_DEPTH,
            READY_PERIODIC,
            REQ_CONTINUOUS,
            1,
            0,
            "all_280_words_periodic_backpressure"
        );

        reset_dut();
        run_sequence(20, READY_HEAD_LOW, REQ_CONTINUOUS, 1, 0, "head_backpressure");

        reset_dut();
        run_sequence(40, READY_ALWAYS, REQ_MID_GAP, 0, 1, "request_valid_mid_gap");

        reset_dut();
        run_invalid_request_case();

        if (errors == 0) begin
            $display("PASS tb_stem_weight_controller");
        end else begin
            $display("FAIL tb_stem_weight_controller errors=%0d", errors);
            $finish;
        end
        $finish;
    end

endmodule
