`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

// Minimal final-result testbench for the synthesis-facing accelerator top.
//
// This TB intentionally checks only the system-facing behavior: load one raw
// input frame through the activation RAM write port, start the accelerator, and
// compare the final class result with the checkpoint reference.
//
// Mock blk_mem_gen modules are not duplicated here to avoid module-name
// collisions when multiple TB files are present in a Vivado simulation set. For
// an Icarus mock run, compile tb_stem_dw1_pw1_dw2_pw2_pipeline_top.v in the
// same command as a library of mock IP models and select -s tb_accelerator.

module tb_accelerator #(
    parameter integer RUN_CASE_LIMIT = 20,
    parameter integer START_HOLD_CYCLES = 1,
    parameter integer DEBUG_PROGRESS = 0,
    parameter integer DEBUG_INTERVAL = 50000,
    parameter integer TIMEOUT = 900000
);

    localparam integer DATA_W    = 16;
    localparam integer ROWS      = 4;
    localparam integer STEM_IC   = 5;
    localparam integer INPUT_LEN = 348;
    localparam integer N_CASES   = 20;
    localparam integer ACT_TIME_WORDS = (INPUT_LEN + ROWS - 1) / ROWS;
    localparam integer ACT_RAM_DEPTH  = STEM_IC * ACT_TIME_WORDS;
    localparam integer ACT_ADDR_W     = (ACT_RAM_DEPTH <= 1)
        ? 1 : $clog2(ACT_RAM_DEPTH);

    reg clk;
    reg rst_n;
    reg start;

    reg act_wr_en;
    reg [ACT_ADDR_W-1:0] act_wr_addr;
    reg [ROWS*DATA_W-1:0] act_wr_data;
    wire act_wr_ready;

    wire busy;
    wire done;
    wire class_valid;
    wire [2:0] class_idx;

    integer errors;
    integer current_case;
    integer case_i;
    integer case_limit;
    integer timeout;
    integer load_ch;
    integer load_word;
    integer load_addr;
    integer lane;
    integer t_idx;
    integer class_seen;
    integer hold_cycles;

    reg [2:0] class_observed;
    reg signed [DATA_W-1:0] file_raw_input [0:N_CASES*INPUT_LEN*STEM_IC-1];
    reg [7:0] file_expected_class [0:N_CASES-1];

    accelerator dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .act_wr_en(act_wr_en),
        .act_wr_addr(act_wr_addr),
        .act_wr_data(act_wr_data),
        .act_wr_ready(act_wr_ready),
        .class_valid(class_valid),
        .class_idx(class_idx)
    );

    initial begin
        $readmemh({`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_dw2_pw2_pipeline/testdata/raw_input.mem"}, file_raw_input);
        $readmemh({`PROJECT_ROOT, "/emg_gesture_vivado/src/top/stem_dw1_pw1_dw2_pw2_pipeline/testdata/fc_expected_class.mem"}, file_expected_class);
    end

    always #5 clk = ~clk;

    function [ROWS*DATA_W-1:0] pack_activation_word;
        input integer case_idx;
        input integer ch_idx;
        input integer word_idx;
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

    task drive_idle_inputs;
        begin
            start = 1'b0;
            act_wr_en = 1'b0;
            act_wr_addr = {ACT_ADDR_W{1'b0}};
            act_wr_data = {(ROWS*DATA_W){1'b0}};
        end
    endtask

    task launch_case;
        input integer case_idx;
        begin
            current_case = case_idx;
            class_seen = 0;
            class_observed = 3'd0;
            load_activation_ram(case_idx);

            hold_cycles = START_HOLD_CYCLES;
            if (hold_cycles < 1) begin
                hold_cycles = 1;
            end

            @(negedge clk);
            start = 1'b1;
            repeat (hold_cycles) @(negedge clk);
            start = 1'b0;

            timeout = 0;
            while ((done !== 1'b1) && (timeout < TIMEOUT)) begin
                @(posedge clk);
                #1;
                if (class_valid && !class_seen) begin
                    class_seen = 1;
                    class_observed = class_idx;
                end
                timeout = timeout + 1;
                if (DEBUG_PROGRESS && ((timeout % DEBUG_INTERVAL) == 0)) begin
                    $display("DBG case=%0d elapsed_cycles=%0d busy=%0b class_seen=%0d",
                        case_idx, timeout, busy, class_seen);
                end
            end

            if (done !== 1'b1) begin
                $display("ERROR timeout case=%0d elapsed_cycles=%0d class_seen=%0d",
                    case_idx, timeout, class_seen);
                errors = errors + 1;
            end else begin
                if (class_valid && !class_seen) begin
                    class_seen = 1;
                    class_observed = class_idx;
                end

                if (!class_seen) begin
                    $display("ERROR no class_valid case=%0d", case_idx);
                    errors = errors + 1;
                end else if (class_observed !== file_expected_class[case_idx][2:0]) begin
                    $display("ERROR class case=%0d got=%0d expected=%0d",
                        case_idx,
                        class_observed,
                        file_expected_class[case_idx]);
                    errors = errors + 1;
                end else begin
                    $display("CASE %0d cycles=%0d class=%0d PASS",
                        case_idx, timeout, class_observed);
                end
            end

            repeat (8) @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        errors = 0;
        current_case = 0;
        drive_idle_inputs();

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

        if (errors == 0) begin
            $display("PASS tb_accelerator");
        end else begin
            $display("FAIL tb_accelerator errors=%0d", errors);
            $fatal(1);
        end

        $finish;
    end

endmodule
