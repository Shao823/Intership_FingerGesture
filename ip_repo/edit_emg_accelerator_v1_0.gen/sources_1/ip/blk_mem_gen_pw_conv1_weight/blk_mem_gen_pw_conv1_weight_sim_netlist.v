// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Fri Jul 17 12:22:52 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Intership/ip_repo/edit_emg_accelerator_v1_0.gen/sources_1/ip/blk_mem_gen_pw_conv1_weight/blk_mem_gen_pw_conv1_weight_sim_netlist.v
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
