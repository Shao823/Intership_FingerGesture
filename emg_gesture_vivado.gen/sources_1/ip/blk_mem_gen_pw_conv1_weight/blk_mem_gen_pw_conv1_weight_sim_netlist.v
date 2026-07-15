// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Tue Jul 14 13:02:36 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Intership/emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_pw_conv1_weight/blk_mem_gen_pw_conv1_weight_sim_netlist.v
// Design      : blk_mem_gen_pw_conv1_weight
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k70tfbv676-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_pw_conv1_weight,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_pw_conv1_weight
   (clka,
    ena,
    addra,
    douta);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [7:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [127:0]douta;

  wire [7:0]addra;
  wire clka;
  wire [127:0]douta;
  wire ena;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rsta_busy_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [127:0]NLW_U0_doutb_UNCONNECTED;
  wire [7:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [7:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [127:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "8" *) 
  (* C_ADDRB_WIDTH = "8" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "0" *) 
  (* C_COUNT_36K_BRAM = "2" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     12.7408 mW" *) 
  (* C_FAMILY = "kintex7" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "0" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "1" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "blk_mem_gen_pw_conv1_weight.mem" *) 
  (* C_INIT_FILE_NAME = "blk_mem_gen_pw_conv1_weight.mif" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "1" *) 
  (* C_MEM_TYPE = "3" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "256" *) 
  (* C_READ_DEPTH_B = "256" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "128" *) 
  (* C_READ_WIDTH_B = "128" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "256" *) 
  (* C_WRITE_DEPTH_B = "256" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "128" *) 
  (* C_WRITE_WIDTH_B = "128" *) 
  (* C_XDEVICEFAMILY = "kintex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_pw_conv1_weight_blk_mem_gen_v8_4_5 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[127:0]),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(1'b0),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[7:0]),
        .regcea(1'b0),
        .regceb(1'b0),
        .rsta(1'b0),
        .rsta_busy(NLW_U0_rsta_busy_UNCONNECTED),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[7:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[127:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(1'b0),
        .web(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2022.2"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
VHPlDkoDlWlBfBMvPBmGYmaek3s9hXXhjF28kllYPnaNm3TSnzzpXHWHc8Ye9/2L2yiQfJ1hTWou
Ia/zeQ8h9/dtr6QB5YkyW4wlb/LbMgXb+DGIXPSllNl0IMsRQIcQDbcQm1bO/nlhb+2pjxiuaQrl
DbvxoDwPs7z3LunRxsg=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
lmIhoX8hXuc7tNV1sXY1K2/gXL7Y7Hq73qQF7+x03UWWTRd3uhGmVQtOMVbhIW+66UkWUHiD26zL
fzqGor8bgSNGpSFyS11k4TwLQT4OfAMGO8C9Qmmh4+VENBnpS9TW+wHzCv8oUwht7xYtYRZvOvYK
F3fMppz2sBkUd1lciw98ZE/UmNkhqBuMfIYF43j45DEJ55PBhOZNg91Ls4v3qBHyBAaYPFFoMry3
d5Fw1PZyFQSEOSSpwgyds2aN0g6oIwl7zm0LJrM9VDAOxBUE50hk+oHr4jj8J8UhHQJnlEHm1Idm
rvxKygNKRvfSpa90NYxZJFYgqnrMYg+19+9aZA==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
VkyCjO2onoeZWEoYQ/4ue7X5mkHyTYVW9xjdoTsGS4GdP/Q64VaCZL/jr6R8DVDXPMnH7tRMrDpo
jpYBnyzSgOkfgqM+96ioC2fDyAaG4gYgGLmrBR6qK3/mxXwAZZX+GJ9R/eWXkc9h8xN+gsSSX6/M
jIQCgeT6q7PB4dWT6KY=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Iub91V+TnhVlZCSLu6iKmFjix71y6/l83OPTs8uewWvkE7WcqYxEKi9fonXEkzAtWzuKwEUqnOlN
VBsNJqPUdKcd22q523mrdt89mpdosWD+hvZdO7ELhJniY5u9h49FFkubpN2JiUTcIcKEYxVNlds4
wyvaYUqbPVH5v2ooJwDdimS4GVn9HerCOgPwfshvQDNlMTxLcYju4v8BHMc5Rub9Q/ihvpQU74v2
ouZ9XIwA+C6pBLwvaqS8jE7HXOokgqJilaX/W/t+KEgiFry/txRTMU9WMD7tCN7lcfjCydmS3Lq+
3u6Hsr0S8BwNjcaDpZDnBTygUJd4JSqREnk33w==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
U46EWFmKmpZGaWfyL+dokyQtJtaOYsa7HCW/+fdtw9/yHKTWFpmqKBZngBj5rPkNhtTDDCJkqsYj
tUXg1j4tgIBaCQn9B0q/aG+B3gPLrudp9hLL25mVbsfiTzdekiV2hJMmhuMoavKKPJHC6zyW7kZi
80er82OQy8h+Df/fe6TRjH9xEt3/b80tRKUMbxkLfnnkAyyf1KfOhB6/uyI4mwXuQR+DsAbzybKR
YtXpOiW72tGrXTFlzcwbHamWZefqsilVpBw6V5dh33vYKGx50xwWpj76maAkpQrOpB7zufeldJe4
W1UOEN84AZdRTLkVSxamWo/wp8nP9fiGS/ItRw==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2021_07", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
qczgIJYpE/SzErzK7eWJBGcDFEzDLm8cKbwJbPXuM6YnJxx44W+E60R3war7K2QGFAkOoCDUtDC7
SghJGF32btaDLzeKm0tQ669sBtQmMIaBrlt7I9QBkNM8zN9GL92qxNC9o3UVWMOYy5BmH8nUPgcE
O6lRubeltlrTuDe7UJQ2nEPHcXjpUJJ8dxktyW+LovBy1OxW8g4GRAsmEJsoOEg0HuDdWcc4IshJ
PvwPJ7LblELAKsdkSt65y9VaklaEm7MlH4ImlgIa74TgRmutLUbWxM1QYhGE5rAzFhGU5i3RJOdx
L3N7GGGvLMW2z9NSHbIFX+/eNII9fNJ9nZbgLA==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Ti1NUgDv8YPk90APMwfu/mRr38QYwAxZfv0T6zQ89YS55t2EquEGVqrEafYX6rTydLOw8le1Oucv
f2oERpSSSTih/ScZneSZmuPE/Zh2BU1Ajv0j+/+0uEWXU+5lLPbDJjnapTmJXih1MYPf0SHpZZmE
BKj2IEBI9MPZlh6bxpa5BWJnyPdAvHf+UNaMXU9+pmbtrzUVebql4mFJu45Z3+ehmFY4FBW3zXMF
44C4TlHACLwL3vHVMCVfeKhgdVDbpE+/IFhTStz7mZ9h9RKGanQcs6YDVM1R+2RKA1QT1fX4FiQc
1V+FGmrm1ujxmFGXwpfNKByVlfCY0oWhRJCYYQ==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
HuEXFK0NXt09xU2yxxjng1OLsT+ZEM4EhqBgpr9D2ljw2vDaMBrqEsRQTc2B9soDq3ewDduHJXBd
OGYxkPnoN6LhjULtB2nTgjcH6NxA4puZ1ZNcndDndVBo8rTW5W1OqHq6InAG0CqPpTIkuqz3ECPl
EysI++MCDfH6tIzlekxJFIJ1McJsTq5rFuLzMMcrmkBxgcayDpOcCFuzZzCczxmt/cCCIKmDybwT
OQXmOcLJoYLP4sFu6R9c6xO8i6p++crv2N3eIxZHKbek9xBBZqQM9EYuEtsbkqAs9XZpa16i5njR
BDFxTKcP6r7JgFALJE89AZhBbate5JXWp0v4ECZD18aEL17CipwcWPutNMdG1apzSPP5y59n7rMG
yxBPz1gKHc3Emkl4WcO0hjICxqmO6dMXoY8JvBSf6ry2l0sH9Ihr3Bq5WWmlhPHnoaNr5jl//vNe
KfToWtn97eoVSt1LnmXXnSpdigbHr0UIg8AdkpdkuNRaWdVicDdgSo49

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
mokwst2bn6UxD6V9UdIgCIG1QQ/d0FiJqYGOTI2eHPV6YElaLjnJ8DnQmZnGS95o3x93FDOoa58C
RwYsX1fVoVtXkj1LuZq0k7q9vEe4T8xMjpkeYtIHY9k0Xhy1Lq/xRlfzGAf9fvf9e+f4r7aR/Sb/
uCZxxugG5niTwLENY1n3NthYL0jvo8Fmdw4Qg0nTCGWlVCws+09K0g9/lx6I9EcuHHemcHO3fOZG
lMc4NaPNozKwnyDMoWUkwiVxyFEPFaQLNYqzjvR+CqrWfhFLo96JWhL+eaDoNuZoBVYQtNH5ZwBL
BoO27Pw10lgcReGlZBz3BLO7T4ddynCx0+eSnw==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
PiP7AjOQqqouyQMoBQqgWIDhUSViq94rIvGiIJ/UKMDspM/yXw1caE8AhWHTjYckC4yLpPAz5P6s
1Z6flzDPrzVwg4e59X2cc4IMCHhedna0rDO804njcc6amRDTeLsMLTkWfvomB4xwszm2AgT+PRnB
WHd09ZUDVFjiBXT+Oa9AicgGJHrX3w823yBPuAa704kje/SzgtiDpcTU1eLmLhLW7LpEd9KIHd9s
ER7Uk9Orws0Kq9PMTqMX4hMn5K5mFakOeOURiEbUjdv5RiIJ2g/PlQXSItM8fHsBTQa6fOaJwQTI
vHwK3a8ZBHpfT1YH+n7wNiNUZwD4SFXm1QVx4g==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Ul5ZfTHJwMctaNhYRortUZizYMPYRef7uYqPSuMkxsArnxI/cjGh+KRMwzV86hyp/6TXSJIjm5ec
2wX2UONdPN+DOJ84jYC4JbgJQrPnTj7ioD8uLX/WlyPcQzyF5keqFgj5eR5s13FskVWCuAWf5m9w
mhFEKFjVXDAr7gVgAJh/hL8P6Psrnf+LGfiM8JhnDepsHEYykGlpD3fzru2BGgqHWqPqFMcnyVGl
vysaIXiJz/eYKvO8RGcgd3DJAM/wPm9A0m/DWcmSnczOgTjoqkHcBg2H5uJMLvufzmjImi6LYEqq
v04ESDEN31cSUzqUYcayvMFOnI/WNsWbFIa5+Q==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 52192)
`pragma protect data_block
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
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
