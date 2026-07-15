`timescale 1ns / 1ps

`ifndef PROJECT_ROOT
`define PROJECT_ROOT "D:/Intership"
`endif

module tb_fc_weight_controller_with_rom;

    localparam integer DATA_W        =  8;
    localparam integer MULT_W     = 16;
    localparam integer FC0_IN        = 96;
    localparam integer FC0_OUT       = 96;
    localparam integer FC1_OUT       = 5;
    localparam integer FC0_OUT_LANES = 16;
    localparam integer ADDR_W        = 10;
    localparam integer WORD_W        = FC0_OUT_LANES * DATA_W;
    localparam integer FC_K_EXT      = FC0_IN + 1;
    localparam integer FC0_GROUPS    = FC0_OUT / FC0_OUT_LANES;
    localparam integer FC1_BASE_ADDR = FC0_GROUPS * FC_K_EXT;
    localparam integer ROM_DEPTH     = FC1_BASE_ADDR + FC_K_EXT;
    localparam integer TIMEOUT       = 4000;

    reg clk;
    reg rst_n;
    reg weight_req_valid;
    reg weight_req_layer;
    reg [6:0] weight_req_oc_base;
    reg [6:0] weight_req_k;
    wire weight_req_ready;
    wire weight_vec_valid;
    reg weight_vec_ready;
    wire signed [WORD_W-1:0] weight_vec;

    reg [WORD_W-1:0] packed_mem [0:ROM_DEPTH-1];

    integer errors;
    integer group_i;
    integer k_i;
    integer timeout;

    fc_weight_controller_with_rom #(
        .DATA_W(DATA_W),
        .FC0_IN(FC0_IN),
        .FC0_OUT(FC0_OUT),
        .FC1_OUT(FC1_OUT),
        .FC0_OUT_LANES(FC0_OUT_LANES),
        .BRAM_READ_LATENCY(1),
        .ADDR_W(ADDR_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .weight_req_valid(weight_req_valid),
        .weight_req_layer(weight_req_layer),
        .weight_req_oc_base(weight_req_oc_base),
        .weight_req_k(weight_req_k),
        .weight_req_ready(weight_req_ready),
        .weight_vec_valid(weight_vec_valid),
        .weight_vec_ready(weight_vec_ready),
        .weight_vec(weight_vec)
    );

    initial begin
        $readmemh({`PROJECT_ROOT, "/weight_data/fc/weight_packed_256.mem"}, packed_mem);
    end

    always #5 clk = ~clk;

    function [ADDR_W-1:0] calc_addr;
        input layer_i;
        input [6:0] oc_base_i;
        input [6:0] k_i_local;
        begin
            if (layer_i) begin
                calc_addr = FC1_BASE_ADDR + k_i_local;
            end else begin
                calc_addr = ((oc_base_i / FC0_OUT_LANES) * FC_K_EXT) + k_i_local;
            end
        end
    endfunction

    task drive_idle;
        begin
            weight_req_valid = 1'b0;
            weight_req_layer = 1'b0;
            weight_req_oc_base = 7'd0;
            weight_req_k = 7'd0;
            weight_vec_ready = 1'b1;
        end
    endtask

    task issue_req;
        input layer_i;
        input [6:0] oc_base_i;
        input [6:0] k_i_local;
        begin
            @(negedge clk);
            weight_req_layer = layer_i;
            weight_req_oc_base = oc_base_i;
            weight_req_k = k_i_local;
            weight_req_valid = 1'b1;
            while (weight_req_ready !== 1'b1) begin
                @(negedge clk);
            end
            @(negedge clk);
            weight_req_valid = 1'b0;
        end
    endtask

    task request_and_check;
        input layer_i;
        input [6:0] oc_base_i;
        input [6:0] k_i_local;
        input integer ready_delay;
        reg [ADDR_W-1:0] expected_addr;
        reg [WORD_W-1:0] expected_word;
        begin
            expected_addr = calc_addr(layer_i, oc_base_i, k_i_local);
            expected_word = packed_mem[expected_addr];
            weight_vec_ready = 1'b0;
            issue_req(layer_i, oc_base_i, k_i_local);

            timeout = 0;
            while ((weight_vec_valid !== 1'b1) && (timeout < TIMEOUT)) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end
            if (weight_vec_valid !== 1'b1) begin
                $display(
                    "ERROR fc_weight_controller_with_rom timeout layer=%0d oc_base=%0d k=%0d",
                    layer_i,
                    oc_base_i,
                    k_i_local
                );
                errors = errors + 1;
            end else begin
                if (weight_vec !== expected_word) begin
                    $display(
                        "ERROR fc_weight_controller_with_rom word layer=%0d oc_base=%0d k=%0d addr=%0d got=%h expected=%h",
                        layer_i,
                        oc_base_i,
                        k_i_local,
                        expected_addr,
                        weight_vec,
                        expected_word
                    );
                    errors = errors + 1;
                end
                repeat (ready_delay) @(posedge clk);
                weight_vec_ready = 1'b1;
                @(posedge clk);
                #1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        errors = 0;
        drive_idle();

        repeat (8) @(negedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        for (group_i = 0; group_i < FC0_GROUPS; group_i = group_i + 1) begin
            for (k_i = 0; k_i < FC_K_EXT; k_i = k_i + 1) begin
                request_and_check(
                    1'b0,
                    (group_i * FC0_OUT_LANES),
                    k_i[6:0],
                    (k_i + group_i) % 3
                );
            end
        end
        for (k_i = 0; k_i < FC_K_EXT; k_i = k_i + 1) begin
            request_and_check(1'b1, 7'd0, k_i[6:0], k_i % 4);
        end

        if (errors == 0) begin
            $display("PASS fc_weight_controller_with_rom self-check");
            $finish;
        end else begin
            $display("FAIL fc_weight_controller_with_rom errors=%0d", errors);
            $fatal(1);
        end
    end

endmodule

`ifdef FC_MOCK_WEIGHT_ROM

module blk_mem_gen_fc_weight (
    input wire clka,
    input wire ena,
    input wire [9:0] addra,
    output reg [127:0] douta
);
    reg [127:0] mem [0:678];
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
