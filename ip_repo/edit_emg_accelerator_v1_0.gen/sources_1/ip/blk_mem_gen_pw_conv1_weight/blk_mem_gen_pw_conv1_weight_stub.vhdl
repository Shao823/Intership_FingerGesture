-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
-- Date        : Fri Jul 17 12:22:52 2026
-- Host        : ShaoQingyu running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               d:/Intership/ip_repo/edit_emg_accelerator_v1_0.gen/sources_1/ip/blk_mem_gen_pw_conv1_weight/blk_mem_gen_pw_conv1_weight_stub.vhdl
-- Design      : blk_mem_gen_pw_conv1_weight
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu7ev-ffvc1156-1-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity blk_mem_gen_pw_conv1_weight is
  Port ( 
    clka : in STD_LOGIC;
    ena : in STD_LOGIC;
    addra : in STD_LOGIC_VECTOR ( 7 downto 0 );
    douta : out STD_LOGIC_VECTOR ( 63 downto 0 )
  );

end blk_mem_gen_pw_conv1_weight;

architecture stub of blk_mem_gen_pw_conv1_weight is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clka,ena,addra[7:0],douta[63:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_5,Vivado 2022.2";
begin
end;
