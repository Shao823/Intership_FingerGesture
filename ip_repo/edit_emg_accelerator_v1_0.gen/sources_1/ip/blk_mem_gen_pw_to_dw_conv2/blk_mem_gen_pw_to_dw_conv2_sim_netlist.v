// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Fri Jul 17 16:08:03 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top blk_mem_gen_pw_to_dw_conv2 -prefix
//               blk_mem_gen_pw_to_dw_conv2_ blk_mem_gen_dw_to_pw_conv2_sim_netlist.v
// Design      : blk_mem_gen_dw_to_pw_conv2
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu7ev-ffvc1156-1-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_dw_to_pw_conv2,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_pw_to_dw_conv2
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
  blk_mem_gen_pw_to_dw_conv2_blk_mem_gen_v8_4_5 U0
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
EOco60BAhrE1yqlvrwMD2P6rm36G9XzgevTKGcJwatZUm9nzg+D7/te+4EM0KvdwW80c9EnTFbSo
9f6Yl5nlBBVBuct87q33Gzo2/F+1VqwR4rjOV430J0QZx7TFEAT6psos5G2k2Wgwnm4vmhrYFbQz
dpR3RlceMxepiz0zYZPrKtQpyC8FdAX5rqDuNZHK6C84K3YY919LOwJtZ/J81b40Ud0rFtAb/CSQ
/We7DJ8pLMBNzEevpA4lW0TeBHqAaDqzv+0zJ9ZKsclspCl3JrGTeWL5zuqg+s8iUtPDQoiHUyc6
att9oClKUAznLAFvbncdtMBHreciL/UNOe2joJ+X5wXeywXZURGkknE7juZcdwTSLvEsa9sXyM6O
J5k1Boj5a3gIxBpML4FGx5DP0G9ba9YOlfjcWtfQ7JiEplebTfVN8Rvwq7ve+XlVf+MCEIwulJpt
1fNu7u6oK0JOCZxtnEapN3H5YZnoYLrHHmp9XAUlEWi8FiTbMFepO1YUhpUXLUkQNYmF6g2CC8ja
NsbTBWzqYHj1oDhTyGHRnkbuzLoTpMEDn+xDOO7BMYkzZ+EsyLPo7c+slFX0oA8nYfwRqpd5gfDn
k9/aWvQ/6fujzqTfrzXaRE4no5CkqHnX+dauh2ouQ98mtfwMmOf4ffvCalnDKnjqWPNr6SLqvlmU
WCuoSBekFYlPGA2XXT0EJ0CSsaRGBWCjcTBc+xoHKBOm5w2mJFkFU2uhgjmDLoiLjDuKG2b5bjLd
IU1e4eTkz7yEl9E0se3+lZ5VWff8xz27tsmDhuV+YBsg28menFpXTTzLzA7KkOAImPcPVXrsFl8N
bSwy2pgJoC4UQgYA2DxrQXad2dOyP59faQ/CcXMt9U3WWCcvcLvRIJP0+CNRBpuJuVh26h2CUeoQ
+C/OQJ4M9qMOXLqFLdeoU6ufAI1SwOCzXOaaFgD46F4JYMZgtPNtf6bUbK0wClyv/+OQAIYDkeiQ
M88MCaJjLyw1RNGqcXGOSvakZwNi+USaQ3WBbLzxVYyLY00dAqOzY78mJnavrp5dbcZNfxTFe1Ni
hHkUmsT20gnFQPWO7KhoGQY6vXgtUYU532CaLbJu659lRrLqnhr6JHDOehsuW3/8/LmocBT3c1Ox
echyboESKx76MSUWIw0O8D1i2ogEJnH4ODL7oKS3DWKbv4Eyr/kXCQWT6S7vJLyvaNNU66PQFHuB
f0YmLvgCluocYn7zWNcEKf+/oDicQU/Mhs7YuKFOfiWWZa6y0teupHQcXkbGPtA2KwjgDBFXg5Er
u/d9YJvEs9t2ngEu84FNQPbEEXN65rMwUWUfHNPICjqs7J5thoDJW1QQ2G/ds5zMW2QaKs1XyG+A
D7zFChjwFN77b2dYMyRdq+7YcxkSe4LzuyTpxDL+ihMPpO9TtzTzSwEbWm2IeRj7jc+qzV9S7iUR
dBwe7sio8FsZzZgePOmn3bEclWPQf8+KhFxiSFfTqHC/DzEJwFHh9OuyMr0tAh30h2et4UxPLOrk
UuyVmC8JjMJGl/6t8lClpNFNfvH7SNQTbEZ0cU3I+cRg6NlIbIVQKauc88J6QEz2fwR1tgngXULh
5CVpbflOc9bc8hnRPpdvTUsDb7KYBJy406+41dZqQYSLhbX/Ndoy/rh1Kp04fw71futFuiYYM4w8
2MyK0vf+zA4F9YI8MWc5qLkunySagyem8E/9CuANG0Dkuk8RRi82GXeQleI7wUF/XtTXPx+ALN7p
wuDEo1FB7z3ANaqgp1eaKYtUWRbRN6rUpAWyvBgcdBYggGL8DLHcGE8eH1eelcFktAKMsodyzv2D
0Tw+1YzR4EiD3tH7Fx3TT63ACBmtVLX7Ew8b/SixapAt7lHlSs2wIicHP8JbxuKYL3pCJdwhdAN4
vYkfLU7hi1nXVokeaooozuhTA3/yaFmfSJzKiwISMQ006qVCV2sC7cXmNhln3u5GLwqCz/h+kt/P
5QG5hF6OM0uLM8Bom6ooOwn8odzySPxEvwwyj85PgQY9yI9m889qpi0OMFUcULrDyxMNzVE721a7
RKT5yYQDzj24kHXaqDnUHKEg0gUSDzfiYiz739YLO1HAY5ALNtmYX/YJ+qq4mpRG1CRCTIcs/GT6
QZLEzcKA5pOxFJWikMcnu1SWidTqHXCy2ZRJ/lsN70f8tNyr38I3oCjX3x+f8ueSNsqa5pBexw6Y
xgIDJBLuakFprALZT5MZHg+b9s0suXmYj8fNRygFvOp/BnBQKkeuVAsOocjTlTiHs92SjvqAKa42
8yl+1ATX7YYLVsOHggEImhtRUYKZQnP2DwtZRmCLOrZ7eKK1JZtioYIr+QVmhu0ZVSZwDYvCJo2X
lv2+3aNqd+kat+8Hp7jeKiaqXLeafj9gR0Ln8531nfDlz172pzkI4kg0F0x/aKi9tszgYykIJgU2
X5bEPM2oTxmIJOyxxypaA7lyT0Se7+cZ1UNHKWry8eUX6F6y+jfY6j4KewXdgTfZuDBAoR6x1F3a
TDdcHLCW+dOtgw5XoPweyc77rzmbIlc4MfLOTKed8/CqfHHJbKqbYeBj91ZdNoBYLSywh7wQw82/
KmziOQuidMfli+S5w+Y+9aRG9qiXdcNnAKEI8s9TgYSUYALySy2Z5yWFkiEgVIME6ahuR6VixCQ+
0jpZ35v4Koz6cpcMwFqsO7GE97M22O26DKPNTvHHqELGWhkjHR/ldBET6iTQmSIdf0Nury5lpjcM
NgA2BoBIhNpLkBOaSb4MsswEwqDPODehXMGbqi1ul/9ai0vDg69ZFZzcCYiPVGGla/d8NZvN4+Fw
7OpQKyekMFQjyAWvUW6vVFVm1taZgvfCVJ7Qeuqtl1OimTIg4TaXlOV0+Ff4K08iZlAAbK8YXkBG
GsKoAbj0p9LfzL33Yx90ktBNs04cHo/74pwOmB3yW3MZ8cnmlngBluwfgHxd9MY1XC8CZVfkcKUx
ShxcH/7i/7vx2Lp76gHs1mA/PffIVS/FJjoEZF67MaGecKVDxCn1H4L5XFBHhyvoyqV+tJwbeMVY
J4eaLs5fjiZ4at+vGhFza7JKx+9zbj5SigPlguGsS13lsL7pQmwW/X+IhpKwY9Ak5Zjl9Dqh/FPz
+tOHpDZZT5SFQhKPKf85gm7BByjo8MLQrKlmLiMHy0IeEoJrpH3i73QgdLyWzQEzZhz7l1HsMijZ
vkbZce6klVWEQCaXa/MBc6V3Cv4xCWjjgw63RjEDlAQL5Q/wE+TNQniy4dbDhUC7TzaofLbvezeA
WcQYFV+MAfGl+IInDJL2qutgDZihOQBNinhNo0mDZ5RzLD09QAtwp7Qanj9dCheBwYW1//Qu9FqX
CD12P3/H0SxLYfm3duo8CRL0SMFFhQ6ULoQgKzTIcT2jpNVlwEYss+lwQPJzdUF5dEGgWQ8uGCuT
Em+CfrtckUWwA/b1wNPdVjA22isCuXIi0XvisdX6bGl25ArfWYp5wEcmjqDUklSv60md1Llg5t1y
6ivy/H8lXOPW9oh+QiaoLW3+/fi42WGikJ/i2NC4deBbcJTHFK4pTnvZLD+FJb1qidDPIhTIhulA
ZL2vcHpxHuR7CBL//S9VK8t0pmyV8LCFk14E9vk52Ir6mejCVbAnGj+02M0rS4bofm7+IzCPfuMO
a4AbkQlUlVL31PnsmQTNaylwTDGUSjHvYWbWyPlKRlYIx/CkNjfcyVe2htAEiOHUPJaknv1YetGP
Xn2IuG3xnrStSbtmHT/EYBVrY08wn1t4gXSo6jr98TvsCQY/pKAROTa0FadPKWO0t1zu0vvUph+X
rYSkOvz4DuxBBtQf4ZU1DH5WVIBR9+0EYTyEqXtcW8cJL0ZcewdjyyiteA4I2AdTt4gooe9NmH+Z
mpbyZtYeYEd9qZttRTb+hLOwVaE2DuZv61XO+HohS9HaGlpWqyfsKI192h+BJiY0kvhRBj2/a8lz
4oJ+BjBxIl81EKIm4P538uEvtGloxw/3BGfUkGQo3Zws/RUCYyE+82xFaMkq0EU2aQHKzIKcd1Dq
x0/kK7cPghsLAHOhifMP6Vf8bfzXZcjXP+VikKiW0zsEBIcJVOZgiC6DBK5FySy8zNI0aVkzrbS5
pyeagNdXUwoTNmncOq4EUbgX86aUp4TVf3QFABK6ZAqYCJkhV88czsGxlgeywdroLb5/jbVLvSbw
U2Xt0LrU4J+9bdIotxgVxr6RF1PuIwEQq0gVmifobfU7Gb8pydq8Df3GHCQvL4YQSJ7uJDjj/5rr
c6+J2+cZHf+NHYRMZq226yUscOXzzci+IH+IIxTfytJofOPQDnpHN4VyaVQMD0XlHX1RKFuo+15/
ydTHXitGzmpADNEcCKq8ublDQwdQPGb11U6sNh2sM+lKFkqUarwkQZXUaIBSkz5GvYsHBdzvF1OM
bGB1uPHx6H6fQnVU5fMwkiCh6zrJSZxSABYgm65pMnNjT1Cce6fjEpomQKc+NKFitPQ+oB+Wkr/a
A5XKDtgAYdVEaajojOA3e52S5n8ptg6EkQz+C0veWxqT3CyJ+s9j7wSKS+9ZtNmgIFIwvvwYfg6M
W0eoWlkPPweshqIJ6Bk5Pd/OeBurAyTVgMtH5c3GeCSId50MhJyeT1Bunw6KTV6cVh9OSdpgzxDo
8+eQJwaGowkgGlMwuhg7eaWIgTmnxvvEexJXAiVptw4MsbiHIM63JXWop/pyr+B+BPRRKLSbDygO
GLSvnfluHDehpOKR7ZGOOK+n4o1PBavWZCEKMcR/NYn/6QlNS5+M31Di5uaLKjsWAaTxHzMDYvRS
5acuoVYQhghxpO26cGV/2ESXaegGcnwahkLxnpfjS1UhEo2rZclFpxnYNQCI8SMGyrZ2LcfJIter
iwBQRs1dSlYfi+Ve2kmtsLp1UKdAfg2rHe1+G1BFYMV9yNNSqGPGCOxhg6ivLnqolIzfrjZgHwVW
LPfQLNaIC9CeIAyZX89csSSOtyFpAl/d7lvGRwzcbn2M4qh8I4WkXZYdqBk+sF9LsTspwENZQzA1
c9fd2D0ixb536RFB5I16pd8BaYjHX/tMrzrnTJQzhQbsiPLXsjPD/un9yB0NwHVA+xS3QRKdw+eI
nRwHjjppIlfkdrrjoccNN+jACv9+uZJutSPVujHgFHbbx6dAdCvtke2Rmuc9B3KK/dkYX6QzCgBg
GOhYGP5xSVrtyCms65Zs4I5I6QZkyzTRm8xPqgYRI0QUiGkC/uAzZVScJ81rT6KgD2juCjqJXkKS
+RGkw+CkZCASqZfIVRCdQuHCp2tUd8G+vFs7LbpMpWms9ZjwCyIyBuZp73G1nTLChKPgKVh5EK4D
vvt/MO5llCAbjN7aDiGbKEjpu3GNnDWmy2FCLRqjTF9h1ydmQNEH6HyKQ1VQC2L8PN0nfgZvW8DI
5epY3cHsjCLK5DnLzSMLFLzm7BWBwqGgSOvV0Qxa7i8D9KgG/9NU1aJSiAd1W9VQ4zSOYy5bl63b
HWRnGiT90jHtvhnYl40PZtSi4vir8fNsvhOFTo80S2QH6Dnp3C3inwcVomG+jGTeRSdxNcHok+bl
7PAAEHBPiqChpVDeqoCkNAbfbggCQkkWZmf6uGkJhnjkp+UavuFvF2wQhNnxnyyMVAMMa2QLrHtU
hg57t26ckhqKW7p4rqbTYmSGA6dl+TdCvCHO8Kc/RzVIIySudLTNvLxbNZNiufCQOpM0Ivy6c5iL
VcKa841WWrjWdERU9xIeCX40fTKLK8FFEhsAz+Jhtw/vJibqqSeBqcc12xrk60O1Ej9fXzluFAmo
OxJXkUwnfLxvjeWOVOIghwzYqsOnDscXPTfW7PZQmFfSQHZHHXvWufg6UenObznwGdbdbKy+hm0g
yHZI+CDBm9UnzLZ5XyjN6ip/XKxx8UkztAfkayuKt9V90I5i1fdbUcsUu7EFkmF+tshaaR1e0CnG
fIMQY8R2cWLXc9m7VP1kHElg+D6KfROi8XGMHwenMdfckYNHxHew24uFwJx3Hspb1WH2zxxbPSt2
WNwD6+nI2NHBG0VBGbN9erZBr24yqCpGaNS8pGUf0zxvSpuOMHnHZd1/p8IA4R1qXjhAKigS/T5l
UfkwUTxx18wblsXr0riKxOTPbDr48qfoAGbFdlyOzB/v4rurE5x14aPSAA5dtl+pqXMGKMLx6LyN
1CBwECgR+6qudHxJH0I3+IYov5ZWVVNQX9mhULGa2p2CzLt6S3bZoZQjyAN+1QubYHbjqAqiCLXc
ATwO6xvAbHzP/HDBRAxjezPspeDvKj7UPMSqlbC7EucqWPs8neIcnVZCk2v1tzrMYpRnFR1x8zbd
oTpV4ViQ30eLBuNnC9IRaFlu+G03aL30pBNT0uUEHbwCutYFRcgScSfwtW+oiqSS2MCJGWtb9Bdw
2Cji30Dwbf+wWhzt8J7EMtZCnHENAl67tGQFX2UmP2/DVc5GfO/XMfJtnEf3znr7e5JYVC1HHt/H
hQbSiQ374xMLlp7pySdiBy92S2OIT9mprrot4+iug+My6HEc2xUaOrCv5tPBFys9GRKd9qqcdE7E
rgflW6XsRtDYD9C9DM97HLjG9UT2DWqgix6TALUu88Ly5Y3CHmoL32K7uO+7WUXOkHGbebyNmnfL
M27ED07Cdo+xKZUGUP5S3DzBvZiidLoWhfv+NRtFe0rtFevFuZh9IkDbJG7dGjz3KMXsjXPrXo2l
n64lfiXRw8RMuWasJ6BmsbxGYL8bKiSLDYBk8XCEo1xqjT0ya+G/Q+TuTCiTEb9iqamkBWxYwX8Y
ljH2m5eReqGVJ61fSADF+yo59quDBT4w7NrUBTcXyY/AAwuWn5uPk2fEt6eeF5qFzhxX5qhtFSjg
e228dp/CRb0e4/dUAof3r+bB46UiWfLrkfwplqyZVOhnkUdvHHV5TmtPNrQggt8QOGvHEEXEc8TT
83re0yrPj1HCyEIpIoc9pmiWpx2mIbbkuCG9qLsLMfifi+2DoCGy2V+hrXGG8eCtbcNMBtmxkWU1
L1uLwNbrPU0PnldoXbbO2k6QXlIcnaY/yW9Lfe3CAFqRpS7VsRZ/wBgeJ+sgm/HyFpFqZaZ8CTra
BXdFG7apLSc/K1PR80bxBHVuazNVafhCB70Ye8URvQee6sB2FI9c2sZLkVgdMAACQybqKA+HiBUn
fcweLelxbiB1541EgOfu6/abuonqcdiRjQjaSB6pmRauGxutpZpPpH6uIHcF+Zsq2zQX3AystQIW
DF/nQy9SAoIV+qC+dPHaipo4y3V+xgZ/mc84CrV8ehIbC1pYuwbdVkMAEEFQgz8uQV74TyM8ibPL
6b4yI3HRI5DcS+y6YU4EOT1fkNEWdgxKJIe3yXXvElkexqWRWkulDtBGdkclGrju+rUaDy9DzGIf
dhUEbSjKQkqZ1i+kDYUn9zDyx/XssjVoTWeXphQc1ipiZyAbfgjuYbuqjRreJppXxuJT9OFFEfhB
cqtVq3dqz/IHL06E/9a701hIGBR0tmUUp48S1S8M1gzqCPWfCKY+yoCiJiCH9P/aZY3ASTXnNwjX
+bmxOkUgKi+PqScKdlRBetOGW7Z1LoddoPGRydq/1GSIk1spl9aXACyOzDN3bjfd94v0UGOED97Q
Oi12g5IutnXl1nvn0NV1+RSU5cYNcZVkpr7usOlBCn2+CQ3wCfLrX48AJzRfzjHCvNt5jCa0NEyw
yb/RH0QU9qX8Tpw/tuLFGVAd9bKWD7dsx4fp3ao6ESWJ6a1z6u7ckXy6C9c6uKUgIFW+QDzMzqrD
kHdep8KRFUFnH4GZ3IDknHZ9yioAjj6XmtZZ3PRVxhX9gVnR/iWCuCv8Txjlq30BTgAw2L+zpQ+v
vwceB0JNhH2i+SDFMimGbPtnlqWFXBiSEiZn7Npcc8BHbx3XENRcNl9YZejLT0KQGTjl9Tgl6ij7
WdO0OPoB9fXEWmxXRCUdnuySXCnCyGJFcMe7KGPRSJoE/qvF0UXWhOpCWxs+oWJNXOyGgX3nR7lF
kBUAyuKZEdvO1ofJllGTuanwlzTBsN+rqhr/IHiNmgnjqKPcGjbtRklmaQBwiId31Tp5wjjezJGl
arPz8Bs9SYFNwTwf+X1U4mn3HHMr1kEdVRYHMZSTcQCBSm+3nOZhLEQSrshG1qJT3QcaLF7sqWOY
4B0F222MLzdPBb41RwY8MFeX6iH6JxtIN3/tfwpjLb2GCRTRa59bBCvYPKPr9nrabnlq37KcUAKu
s7rlhgE7mgoM6cPllDLlJthvnLaMcblyieaQQlAkpXKEZcMBClrTvNwzp6rdntWaPz0cX1KyP8Gj
dvFT6QMQxQfwURixhHo2NOPRYkVk92d+LEHmls1w95MOGl7khbVNHPV33cKpnEOiFqCMviHuwY9g
tXkmr/5uSfCEXc81BqCpqbuNBxWbO0SzZm9sXB9liwDdnIJ0yfRvfGA17z95KlYZdj+wevwIpsT7
I9wt+BPQcze37I4oj3xEcchcycNhpXKcjkuPX7mAGLl0FRRh07CR2nfrglXIf2Gyh0MWL23JOrB8
qg93XYUnXKG+Cv4bzE0Uw428oFajJHJhjIU5DoxUc9OHuX7A2iA1URVnWPFI0/1K34tuBHYPem1D
vhgVHCdoe/c4HOricXwH9avVjYdISFbw3sEIATCHd6BhoXeWH7Vsg9PwFB+7zjtaGnbeDhg2ZJb2
CzEqrcgUVuOzjy3Dzsm6oSWPuukEBOJuu8r9AGLCsj/pmx7tRtdpuw1A2n2JLHgYg1xczZ4jkoNT
gm95LAob+y5gox2Q9RhYD7b+6XiWoA1xqvb0G0rg2u+iRqW7oQqDV6xozPveYnlZC6YJsvGKBwxs
hEBFb8FDSKsiDUAgY5AU33oFbueCX8Bc+0AFZ5VvOWHp6feKWeNCjGvYb2r3jo8b/DZX+7iuOZ4P
XMC3nBVARRrav1SCXN6QG0z7dZz0wG8tmrRM3FlZKxfkDJpQfaooJH8vS2x82uct7HfC4EBeb0Ih
x9GaOTyx99hCLBxykqh9QyxOfkzP7U/3n/8kxa9mQ4shLKViAUdf9sxLXu2kYM29W9FQo1g4zBnH
9WJP+pTlElo3Ah0f6U9LXl+2SaITPBTkNj1bcfy95UTlJeWEzkSRN9WZyht2DYHK+CJBc6y8sUGy
cpS0vG6O4jZfqyFy4o/nj8g2Of/rFSZzvF53lVArD04frAGRW+ctswdgPxNd9H9YxkfVdGPEz2l3
vip1ERzVC/8R/AcHZqER1RVlFN7a18JJU+BkyemEtLP7G9rVvspxxuIEcnJNW1CXz8a+CugNu1Xk
KORJcNs8HXjHOscnuBuFYIzWadtIFRBi+KZgZlqFRGv9f8DPlYRWmTFDgCm0mQSlY3L33z/TeCS4
m5y6q0oJGpu3MjL0Ie19qXvTsTWk3RT9bAlb4i7995vEYwURJMkRIFTLhK3usOEUIgDefpRIBS3C
HQoGCuJq3ISwq2PAAeH+8kRsVYsDFUwwLbiuVzY4hpHuO7s8gKdV7ecYlsn1a1Zc0Nhtza3/S9ad
jWrpCuNZtiFyOgC9xp0Bt0fhOSAOKwvBIXx8z13/aSG3wKnllMCw9A5Rp6bRxZsJx6Lv6vlOf/rN
vPAH6yI5mT5jbLUzVJm1dakhc2HM/bv1uk96EarR9k124t9vAbI57E+UqfznApaVTQ+H3mZH4D0B
hrIwJ5nPl6wIl9PlVTCRHdbvYjiles2OqzYR6d2BcsoEvBNiN4MKHEGD1u0gozMw2FxvNqBpx3Bt
HXWTQIhy+uzs14LhvS3Fub+kJucdrA8eWd1Ew3wQI4vNzu6BTtWIIbRaKThuSzo0zuIGieAQm/PJ
zRbYP43dsopg1Qkm/Ry7p9DhRSTaD1ad7RXSRKuQaNck1m7RkkArnrQiGAt8ZkyC3g+efRTJF2FC
4T2LjyGqLp3tGW+kSONlrO17jFgWgW+htAx0x+rJ3wOFbd0l8Dy+jsp2vo9+u7LWfyb01Od+7oJk
oPqFoRk3bUyLHisf+1tOkLFpPsSHL8wtb7jeF1Msedrqz++Jk0RxXEQFK3vscEiyOQMKJhwugJnf
qj/gAEDhmXVB7fzTcHDgp5wtAbapg1C+09p4Hbj6RysepR3VzPmXW40YAphN3ttDz+lLt4DUyS/W
QNZPp43BmrwyvOzMSxYk4lluxmkqF32OS0+KgKwDTe/lzW9O8a+4GpW6IAsDuw1T2fMo1Z7LFAPe
ByuvnwIJjmoki8sBihU7azJa8mojU50ZkqKH2Q/yeT0zwj/ZPpcSETCxdzzfiAfuAtYkKINnK04Z
IUzO4U/KcTdtDGgi83kXD5R76c+q2/BRqwYr9cx9CwSEIbcUheo+o9A2Iq8R1L9JYrqfX0yzPWVS
jHkevujxZKzFpPBjkVH28vlkdsoJVXtDE0z89sXgLrN+RlW7PhbserM49Utoa3sBzEavBvKkHBmA
iOnlUYGSGzXQqnN8KgrLqZebxzRnJCJx+lKVKlmxSkWm+Dl051Ol5pT2HZPY1ae1l7GcHMbxz6Zt
3tfJbk+g94VT2uDOhqyGNXNuJmHzWyhhNLLJ7RZ6ZqWkYK9SdyUfPcecvrCAx/W0dzT3CXwuclMb
kM8KOMnFBcw6ostuXP1cgrz/G4YhbwyoisHL7j26B66CzBaSOFrfqXLwYYXwn/Uhis8+ixsySp2b
nRR9+IkQLOnHCKoDhaZpYGyRgghlQqvavE5UHOFDyeNs+fToBz7dGKZbB91hLYBMtDCv5OR2PQnh
5kPZ2oI0vjjiYNpllkzOcpxeBCauX72Ej9ve/mRlbj3S24RncloqiZXm6CMzFZqQPRBs1zEWRrHx
bG34GK7CKjxHnv8L6YpXBwKdpXF5cQIEiLV+9cfET5ioGr7+ipB1WMWcPhh4zaat7STEIkHZGMdr
OnQlqTdb1pJI1CuHs/CybouwkzMDd7EOPi9PEihf1469z4tyyPZlIBhbO35Q+hjSpq63k+MgGvHZ
Hn8d2zK889woyBMfYYQ0kGfwiIYxr7gVrX5MBVQlskwrouYmbARv3fAV7TKpryj0olCfw6I9fctX
gBNaF8VKmyIyjpQhCj/ST6REVG1thVDSpxXVfS83YrbNVU9WjHXGIi/IDCxv6bHQ5d6go61O58AA
BL9cKp3i986HPBM30hDy7kKi4mqPHqJT0IEUY3EXtp6favNV/nXfciHpTNRLh0DMBpzNIhZdeN0c
cyd/d61v3L+19+R2f9lNih4yizchSUGBD5MYrRtX3jfekNFVFD4p3DpuehccvCWEANDKub/Xppc0
55otdZ6U4PZbpBdFWIzHFkHWlu76fNlaH9Jun7zf4YYJK3nPib/JuVR3zLdgxSoOmy1UapPY8xMt
4Q/S/SUShDhwHXUoe1q6tzOSpN3IzMPJrkQg1aUXs7QJf4CS7NPK5TcLPjeGGpBiI7Bd74ELdqKI
/Hes2PCINa8fvy8mxy14zsKoazXPf1kKvNBD7voFixReSxIMwea7vzDMetl43SnBtUHxXKD9+nK1
xtZcsnNCjk3AxzlteUPZuObIj6sAirU1PbL4ATHB1zYUagvqtPWWveE9YeCyXp+9fURyN046nETB
plULF2GeCsG6RPH4HBToooVpAZLAp8iPGdvYwunF8/FiFkwwo39/9KV9hVeYRXrQW74+nvnLxL3r
668fRdulGy9lqnHlZUsBz4+p7VAhTHbyO5nJZZZYzlOWp3DwJwf39lbCOCbNqabT0X+KOHzZEgoK
YMkj3BRXjb9pZoVk9EMS3+vlJ4At9uUfw/k1cj5c0e1IPlyvQrvbRIud/O3GGNBWCxWI2QSBJtTp
CvC17uQJcocOKKlOgSvbmjaNb3oosJCW8elZ9Qkq4O26VlBa+Qg+ZkgCr6pavQTWZzATAwDjkjB9
P/uLdO0vf1hPwa1iHFFQA77mybS+QxPcduoyfZ+61U6BUWiuYSiBjY3E4sdZxpvoIDSNasZy2b8L
qsBLOiMangHa7urnYyZGOUMsJzHenxKmaW/sLB3MUw+FJBDd99fZvBITaKMjFfAXvU7F0vJUAopY
3XzNfYbbcWm29WKUKGSZIZ7hwEd9JGBVBIMwWa2HOnYlKEgXLs+ue0vy1/Qc4EUfQEF8ku+OpvMK
qVtkuvj+gUqupQWgNvKNEJRpJp62XcT7G9lFHqCHm3P7y0GNQWQbFKhtDhsyKscax6UGsM01cDOW
TjpRx4CTvQ2nEOfp+PwA51Cw5yvaRe4YU7XHsEsXueVCehO9J2xafphPQmwlKEOvwPXW8tTmIBzL
c7oX6gxxjl+JKjR6dICb9AFqEioh9BOn68OrF3ekOj1/UhkQnTYqfiramsE/McuHS5QK2adAAgCD
uMxx1Vw4/aCORm4shTP8Ur8dLaaknAUzr2mPTerQRLT2ZYf8aAwGWWFY6TBawhovO7DPvFuZqXlu
iHyD36bdwL32YapZYLd4EAIS1AKl6xLo49xT5KYw+dJXOR/uqLagwPMqh7EqZ67LHuzM/7qnenyW
F53Y6G/XUJhbt0cCfcvu0GZWz0ZQwpja6jqlBB5S/CVW+/nyiFg2HtBYYN758zEYBmrT/efpg8bf
/7ZnnusK/JKvKIuD/pRUncj4i9g0ILTzbQqsOYyQpunh9KxAvsbHePjZSTlhF1tVIk96f7PtIyK6
t0pdy4Db/nq0UIz2IEyLqbaT02uhoTzG7QEuwMT75uiWB3sKeI8LnQvqDvjVF9uBb8KhM0KWetDV
6ahO22VM2+0xtM8wqUcsZbAxaZiKzKJjWnBZjr36xSwztWPd2HoTv1zCnBRVCA3K7CLlvqUtIPue
PcTEHIovKy5+q6pw6S+T/luWgDsSDSLCJlRPI8MuS45CGbu8+xYitUh9GTfnaNIxdJtZldy0AFqq
4yA+QwKAbbPpD8GGv9YNbOxGg72xDjicrCG7lO0TWfjtc3hkNMl+CDOTvXREbjVGKCS/gfoIenLK
Cc1n7BSYvcdtD+i9PvmQBviq8ox7PjthnfDjym29G4lBFt2qwMBH8/Zhj2pv0vdwqB1Nfck0Ocp1
8K8aDm3SnecSoBCbYDbou48cwuqAqsAVsyQvKU/EN4H+xlsLGAzWPPDt3IOgjwdQvCJA9/7Emrxm
G5M0XoNHDo14ub881tFiZwnZBUp2+Lo703yEhuPnAsHb4WLMMu4MT0kn0jGsrFZjrvY4mzOVj9j7
Eap/mDbnWO0rxoOwDPLnSAigzgOZWMUllEKNBMYEgYNACDK3yBDCOHTsBH/py8p7JZf97qzjNir0
hwI40q+tjMNc3n47X+5qrysI8M80LX+hn7Q9ibN5fa8hHvAI/0+T6VLVTP9GYX0XtZEX+BamPTqZ
m0S9M+Hg9rXaehMlc5Zxr1WkhJz1DKr4vU7Qh6c8zZxDqZhgpOvksdsVpe8MdrjutevJmvXveXza
mDTRCif5Kk7kV7jARl0qDRiZmSHMBxrdcFgQg1a0QZF3WpuS1WJ2nkpOlvk+Evk9ukf3YxrK6Ccw
/ZGjEh0orDBj/eZk+tdWhgIj61Q9/7AZUZK6HhcSDeePQA+cdAie2uaNFyz7C1vgSVmIDOwRGcnO
DeQRdJ4zzuvIaRKxqTMXAi4V3bF6f6ngWWGOaU1oAffO0kWwvMv7thPeiqsCUgvw/pinGOmHtWUG
zYjaCb9868Dgu54v5+EzGkJ59xgbr5L0QhMJZmFepzbITkdqhwCD9DV8w7ebC5D6L5k7h0xOqAI0
gsSSwq6psh7X6vM3OehRC4IwnipEf6d78dcBFT3erck+djOwOP0OaX62LALBtBjfGFGc/JNMVmB0
SE3Mirvv/xLBNX45ndZJcKw9fNnHuH040b8T8/mPidpdXzAolcHJfxSJxDOcM9pHUx8joJBGseDS
eDXiOXAQb3YRCUXcHv0m+cvRWlEFe6NuhsGK/Ui324oW7EuYkTCggciYxDPdPE+j2N8kyIfVms0P
t4X+Nvp8xm2vbU+Yamn2k3ZFisT/u8LT0qHRP1jtq8+NYlelbwFtsMYljfp6xz2XgzK3210vcOzs
8FltHKJSd7kCjxOUtjPE+1NrXaALLae5/2LueLytMWp/dT8UxXHhmNT7UAi69C7vn8U6SuTLZpNl
Ccvxadf0vEc1DmJOMSrZsakvz42DU4/5NuKghogQ8zX+Q5Ik7fUDV2TzZ2mPTqKCoHDSRLQRLL52
RQ2MKPMcAKT4sAomq0exnXBF5OM28v5GBueqWYf+0Ap/kKRGDvmh/kFzF8UDmpJG9/4b9Fo0X1Vw
5ZahEMATc1gtE39RGCtmaA4Yi49sqjlDgw+RcQo99hgpu6jcJGAr4daw8YjiUXDiu+1w0BxqLCRb
xwSjqKQId/wJeKW/qOkDvhcZNzZSHXpTtvTvms1ZGgJwdgsxUNDWaOfTp15xRLfiHLrQs9Jnfogj
IDUyHL/a0FdZLxIrm6PQGqNOt0WXPzL0BNMuE81mEMwBXK/tFHwuGQyZYwrDInXYnzm+HfTTmTgj
Jyogu5EGRDpntC5SDaUdX404BL0g5jUYk3MFz9sW6p/VqJgD4k3IrcK3ILA4Y+nWQ2+90Tyx4+Nd
ORWpIw9PEzfT6sXgP4dfjt7DJrp+/z1eub+XmBOVOT3ZMDJyevde+oKR/S4K6HCOvcWszvTYDu9C
0/rAeoW2KsFh7pgRg3Hj12q/8lDTA/kHPpMQgxOFuMCL3/trGJXhgqeQZTP7RwD2KvDo+klzX8Bj
3q9CS8zQuuWE4JhqGXARWGaDI9l32yKvdduHNXf4Z8rUadENHSkkSkh/cEA0JLixplLnrd3xWKma
CKOhzPEWkzhB6JftTICCaARd6y1LeIMGu//D/UyZpr6H8N/fUTgPNVyaOvvbxZpM4nMzFe0n8Lxb
XUb+4lkXbOLu4OZtVvRWvTdhWI8P2IuW1k3fxZyL0NIcmaJCJSK4rF094FrgixNvY56HuwvDWBpS
oyBPKXs7ZOB1thOlM13DBPXg+YNqra1RUVhbB9WH41RqYNy3wE81F55wm97CXYX2s4X0usYSetEi
OFYBHIEeVnnogbWWnBOWgUSRMP+HevHSShYbYSM4vvfVBVXJFuQLCFOrWR4HlAQrCPGEz23uIRPZ
0ppl+de79kcZbHt4IJRLA9fUCkuWoT3kzMnFdwtchfxDNl6IRCZ6+wxv0dG7lsBooAnSzHzVpB1O
xNnxbE5iVK2YznlVFJCwli0zRxkelR30ZySI6BEbZjfMnxMcRSUz9rYD3iUSznsDdzmlnmkobTbO
WyNXb1Urct8pMoUTPySph9uCmCr/vjTAXDTfIbDPQqSwFN54StmPG72VslEZEGaNo0JRqeoRRelZ
dgTGwzzL52y86xYP8pw4Sy5LGEvrwiVP1M2TGJo50yJ3io2QSb6fTBawZc2LwJ7xKFQTT42nuhrb
aB6R+14f10mLsAaa049nyX9u/vT2iV1u2HWkSeBK1Fawz/sS8HsRQN+ghkzfrAmO41t2yIvM5sih
i98x4OPSgU33cFSz2U6kSgGfnSOSp9V+IHNS1c/iqBSqr6cZptcoajgLsM120uGvZd6OJwH1hij+
cS0nZ/l1v2+HGn5hxqxmqBcMr2+jI9cUTup6IwSaknqxWuwn19oTetAxPRApQtPPnx14tUuKdCaV
UbF/d0wGEpX4K9tpJ1ARSKvWf7vugJlFOiWXNpbpgaVBbvV4Z0fgHL8+Dtu0ZeIDwQqQdiu+lQcq
iHS2xDAPfiNopLfndzgHnLgf27yCLq15WFU5c2hGaTm/Qm/LlMzs7J1nArrEdyIRWQrWPEfI410L
R0oZyiCrzjpWo4Rg4Dl1TeXFpzQLguJ13hj3xt+m4MS+Kk0BWecQXLOh8NiCP4SR+ROsA0MMR82V
hlNBorXcnR3lilgZsNUevHtMfpUeZ4f0o7pHtxpnJngg5jdJHsIjeVGPYJFYeWFrUkMigyUVryB0
daGkzmhFbXhbNUq3QEvnlLRdvx62U9yZsxni/MNcromMQ758UyGn3i6zYh3Gb12Oe2yjGs0FwM5R
dyF9KtS3C9Gbb7yJQpxrBfdpVX/r6shxHbaoCPZZeuFUskPYhsldnviWJtD3CmcUqE0OjC672jb1
4iOWql+iDV8cpnzGXWmUrnqmf9xTTD5ANzuves0jJA6+tl2I49Fmb9EYEBS6h80WZoLFprhMAj6p
jgU04MeBjPEtsQroQEGDUEe4OLKtNngerCYbE76LzW03DaaUSK2piT7+ges91Hf6HGcIPiTTnyWu
XC0j8f3PPzr9EBdOVQLx3V/Qb95RoPSzyEDilyiSjrlfUduF9YZBeyuW/S2FhUVEIcAu7qCXKMTe
ritGhjw5Vvq1Accq1HWFCtgozEL9HfGHU6YrbRy4h0uQ4cj+ZPpAa0ERa4mqejK/VU1aL/oHqTpn
VarFqmXnYUVDTpwOh7b9hYpvm7Rv6KXnScCH3Ftpku5loTDKQiBcpB+Bi8dHNcY7/RDMnY+9hQ3s
AUY8VG1Hp0QEvAwXZyjaA4PJzx50X729/n9dOLNJ0IM+gbUIX7/wv88kO5/C8yjdaGWUJYOWMwCY
XgEzd0RcxW17ccvIiceQ2VUpbQxWmj77Sl/glBpGtoB29VWcmjWivvxKwVoYyYBpRWKcxHy1aSKO
KmjXIHGTYNQbAWQzjdayEx+noJQPAYkqam02EF14V7UJMdQ61+BgBBNf7alygh1bwARhX1mTDk5g
aOzrBFzu0v4YZ+q5RFzkUpHrwwEEkw2GVMNg9fOQYu7t2g9xivRyYn769hPp6KLggSf6gzKnIGAf
opeNsrZYeTVS7wsxVvEWrbbRc3Di61Mcx85RpzyKk43b31N/xl1IqYj5771qInmye+nfYvr8gS3k
TNUUNmGRthfCnaebnqltnsvLRDmwIduInNncABG8nhCGU5G2dYQ0AAneQUkNVV/9ZNlsAYcDaxu9
PmwriOQvuLCWRoR6SlpPiAo0rQT0zVGjSg0JGIs6dP+aTDaa4wvrrmgS4TVp0pB0J4GRwNNWUps2
HgnBah1pb99i1NHNFOsBOtPAwHzMMJb14GL+0zhQND0beDnHSbyq7we0wLXSFGqq7LUEVDIXAymZ
wVVwl53nyxL/JbKSzXo/h8Oj0HWMPf6mMtXydlLMMwjlDIiFMw6FBrNL++wXOYffW84BCqmWtWFf
5RyMAjSsg86dMbC/6q9v5veWAkGNNs5g8/NopcmTb12TfhLlmzaDF5aibOe2XJpMSyceoTWOPjrh
xdT6rVNtWS5zEB0XrK6bj+4fHHs2AVbREUwq3VrhwgsyO3T5tJNZ4tirnWOMaeDo/lySS4XctB0V
KXfJkHzZB71SfHpZ53RyGw2iKTrUL/YVchXwoGiqIJgI75c1NR/4qhXuPL7ukKgOQeiXj3x4cfaQ
KF8lz39Y4M1Af7IsxPfcZYAiCcSDtox6TjAaoHCmwEc1OL8upzh6L+uwQfE5HqujI+J6UvMr7ha4
H+snj8dlJx/HKxRxf5sdGIU2QteYHYcDguydmMrN+rmoRZQiv+8QD+ve68hIuMd3r2xGUANeFEJx
mQ8BPasWF4Ja/RE0raIBxYhMwySsfN5Pt5xJCLuyvqTEN55/aARX/uQxsVxTDAXm0US8v+8WA6yQ
8aDnDSJHQfSyiSPg2wXxoSVwDsEFIahVeqr0NQ9v0vnqJ1znMg5dbivCtiynG9VJ8tq+TrY1AcHG
ExYMdtrwzw/27Z/l1zPU7TibX8DfmfeSRZyhfWSKspcuikyo9pUUgjEWG1WECUQ9VAk0U+cyrehh
0zd5GzkzWmXeNK/EPiRb2x8Vy4JBqoOXP68/J/v3qNWf0jDxp0e97xQ1iyUAc2TUm5XLVlF7DnO7
ZMMTXg3rkjpMxg0/r0xlJCstrxlr/+DkuwPxi/AukkW58LIPtqekCcE776iTqNYR/qTY2ju26d+l
eDi+yIcAPeOri/G+kPAmXEZ/FyUbuaLNffa/W4L5sE+Y7H7VEIwbQfNwraZJ4YLS7Baf2eXmQsJA
QjHVaxlMgyVChtFGhUPnNeWcwD3eIaU+AeAjw3JbhiwqHTbu6YJC4IWwe6Vn9ufw0o808jS2upZK
8ZMryipMh+YzSidPm6LkUHRSORWOjhWpBftI2y1xmLbMYcSgUyYB+mb9IS5hUUT43RKZ78dk2L80
Q7IoF+2dsIkNGeb3XVAO2F0WOFk33ROC48PQVrhr/sEF+rTlQFfyNNfQVy0CewlKfocoairxgepM
BexRmI9EUMphCmafNUYb60Un80JRZFP+DCOA0wzUP2OZ/1/7ebUCBWH3oHvsH/CwWLyaNgnU7qOp
qeOXSbL2FuebxIFbpKKH2ZksEx6OvelgVbUsyoO7TFgtInQDFJuKnJI2soRoo6ZbXIIdyR96T0Ag
/Wl06+9O6Ee32bJBOM/On16/gaD7JyxEIQLg3qJo6F1mOjsjkXC2JCoBIFNqS3WuuXoEq/N66HbA
//zvlnaaFO/9PJBnkS9slwZQkiA2em+KtQnwOl38M8yV++TN9Mf5Gc6v1+szktw1dBarx5lyZqIx
rbx8I7XX1JcpLq629GqDrJIK2pwe5UCMlJ4V/56zV3Vdesn6k2+CJaSUwRCsD1Pr/zn/ysG/mBY2
JIaXOl2mxId8UXOe+Sj6fehGf1fHSQpM2534KXzPBrRQv/jBNolEXunkxQYmPXyiG35PvsRaEYds
DlHbEYEtY66J4w5nzL2ycW0hesZXvVEYJ/EOr9W9VEZqoxLttiflfVmdmd3/3YPC2p7onTnx40hy
iipiGaN4TuzpU/MRHbcdmYJwd1pTUGlSsbFal+l6TgKPl7XKs3wmjsbWYUoMK4eGjWph9q1bYntD
M7a/zDmFVHDbHyqrHw+OcbdpSEHSSfHCkbPVuUTLbt3ZqPIyoY7gNZNbAMg3AJLgsd9K/tuxxaTh
ZzTOwvPgU56azUqZsgA/KA5d9mDO+UqCVD4sHYAXWA1ZVA1lDznl3ZQy1YMvL9cGdnt+s2DWWf41
eUvFtkrEZRbZvRv+HuuuMJf06savoG0g8DNntk8GcI93Iu8ZjrBljs+vjih5CwAul7D2r/negLMN
jHYkbGIQTNpd/n9+0xUZwxHQj5K1sd8FR+w4Me6gw1vddrKm5mkmivMTbn63sWXLcQXGj9c5Lifr
Jfq2NgeTHzOxDqp5XCUxBz2xvU/DDHjF52aSHM8gtg407/OWWAY1Ce4OVeSDIycgb+0ApmAfKZgm
Jzc4kGd+S1VepEB9Na9eki6mfcxgA+mBtLQNRRR2SososPRSi87sv3HTiEr5yAfkkox7bTWOO8zC
TfeMHCWrvzgEyRUY9hoFGm1w+Cc/ZInRCAiQFXI5PympxFqypSyfQAENX8UQaLGovNWho22HHABu
InJokxy0A3HqEzSSEd8h0OHQo28enS3iDB5EHwd4lm7WSRv86+E6i3h7WKIC1lsiBndUYerj53mp
Pfcz9QAzerxOYSe6bH2b+75Nnvcz+e1EB2bN4K68qDMjSqqs9r+wV5AFnw+sMeaIi7EtDvtMumMF
1d+Bw3SZ1du9t5ezszK7QWHlEieRybTenruT/Gpbv1GosLQguBIcHHyfSudeEvOfv1iwwIjD9KG9
qxTsmK8doWHAASYQ48OQiL35dQyDuAklg+qNgbMimxLNhMgHeMAOUy01z/OGfmS8kAVIhz5e261l
oNCPyVCStSOXUO1cpYbyP1/EUaJE38bAKBtJYTNLaBFTEHbGPAOhIrDsmgGslWdHru5p6z029UjJ
X1NgcwTrVf/w3JZCsHruzM2TwLKre4uaakikAdFAUAg+nhDH3tdcVOuADkxQWssNk5HFRAKWHwOP
ZJFDK4cR269G1kAkTccRz/B/SDbJzu8UTPnRZvjvOkewjwaJ/JGQVz2EGkkjw98A6RednzJ4byPV
6q5WgADisl9L9J8l52gzxRHuDxXjoUy2Coi28BWaXvee/dRFOCe8N6mB6XYbmAGUEzaHi72YROJU
hJE6/MmQytHAde/z6zxm1iu4L7+H8z+VGtS3E8Ws9h+GsG/mrmoQpt7YzW9QaN/eM9qSjhnqmyOU
3RSjPtzXIXXmIL/8zrcw6fm2yuJjYHK55LE5AHJrGzb0hy3Uib2TwLOAK7QJ+ZWSREZEfFz0Oo+L
p3KoFY/phomGVGmJck1KH9iC0nEK2CHEPMEHVZC198okH3TR8u4gMG8NG12HF6zEN9l43kx61+QK
RImEtd01unvO4Qm2wnxGwZg+4UCt51lg1aI7tGY8g97snZeupXXC95xi6QkeH48eSiYoTtcQPyd/
uGrXvC8SVNY4Jaqe2qN0wEuB0bybJelTwBDSJnILEzx6vS2T1iiJoYYxOfdl7g+xPW5ARg1MbxkP
L8c72VzcG/E+KHmA5+ttnqirVRsiDJNjTsUGzXhORKWeiXrRo9g38K/EXYmRLrOfhik4zf31Fq4g
lJvg0lk5JYmBFkxCcHftDAFxH77Y9QMHDPBAkH7+thpxm6+NKycMvgBCWPZTXRKt3X4umlxh8RdL
f38QO4VqihDBFWwY0PoLcWDfLYLz+qhY8Rn80y8Y0XUhh3fAZankuHGKquw/ESTkQypfLNJCm4b5
/OCtdpMmwDjJeljcHM0fTZMpmGcoPhUogNZOnl1rBHFX8rU3f/8ADsM0/qrXb/E3Zxc1Gy/IG2GS
CO0JnYLWnEhpaf9csHbCoQecVHNQwuJRFMLj5kIkQa0DUmEX25GWloSpB5jvxgje1PNYljOC3GDa
R/l4aGOgXOWWQXTsf5PAv/bi/sCQoPLoBAN5XtHHM6hl24+s1A4qf4eBQ9jx9S/bhSm7CpNnIFtd
FxW9UsFBExjvZ1deZkQjkiiz8Q6vAgqN/OMYe7sh0D1yc6WXX/I2tdjW4l33LwYggpikGNfncc0Y
SUlNYlz9mqMIhF3OpCrAembPQnVROoyicP9dLatKl3ZDRiFdlXkK7FE5gG7WgQ8KLc+wfZV6F+s1
3yPqiqcuK+pdvTBv/XeJOeLN2/z/AUdhqsNafPhPwN1MUk6sB954TifLtW/lGUVfc74yPA23W0b3
roZ5IQjH0qSwCi3znB65t0V+MQn4DCjPIocx7gSWuhVayrALbDHeA9myKtetBds6TBvdbrmLPdXG
7B2P2QJ0I4BnPXK2XaRlCogGtqR+ZjtJqVe/l1mCZH4OtKCfExsJMwf/sWOw2VsC9JH2ASVY3Kgp
ujtrnKTqjC8hqhas8JnsE0Wl0fGbW04VTrUmY22zIWJ6ZxbNPNgpqnakFs9SaFeCFoV75MKEzlIW
bjYHvKZ+pW2z024z7f2dL4yDoGxW/r1158/bt0YFcV7zmUyO6ByEzLEH5E5EgqawwCv28J9V+Azv
VCRz8GXi+lArt70nGKb2zczcCdBRGQ6U3dtyRW+bjVBrR+Qd5RUnikO4ZbCU75+DCf9pogiqGpqp
rIxRByj2OLFkjdpQKOsnxSH0g1dp2OH5ObkLuO2OxL77fGNNV8Xcq3sSY3efzq24jE3DPIjxPSm1
EVdsqTah2SjoVUtBpm9WA3ZxC8jeqASauE4ZcuUs0PsVh5YQos5f2Mr9Z55nx26dBrZdvaVflKvz
mIUHCkLAKxrTL8NhczCt8dRcn9++ILi33XO0Qsq/ICId+K/4LrbJJVc14Ppnn/ryFiMIBe8KqtrM
iaY/jRJyrzaZb8RwYqNNppaGcHipAkYsCWLkVxsuqEp3jS+YPPP6MmDqciCeh0E8s/BQA3BVVh/M
CwemmK9fQgMU/5YVbTLgdaYI7ChAKnwZxLI57d2s+ALme9uXZkAhOtMIA+Hj36Uz2Q83EcUElXoa
ENDNDfe1oaAqVfUnB9q5+wtu7cuQH75hYpIJhWd3HYR6cY85UB6oIiovN7QUAkHpykC0t7aW27s8
hWUBnL5awmG0WdVs+ECRCq+uFFRH5E2yDB+S9HS3QPsgCBsOwR9IjpHH9jAr6cma8JNI8Pg4vEdh
c7ptQccXBR+f00Xv12aa9gPjdnJ5jf+n4IUKTO58++WMqY13l0oqaqVoUzQSB9PY1RsaH5WXsp0l
Ud3zZCSiINX341sCdJDFxmx7c/SKG8vIhVANYIqo+YwRKvXDsm+GA/QsAxhh/NXIeq9YMKRi9lUE
MZ3W7OhZsgp9+tfupv7evPQnfRwDWtcqoYlHw6ePWmqUuuqVz6IndvERd7JKHZEWLnodl4KlGhaV
vkYw5nbQv93EcFsY6fylKdo8lV/gkwUMbWEkdTA4gHgiAcP2xo4dp4eVfrILIDZBp/MnB8GHI6ep
0eb+7/lV7Qf+yfHEAd20JQO6QryvslHjiAO6V2Urrc/h1IrVGl+DLfQR0WhMldX6uyOFDmPJegpQ
bZuxQOJXpHEL7BLB/GvqEHUJilTgRG+PAHchblSfuiCazrZZsA/6yP0CZDC81qg6wyVgXWAEw03q
xiUAGyA5Qp5uaromNaRt3G+mSdtRsU/55T8FGSFkE+jj4Y2V9GE83l6ZgiCB5ZcRtU8EGvJZyFuT
ffhfZsXEdUYwnoHv2y5zLNOr7UsOXkXpQzaq3WyaJK+w0W4eLUFFVCpk7tGl2yoB9j3FrNMDe+nQ
lA1odS+t8o7uyc7RaO1X9+P1wg73XPWIW2iEZ9ioOeozrfR3MFYWfZ3acv0hDM5EjtgOveGd5evO
vatC0+3lI2lTuzJx0dxnYtRPucuGbkvBWLHsBWjuqSBSQZ7gPWTJsieuPhCW0gXmuRQ1t+QCx5C7
nDRc2r4F1XnUH9C0G7GvQTPvipWJLVDTFtSEVZrJRU8P+9wuGR1bClKIBoDFmBblVnXX3YP0fdhp
iARfb/LuNjBM1i2RwWhpo4X+b108X2Z3Ij5KcltMZQcFDWqW+akK/K5jj9jwzC+J760E9C7zAo+q
9A/vy55Qqz18ioooInpLsw3ghPPwTPVk9sQxlFKoID0FZiVl/W9kAXZkL6BTIfv62W7/65M+5xNc
UEbL1B3+kWjZW1Kcuv75kWXKW8/kS6VcmnfHI/i34Dhvlz1c86sJ1Y1LFV9isne75FffnCnEhuOd
Q/PksPA9fqFBknK6xvzdrUFpB1PH9gmGSnXUZyLGj8QE0vLvOaQZqNPdAFQN0qXayZFU5raurbs1
utR9PcVRimM78158nMGBDpSHpUaKkfsPzOHVDv1ZULBWigN8EU67nP9fdc752pK5tBW6gEebUo0y
ZJ8eoJ3laW4Q18WSPgGsIsQ0OAu21JNrMDvvL8UOBd5KebIpI5g2hwlLdf5F+JlqP9jZUhlFAM9z
ThYhKlRAknMrUq5664nnNqnGMfAyucS+57IhPTFV50VfKPY6RtjD77AwdBzfPh//Q/z5Yk/45BYs
HvtIS487ISDIrUz33TY3nvB7rItZYQQeXsaIagJmc9lPG2ZbJJwGs8pY3IW4egqUe1tkNmyGaRNy
2B+r1BX5sr/MLDxIhlZCrkW89tK95IeTltqzYX87m3DWRYeiN32BqiWEI0GrsZZetM/hyHK4DN47
qyWdwTCIwkeoq1cOUYnE+LXgIuNm70xdqIAUC4KcpoATJf0NlhmBY0EpxXZI9WoZtJhSBnZ6RNL1
FskwDyQip+HNsf3xpSENTcGuwSgsvF22mYW9B1hrk+O2znpqskgMj/wprybDb6dib7hNheikR7ue
ue2/LlMtFSVAh9szFFDFbvYDtnYdt3VFtHXSUujghULUHkfkQzVqPJnqLD6e0w19AyL6BAgoFdzB
OPNm6MPSlfVttyWet4FJ64Egl+sEzBcoF8VPCsoRfEnzoiuejwQq7wGF4B50Yniv22XTCTPnyYyS
69PASXhG6r+NWfCcTRZR2D60bVaaznipvtF35q3TNw7ewahI++I+0Kjd/qTGblRC/u92A2bhmvV7
b3HVEmNfaWvRwYWsJlgQwaMR5+qTaIUQtCs1wkcvERRuY6r5GSVLkek4pR9IXyDIDUnlfP3Y3urg
GsWOqod/iMp9v3QCGkv8vTzIxYFlMbf6hfyh7Oykg8rqgFGO6df7MwttPwetaDWa6bQ3XzdzZO4B
qBgMA/63woBu6FEOBiBtjCV+spJr11B7L8heRWatE9Sj8Vju8AJyv1zwWZbZdYGOugSJBwUyDCit
JsVa4jSoT9nBa4jrGVBhzFKVzcTASri8aufIFgFoZEwIyvoj03gaweGrjhBGZj2i+s+2URjpFgWC
qXygn8uosmCgVK+FXOg33amWaMWPwDKeBNOX775H22/E/zI8F3SC6xmwVbuwjnleOQqy0UfTUZCW
rK8Op9FdR4VDk341StP20tD/e+i6gUb2e/OWWhdvQNJrpchuov+ywZU0mnDJZM00WE1zc7s1a0Cm
evFu0i8H77vXaqN2dyZjkfLdn0fCRbsfNBuqU5UrTOHTZF8Gw4ZzuKtlaGsmrVwAQT5QbdnQkSHJ
k/3LVoTpCX1dk7Vm4EBPQ3j9pw5y4f7SVhHaJyTCfSEiGKBy39bUI2VYVq807nNp7cOxD6q4qrGu
YL0NRp9A1eX8UCE3iIgISVSPbPiSj07msO025r0J/dfNlF+UkmkjQeZmVsriyIGkv64QNKgKEAdZ
KCJ10ylR+HlraiejO9qCA4d39ccpAeh1UpdG3eDf0YX1vO2UryUiy0v3JLnpjKw7xRSFTbKovAoa
8ywXtNftUBM0W8MhUnJhWVXaRcUyyRtT2tpiyfkrZNM5U3vEL5VSiZZJKJvaDSGv9rb0FXqNu5Le
riRxBnOeLFeAnqurpcLLDimtsOqe5cL6JX89ZIOYhfvRcLB3bMkVrI7cJ+mb8gp0dSb6pnUi5i1G
SDnqN8P4UmzPwh1Dl/zvTlbU2tXOp9a1Yw9GtZYoxdc99v661GfBe2nWqHk/UK15OMynLZ7XgFPD
nQX2SEAYfL0H5gkvyJfu7cpIIl6iXu/Hp2c5JMTyiDHxpWz3BV5sGAk8dEckUNggoFxA5smy8T7y
qpnaBMy+TpC4vTy99UqGYhr6v+GFZsQaXy7EAuAat4PqS/FQyhra7/m9N4qIuSFVNWZbOorosQt/
2NHw5EzVWAmpn9iM61spYhQLKT2WsaYGPXfDsVmj+KUcIHyJIsRBUEBGWJ8pT35h80lTL42v6sPz
jPO4skh0WDm3ba9hOjTjng8tSFNfFrZC7kDwyFqX4xxUWCvn4uBrYSOAFJ6dngs711Mz/Z/o1G+f
6LqZYBpLB/GpPadPOpxRqwfNFEGW6Qq5Z1hlXojg4HrcL2GtD4v5uIeZ8+HFvF72JEIUdRkXevGZ
wtApHVsCxKVpNsQlo7BJku3prS67b3gq95pdrgu/4QAgO11uEKd85T1oiAzCA3gPyIfTAqpAXsH8
hA5iHY23OxSc7QUA4MeLs6z8o/f6dFwK6nD0dSdaCVUsKw0P/dA0rEbM0Am3gGN3q2CD5u6ZIRQP
rlqD0m/ND5INqhB84skSQ+mGdfn0DwkCbnQexIS7x64tCTip5Xlc7yc39kEuJxF1+GaE0DE0yvp1
IAGIzOvCLcoWKEEh0TgXuWIaVVxWUyAp30/po00brQqSreEkTpYhedL5SD9MYcaVXjB6AmoEHFCz
hlSbLFf+w4nNUE2VpyY3b8xbDllnc6HzJ7RlYxdCFBzqMiR8mIr4o/tpLhsKWao1ACXWx/3SHjbd
lBP5S94aQ+xdPzOvRMyu4a6uCJM5bd8EbRcpN2Jh7NbHj8rl1Cy5laUQOWc9CJ0sSLxQFlwG6vbY
aiDpu7VeDXH+XtcYzW90PO/3xlE3dRnT2Dpq6OOdNWWpdRpiPN43KOBSTjK2lVN37BOZvhtCLAJk
HGqAN2FCqLzF6aLjQoGRZ5C8uU5bCdYOthDVtLOO3VPhIEGEhnAeD2lYbvUpP4L2IgGrGL4nciTx
Z4pUfC22+CZbnBRZhMUIlHc+KRkBz/U8EsZDtZjID3TYhOYclqE020lXuyA19Ap8NnowmkTvUQ6d
QjtnLPAzbw6CrlbKLvnJE0ptaJhB05zAvzCfeGNfEVjz21njN4EAGtEboc/Tj+/v8zL3q8NenBeR
8gaIjb1H+v3cYOJaYz5XzE29MhWOoUiPfeBs/kqkmVWzx4iB+yp/1PDc+ywOpYDCV5gYI5mxbS2a
ClQKigKPMDnaVQKVb80vIaM5gTvBdzOmLmIqb5XHItPwTjLgLR+ApEFgWiBN5yWT+aUPKM4W8NIP
ivLxDf3u9wE5BtuIQMpvFlbthAGklILO9vGjtPGdXOE6DV3QjxbSS/HuF/yGcEGQA8jVK7TGHH8t
fvdMaiG0Vt3Q8mItwl+ShKdGZsRsDZHwnQnbIja3AhrCctjMni8/RPS5G8vMb5xkVHJ4m7qdns8Y
6DpZKhUorehEBTEWF/bIYSeLxPGL8pBeU3KhwRDo/NGn3XYi+bWdkU+IaQF/mWPrhEkCWcgoklC0
ZzIB83nC65wpt6cbQIl6H0pslO2KceT4Z/tefN0N64yEFLOPnWDsM0GBvtE0Z1CJTkHfRNHfoEMS
b6dKkGiC6rEq6R4ZPw3bZXG/sUYQnboZs6STXvlW3tAkDgRTXzCmoGjJHrxUowcPxxMarSMB8jAm
FkOm8LIXVBl+CXIg3bMSzV5ihpKsIYdNQHXJXhUTH2gmnMxxTYDXaBW0YerU8g1P4ZKW11g40EcG
BJts424MpuA+3duDGRS8vKotCjN4P2KOdpZ/a80pvm4EBeCPWE7jGMSN626VqxHvYQmyqSRUUgrQ
EOJKOO5jY5ObzrFGNVOI6jRM6uRnA5RjvY8j08hlJojhOg9VDGyxu/kikEUfMDMTmEfchcb3/4/v
eoacMqwfUGeQLA2/HGiMbBBy774EyUkSMaQqsXlasWn6g5gE7Tn/au++eQzQdRsPvqby+3sddFs7
kYn+0NSIRAp3gxmHl4TS7RxrpAJItBVagur4B/45cQg6nVwgtfkUvzhh20wNOBrQfRyk+wBRDdIA
55MLvBAZL7S18OKikIVd05t8LPxnkmEc2gONCjhpvKBhtBynb58O3K5wZogqp1BaJzaqzRCbU/Wr
b4590/zopMCe6Ysuwx1dJhF1TpQlJNA7a1nMez+YwMj2MuSWUfbmcuxZOLmqwbVJMptu2aRpZzuu
AcjJaKlhZaKu9iyyCF76SYrw99ofFE0P+Nu6xXzv5s269tJ9inV0Yl3nvvz7KwfotXsnT2Ych0Vc
1Ueterf0JQCmevSo0RAOshpqWrjHqGedvdbfEWfm2c1cuoE/JZ7OQdXdVgHxV0OMIIacNhzjAYC2
f5lTFJYG1yb2F1EsrfpChBwhrCdZrKkRSS/p9HfNszSkLFzTUCSTADqMS/igzhJi6nUrdPpQUc26
ST8B10TeVTLh+17FwgzqijmtbMjjKVJ8bg7U3iM3qn++EAd6gucroxTJUPbZjWESdqtC9Uv+a5Q/
P5V0y4NdXJ2cSIFAY3ix+SC0EPNQwS+cxxk9UyOvH7zWyCHTSec1ttYZvKZa628IrL1CqCEirkll
uxpZdKr8l/qBczrX2S+Uz1+OkM/ISLgt3G2Ctgfrkkj4hMGXokMAozOJ3tNqyQdynUzb0W6bqSyQ
4TF/NWw6Rxt7on505ij5Pu39C8BEauhOLSGExJ6VcqumDa9Z/R60KTYjmiIErxP2Y2hKRIsNber+
0kpJjDT9+Vg64BsXg5O2EFdyqO3n9QI55N53ncODkt1mM5lHDpta08qdUJYrRUr75/ItR6WIMUNT
FpRm2QjH4WleigdK4AqCO5CuDSr8dvddFN/RAPkbSoDm0M+gv8S0QH+hovPt9G14Tc6cs0CWS05m
hmpzs3Do4iSaKmFJHij1w0chLGIbpelann/JDZDopsdm+ORyUDT9bwg3YbYOcqXdwdTlWXk+a4WS
lcqXA/JRbM3/3F3vbrLQpIwdAGqE6cISf16RbDB/kKmdIGifg/Exc2RYxvYmlBks5zOy6tha+uq6
i1HhXzKclyXiatGbfq914sVmWGI+0oe6xH+/3Kf9QfoLQwrykkf8GPxxs8Ul3fIXn/C/3acEktQd
DhOnqROsGNIJn5Z1pZf4sW8XqbGe1fwt1S9YYNdz/+7FWNGve0b+4OcDZW2cy9/+UByxXr7I3eoC
RS1ue40o/vtHW0YEbLFNgKlo+oUKLpERKe65DLvM44retB5MTHIG8+ePqeIaZgu+jJchjInOSJ44
7FUcKSAIEu92qPX+98LsaukYoZqHRRmn54d8hQjH3kcU2NsX8yh4DXPQCUTEpk0HLAauVmjYqZF7
a+pO+Uu9INDr8UEir4s3V5oiwoWvhdolCxr8RLMYmTMpi9PYUijAyYGN77Mir8QCxRVTcTq7jCKv
1hb4b+iyLKqRpVT768EAksUJIfS2dQn4Oe+FtuAGgjnvhEQiXRayiSwLWbHY3IorfnRGyqi17lPe
qkbFwFvzEV80wF618sg5DhVcHFJ4gL+WxWXNA5pCXL2bwXxZdDKVweHEoPQKoCfvy9loznn3riR+
UOO2N1IKezW52+EwKarfMB2xVNagKizhhzgsDDxv1Nr0uFyHm65K6KqOYBok5LvUs7DsfWA1vxGL
AOr3a4AGQjcIGnTRS9pRoZIHgpAjFSlwrL4OK8ZTwbQrGY5NoyyrFz03wGTXEFxsXUNrGyIXzx4h
s9LdkotQl+WfwX6NXFmm+gbyJnx1nEYuj7GS0APhKpHfCnprL4qe/q97qcdzuZWrMb8cqwUHteRU
WYfpdV3+pIkt5K34+nAPJE65lzLsDbSWopxG5hKFLnrByRdqOw6KqGI2U1cNY7/EtoSGCW8LDyUH
0+RWsjmOqcClus2P0/cA0E3bsbE8bz2wZ6OFluISEdimMLGDnHLea+HLUAhBNIJDFwy9mVb/Qx/A
OFzx1AYvkpjrdfUqhZ7LqQ+Morff+uWVKPl8J+vsHSUGYpVi4Zza5sWTxfV0+VIiCNISYkcFMZQo
yGvJkLa0hj0Y06yrCTV0oDl7YGiRZ1cEowU5OjWWgKCAit27hMaqSwC0OJL3s2cqMgrXGiKTIH0i
pLlj0dQE59r1YtyRzdoIxzVOcJD1EXBFWOVsM1WZ/U1rVDJhulA4gQuvVoj1Y1b3IekkpfJ/lqyQ
UhqK9nk78ItgMMZe8z6idbG91PTGhl28gGYEHuPCRpJknhHFiKbqFnCgIMq77g7dlMuMsjmpTeJ1
OyduHs7+Az1tP3NAugj4aSaJlDkNgTYBu8lyt4nRks5R3UhlR8/8fUptr9OF5uhz6IS8Gh6Kn7k5
O/OQS/L9RFaXvP2h7OTZeCRkaLW3d/EV4y4Uby/8Q6yCvElc6h6wkkLxK7WkqLGSNqGrx0hPNnjj
+ld2Y6UVyaBnFDHVr9UjKZTd7Fh5mg9NYKp+xLa3Kf63eVpEyd5v7/RBRU1ju9Vv48psXsaju2sw
Gqrs4of5xhv7OB4s5uxjU4z3rlSr6Vf9abSIPeGrASzSclJ1bEGxEtncPdiHUGL8nK5w2OLU/YbG
uKqQntXgVkhLWiXjETxmg3d0JZBY+Z/Qz5p+8CXbM6MAs5DxllN8tYGqP9jrZktRI7OF9Ipok79E
TvmbalJpSmGoWK+3netcq27hixB7Vp6x7cMZIFUw2GZGULNN+DH8+qqxWJuXoByuQTeiOAPMVCGg
F8j1TU9FcPHKJOvm8X5rkVzplf9SZ6kO/XzmNEi5gGASY7UH5Guf1xjwFJuKOS8+huXID8oHie5n
gtqKZntKTn4krGxBmiXTfUFjtLcmggpl7o/3x8WDju6af7GXVaVs0y3C4ym29RENS7Xi6SuO86Jm
ai2VVZ0VrM9mlVR+w7r+TM7+d54HDCkBfTsBE75e5ctQOIC3PPbYXSZ8LE5/EXroqjT8lyrUpIBO
boJIYutIsCA7NdRwT0vdzn7MDQt27iRzT+12MOeIuWl/Z+MkQV4v7b5h+gZj6+M9uL0j2gttdSdQ
O0iKlTVudX7UUOgvIdEXwfjPzVaF27RNin2hWMGk8HfeDQO6W7uUUnl+vLjA7SmU4peSgkkPQxxe
3wB9R55VwPPKGxKJG0YZYEIhJWlrOdSonweG8hz6OQqu+aiXqaVg/nyj6bYxH4hIruMCLQiOni1s
sMKL+kYJXxYQApdmakl2WYgked3lTcAMoOXEkdIlKWHfICWOyUHgyC6JDQVXI4SjfRN8jcMFIJ42
P1q7NDF6Vehc1WXhgJawYVtVcAwDEL0SlxQEnezx7DuXpx+G+6I9XB6VdwfE5fPu0gsZT4f9ws9G
P6WHC8H1TVq7vKQOhBRqAJEcDN6/IWdHqDta0enqr0sxxD41VysGFnA2gBtfrlqbicfLPlOGl6XX
T0ZovQP+S4wiaRkLx+FDjLWlW2WrEeZuSAtTcA528m1oKvtA8X/dNwRqXEO70nEHJwvfSSTqvxnW
ixhmKBGeEQx+eIQXmdWckFv3KrhV9I7osGKYM7MiI5ozjYcV26kO6V1ASEQKZ3Wn9HlwsKdy1EH0
wNx0ikY7hswmwTMApeaPIkRwTr+ch08dvlIv+tEt4CADSSbZOqog0FrRfiegpvjR0S5BnKVDjZu8
vsGZek/BgDPVcQ+L8UpzX/7MW1i49J9ALBezMeQGz2iLP03jH5MoSSZv/lLPCJMyyYu3heA1w0Pt
AUjA0cwHGLPz3fXOXr+eMUwY2cL6rnADPN5RQ1cHxTK4TEAL5jnYEy3NNsaYrZfI/2hYOd0mH/Hm
JRQLND1lfRAhxXSAzfoPR6Xql5F2gxKi0F8RvMT5ckYtTGlfFvLWw83rpNyXXHY7OufgQp4krPQB
1ysMZoN75pQMsqLAsd9th3SrKcVBjiZOESQEngULagwct8PkSBlpXniB1luEyiGEjNI30Hyclilf
aXFaLYELbptc0kS31NkX+V4d4a1a1A9oyVcRsLf55TstpAKpxOxc5qfEK9yAbqBx/Ta/U4I8t+gw
rH8KxMxA4GwkOzxStnaMG/lYJ7xUtDT/3Aa2521aXKPW6bOMX9xZMXEdU27E22NQUbrUh+xMFsa1
PxtFTawTj7gWzP2yhNz0nChG7W2524K8ug210RwCLOM3rBimOFHyAjW+tRj8rOZ8pgaGc2M8MC0M
GvQj5q+AQr+QdN7UqHnqal9K/vkNNKwcSxALPheHcLYyVnJNe/OY7um4+EAFVJ5fihtqLksTxlXr
rPXEfhp723TGDdZPVYRRe7M7wTzO+k7mEscKNB5JDC+bMaLv8cJrs8OM/Jv97JlC0J0tdkSt4n/k
r5MzKypr/elBnYhUEI8iwE5384J9aW99hLmXeo+InB99o987nqpPiibOF9ock3i1P9NHMHdBwUa1
OL9Z8Ya9YLovSKYns5BfFbY/NyHaIq4tr+h8Vcmw+NwZPfuju40WoM8HNtNAc3xHARJj2bIWv258
ePFbS3UgFItmZSkG4/k/Bh/264g6OIy3s/1me3pmuzBDR2d1oHn16jRQHqPkBFZy4NnmJVfUs6Qc
522tuxCO5jF/sDCz8QqDX4rBZ1c9/cnd3cjnxJAm9FgejLaeS03pvw0fBD3/NCOQyjMnTBtEMkKy
00jpGZ7vRGwrNAVDkKuBlAL+JRj/vYhUncyc96d0kNx8bX32oksMZv83D/n9RvPSrgNDLA75MEPu
nWy1Ig+AdI3vGMc1d5lGOQvDRTosJlfo6BiK/ffvy16Hv9hYOwMaKc0nOzzCmRhu4sJHTLxH71Kt
bP7nfiFSFLMcVl90wnl6KDXrom32zg+DmfmCCUHZGEtdfCut6agI+vGQCqkhbMw81bGKwwAWO+nr
Zk85A+gRYlIAQgCfVkS6oX0M4vT349ORYD4TyWAPT8fB+0KWIqx5aOl6WJG91sbe6UZo2R5ayTe0
JFyulMR2L2BZ8jH9Ad0uZtIM0M272gdub8EUTEWzjGWMB358WlFK5BYyzJPpJPpBd12MWfBE/Zya
Gb7W32YMLO88FWWbYxpIqi3C21Sjen3BfdtojKifZ4Xrfv9LXQupsuVJqnt3j/kzWLNC8JUPXZTd
w8EWlLKKwJkOzOWMabXYyGiklQjK4/hHvFA/SWlwIMiPLNc7QJQdKkWc/wXc+u3LpYf6zxBf0CKL
EMX8GgRZJoikVyWMovphCWUyhdWtPkE2zGNg3ZOMN1beo5XqeL/41y3efLXIqMKYb7KpTxZHr+ax
O1iCT+f2lr4QaM/7rAIHUx+3m6n8bB1LWqDxLkdl+yQO2xnNraoMSgY1ZK8hDg+O+7u7P35LrNqU
FJEwmWg2qp7HIzhBhEhPtzafX0JZBZf/L+tibwH/lG7otZb5N92S+C/Tb07vRzcZwU4S8zB6FE/G
RqXTeJLH0Rraj+DQkQ0GxgWdLPp55nSLDnndEEQoFGbzy+4o/eNE5lixVJB5NK0QiGX6EZYusluS
nIoFh9smtBbpXm9pFP6j8mKBvumPrwgUoseza8vpUA9yrFMMBTYVTZxPN4aZ6tNGv81ldZRnpabV
kPmIsxjeGgXiTykdJOXSGIWbvNFiZ04wJ9wvu1maliEEwooGBH+p4V+A2WOfoi6fYsQoIXJ/wfHb
sFEgIBT5MFX1MA4b4fFuSNgncus+7oLNjAuz+elx+TtlsJlTV2/ijC7dzMOBnqv76fuD9ReU+eOL
kg6RHG+v604s07T21CrmLVSBiG0isGLO/qpInBLI1eZqS92tT3oLVqC6gYagdWY/IEgQBuvcRvM4
t14dNVg596xCcl3ify75o2SigoasS+r2aM5FUzx0XvzFlq1fUL4P3K9TtQPSsWNdGEYxrQ21xdmg
inTNoVdLZ6D4NYtp9C88Ls/hve42Mt2jFTw7X+FCB9p8esH9q17VWLrUYZjUjRoSTBYZl1BpgBMc
VMlDjfizesyCcgsEP1GTBlc52I6v4ZYNxVKej3QmMqFp/SrRcJhfDek/sYTtfqHGm0z5po3ZehnS
Ohk2DZsOVlgcojPFzYOAGtAyIDeddff1Vo0l/P/hPoDMdvLnGj1hDv7efldvFGrElAxfcIfYYklS
h85n3t4P7J3u3DzhSt8doM6gQSVu3i4hE5fGoj6cW1XOcg8xznF6eBOYDLTpkNMs5gxutd10uPE6
wp/4wvKH/Lpyr17Y8PGeAryLIJO+WU/p/HlLNpTLa/U1M2ViL4Qblnurw2NGSNY/i1GtvW91w7QQ
X4ZxWuZxY8vKrOxvwsMDgx3uenWt9BjtrfZlymrKBnFxauxwzMYd1XjKG1pB0nW95+ZFZ+9o8/hA
EwdNPxUKueVas7Z6D+5MhCPuXnXnGlfETrib3I7wVGflwaGkhwoaHQOtVwZYT2zIJ/AP3xACiiGO
+h88v3CSDL3/j/xcsXgZMzomUGI39d6XeQHU41Mq6DXZGnDGZqIRGc7/37XFdBj8e2Z4q4Yjm0hO
y+0kO9g0G4bNJ3jRsozhfCT9pi6fn0eXReEDDOXpi6eiAIcfRVQc4WbQrLkhPV28I1nvVTlKnSGh
W4IE8qfQ/BTNpI2+1XCQHYV+gKAFTadmupl3wxq8dvafvWKrmzh+Vk+HlwyTFKtEjUla6oB1JVqZ
OU0sjIYU0r8LXkRm+fVUYShZ5QCb16yxJvqg5xs/eb8SVv8G0bJY+2hzcGZ6fAvlvtF1bi5V+oQ8
z735DhbLRR1ICYdfu6QrT7MoUDv+Oc9Rs0U8zpvmv5ve1odjb3fgeF08YfV+zsE9Vl+PWuZNVKGm
Mav6zMpji0LR8XhyhO77DK4Sz2cSUOEgeJE3/UheHKgCt9UqQr40/Hv/c0dgHuNTPr5XO6cv74Q3
KRcfT/NLAB/eJ7WIEsDCziR9PF6voQWT1/Zrk9fPVhx67342bOAkfjeA5FPy3jegg0fLy8rfqMy7
fuHRaQP0VyFVqt59ieRMpzzDJB34CGeAsNgeL5bnTqTWhlmW2FkZURI15DuO54UZosja4648uDkx
HUrbS83TDeb4yMrUtlOuBw4E2sbXZtZ0S+DedkFUtcZjkmv96KKLHN5RxxDaYwn78dM0yQCE+UOb
lK444fPSnzYO/H4w2OSge+1e24iEQ6A0SNPSqV3mGsEfcXwPy3XvEW8+T2AoG431QMWTCOOSvXy8
tedwwKZrGot7or9+KjcpYKJx2y9Dt59uAls5Rl2zv73y6VptSly3JdCuE9snYjSheKHBCE2wgqBg
KIAtnqgqaNzn9qLymc3wkIYWU3FAz/V+ab711Y3NzfgWKr6gU1CHqsNH8vAIDJjz3CSDmAj5Q7Cu
zV65GnDncRhLsxXu13WhAyGw/SR8nuNNUKqDKwnkzZdf2S0UdB030j54eqQnNRybShVwNg9xNrD5
PDYp++tDbm+4hH1x2vRBCYzlPYbFw990bPk8RQo1m/LEMVTVTLbMLk9IH/fc2LvatFUYtdZkec3t
k9Ezwvzn9z3CUHJzf5bOkP02x2RYAgc/oElpsCMsfQupzDbT11zzydX8+I8V5liGUEfQTAPsax9D
rM8x+8xFxsIV7+QwEs88QTJmNyK0AntEj0gnXsaJimaBelc6J6Jx66P1kR4+i584Ip4HTJBcfBfQ
T+cBeNwGS8OR9VZ89W4fpOXqbIIIwt1saJ0vzl1I+nmwr/XeS5dw6saXr6EVpDKgWbp8kIb7XoCM
kjeMLg6uXNv5AMA+WVINIQuEzXZ1+zAFBClk7gUXZN+guR86kQsg6yzsQ+tCK/67rQchTxIRnJKw
1dpRuwJ5O12vHGe98lj7Szx2915OUMm7QJXHHks/Cozo3uKRZ+5FUCAWtHL8rNnX/9Eagxy1eg5l
Dw99t3H7k4IUM2r1eTE5oTD7K27JScn0WHMkzyXmqMLCsNHBHXFm1negSmxS9/U3/2JClxvddeS8
ARjs9Z1L+igkDTjqtGdXYgojF2DvyVcR9obwxsEMxEXEtilW+s33HtW/AZN2ZZhGXxgjN0gzblWK
ctpg9p/hvRF5dO6OOm01QiRk1t0TJ6nmT4CHo6cm+Z6nykH7E/5EtJWgewDSCIGMttiUgeUD0Lwq
e08INlN/TCHAaPxhcySSeUokeWeNTU6BXjSEziIugc6WFQoPuPU62+rqQu0eAC1YxEIJ0i0rbbMy
EmU4cSfJ0C3EFLRWktSATePDLZqy3ASEdNeBSVFqnlwsLJmp4qmuSp42Zu5761o5A7Hxw+A0rAED
CVHpGLC+0XAYftSAtG6uFJMI8OPJ0j4IzCS0zJobOKHlGaRMQdRhq0r/a25sOKPK69TTW3X8ap8C
7Hzv1IgRXadwbrNAXt1OyNEeHRFLxQfULxMM7R2bKahU5QBgvhs2UFRNUUTJzyW+pQQaH4mLuBg9
Trlc9JEyhqXHYr7URSDjf3bDLgmtB6eM2XypAOlW7zMLam8f77n6/M7V7U9BB2RExLR7B0DtQE/Q
zCpkF6us0rZtgiqqT+gcW9SC9HI5cmVHsTkwP/Ryhd/7lsxruS1XzA9ae9TSPCOz4kqG8G2CZ9ZY
bcO3rx6Su5PL7PtHkL5gr0Wd8NqiIGQ+cEpmmUKkle7LAr3B8F/+d+vGSiB3FZ9ebFMdgKVKe6Gb
I2f7qSNRXWgHxO2YtbP8y6vDmc2vWicJ+GCs/x0PJrVzmapoe5OQG0yKEiU+Bp8g9qPskk1mdH9m
D4hy6+KQ3/1AWJO8mqtY6/jNX+td8sNeBKq+Kvj/uIp/um+HLHYcbiiJbfZeDIDG2hUTTI7VP23z
PbQNfTbx2DZnsVBoxhcVDW68lgzb525/s86ZlSUABpokIRoE/NnZTWgf8FOUCUcLbYE/hOBBJ11R
CuqYxsldG88fxGmLhT24BKI8q84/S4qsh/DQkZXPBn0FwRLer3V8Zyih3W7GGNGjrjASVwkqXtzS
USCre0fk0h8JHKKs7nRyMFPGld2b7JPdt+AcSb/+zM76KDSEmBQ4dd0ws0cW/6MeuLK6LdtlxQpp
7R8qwZNbGD+g3ZJhPNH6iCWria/ZUx0z7XcoIiU9YBKzeM/2+s2PKexh7v+dryLZa9vIpyFX1WeR
+WAv0rhQXiG/PiRO9X18RJ6wdRA9yi6H84DJJ59fishp0klpkl4qPHgf7n13wnihG1vnLmf60/nm
ZMwSedWcOHnpD+HCCV18xJqvzSM81IpLmlFKRixVkv2grHs1bcMnI3W/mkDn+LtvV3X68SDeLyCp
L+qd0C/tqND9n15nqsnT/8krcYGTYkRCMXAe54bY0MrDi+u3b53zMQpBc4Ea4C6RizaDqbhAh0A4
UJ76X5kqPwxQ57QZoxlnS5FHJNJ41ZakBs2hrmIgQ65/QfWNxEG8q6uQc7evA+5rE/eSiq8TKBRs
9M7tMMsKCYnLQMiNlSY/+K/sYIGybPWcBkVwsMZUBttWrlriWL6gmIuqcXz6IJNEnNy3i+di2F1M
Aaw261aUh7W83XGww0td0Mxc7xGhdL5C5zKcttaDjiQbAuZLpSuLrPveV0n3vrK5G9ZV0Xij6J4L
dZ33r7yIFW0V1ONTGfFscSpoeDXkJrsG8FYVwqE39wkb3YyPbgk0P+L7OgrhpHygWAI/OJ/0+xy9
WaNlozILNVLj+gT0EaUcASRGgUGUjEAsQbPnhE7EyQlehtKDv76HT0ie7XM9jYwBSSJwwKSRTl6d
k6XvuXkd1xX8Krz23QXFqbcPuVQgp52M6cBMQa0qC1Pyk0ScM0A0+pxYRTbRI5uJHGy65iPSc5Tm
5a3CTq2wmcPX/TSX62ED0F3O1ztrkhqCw/fEfh6XhiW5b4XO4+R0qs4n4aU0ahLF/g4rBoyIb2U4
qSV032mRPnh9r2fbvtjIWXeaKK/DOapSPobaBmeNeG2AmEKZHvN5NWhu7QcLJNcoXPmcr6rP+Gtm
DnHBCW9U1G8s+9xqGMZdQjhE3h5OoJUNpDS9Mea6y3O254FpXw1H8SKG6bBL7eJr7GrOs7KU/Sdy
sfJn7QPcAprxUwfIT5EMx+kHsKJyZ8YlwBgz9bldvGjl/NVt5p7pd8FSWjI3QbLHXqQE0nuNpfcN
0XSnV/TzUSfasw7dj785Jr0YuoEeT36OrLCb+Z8l2gUmfhRc9AE8Ck+4Kv7jUVpQJ8mfUKx2OTT6
e0fllhRWlHPQWioXbwLKEAuEI06E9eAJbXPFhnKDqx1VHbLMI6FveZ8p+AGzG2vD3AtNATLlkLeP
u1QwSVpTuwkWY5k4oVF0of7x9yuCpylPyIF7+qto5sns2Delo23HdztNNT47dZ9nUOVmrqnoPabx
xihCvUVlbuHDvLTu16qWGgLNghR2OOLWfCh4iIkZ4CbNYcZkelNH9gIpSJGSSOYYJAGbBTSCYukn
wzk6PSD2BsbZNsjgbymvYwO+X3pMYirviGoHCQ/fyUtyQDI3LsRVcgl5E05/+QhFiwws4lYU0J0L
Calfgk8YPHyii5hKpEhvlTq1rMfiGRuNeFFXrWuXvodl0dbp+a+t39+FZzs0ksnaMil5CCHOiLMc
CoYk4umoc7OZNqN+5astfVhLoS+IJJJ3CjJP3KtEkpPwT3kZTBShEliall8ATWcBjDP/vYe39NlQ
7HYPzjSWrgxVWKWm9VmIczYnTzKjnVmNUf/Gci4H3bTGkhz7JVBBFeSxC9DwvC7UystplWWLyn7a
4BDZ3zX8X3kmGs1T6I3B/DMpxjKDKOW/Fzn38naA5aGrobvfjv4/1TK6aN0H6+RpLSy391Xccf2x
pmV49b1KivDxWRlKz+SyAKffNw2XPVVDMe46NtVGErZpdCGRhRjgQF1yqlmfTJ3Ihw1JFg16l4Rb
OTSFxM4iqLh7E+Bv3Mpjycm04DlggA5P9BH7iuheqHFam16l8JPy95a4oc0UgOYjX+hXJE87M9DT
71GCwuyTpKva5eJGyawiil+qBypGnHnKMMSGWC1waQZ2o0k1+zSc0lTCUn/F3m4jspJSCgJwjse0
vs49nD/xjNrn6ud+bmnn17XN0R+j7IDTAfu4NXHHDqcg+WLtX5OAAxZ8NWQAldAPWEjFBVrFz5H/
Zv4LHS2oPP1D/KePcip3ZYKA7MlF1PMNQWS/yHBQcNcHH6Fs2LoLCH1iRPG97DETQKttSd5qAi9e
fXwhOBMZy+dkhPg8Mb9kuNc2PGZLAbfjcI3x+QhSZU3NC4xuhVqmF3AkiYuuEzT4rSzrLAyPPHnv
SqHo+k9T8yHPT+3/HG9LHEH5gyV2u+XNwDnoMBeO/6yzwUCQu1NKpZ5bztoOtVIp86tkjEPPmUS1
1MSt1bz1rVwmRtb9AAK57FPtqceBV9R9yOYX3koTRB1wT0Y3eh7D2zEAS/x3TaeWzx4JQz0eJdZm
TQCHjS7NdRNvWO5tSRYgu1qYJQzpsSTQX11yIDJGRtvVBxAAQCVJ9rvNV8TMDS1oOWBJJ2+AyWgH
++LnQ7X8m8kNMOqYgKZR8IMhkR9slvGF01LHUsC9wGTXsxr5VvnSfBNOXbXF281JTTRIRV3rApqi
7AV7j7Hk0LlOzWm3G1Alxck71RI+6cZWWgvX1vTMpfJTmwAFVKGkPevk77HQ9rhNPq2N0kIEj4iV
kjelGhvK2mjAP7Dpoz5zjQF6wbHilbp2R6e0D3Dosrb27oHAXF/BkJek+g4tXtdzYRMOzQCk65cY
z8XrvigQtN1R7cSgBqA5MZoqNH9rU1yGUUVrqfz1QpNPQ6BnTIh3DHu59hSILcTKOK/Rhmx7poDp
8SgT4QVsyicVRCxJ27ETcCbE3zvIOxePNkyCHXChdQarWkO+PLPsH1TJNrQ7XzSwsNS+ftThwumR
BN+bhbIkn2anwseTIAPW/9fi3JffS+aCHVjEpemV8/ZWImhm7eFH5OgbHdMNl4CaBFvBQiQopDlg
5ufResSZyzM4glSmESmIbQ9GbydLCVzvdFJIZI7+FVsU9LZCW4QEIEinDQUcfSCuvlyvgeI61l9x
9hnHwlSGx2b+vS5Uo4+I/2NVN7glhUwpcgyLTR7Xz+LxAT2wtRka5ZGjQO9+P9Gowgu4Pr7Edvfo
HTJm43aNm5MtmNNsLWlwn5XntSHprrDnlNGxOYq7opgQz7M7oM6o7FhvaRqtw8xjKRgSrBMYTggK
9DoP0VphPB6WMpxtm8RXIF0qRNXrk724Yypz2qoek19Y/B3ij0qKxKgm0m6ZNmrssB5LaIJsPSid
QVkvVJkzygd9+t0UilNz2YtU+NyWikv7c4DagBk9qsxAJCgJ1lmgQWsM5/BaK92//CkL8u3mAMSB
8IPH9VcS8w+/jO0Kx8kp5Wj5VUfUF+82tns8uDGiuJHdepWQZWHKoHKVtcIEi4nGzuvXIAz7G7sM
ykG9OShFXEVpOWeSUqEfwuw+0Otg8eMJ2KhX5Khrg8iBjWhkkZ+KBK9uxlCplWRca+M3DBQhP16H
KHjhK67oWoLA/uic5RD97+XwIPDJg7F+bQM4M+rnjjPcAcyOUWrZc9L4B1ZSw/02EB2pHbVnhWo0
R6boomcF22fT7Wl+jnr/keVfXsFhFM+ZlEvcuj6W5KrYBvxTqUyxoUMv8d+5cJ9O+H3f86oIwXfZ
A/xGtlkiekrAiThqz+/EHiO9YHu6dlniUBWfLqmHjgVNfslpaSzcarxNeV97yWC3UKuzXiqy2G1p
ld4UUX/E2tLZZRuC/oDyz+aw/YEmocMqVu4AkeqWLXVaX0CM7RplxEMAa/zrX5BWVANbsxZ8UVtY
yyHFV5Bs0s2o94tPRnI4qYvH+iMljVavWBAv9tN6zyJKVYaYaom9eTAir1A/bKB9n1FTga2c7g5J
iE2bpIxA5wblZRieM0YZX55FcyflBsHTPgjmJQTFqzEcodPNrT0tgjihR25Mtd1kxtMZ8VbSaEqE
fw1zOot+RrTKUDYdQ1ySXcJvyWb/2bQgNXKnG3IqZQu5Hej3VXK3/8PCPYrRgv/ckn5KmrAZPNKy
7zQKkLHNlFCGIFtdMzzldXQBx65kwQnRavCJuudVLIXWd+PySWKXghy84+7sdfqGkNWVMbhmMEZ8
fPOu9RjIexpsbArpz/rEFsNvhjxXIKLlr+wpWjEtl78cOIwkMmLHHbC3EvXyqvMv7Kq7gnxOSxv0
EagnJ2vinjwUsaTVmC6dtc/u5IpOX6M2vYm6zLCGqX6U+bpK4cEUMBv7nt4FQ9b9Stn4pVcquThF
gE3lZGRPOkpx2xwsiA+gg1j8fg2XkErOJLMbHxodHtKXOmi9UXFsmHWfbcc9uKOcRubG8KoZ79QV
Z9gQoTJgCIIZ4MgJX+sU11q83wLyb3KL0qTRZmSAGO/SDtIRjMy388Xpn8rnnVrdz4yX5o1tx+SA
hdRg30illGQ2KUe6WQIThw58pJi1XXcDWO+O22E+AWyMxSBicqt8TdWFFnnDc3l95+NrwjpIPpdC
jm6eSLqghqLng3KKgmzthVCmz1vKYD8B4e973PsWOr3JWExBKq5IUfe19pWVsy03C7LnA57suapi
YJIiRAoTbweCqXn4jXt1Q1BwtGbh7Tuo8IVszPvukclRQsrzr+JZ1Kopq0MfE9GZIfkRo0ByCBbR
4pM4Ev4tlIN7/3tAKBpgb9XPaf5qX1R0CB7o6iR5OCD7l63Ye0r9XUouUfJ+g6PjldXuWcROo2bE
esQ6F4buh6so8VMxrXCIYMdPUm1hNkVfquPVPJQj7MLhd0K4AxcAGoJZLlWJfxXEyv4sOTmjaPGq
LXOkIJK8iqaMx38PW7Q39aDZBPZnyqZ8gyXvCxi0YYbzLtSRNmC3SjbEAJNiRuzc04NdKaNH6+2M
UxvltRur/6lmb30prYzA+b8x7VavpJtBbykWwp3gPQl9/ELPIp6l4K4+TBvxNpsOxI+KJvJJHx1x
4CpVn0P00CinaYiIR5GifSvwT9Z3LCdct1REYLFU6fo+I57y+hbwu7NzEFNJODErHzptrdXc+2Y3
dw==
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
