
`timescale 1 ns / 1 ps

	module emg_accelerator_axi_v1_0_S00_AXI #
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

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
		output wire irq,
		output wire accelerator_busy,
		output wire accelerator_done_sticky,
		output wire accelerator_class_valid_sticky,
		output wire [2:0] accelerator_class_idx,

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 2;
	//----------------------------------------------
	//-- AXI-visible register map.
	//------------------------------------------------
	// Address 0x00, slv_reg0, CTRL:
	//   CPU write bit0=1: start one inference if accelerator is idle.
	//   CPU write bit1=1: clear sticky done/class/error status bits.
	//   Readback is only the last CPU-written CTRL word; start itself is a
	//   one-cycle pulse generated below, not a level held by slv_reg0[0].
	//
	// Address 0x04, STATUS:
	//   Read-only dynamic value, not slv_reg1 storage:
	//     bit0 accelerator busy
	//     bit1 done sticky
	//     bit2 class_valid sticky
	//     bit3 activation write ready
	//     bit4 irq pending
	//     bit5 activation write error sticky
	//   CPU write bit1/bit2/bit5 clears those sticky bits.
	//
	// Address 0x08, CLASS:
	//   Read-only dynamic value, not slv_reg2 storage:
	//     bits[2:0] last class index latched when accelerator class_valid=1.
	//
	// Address 0x0C, slv_reg3, ACT_ADDR:
	//   CPU writes the accelerator activation RAM word address.
	//
	// Address 0x10, slv_reg4, ACT_DATA_LO:
	//   CPU writes activation word bits[31:0].
	//
	// Address 0x14, slv_reg5, ACT_DATA_HI / COMMIT:
	//   CPU writes activation word bits[63:32]. This same write commits
	//   {S_AXI_WDATA, slv_reg4} to accelerator.act_wr_data and pulses
	//   accelerator.act_wr_en for one cycle if act_wr_ready=1.
	//
	// Address 0x18, slv_reg6, IRQ_ENABLE:
	//   CPU write bit0=1 enables irq output when done_sticky=1.
	//
	// Address 0x1C, VERSION:
	//   Read-only constant 0x00010000. slv_reg7 storage is unused.
	//
	// Only slv_reg0/slv_reg3/slv_reg4/slv_reg5/slv_reg6 are real CPU-writable
	// holding registers. slv_reg1/slv_reg2/slv_reg7 remain from the Vivado
	// template, but their addresses are read through status_reg_value,
	// class_reg_value, and version_reg_value instead of the raw slv_reg storage.
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;
	reg done_sticky;
	reg class_valid_sticky;
	reg act_wr_error_sticky;
	reg [2:0] class_idx_reg;
	wire irq_pending;
	wire [C_S_AXI_DATA_WIDTH-1:0] status_reg_value;
	wire [C_S_AXI_DATA_WIDTH-1:0] class_reg_value;
	wire [C_S_AXI_DATA_WIDTH-1:0] version_reg_value;
	reg accel_start;
	reg accel_act_wr_en;
	reg [ACT_ADDR_W-1:0] accel_act_wr_addr;
	reg [ROWS*DATA_W-1:0] accel_act_wr_data;
	wire accel_busy;
	wire accel_done;
	wire accel_act_wr_ready;
	wire accel_class_valid;
	wire [2:0] accel_class_idx;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	assign irq_pending = slv_reg6[0] && done_sticky;
	assign irq = irq_pending;
	assign accelerator_busy = accel_busy;
	assign accelerator_done_sticky = done_sticky;
	assign accelerator_class_valid_sticky = class_valid_sticky;
	assign accelerator_class_idx = class_idx_reg;
	assign status_reg_value = {
		26'd0,
		act_wr_error_sticky,
		irq_pending,
		accel_act_wr_ready,
		class_valid_sticky,
		done_sticky,
		accel_busy
	};
	assign class_reg_value = {29'd0, class_idx_reg};
	assign version_reg_value = 32'h0001_0000;

	accelerator #(
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
		.ACT_ADDR_W(ACT_ADDR_W)
	) u_accelerator (
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.start(accel_start),
		.busy(accel_busy),
		.done(accel_done),
		.act_wr_en(accel_act_wr_en),
		.act_wr_addr(accel_act_wr_addr),
		.act_wr_data(accel_act_wr_data),
		.act_wr_ready(accel_act_wr_ready),
		.class_valid(accel_class_valid),
		.class_idx(accel_class_idx)
	);

	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	// CPU-writable register storage.
	//
	// The branches below look similar because AXI4-Lite writes a 32-bit word
	// with byte strobes no matter what the register means. This block only
	// stores the bytes for writable holding registers. Command side effects
	// such as start pulses, sticky clears, and activation commits are handled
	// in the next always block so each signal still has one sequential owner.
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	      slv_reg4 <= 0;
	      slv_reg5 <= 0;
	      slv_reg6 <= 0;
	      slv_reg7 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          3'h0: // CTRL: stores the last CPU command word for readback.
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          3'h1: begin
	            // STATUS is not stored in slv_reg1. Writes here are ignored
	            // by storage and interpreted below as write-1-to-clear bits.
	          end
	          3'h2: begin
	            // CLASS is not stored in slv_reg2. Reads return class_idx_reg.
	          end
	          3'h3: // ACT_ADDR: activation RAM word address.
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          3'h4: // ACT_DATA_LO: activation word bits[31:0].
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          3'h5: // ACT_DATA_HI: activation word bits[63:32] and commit.
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          3'h6: // IRQ_ENABLE: bit0 enables done interrupt/status.
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          3'h7: begin
	            // VERSION is not stored in slv_reg7. Reads return a constant.
	          end
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                      slv_reg4 <= slv_reg4;
	                      slv_reg5 <= slv_reg5;
	                      slv_reg6 <= slv_reg6;
	                      slv_reg7 <= slv_reg7;
	                    end
	        endcase
	      end
	  end
	end    

	// Register side effects and accelerator status capture.
	//
	// This block translates accepted AXI writes into accelerator-facing
	// one-cycle pulses and sticky software-visible state:
	//   - CTRL[0] write creates accel_start for one cycle.
	//   - CTRL[1] or STATUS write-1-to-clear clears sticky status bits.
	//   - ACT_DATA_HI write commits the 64-bit activation word to accelerator.
	// It owns accel_start/accel_act_wr_en and sticky status registers, while
	// the storage block above owns only slv_reg* holding registers.
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      accel_start <= 1'b0;
	      accel_act_wr_en <= 1'b0;
	      accel_act_wr_addr <= {ACT_ADDR_W{1'b0}};
	      accel_act_wr_data <= {(ROWS*DATA_W){1'b0}};
	      done_sticky <= 1'b0;
	      class_valid_sticky <= 1'b0;
	      act_wr_error_sticky <= 1'b0;
	      class_idx_reg <= 3'd0;
	    end
	  else
	    begin
	      accel_start <= 1'b0;
	      accel_act_wr_en <= 1'b0;

	      if (accel_done)
	        begin
	          // Hold done for software polling until CPU clears it.
	          done_sticky <= 1'b1;
	        end

	      if (accel_class_valid)
	        begin
	          // Latch the final class so software can read it later.
	          class_valid_sticky <= 1'b1;
	          class_idx_reg <= accel_class_idx;
	        end

	      if (slv_reg_wren)
	        begin
	          case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	            3'h0:
	              begin
	                if (S_AXI_WDATA[0] && !accel_busy)
	                  begin
	                    // CTRL bit0 is a command bit, not a stored level:
	                    // one accepted write produces one start pulse.
	                    accel_start <= 1'b1;
	                    done_sticky <= 1'b0;
	                    class_valid_sticky <= 1'b0;
	                    act_wr_error_sticky <= 1'b0;
	                  end
	                if (S_AXI_WDATA[1])
	                  begin
	                    // CTRL bit1 clears old software-visible completion state.
	                    done_sticky <= 1'b0;
	                    class_valid_sticky <= 1'b0;
	                    act_wr_error_sticky <= 1'b0;
	                  end
	              end
	            3'h1:
	              begin
	                // STATUS is write-1-to-clear for sticky bits only.
	                if (S_AXI_WDATA[1])
	                  begin
	                    done_sticky <= 1'b0;
	                  end
	                if (S_AXI_WDATA[2])
	                  begin
	                    class_valid_sticky <= 1'b0;
	                  end
	                if (S_AXI_WDATA[5])
	                  begin
	                    act_wr_error_sticky <= 1'b0;
	                  end
	              end
	            3'h5:
	              begin
	                if (accel_act_wr_ready)
	                  begin
	                    // Writing ACT_DATA_HI completes one 64-bit activation
	                    // word: low half from ACT_DATA_LO, high half from this
	                    // write data, address from ACT_ADDR.
	                    accel_act_wr_en <= 1'b1;
	                    accel_act_wr_addr <= slv_reg3[ACT_ADDR_W-1:0];
	                    accel_act_wr_data <= {S_AXI_WDATA, slv_reg4};
	                  end
	                else
	                  begin
	                    // Software tried to load activation data while the
	                    // accelerator was not accepting writes.
	                    act_wr_error_sticky <= 1'b1;
	                  end
	              end
	            default:
	              begin
	              end
	          endcase
	        end
	    end
	end

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	  // Address decoding for CPU reads. Read-only dynamic registers bypass
	  // their unused slv_reg storage and return live/sticky state instead.
	  case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	    3'h0   : reg_data_out <= slv_reg0;          // CTRL readback
	    3'h1   : reg_data_out <= status_reg_value;  // STATUS dynamic bits
	    3'h2   : reg_data_out <= class_reg_value;   // CLASS latched result
	    3'h3   : reg_data_out <= slv_reg3;          // ACT_ADDR readback
	    3'h4   : reg_data_out <= slv_reg4;          // ACT_DATA_LO readback
	    3'h5   : reg_data_out <= slv_reg5;          // ACT_DATA_HI readback
	    3'h6   : reg_data_out <= slv_reg6;          // IRQ_ENABLE readback
	    3'h7   : reg_data_out <= version_reg_value; // VERSION constant
	    default : reg_data_out <= 0;
	  endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here

	// User logic ends

	endmodule
