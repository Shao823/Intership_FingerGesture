`timescale 1ns / 1ps

module emg_ddr_model #(
    parameter integer N_CASES = 10,
    parameter integer CHANNELS = 5,
    parameter integer INPUT_LEN = 348,
    parameter integer FRAME_BYTES = CHANNELS * INPUT_LEN,
    parameter RAW_INPUT_FILE = "raw_input.mem"
) (
    input  wire [31:0] rd_addr,
    output wire [31:0] rd_data
);

    localparam integer TOTAL_BYTES = N_CASES * FRAME_BYTES;

    reg signed [7:0] raw_input [0:TOTAL_BYTES-1];
    reg [7:0] memory [0:TOTAL_BYTES-1];

    integer case_index;
    integer channel_index;
    integer time_index;
    integer source_index;
    integer destination_index;

    initial begin
        $readmemh(RAW_INPUT_FILE, raw_input);

        if (^raw_input[0] === 1'bx) begin
            $fatal(1, "DDR raw-input file was not loaded: %0s", RAW_INPUT_FILE);
        end

        for (case_index = 0; case_index < N_CASES;
             case_index = case_index + 1) begin
            for (channel_index = 0; channel_index < CHANNELS;
                 channel_index = channel_index + 1) begin
                for (time_index = 0; time_index < INPUT_LEN;
                     time_index = time_index + 1) begin
                    source_index = case_index * FRAME_BYTES
                        + time_index * CHANNELS
                        + channel_index;
                    destination_index = case_index * FRAME_BYTES
                        + channel_index * INPUT_LEN
                        + time_index;
                    memory[destination_index] = raw_input[source_index];
                end
            end
        end
    end

    assign rd_data = {
        memory[rd_addr + 3],
        memory[rd_addr + 2],
        memory[rd_addr + 1],
        memory[rd_addr]
    };

endmodule
