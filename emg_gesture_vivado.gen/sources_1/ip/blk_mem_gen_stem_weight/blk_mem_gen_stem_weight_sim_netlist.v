// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Thu Jul 16 14:23:26 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Intership/emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_stem_weight/blk_mem_gen_stem_weight_sim_netlist.v
// Design      : blk_mem_gen_stem_weight
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu7ev-ffvc1156-1-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_stem_weight,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_stem_weight
   (clka,
    ena,
    addra,
    douta);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [8:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [31:0]douta;

  wire [8:0]addra;
  wire clka;
  wire [31:0]douta;
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
  wire [31:0]NLW_U0_doutb_UNCONNECTED;
  wire [8:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [8:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdata_UNCONNECTED;
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
  (* C_COUNT_36K_BRAM = "0" *) 
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
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     3.163063 mW" *) 
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
  (* C_INIT_FILE = "blk_mem_gen_stem_weight.mem" *) 
  (* C_INIT_FILE_NAME = "blk_mem_gen_stem_weight.mif" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "1" *) 
  (* C_MEM_TYPE = "3" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "280" *) 
  (* C_READ_DEPTH_B = "280" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "32" *) 
  (* C_READ_WIDTH_B = "32" *) 
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
  (* C_WRITE_DEPTH_A = "280" *) 
  (* C_WRITE_DEPTH_B = "280" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "32" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "zynquplus" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_stem_weight_blk_mem_gen_v8_4_5 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[31:0]),
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
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[31:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 20944)
`pragma protect data_block
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
MfPqLEw8JScC+H1wmWOKNvmSAb3jMUsWfw==
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
