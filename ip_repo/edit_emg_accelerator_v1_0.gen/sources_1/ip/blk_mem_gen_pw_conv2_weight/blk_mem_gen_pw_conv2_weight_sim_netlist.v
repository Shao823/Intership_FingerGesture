// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Fri Jul 17 12:23:30 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Intership/ip_repo/edit_emg_accelerator_v1_0.gen/sources_1/ip/blk_mem_gen_pw_conv2_weight/blk_mem_gen_pw_conv2_weight_sim_netlist.v
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
