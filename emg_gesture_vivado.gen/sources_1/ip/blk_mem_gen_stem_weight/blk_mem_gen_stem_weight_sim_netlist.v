// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Tue Jul 14 13:02:00 2026
// Host        : ShaoQingyu running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Intership/emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_stem_weight/blk_mem_gen_stem_weight_sim_netlist.v
// Design      : blk_mem_gen_stem_weight
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k70tfbv676-1
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
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [63:0]douta;

  wire [8:0]addra;
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
  wire [8:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [8:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [63:0]NLW_U0_s_axi_rdata_UNCONNECTED;
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
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     6.370399 mW" *) 
  (* C_FAMILY = "kintex7" *) 
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
  (* C_WRITE_DEPTH_A = "280" *) 
  (* C_WRITE_DEPTH_B = "280" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "64" *) 
  (* C_WRITE_WIDTH_B = "64" *) 
  (* C_XDEVICEFAMILY = "kintex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_stem_weight_blk_mem_gen_v8_4_5 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 29840)
`pragma protect data_block
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
+vhpyVo4vmhlInftMVpDMbAabTdc1U2Y6uFTtOA=
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
