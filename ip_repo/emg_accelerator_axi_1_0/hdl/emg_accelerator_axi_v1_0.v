
`timescale 1 ns / 1 ps

	module emg_accelerator_axi_v1_0 #
	(
		// Users to add parameters here
		parameter integer DATA_W     = 16,
		parameter integer ACC_W      = 48,
		parameter integer ROWS       = 4,
		parameter integer STEM_OC_LANES = 4,
		parameter integer PW1_OC_LANES  = 8,
		parameter integer PW2_OC_LANES  = 12,
		parameter integer FC_AVG_LANES  = 12,
		parameter integer POOL_ROWS  = 2,
		parameter integer CH_LANES   = 4,
		parameter integer STEM_OC    = 32,
		parameter integer PW1_OC     = 64,
		parameter integer PW2_OC     = 96,
		parameter integer FC_CLASSES = 5,
		parameter integer STEM_K     = 35,
		parameter integer STEM_IC    = 5,
		parameter integer STEM_KERNEL = 7,
		parameter integer STEM_PADDING = 3,
		parameter integer DW_K       = 5,
		parameter integer DW_PAD     = 2,
		parameter integer INPUT_LEN  = 348,
		parameter integer FRAC_BITS  = 8,
		parameter integer TIME_W     = 9,
		parameter integer ROWS_W     = 4,
		parameter integer LOW_TIME_W = 8,
		parameter integer DW2_ROWS_W = 3,
		parameter integer STEM_TO_DW1_RING_ROWS = 8,
		parameter integer DW1_TO_PW1_RING_ROWS  = 16,
		parameter integer PW1_TO_DW2_RING_ROWS  = 8,
		parameter integer DW2_TO_PW2_RING_ROWS  = 8,
		parameter integer PENDING_DEPTH = 8,
		parameter integer DW2_PENDING_DEPTH = 32,
		parameter integer BRAM_READ_LATENCY = 1,
		parameter integer POOL_LEN   = INPUT_LEN / 2,
		parameter integer CH_GROUPS  = STEM_OC / STEM_OC_LANES,
		parameter integer ACT_TIME_WORDS = (INPUT_LEN + ROWS - 1) / ROWS,
		parameter integer ACT_RAM_DEPTH  = STEM_IC * ACT_TIME_WORDS,
		parameter integer ACT_ADDR_W     = (ACT_RAM_DEPTH <= 1)
			? 1 : $clog2(ACT_RAM_DEPTH),

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5
	)
    (
		// Users to add ports here
		// Sideband outputs for the block design. The same state is also
		// readable through S00_AXI; these ports are for IRQ wiring or ILA/debug.
		output wire irq,
		output wire accelerator_busy,
		output wire accelerator_done_sticky,
		output wire accelerator_class_valid_sticky,
		output wire [2:0] accelerator_class_idx,

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);

// Instantiation of Axi Bus Interface S00_AXI
	emg_accelerator_axi_v1_0_S00_AXI # ( 
		.DATA_W(DATA_W),
		.ACC_W(ACC_W),
		.ROWS(ROWS),
		.STEM_OC_LANES(STEM_OC_LANES),
		.PW1_OC_LANES(PW1_OC_LANES),
		.PW2_OC_LANES(PW2_OC_LANES),
		.FC_AVG_LANES(FC_AVG_LANES),
		.POOL_ROWS(POOL_ROWS),
		.CH_LANES(CH_LANES),
		.STEM_OC(STEM_OC),
		.PW1_OC(PW1_OC),
		.PW2_OC(PW2_OC),
		.FC_CLASSES(FC_CLASSES),
		.STEM_K(STEM_K),
		.STEM_IC(STEM_IC),
		.STEM_KERNEL(STEM_KERNEL),
		.STEM_PADDING(STEM_PADDING),
		.DW_K(DW_K),
		.DW_PAD(DW_PAD),
		.INPUT_LEN(INPUT_LEN),
		.FRAC_BITS(FRAC_BITS),
		.TIME_W(TIME_W),
		.ROWS_W(ROWS_W),
		.LOW_TIME_W(LOW_TIME_W),
		.DW2_ROWS_W(DW2_ROWS_W),
		.STEM_TO_DW1_RING_ROWS(STEM_TO_DW1_RING_ROWS),
		.DW1_TO_PW1_RING_ROWS(DW1_TO_PW1_RING_ROWS),
		.PW1_TO_DW2_RING_ROWS(PW1_TO_DW2_RING_ROWS),
		.DW2_TO_PW2_RING_ROWS(DW2_TO_PW2_RING_ROWS),
		.PENDING_DEPTH(PENDING_DEPTH),
		.DW2_PENDING_DEPTH(DW2_PENDING_DEPTH),
		.BRAM_READ_LATENCY(BRAM_READ_LATENCY),
		.POOL_LEN(POOL_LEN),
		.CH_GROUPS(CH_GROUPS),
		.ACT_TIME_WORDS(ACT_TIME_WORDS),
		.ACT_RAM_DEPTH(ACT_RAM_DEPTH),
		.ACT_ADDR_W(ACT_ADDR_W),
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) emg_accelerator_axi_v1_0_S00_AXI_inst (
		.irq(irq),
		.accelerator_busy(accelerator_busy),
		.accelerator_done_sticky(accelerator_done_sticky),
		.accelerator_class_valid_sticky(accelerator_class_valid_sticky),
		.accelerator_class_idx(accelerator_class_idx),
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here
	// User logic is contained in S00_AXI, which owns the register map and
	// directly instantiates the accelerator compute top.

	// User logic ends

	endmodule
