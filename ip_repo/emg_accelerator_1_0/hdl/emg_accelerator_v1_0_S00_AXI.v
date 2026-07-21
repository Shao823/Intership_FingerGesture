`timescale 1ns / 1ps

module emg_accelerator_v1_0_S00_AXI #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6,
    parameter integer FRAME_WORDS = 435,
    parameter integer FRAME_BYTES = 1740,
    parameter [31:0] IP_VERSION = 32'h0001_0001
) (
    output reg start_pulse,
    output reg auto_start,
    output reg clear_errors_pulse,
    output reg irq_enable,
    output wire irq,

    input  wire core_busy,
    input  wire core_done,
    input  wire core_class_valid,
    input  wire [2:0] core_class_idx,
    input  wire frame_ready,
    input  wire rx_active,
    input  wire act_wr_ready,
    input  wire [15:0] beat_count,
    input  wire [15:0] frame_count,
    input  wire error_early_tlast,
    input  wire error_missing_tlast,
    input  wire error_bad_keep,
    input  wire error_dropped_frame,
    input  wire start_accept,
    input  wire start_reject_no_frame,
    input  wire start_reject_busy,
    input  wire [31:0] inference_cycles,

    input  wire S_AXI_ACLK,
    input  wire S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire [2:0] S_AXI_AWPROT,
    input  wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    output wire [1:0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input  wire S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire [2:0] S_AXI_ARPROT,
    input  wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input  wire S_AXI_RREADY
);

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;
    localparam integer REG_ADDR_BITS = 4;

    reg aw_hold_valid;
    reg [C_S_AXI_ADDR_WIDTH-1:0] aw_hold_addr;
    reg w_hold_valid;
    reg [C_S_AXI_DATA_WIDTH-1:0] w_hold_data;
    reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_hold_strb;
    reg [1:0] axi_bresp;
    reg axi_bvalid;
    reg axi_arready;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [1:0] axi_rresp;
    reg axi_rvalid;

    reg done_sticky;
    reg [2:0] result_class_idx;
    reg start_reject_no_frame_sticky;
    reg start_reject_busy_sticky;

    wire slv_reg_wren;
    wire slv_reg_rden;
    wire aw_handshake;
    wire w_handshake;
    wire [REG_ADDR_BITS-1:0] write_index;
    wire [REG_ADDR_BITS-1:0] read_index;
    wire error_any;

    assign S_AXI_AWREADY = !aw_hold_valid && !axi_bvalid;
    assign S_AXI_WREADY = !w_hold_valid && !axi_bvalid;
    assign S_AXI_BRESP = axi_bresp;
    assign S_AXI_BVALID = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA = axi_rdata;
    assign S_AXI_RRESP = axi_rresp;
    assign S_AXI_RVALID = axi_rvalid;

    assign aw_handshake = S_AXI_AWREADY && S_AXI_AWVALID;
    assign w_handshake = S_AXI_WREADY && S_AXI_WVALID;
    assign slv_reg_wren = aw_hold_valid && w_hold_valid && !axi_bvalid;
    assign slv_reg_rden = axi_arready && S_AXI_ARVALID && !axi_rvalid;
    assign write_index = aw_hold_addr[ADDR_LSB+REG_ADDR_BITS-1:ADDR_LSB];
    assign read_index = axi_araddr[ADDR_LSB+REG_ADDR_BITS-1:ADDR_LSB];
    assign error_any = error_early_tlast
        || error_missing_tlast
        || error_bad_keep
        || error_dropped_frame
        || start_reject_no_frame_sticky
        || start_reject_busy_sticky;
    assign irq = irq_enable && done_sticky;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            aw_hold_valid <= 1'b0;
            aw_hold_addr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (slv_reg_wren) begin
                aw_hold_valid <= 1'b0;
            end else if (aw_handshake) begin
                aw_hold_valid <= 1'b1;
                aw_hold_addr <= S_AXI_AWADDR;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            w_hold_valid <= 1'b0;
            w_hold_data <= {C_S_AXI_DATA_WIDTH{1'b0}};
            w_hold_strb <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
        end else begin
            if (slv_reg_wren) begin
                w_hold_valid <= 1'b0;
            end else if (w_handshake) begin
                w_hold_valid <= 1'b1;
                w_hold_data <= S_AXI_WDATA;
                w_hold_strb <= S_AXI_WSTRB;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_bvalid <= 1'b0;
            axi_bresp <= 2'b00;
        end else begin
            if (slv_reg_wren && !axi_bvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp <= 2'b00;
            end else if (axi_bvalid && S_AXI_BREADY) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            start_pulse <= 1'b0;
            auto_start <= 1'b0;
            clear_errors_pulse <= 1'b0;
            irq_enable <= 1'b0;
            done_sticky <= 1'b0;
            result_class_idx <= 3'd0;
            start_reject_no_frame_sticky <= 1'b0;
            start_reject_busy_sticky <= 1'b0;
        end else begin
            start_pulse <= 1'b0;
            clear_errors_pulse <= 1'b0;

            if (slv_reg_wren && write_index == 4'd0 && w_hold_strb[0]) begin
                start_pulse <= w_hold_data[0];
                if (w_hold_data[1]) begin
                    done_sticky <= 1'b0;
                end
                clear_errors_pulse <= w_hold_data[2];
                if (w_hold_data[2]) begin
                    start_reject_no_frame_sticky <= 1'b0;
                    start_reject_busy_sticky <= 1'b0;
                end
            end

            if (slv_reg_wren && write_index == 4'd8 && w_hold_strb[0]) begin
                auto_start <= w_hold_data[0];
                irq_enable <= w_hold_data[1];
            end

            if (start_accept) begin
                done_sticky <= 1'b0;
            end
            if (start_reject_no_frame) begin
                start_reject_no_frame_sticky <= 1'b1;
            end
            if (start_reject_busy) begin
                start_reject_busy_sticky <= 1'b1;
            end
            if (core_class_valid) begin
                result_class_idx <= core_class_idx;
            end
            if (core_done) begin
                done_sticky <= 1'b1;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_arready <= 1'b0;
            axi_araddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (!axi_arready && S_AXI_ARVALID && !axi_rvalid) begin
                axi_arready <= 1'b1;
                axi_araddr <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_rvalid <= 1'b0;
            axi_rresp <= 2'b00;
            axi_rdata <= {C_S_AXI_DATA_WIDTH{1'b0}};
        end else begin
            if (slv_reg_rden) begin
                axi_rvalid <= 1'b1;
                axi_rresp <= 2'b00;
                case (read_index)
                    4'd0: axi_rdata <= {C_S_AXI_DATA_WIDTH{1'b0}};
                    4'd1: axi_rdata <= {
                        22'd0,
                        error_any,
                        start_reject_busy_sticky,
                        start_reject_no_frame_sticky,
                        irq,
                        core_class_valid,
                        act_wr_ready,
                        rx_active,
                        frame_ready,
                        done_sticky,
                        core_busy
                    };
                    4'd2: axi_rdata <= {29'd0, result_class_idx};
                    4'd3: axi_rdata <= {FRAME_BYTES[15:0], FRAME_WORDS[15:0]};
                    4'd4: axi_rdata <= {frame_count, beat_count};
                    4'd5: axi_rdata <= {
                        26'd0,
                        start_reject_busy_sticky,
                        start_reject_no_frame_sticky,
                        error_dropped_frame,
                        error_bad_keep,
                        error_missing_tlast,
                        error_early_tlast
                    };
                    4'd6: axi_rdata <= inference_cycles;
                    4'd7: axi_rdata <= IP_VERSION;
                    4'd8: axi_rdata <= {30'd0, irq_enable, auto_start};
                    default: axi_rdata <= {C_S_AXI_DATA_WIDTH{1'b0}};
                endcase
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
