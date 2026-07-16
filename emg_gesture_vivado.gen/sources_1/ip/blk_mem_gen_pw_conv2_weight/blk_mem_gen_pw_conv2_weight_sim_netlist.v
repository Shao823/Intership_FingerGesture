// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Thu Jul 16 14:25:11 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Intership/emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_pw_conv2_weight/blk_mem_gen_pw_conv2_weight_sim_netlist.v
// Design      : blk_mem_gen_pw_conv2_weight
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu7ev-ffvc1156-1-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_pw_conv2_weight,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_pw_conv2_weight
   (clka,
    ena,
    addra,
    douta);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [8:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [95:0]douta;

  wire [8:0]addra;
  wire clka;
  wire [95:0]douta;
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
  wire [95:0]NLW_U0_doutb_UNCONNECTED;
  wire [8:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [8:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [95:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "9" *) 
  (* C_ADDRB_WIDTH = "9" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "1" *) 
  (* C_COUNT_36K_BRAM = "1" *) 
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
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     9.013672 mW" *) 
  (* C_FAMILY = "zynquplus" *) 
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
  (* C_INIT_FILE = "blk_mem_gen_pw_conv2_weight.mem" *) 
  (* C_INIT_FILE_NAME = "blk_mem_gen_pw_conv2_weight.mif" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "1" *) 
  (* C_MEM_TYPE = "3" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "512" *) 
  (* C_READ_DEPTH_B = "512" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "96" *) 
  (* C_READ_WIDTH_B = "96" *) 
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
  (* C_WRITE_DEPTH_A = "512" *) 
  (* C_WRITE_DEPTH_B = "512" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "96" *) 
  (* C_WRITE_WIDTH_B = "96" *) 
  (* C_XDEVICEFAMILY = "zynquplus" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_pw_conv2_weight_blk_mem_gen_v8_4_5 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[95:0]),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(1'b0),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[8:0]),
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
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[8:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[95:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 44896)
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
