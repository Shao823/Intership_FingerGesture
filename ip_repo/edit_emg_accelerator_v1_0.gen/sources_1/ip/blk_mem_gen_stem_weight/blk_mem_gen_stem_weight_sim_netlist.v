// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Fri Jul 17 12:21:47 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Intership/ip_repo/edit_emg_accelerator_v1_0.gen/sources_1/ip/blk_mem_gen_stem_weight/blk_mem_gen_stem_weight_sim_netlist.v
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
DtITtgwJCKHu4ZA3H3Ab602UR/LGkYvLHw==
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
