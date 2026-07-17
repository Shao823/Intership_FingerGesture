// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Fri Jul 17 16:11:50 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Intership/ip_repo/edit_emg_accelerator_v1_0.gen/sources_1/ip/blk_mem_gen_stem_to_dw_conv1/blk_mem_gen_stem_to_dw_conv1_sim_netlist.v
// Design      : blk_mem_gen_stem_to_dw_conv1
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu7ev-ffvc1156-1-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_stem_to_dw_conv1,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_stem_to_dw_conv1
   (clka,
    ena,
    wea,
    addra,
    dina,
    clkb,
    enb,
    addrb,
    doutb);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [0:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [5:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [31:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTB, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clkb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB EN" *) input enb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *) input [5:0]addrb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *) output [31:0]doutb;

  wire [5:0]addra;
  wire [5:0]addrb;
  wire clka;
  wire clkb;
  wire [31:0]dina;
  wire [31:0]doutb;
  wire ena;
  wire enb;
  wire [0:0]wea;
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
  wire [31:0]NLW_U0_douta_UNCONNECTED;
  wire [5:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [5:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "6" *) 
  (* C_ADDRB_WIDTH = "6" *) 
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
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     1.375111 mW" *) 
  (* C_FAMILY = "zynquplus" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "1" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
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
  (* C_INIT_FILE = "blk_mem_gen_stem_to_dw_conv1.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "1" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "64" *) 
  (* C_READ_DEPTH_B = "64" *) 
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
  (* C_WRITE_DEPTH_A = "64" *) 
  (* C_WRITE_DEPTH_B = "64" *) 
  (* C_WRITE_MODE_A = "NO_CHANGE" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "32" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "zynquplus" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_stem_to_dw_conv1_blk_mem_gen_v8_4_5 U0
       (.addra(addra),
        .addrb(addrb),
        .clka(clka),
        .clkb(clkb),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(NLW_U0_douta_UNCONNECTED[31:0]),
        .doutb(doutb),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(enb),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[5:0]),
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
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[5:0]),
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 22272)
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
