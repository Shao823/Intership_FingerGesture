`timescale 1ns / 1ps

module emg_dma_pingpong_controller #(
    parameter integer DATA_WIDTH  = 32,
    parameter integer FRAME_WORDS = 435,
    parameter integer ADDR_WIDTH  = (FRAME_WORDS <= 1) ? 1 : $clog2(FRAME_WORDS)
) (
    input  wire clk,
    input  wire rst_n,

    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axis_tkeep,
    input  wire s_axis_tlast,
    input  wire s_axis_tvalid,
    output wire s_axis_tready,

    output wire act_wr_en,
    output wire [ADDR_WIDTH-1:0] act_wr_addr,
    output wire [DATA_WIDTH-1:0] act_wr_data,
    input  wire act_wr_ready,

    input  wire frame_consume,
    input  wire clear_errors,

    output reg frame_ready,
    output wire rx_active,
    output reg [15:0] beat_count,
    output reg [15:0] frame_count,

    output reg error_early_tlast,
    output reg error_missing_tlast,
    output reg error_bad_keep,
    output reg error_dropped_frame
);

    localparam [(DATA_WIDTH/8)-1:0] FULL_KEEP = {(DATA_WIDTH/8){1'b1}};

    reg drop_until_tlast;

    wire axis_fire;
    wire bad_keep;
    wire final_word;
    wire write_fire;

    assign s_axis_tready = rst_n && (drop_until_tlast
        ? 1'b1
        : (!frame_ready && act_wr_ready));
    assign axis_fire = s_axis_tvalid && s_axis_tready;
    assign bad_keep = s_axis_tkeep != FULL_KEEP;
    assign final_word = beat_count == (FRAME_WORDS - 1);
    assign write_fire = axis_fire
        && !drop_until_tlast
        && !bad_keep
        && !frame_ready;

    assign act_wr_en = write_fire;
    assign act_wr_addr = beat_count[ADDR_WIDTH-1:0];
    assign act_wr_data = s_axis_tdata;
    assign rx_active = drop_until_tlast || (beat_count != 16'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_ready <= 1'b0;
            beat_count <= 16'd0;
            frame_count <= 16'd0;
            drop_until_tlast <= 1'b0;
            error_early_tlast <= 1'b0;
            error_missing_tlast <= 1'b0;
            error_bad_keep <= 1'b0;
            error_dropped_frame <= 1'b0;
        end else begin
            if (clear_errors) begin
                error_early_tlast <= 1'b0;
                error_missing_tlast <= 1'b0;
                error_bad_keep <= 1'b0;
                error_dropped_frame <= 1'b0;
            end

            if (frame_consume && frame_ready) begin
                frame_ready <= 1'b0;
                beat_count <= 16'd0;
            end

            if (axis_fire) begin
                if (drop_until_tlast) begin
                    if (s_axis_tlast) begin
                        drop_until_tlast <= 1'b0;
                        beat_count <= 16'd0;
                    end
                end else if (bad_keep) begin
                    error_bad_keep <= 1'b1;
                    error_dropped_frame <= 1'b1;
                    beat_count <= 16'd0;
                    if (!s_axis_tlast) begin
                        drop_until_tlast <= 1'b1;
                    end
                end else if (final_word) begin
                    if (s_axis_tlast) begin
                        frame_ready <= 1'b1;
                        frame_count <= frame_count + 1'b1;
                        beat_count <= FRAME_WORDS;
                    end else begin
                        error_missing_tlast <= 1'b1;
                        error_dropped_frame <= 1'b1;
                        drop_until_tlast <= 1'b1;
                        beat_count <= 16'd0;
                    end
                end else if (s_axis_tlast) begin
                    error_early_tlast <= 1'b1;
                    error_dropped_frame <= 1'b1;
                    beat_count <= 16'd0;
                end else begin
                    beat_count <= beat_count + 1'b1;
                end
            end
        end
    end

endmodule
