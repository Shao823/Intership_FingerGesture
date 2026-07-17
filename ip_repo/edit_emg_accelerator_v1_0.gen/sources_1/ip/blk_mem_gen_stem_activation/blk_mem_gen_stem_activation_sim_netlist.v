// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Fri Jul 17 16:15:17 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Intership/ip_repo/edit_emg_accelerator_v1_0.gen/sources_1/ip/blk_mem_gen_stem_activation/blk_mem_gen_stem_activation_sim_netlist.v
// Design      : blk_mem_gen_stem_activation
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu7ev-ffvc1156-1-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_stem_activation,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_stem_activation
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
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [8:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [31:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [31:0]douta;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTB, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clkb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB EN" *) input enb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB WE" *) input [0:0]web;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *) input [8:0]addrb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DIN" *) input [31:0]dinb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *) output [31:0]doutb;

  wire [8:0]addra;
  wire [8:0]addrb;
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
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     4.102289 mW" *) 
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
  (* C_INIT_FILE = "blk_mem_gen_stem_activation.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "2" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "435" *) 
  (* C_READ_DEPTH_B = "435" *) 
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
  (* C_WRITE_DEPTH_A = "435" *) 
  (* C_WRITE_DEPTH_B = "435" *) 
  (* C_WRITE_MODE_A = "NO_CHANGE" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "32" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "zynquplus" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_stem_activation_blk_mem_gen_v8_4_5 U0
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 30912)
`pragma protect data_block
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
75q1pyi5OR1zOj6yx3jkTKCs
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
