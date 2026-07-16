// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Thu Jul 16 14:24:22 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Intership/emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_pw_conv1_weight/blk_mem_gen_pw_conv1_weight_sim_netlist.v
// Design      : blk_mem_gen_pw_conv1_weight
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu7ev-ffvc1156-1-i
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
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [63:0]douta;

  wire [7:0]addra;
  wire clka;
  wire [63:0]douta;
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
  wire [63:0]NLW_U0_doutb_UNCONNECTED;
  wire [7:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [7:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [63:0]NLW_U0_s_axi_rdata_UNCONNECTED;
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
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     5.831765 mW" *) 
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
  (* C_READ_WIDTH_A = "64" *) 
  (* C_READ_WIDTH_B = "64" *) 
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
  (* C_WRITE_WIDTH_A = "64" *) 
  (* C_WRITE_WIDTH_B = "64" *) 
  (* C_XDEVICEFAMILY = "zynquplus" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_pw_conv1_weight_blk_mem_gen_v8_4_5 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[63:0]),
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
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[63:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 31568)
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
