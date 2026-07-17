// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Fri Jul 17 16:08:04 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Intership/ip_repo/edit_emg_accelerator_v1_0.gen/sources_1/ip/blk_mem_gen_dw_to_pw_conv2/blk_mem_gen_dw_to_pw_conv2_sim_netlist.v
// Design      : blk_mem_gen_dw_to_pw_conv2
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu7ev-ffvc1156-1-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_dw_to_pw_conv2,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_dw_to_pw_conv2
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
  blk_mem_gen_dw_to_pw_conv2_blk_mem_gen_v8_4_5 U0
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 30768)
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
