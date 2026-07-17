// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Fri Jul 17 16:08:03 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top blk_mem_gen_dw_to_pw_conv1 -prefix
//               blk_mem_gen_dw_to_pw_conv1_ blk_mem_gen_dw_to_pw_conv2_sim_netlist.v
// Design      : blk_mem_gen_dw_to_pw_conv2
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu7ev-ffvc1156-1-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_dw_to_pw_conv2,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_dw_to_pw_conv1
   (clka,
    ena,
    wea,
    addra,
    dina,
    douta,
    clkb,
    enb,
    web,
    addrb,
    dinb,
    doutb);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [0:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [6:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [31:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [31:0]douta;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTB, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clkb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB EN" *) input enb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB WE" *) input [0:0]web;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *) input [6:0]addrb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DIN" *) input [31:0]dinb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *) output [31:0]doutb;

  wire [6:0]addra;
  wire [6:0]addrb;
  wire clka;
  wire clkb;
  wire [31:0]dina;
  wire [31:0]dinb;
  wire [31:0]douta;
  wire [31:0]doutb;
  wire ena;
  wire enb;
  wire [0:0]wea;
  wire [0:0]web;
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
  wire [6:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [6:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "7" *) 
  (* C_ADDRB_WIDTH = "7" *) 
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
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     4.238151 mW" *) 
  (* C_FAMILY = "zynquplus" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "1" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "1" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "1" *) 
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
  (* C_INIT_FILE = "blk_mem_gen_dw_to_pw_conv2.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "2" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "128" *) 
  (* C_READ_DEPTH_B = "128" *) 
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
  (* C_WRITE_DEPTH_A = "128" *) 
  (* C_WRITE_DEPTH_B = "128" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "32" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "zynquplus" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_dw_to_pw_conv1_blk_mem_gen_v8_4_5 U0
       (.addra(addra),
        .addrb(addrb),
        .clka(clka),
        .clkb(clkb),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb(dinb),
        .douta(douta),
        .doutb(doutb),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(enb),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[6:0]),
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
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[6:0]),
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
        .wea(wea),
        .web(web));
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 30496)
`pragma protect data_block
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
Pw==
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
