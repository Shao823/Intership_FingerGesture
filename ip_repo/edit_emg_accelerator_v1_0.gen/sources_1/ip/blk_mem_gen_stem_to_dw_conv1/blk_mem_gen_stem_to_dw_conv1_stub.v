// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Fri Jul 17 16:11:50 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/Intership/ip_repo/edit_emg_accelerator_v1_0.gen/sources_1/ip/blk_mem_gen_stem_to_dw_conv1/blk_mem_gen_stem_to_dw_conv1_stub.v
// Design      : blk_mem_gen_stem_to_dw_conv1
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu7ev-ffvc1156-1-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *)
module blk_mem_gen_stem_to_dw_conv1(clka, ena, wea, addra, dina, clkb, enb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[5:0],dina[31:0],clkb,enb,addrb[5:0],doutb[31:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [5:0]addra;
  input [31:0]dina;
  input clkb;
  input enb;
  input [5:0]addrb;
  output [31:0]doutb;
endmodule
