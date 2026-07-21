`timescale 1ns / 1ps

import axi_vip_pkg::*;
import emg_finger_sim_axi_vip_0_0_pkg::*;

module tb_emg_finger_sim;

    localparam xil_axi_ulong DMA_BASE = 32'h8000_0000;
    localparam xil_axi_ulong ACCEL_BASE = 32'h8001_0000;

    localparam xil_axi_ulong DMA_MM2S_DMACR = DMA_BASE + 32'h00;
    localparam xil_axi_ulong DMA_MM2S_DMASR = DMA_BASE + 32'h04;
    localparam xil_axi_ulong DMA_MM2S_SA = DMA_BASE + 32'h18;
    localparam xil_axi_ulong DMA_MM2S_LENGTH = DMA_BASE + 32'h28;

    localparam xil_axi_ulong ACCEL_CONTROL = ACCEL_BASE + 32'h00;
    localparam xil_axi_ulong ACCEL_STATUS = ACCEL_BASE + 32'h04;
    localparam xil_axi_ulong ACCEL_RESULT = ACCEL_BASE + 32'h08;
    localparam xil_axi_ulong ACCEL_ERROR_STATUS = ACCEL_BASE + 32'h14;
    localparam xil_axi_ulong ACCEL_CYCLE_COUNT = ACCEL_BASE + 32'h18;

    localparam bit [31:0] DMA_DMACR_RESET = 32'h0000_0004;
    localparam bit [31:0] DMA_DMACR_RUN_IOC_ERR_IRQ = 32'h0000_5001;
    localparam bit [31:0] DMA_DMASR_CLEAR_IRQS = 32'h0000_5000;
    localparam bit [31:0] ACCEL_CONTROL_INIT = 32'h0000_001E;
    localparam bit [31:0] ACCEL_CONTROL_CLEAR_DONE = 32'h0000_0016;

    localparam int FRAME_BYTES = 1740;
    localparam int N_CASES = 4;
    localparam int INITIALIZED_WORDS = N_CASES * FRAME_BYTES / 4;
    localparam int BRAM_WORDS = 16384;
    localparam int IRQ_TIMEOUT_CYCLES = 250000;
    localparam int AXI_POLL_LIMIT = 1000;

    bit clk_100MHz = 1'b0;
    bit reset_rtl_0 = 1'b1;

    wire [2:0] class_id;
    wire class_valid;
    wire inference_done;
    wire inference_busy;
    wire accelerator_irq;
    wire dma_irq;

    bit class_valid_seen;
    bit inference_done_seen;
    bit [2:0] class_id_at_valid;

    bit [31:0] frame_address [0:N_CASES-1];
    bit [2:0] expected_class [0:N_CASES-1];
    int source_case [0:N_CASES-1];
    integer word_index;
    bit [31:0] bram_init_words [0:BRAM_WORDS-1];
    bit bram_porta_en_force;
    bit [3:0] bram_porta_we_force;
    bit [15:0] bram_porta_addr_force;
    bit [31:0] bram_porta_din_force;

    emg_finger_sim_axi_vip_0_0_mst_t control_master;

    emg_finger_sim_wrapper dut (
        .accelerator_irq(accelerator_irq),
        .class_id(class_id),
        .class_valid(class_valid),
        .clk_100MHz(clk_100MHz),
        .dma_irq(dma_irq),
        .inference_busy(inference_busy),
        .inference_done(inference_done),
        .reset_rtl_0(reset_rtl_0)
    );

    always #5 clk_100MHz = ~clk_100MHz;

    always @(posedge clk_100MHz) begin
        if (class_valid) begin
            class_valid_seen <= 1'b1;
            class_id_at_valid <= class_id;
        end
        if (inference_done) begin
            inference_done_seen <= 1'b1;
        end
    end

    task automatic axi_write(input xil_axi_ulong address, input bit [31:0] value);
        bit [63:0] write_data;
        xil_axi_resp_t response;
        begin
            write_data = 64'd0;
            write_data[31:0] = value;
            control_master.AXI4LITE_WRITE_BURST(address, 3'b000, write_data, response);
            if (response != XIL_AXI_RESP_OKAY) begin
                $fatal(1, "AXI-Lite write failed address=0x%08h data=0x%08h response=%0d",
                    address[31:0], value, response);
            end
        end
    endtask

    task automatic axi_read(input xil_axi_ulong address, output bit [31:0] value);
        bit [63:0] read_data;
        xil_axi_resp_t response;
        begin
            read_data = 64'd0;
            control_master.AXI4LITE_READ_BURST(address, 3'b000, read_data, response);
            if (response != XIL_AXI_RESP_OKAY) begin
                $fatal(1, "AXI-Lite read failed address=0x%08h response=%0d",
                    address[31:0], response);
            end
            value = read_data[31:0];
        end
    endtask

    task automatic initialize_dma;
        bit [31:0] status;
        int poll_count;
        begin
            axi_write(DMA_MM2S_DMACR, DMA_DMACR_RESET);
            status = DMA_DMACR_RESET;
            poll_count = 0;
            while (status[2] && poll_count < AXI_POLL_LIMIT) begin
                axi_read(DMA_MM2S_DMACR, status);
                poll_count++;
            end
            if (status[2]) begin
                $fatal(1, "AXI DMA reset did not complete");
            end
            axi_write(DMA_MM2S_DMASR, DMA_DMASR_CLEAR_IRQS);
            axi_write(DMA_MM2S_DMACR, DMA_DMACR_RUN_IOC_ERR_IRQ);
            axi_read(DMA_MM2S_DMACR, status);
            if (!status[0]) begin
                $fatal(1, "AXI DMA MM2S channel did not enter run state: DMACR=0x%08h", status);
            end
        end
    endtask

    task automatic initialize_input_bram;
        begin
            $readmemh("emg_representative_4cases.mem", bram_init_words);
            if (^bram_init_words[0] === 1'bx) begin
                $fatal(1, "BRAM input initialization file was not loaded");
            end

            bram_porta_en_force = 1'b0;
            bram_porta_we_force = 4'h0;
            bram_porta_addr_force = 16'd0;
            bram_porta_din_force = 32'd0;
            force dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_EN = bram_porta_en_force;
            force dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_WE = bram_porta_we_force;
            force dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_ADDR = bram_porta_addr_force;
            force dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_DIN = bram_porta_din_force;

            repeat (2) @(posedge dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_CLK);
            for (word_index = 0; word_index < INITIALIZED_WORDS; word_index = word_index + 1) begin
                @(negedge dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_CLK);
                bram_porta_en_force = 1'b1;
                bram_porta_we_force = 4'hF;
                bram_porta_addr_force = word_index * 4;
                bram_porta_din_force = bram_init_words[word_index];
                @(posedge dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_CLK);
            end

            @(negedge dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_CLK);
            bram_porta_en_force = 1'b0;
            bram_porta_we_force = 4'h0;
            @(posedge dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_CLK);

            release dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_DIN;
            release dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_ADDR;
            release dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_WE;
            release dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_EN;

            repeat (4) @(posedge dut.emg_finger_sim_i.axi_bram_ctrl_0_BRAM_PORTA_CLK);
            $display("Initialized input BRAM with %0d words for %0d representative cases",
                INITIALIZED_WORDS, N_CASES);
        end
    endtask

    task automatic wait_for_irq(
        input string irq_name,
        input bit select_accelerator_irq
    );
        int timeout_count;
        bit irq_value;
        begin
            timeout_count = 0;
            irq_value = select_accelerator_irq ? accelerator_irq : dma_irq;
            while (!irq_value && timeout_count < IRQ_TIMEOUT_CYCLES) begin
                @(posedge clk_100MHz);
                timeout_count++;
                irq_value = select_accelerator_irq ? accelerator_irq : dma_irq;
            end
            if (!irq_value) begin
                $fatal(1, "%s timeout after %0d cycles", irq_name, IRQ_TIMEOUT_CYCLES);
            end
        end
    endtask

    task automatic wait_for_irqs_low;
        int timeout_count;
        begin
            timeout_count = 0;
            while ((dma_irq || accelerator_irq) && timeout_count < AXI_POLL_LIMIT) begin
                @(posedge clk_100MHz);
                timeout_count++;
            end
            if (dma_irq || accelerator_irq) begin
                $fatal(1, "interrupts did not clear dma_irq=%0b accelerator_irq=%0b",
                    dma_irq, accelerator_irq);
            end
        end
    endtask

    task automatic run_case(input int packed_case_index);
        bit [31:0] dma_status;
        bit [31:0] accel_status;
        bit [31:0] accel_result;
        bit [31:0] accel_error;
        bit [31:0] cycle_count;
        begin
            class_valid_seen = 1'b0;
            inference_done_seen = 1'b0;
            class_id_at_valid = 3'd0;

            axi_write(ACCEL_CONTROL, ACCEL_CONTROL_INIT);
            axi_write(DMA_MM2S_DMASR, DMA_DMASR_CLEAR_IRQS);
            axi_write(DMA_MM2S_SA, frame_address[packed_case_index]);
            axi_write(DMA_MM2S_LENGTH, FRAME_BYTES);

            wait_for_irq("DMA MM2S interrupt", 1'b0);
            wait_for_irq("Accelerator interrupt", 1'b1);

            axi_read(DMA_MM2S_DMASR, dma_status);
            axi_read(ACCEL_STATUS, accel_status);
            axi_read(ACCEL_RESULT, accel_result);
            axi_read(ACCEL_ERROR_STATUS, accel_error);
            axi_read(ACCEL_CYCLE_COUNT, cycle_count);

            if (dma_status[6:4] != 3'b000 || dma_status[14]) begin
                $fatal(1, "DMA error source_case=%0d DMASR=0x%08h",
                    source_case[packed_case_index], dma_status);
            end
            if (!dma_status[12]) begin
                $fatal(1, "DMA IOC status missing source_case=%0d DMASR=0x%08h",
                    source_case[packed_case_index], dma_status);
            end
            if (!accel_status[1] || accel_status[0]) begin
                $fatal(1, "Accelerator completion status invalid source_case=%0d STATUS=0x%08h",
                    source_case[packed_case_index], accel_status);
            end
            if (accel_error != 32'd0) begin
                $fatal(1, "Accelerator error source_case=%0d ERROR_STATUS=0x%08h",
                    source_case[packed_case_index], accel_error);
            end
            if (accel_result[2:0] != expected_class[packed_case_index]) begin
                $fatal(1, "RESULT mismatch source_case=%0d got=%0d expected=%0d",
                    source_case[packed_case_index], accel_result[2:0],
                    expected_class[packed_case_index]);
            end
            if (class_id != expected_class[packed_case_index]) begin
                $fatal(1, "class_id mismatch source_case=%0d got=%0d expected=%0d",
                    source_case[packed_case_index], class_id,
                    expected_class[packed_case_index]);
            end
            if (!class_valid_seen || class_id_at_valid != expected_class[packed_case_index]) begin
                $fatal(1, "class_valid output mismatch source_case=%0d seen=%0b class=%0d expected=%0d",
                    source_case[packed_case_index], class_valid_seen, class_id_at_valid,
                    expected_class[packed_case_index]);
            end
            if (!inference_done_seen) begin
                $fatal(1, "inference_done pulse was not observed source_case=%0d",
                    source_case[packed_case_index]);
            end

            $display(
                "PASS representative case packed=%0d source=%0d address=0x%08h class=%0d cycles=%0d",
                packed_case_index, source_case[packed_case_index],
                frame_address[packed_case_index], accel_result[2:0], cycle_count
            );

            axi_write(DMA_MM2S_DMASR, DMA_DMASR_CLEAR_IRQS);
            axi_write(ACCEL_CONTROL, ACCEL_CONTROL_CLEAR_DONE);
            wait_for_irqs_low();
        end
    endtask

    initial begin
        frame_address[0] = 32'h0000_0000;
        frame_address[1] = 32'h0000_06CC;
        frame_address[2] = 32'h0000_0D98;
        frame_address[3] = 32'h0000_1464;

        source_case[0] = 6;
        source_case[1] = 8;
        source_case[2] = 0;
        source_case[3] = 2;

        expected_class[0] = 3'd1;
        expected_class[1] = 3'd2;
        expected_class[2] = 3'd3;
        expected_class[3] = 3'd4;

        control_master = new(
            "emg_finger_sim control master",
            dut.emg_finger_sim_i.axi_vip_0.inst.IF
        );
        control_master.vif_proxy.set_dummy_drive_type(XIL_AXI_VIF_DRIVE_NONE);
        control_master.set_agent_tag("Control AXI VIP");
        control_master.set_verbosity(0);
        control_master.start_master();

        #200ns;
        reset_rtl_0 = 1'b0;
        wait (dut.emg_finger_sim_i.rst_clk_wiz_100M_peripheral_aresetn === 1'b1);
        repeat (20) @(posedge clk_100MHz);

        initialize_input_bram();
        initialize_dma();
        for (int case_index = 0; case_index < N_CASES; case_index++) begin
            run_case(case_index);
        end

        $display("PASS all %0d representative BD DMA test cases", N_CASES);
        $finish;
    end

endmodule
