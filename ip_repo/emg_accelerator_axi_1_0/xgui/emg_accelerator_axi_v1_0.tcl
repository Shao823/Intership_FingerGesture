# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}


}

proc update_PARAM_VALUE.ACC_W { PARAM_VALUE.ACC_W } {
	# Procedure called to update ACC_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ACC_W { PARAM_VALUE.ACC_W } {
	# Procedure called to validate ACC_W
	return true
}

proc update_PARAM_VALUE.ACT_ADDR_W { PARAM_VALUE.ACT_ADDR_W } {
	# Procedure called to update ACT_ADDR_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ACT_ADDR_W { PARAM_VALUE.ACT_ADDR_W } {
	# Procedure called to validate ACT_ADDR_W
	return true
}

proc update_PARAM_VALUE.ACT_RAM_DEPTH { PARAM_VALUE.ACT_RAM_DEPTH } {
	# Procedure called to update ACT_RAM_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ACT_RAM_DEPTH { PARAM_VALUE.ACT_RAM_DEPTH } {
	# Procedure called to validate ACT_RAM_DEPTH
	return true
}

proc update_PARAM_VALUE.ACT_TIME_WORDS { PARAM_VALUE.ACT_TIME_WORDS } {
	# Procedure called to update ACT_TIME_WORDS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ACT_TIME_WORDS { PARAM_VALUE.ACT_TIME_WORDS } {
	# Procedure called to validate ACT_TIME_WORDS
	return true
}

proc update_PARAM_VALUE.BRAM_READ_LATENCY { PARAM_VALUE.BRAM_READ_LATENCY } {
	# Procedure called to update BRAM_READ_LATENCY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRAM_READ_LATENCY { PARAM_VALUE.BRAM_READ_LATENCY } {
	# Procedure called to validate BRAM_READ_LATENCY
	return true
}

proc update_PARAM_VALUE.CH_GROUPS { PARAM_VALUE.CH_GROUPS } {
	# Procedure called to update CH_GROUPS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CH_GROUPS { PARAM_VALUE.CH_GROUPS } {
	# Procedure called to validate CH_GROUPS
	return true
}

proc update_PARAM_VALUE.CH_LANES { PARAM_VALUE.CH_LANES } {
	# Procedure called to update CH_LANES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CH_LANES { PARAM_VALUE.CH_LANES } {
	# Procedure called to validate CH_LANES
	return true
}

proc update_PARAM_VALUE.DATA_W { PARAM_VALUE.DATA_W } {
	# Procedure called to update DATA_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_W { PARAM_VALUE.DATA_W } {
	# Procedure called to validate DATA_W
	return true
}

proc update_PARAM_VALUE.DW1_TO_PW1_RING_ROWS { PARAM_VALUE.DW1_TO_PW1_RING_ROWS } {
	# Procedure called to update DW1_TO_PW1_RING_ROWS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DW1_TO_PW1_RING_ROWS { PARAM_VALUE.DW1_TO_PW1_RING_ROWS } {
	# Procedure called to validate DW1_TO_PW1_RING_ROWS
	return true
}

proc update_PARAM_VALUE.DW2_PENDING_DEPTH { PARAM_VALUE.DW2_PENDING_DEPTH } {
	# Procedure called to update DW2_PENDING_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DW2_PENDING_DEPTH { PARAM_VALUE.DW2_PENDING_DEPTH } {
	# Procedure called to validate DW2_PENDING_DEPTH
	return true
}

proc update_PARAM_VALUE.DW2_ROWS_W { PARAM_VALUE.DW2_ROWS_W } {
	# Procedure called to update DW2_ROWS_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DW2_ROWS_W { PARAM_VALUE.DW2_ROWS_W } {
	# Procedure called to validate DW2_ROWS_W
	return true
}

proc update_PARAM_VALUE.DW2_TO_PW2_RING_ROWS { PARAM_VALUE.DW2_TO_PW2_RING_ROWS } {
	# Procedure called to update DW2_TO_PW2_RING_ROWS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DW2_TO_PW2_RING_ROWS { PARAM_VALUE.DW2_TO_PW2_RING_ROWS } {
	# Procedure called to validate DW2_TO_PW2_RING_ROWS
	return true
}

proc update_PARAM_VALUE.DW_K { PARAM_VALUE.DW_K } {
	# Procedure called to update DW_K when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DW_K { PARAM_VALUE.DW_K } {
	# Procedure called to validate DW_K
	return true
}

proc update_PARAM_VALUE.DW_PAD { PARAM_VALUE.DW_PAD } {
	# Procedure called to update DW_PAD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DW_PAD { PARAM_VALUE.DW_PAD } {
	# Procedure called to validate DW_PAD
	return true
}

proc update_PARAM_VALUE.FC_AVG_LANES { PARAM_VALUE.FC_AVG_LANES } {
	# Procedure called to update FC_AVG_LANES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FC_AVG_LANES { PARAM_VALUE.FC_AVG_LANES } {
	# Procedure called to validate FC_AVG_LANES
	return true
}

proc update_PARAM_VALUE.FC_CLASSES { PARAM_VALUE.FC_CLASSES } {
	# Procedure called to update FC_CLASSES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FC_CLASSES { PARAM_VALUE.FC_CLASSES } {
	# Procedure called to validate FC_CLASSES
	return true
}

proc update_PARAM_VALUE.FRAC_BITS { PARAM_VALUE.FRAC_BITS } {
	# Procedure called to update FRAC_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAC_BITS { PARAM_VALUE.FRAC_BITS } {
	# Procedure called to validate FRAC_BITS
	return true
}

proc update_PARAM_VALUE.INPUT_LEN { PARAM_VALUE.INPUT_LEN } {
	# Procedure called to update INPUT_LEN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INPUT_LEN { PARAM_VALUE.INPUT_LEN } {
	# Procedure called to validate INPUT_LEN
	return true
}

proc update_PARAM_VALUE.LOW_TIME_W { PARAM_VALUE.LOW_TIME_W } {
	# Procedure called to update LOW_TIME_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LOW_TIME_W { PARAM_VALUE.LOW_TIME_W } {
	# Procedure called to validate LOW_TIME_W
	return true
}

proc update_PARAM_VALUE.PENDING_DEPTH { PARAM_VALUE.PENDING_DEPTH } {
	# Procedure called to update PENDING_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PENDING_DEPTH { PARAM_VALUE.PENDING_DEPTH } {
	# Procedure called to validate PENDING_DEPTH
	return true
}

proc update_PARAM_VALUE.POOL_LEN { PARAM_VALUE.POOL_LEN } {
	# Procedure called to update POOL_LEN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.POOL_LEN { PARAM_VALUE.POOL_LEN } {
	# Procedure called to validate POOL_LEN
	return true
}

proc update_PARAM_VALUE.POOL_ROWS { PARAM_VALUE.POOL_ROWS } {
	# Procedure called to update POOL_ROWS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.POOL_ROWS { PARAM_VALUE.POOL_ROWS } {
	# Procedure called to validate POOL_ROWS
	return true
}

proc update_PARAM_VALUE.PW1_OC { PARAM_VALUE.PW1_OC } {
	# Procedure called to update PW1_OC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PW1_OC { PARAM_VALUE.PW1_OC } {
	# Procedure called to validate PW1_OC
	return true
}

proc update_PARAM_VALUE.PW1_OC_LANES { PARAM_VALUE.PW1_OC_LANES } {
	# Procedure called to update PW1_OC_LANES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PW1_OC_LANES { PARAM_VALUE.PW1_OC_LANES } {
	# Procedure called to validate PW1_OC_LANES
	return true
}

proc update_PARAM_VALUE.PW1_TO_DW2_RING_ROWS { PARAM_VALUE.PW1_TO_DW2_RING_ROWS } {
	# Procedure called to update PW1_TO_DW2_RING_ROWS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PW1_TO_DW2_RING_ROWS { PARAM_VALUE.PW1_TO_DW2_RING_ROWS } {
	# Procedure called to validate PW1_TO_DW2_RING_ROWS
	return true
}

proc update_PARAM_VALUE.PW2_OC { PARAM_VALUE.PW2_OC } {
	# Procedure called to update PW2_OC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PW2_OC { PARAM_VALUE.PW2_OC } {
	# Procedure called to validate PW2_OC
	return true
}

proc update_PARAM_VALUE.PW2_OC_LANES { PARAM_VALUE.PW2_OC_LANES } {
	# Procedure called to update PW2_OC_LANES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PW2_OC_LANES { PARAM_VALUE.PW2_OC_LANES } {
	# Procedure called to validate PW2_OC_LANES
	return true
}

proc update_PARAM_VALUE.ROWS { PARAM_VALUE.ROWS } {
	# Procedure called to update ROWS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ROWS { PARAM_VALUE.ROWS } {
	# Procedure called to validate ROWS
	return true
}

proc update_PARAM_VALUE.ROWS_W { PARAM_VALUE.ROWS_W } {
	# Procedure called to update ROWS_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ROWS_W { PARAM_VALUE.ROWS_W } {
	# Procedure called to validate ROWS_W
	return true
}

proc update_PARAM_VALUE.STEM_IC { PARAM_VALUE.STEM_IC } {
	# Procedure called to update STEM_IC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STEM_IC { PARAM_VALUE.STEM_IC } {
	# Procedure called to validate STEM_IC
	return true
}

proc update_PARAM_VALUE.STEM_K { PARAM_VALUE.STEM_K } {
	# Procedure called to update STEM_K when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STEM_K { PARAM_VALUE.STEM_K } {
	# Procedure called to validate STEM_K
	return true
}

proc update_PARAM_VALUE.STEM_KERNEL { PARAM_VALUE.STEM_KERNEL } {
	# Procedure called to update STEM_KERNEL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STEM_KERNEL { PARAM_VALUE.STEM_KERNEL } {
	# Procedure called to validate STEM_KERNEL
	return true
}

proc update_PARAM_VALUE.STEM_OC { PARAM_VALUE.STEM_OC } {
	# Procedure called to update STEM_OC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STEM_OC { PARAM_VALUE.STEM_OC } {
	# Procedure called to validate STEM_OC
	return true
}

proc update_PARAM_VALUE.STEM_OC_LANES { PARAM_VALUE.STEM_OC_LANES } {
	# Procedure called to update STEM_OC_LANES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STEM_OC_LANES { PARAM_VALUE.STEM_OC_LANES } {
	# Procedure called to validate STEM_OC_LANES
	return true
}

proc update_PARAM_VALUE.STEM_PADDING { PARAM_VALUE.STEM_PADDING } {
	# Procedure called to update STEM_PADDING when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STEM_PADDING { PARAM_VALUE.STEM_PADDING } {
	# Procedure called to validate STEM_PADDING
	return true
}

proc update_PARAM_VALUE.STEM_TO_DW1_RING_ROWS { PARAM_VALUE.STEM_TO_DW1_RING_ROWS } {
	# Procedure called to update STEM_TO_DW1_RING_ROWS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STEM_TO_DW1_RING_ROWS { PARAM_VALUE.STEM_TO_DW1_RING_ROWS } {
	# Procedure called to validate STEM_TO_DW1_RING_ROWS
	return true
}

proc update_PARAM_VALUE.TIME_W { PARAM_VALUE.TIME_W } {
	# Procedure called to update TIME_W when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TIME_W { PARAM_VALUE.TIME_W } {
	# Procedure called to validate TIME_W
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to update C_S00_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to validate C_S00_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to update C_S00_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to validate C_S00_AXI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.DATA_W { MODELPARAM_VALUE.DATA_W PARAM_VALUE.DATA_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_W}] ${MODELPARAM_VALUE.DATA_W}
}

proc update_MODELPARAM_VALUE.ACC_W { MODELPARAM_VALUE.ACC_W PARAM_VALUE.ACC_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ACC_W}] ${MODELPARAM_VALUE.ACC_W}
}

proc update_MODELPARAM_VALUE.ROWS { MODELPARAM_VALUE.ROWS PARAM_VALUE.ROWS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ROWS}] ${MODELPARAM_VALUE.ROWS}
}

proc update_MODELPARAM_VALUE.STEM_OC_LANES { MODELPARAM_VALUE.STEM_OC_LANES PARAM_VALUE.STEM_OC_LANES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STEM_OC_LANES}] ${MODELPARAM_VALUE.STEM_OC_LANES}
}

proc update_MODELPARAM_VALUE.PW1_OC_LANES { MODELPARAM_VALUE.PW1_OC_LANES PARAM_VALUE.PW1_OC_LANES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PW1_OC_LANES}] ${MODELPARAM_VALUE.PW1_OC_LANES}
}

proc update_MODELPARAM_VALUE.PW2_OC_LANES { MODELPARAM_VALUE.PW2_OC_LANES PARAM_VALUE.PW2_OC_LANES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PW2_OC_LANES}] ${MODELPARAM_VALUE.PW2_OC_LANES}
}

proc update_MODELPARAM_VALUE.FC_AVG_LANES { MODELPARAM_VALUE.FC_AVG_LANES PARAM_VALUE.FC_AVG_LANES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FC_AVG_LANES}] ${MODELPARAM_VALUE.FC_AVG_LANES}
}

proc update_MODELPARAM_VALUE.POOL_ROWS { MODELPARAM_VALUE.POOL_ROWS PARAM_VALUE.POOL_ROWS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.POOL_ROWS}] ${MODELPARAM_VALUE.POOL_ROWS}
}

proc update_MODELPARAM_VALUE.CH_LANES { MODELPARAM_VALUE.CH_LANES PARAM_VALUE.CH_LANES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CH_LANES}] ${MODELPARAM_VALUE.CH_LANES}
}

proc update_MODELPARAM_VALUE.STEM_OC { MODELPARAM_VALUE.STEM_OC PARAM_VALUE.STEM_OC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STEM_OC}] ${MODELPARAM_VALUE.STEM_OC}
}

proc update_MODELPARAM_VALUE.PW1_OC { MODELPARAM_VALUE.PW1_OC PARAM_VALUE.PW1_OC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PW1_OC}] ${MODELPARAM_VALUE.PW1_OC}
}

proc update_MODELPARAM_VALUE.PW2_OC { MODELPARAM_VALUE.PW2_OC PARAM_VALUE.PW2_OC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PW2_OC}] ${MODELPARAM_VALUE.PW2_OC}
}

proc update_MODELPARAM_VALUE.FC_CLASSES { MODELPARAM_VALUE.FC_CLASSES PARAM_VALUE.FC_CLASSES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FC_CLASSES}] ${MODELPARAM_VALUE.FC_CLASSES}
}

proc update_MODELPARAM_VALUE.STEM_K { MODELPARAM_VALUE.STEM_K PARAM_VALUE.STEM_K } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STEM_K}] ${MODELPARAM_VALUE.STEM_K}
}

proc update_MODELPARAM_VALUE.STEM_IC { MODELPARAM_VALUE.STEM_IC PARAM_VALUE.STEM_IC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STEM_IC}] ${MODELPARAM_VALUE.STEM_IC}
}

proc update_MODELPARAM_VALUE.STEM_KERNEL { MODELPARAM_VALUE.STEM_KERNEL PARAM_VALUE.STEM_KERNEL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STEM_KERNEL}] ${MODELPARAM_VALUE.STEM_KERNEL}
}

proc update_MODELPARAM_VALUE.STEM_PADDING { MODELPARAM_VALUE.STEM_PADDING PARAM_VALUE.STEM_PADDING } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STEM_PADDING}] ${MODELPARAM_VALUE.STEM_PADDING}
}

proc update_MODELPARAM_VALUE.DW_K { MODELPARAM_VALUE.DW_K PARAM_VALUE.DW_K } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DW_K}] ${MODELPARAM_VALUE.DW_K}
}

proc update_MODELPARAM_VALUE.DW_PAD { MODELPARAM_VALUE.DW_PAD PARAM_VALUE.DW_PAD } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DW_PAD}] ${MODELPARAM_VALUE.DW_PAD}
}

proc update_MODELPARAM_VALUE.INPUT_LEN { MODELPARAM_VALUE.INPUT_LEN PARAM_VALUE.INPUT_LEN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INPUT_LEN}] ${MODELPARAM_VALUE.INPUT_LEN}
}

proc update_MODELPARAM_VALUE.FRAC_BITS { MODELPARAM_VALUE.FRAC_BITS PARAM_VALUE.FRAC_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAC_BITS}] ${MODELPARAM_VALUE.FRAC_BITS}
}

proc update_MODELPARAM_VALUE.TIME_W { MODELPARAM_VALUE.TIME_W PARAM_VALUE.TIME_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TIME_W}] ${MODELPARAM_VALUE.TIME_W}
}

proc update_MODELPARAM_VALUE.ROWS_W { MODELPARAM_VALUE.ROWS_W PARAM_VALUE.ROWS_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ROWS_W}] ${MODELPARAM_VALUE.ROWS_W}
}

proc update_MODELPARAM_VALUE.LOW_TIME_W { MODELPARAM_VALUE.LOW_TIME_W PARAM_VALUE.LOW_TIME_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LOW_TIME_W}] ${MODELPARAM_VALUE.LOW_TIME_W}
}

proc update_MODELPARAM_VALUE.DW2_ROWS_W { MODELPARAM_VALUE.DW2_ROWS_W PARAM_VALUE.DW2_ROWS_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DW2_ROWS_W}] ${MODELPARAM_VALUE.DW2_ROWS_W}
}

proc update_MODELPARAM_VALUE.STEM_TO_DW1_RING_ROWS { MODELPARAM_VALUE.STEM_TO_DW1_RING_ROWS PARAM_VALUE.STEM_TO_DW1_RING_ROWS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STEM_TO_DW1_RING_ROWS}] ${MODELPARAM_VALUE.STEM_TO_DW1_RING_ROWS}
}

proc update_MODELPARAM_VALUE.DW1_TO_PW1_RING_ROWS { MODELPARAM_VALUE.DW1_TO_PW1_RING_ROWS PARAM_VALUE.DW1_TO_PW1_RING_ROWS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DW1_TO_PW1_RING_ROWS}] ${MODELPARAM_VALUE.DW1_TO_PW1_RING_ROWS}
}

proc update_MODELPARAM_VALUE.PW1_TO_DW2_RING_ROWS { MODELPARAM_VALUE.PW1_TO_DW2_RING_ROWS PARAM_VALUE.PW1_TO_DW2_RING_ROWS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PW1_TO_DW2_RING_ROWS}] ${MODELPARAM_VALUE.PW1_TO_DW2_RING_ROWS}
}

proc update_MODELPARAM_VALUE.DW2_TO_PW2_RING_ROWS { MODELPARAM_VALUE.DW2_TO_PW2_RING_ROWS PARAM_VALUE.DW2_TO_PW2_RING_ROWS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DW2_TO_PW2_RING_ROWS}] ${MODELPARAM_VALUE.DW2_TO_PW2_RING_ROWS}
}

proc update_MODELPARAM_VALUE.PENDING_DEPTH { MODELPARAM_VALUE.PENDING_DEPTH PARAM_VALUE.PENDING_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PENDING_DEPTH}] ${MODELPARAM_VALUE.PENDING_DEPTH}
}

proc update_MODELPARAM_VALUE.DW2_PENDING_DEPTH { MODELPARAM_VALUE.DW2_PENDING_DEPTH PARAM_VALUE.DW2_PENDING_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DW2_PENDING_DEPTH}] ${MODELPARAM_VALUE.DW2_PENDING_DEPTH}
}

proc update_MODELPARAM_VALUE.BRAM_READ_LATENCY { MODELPARAM_VALUE.BRAM_READ_LATENCY PARAM_VALUE.BRAM_READ_LATENCY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRAM_READ_LATENCY}] ${MODELPARAM_VALUE.BRAM_READ_LATENCY}
}

proc update_MODELPARAM_VALUE.POOL_LEN { MODELPARAM_VALUE.POOL_LEN PARAM_VALUE.POOL_LEN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.POOL_LEN}] ${MODELPARAM_VALUE.POOL_LEN}
}

proc update_MODELPARAM_VALUE.CH_GROUPS { MODELPARAM_VALUE.CH_GROUPS PARAM_VALUE.CH_GROUPS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CH_GROUPS}] ${MODELPARAM_VALUE.CH_GROUPS}
}

proc update_MODELPARAM_VALUE.ACT_TIME_WORDS { MODELPARAM_VALUE.ACT_TIME_WORDS PARAM_VALUE.ACT_TIME_WORDS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ACT_TIME_WORDS}] ${MODELPARAM_VALUE.ACT_TIME_WORDS}
}

proc update_MODELPARAM_VALUE.ACT_RAM_DEPTH { MODELPARAM_VALUE.ACT_RAM_DEPTH PARAM_VALUE.ACT_RAM_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ACT_RAM_DEPTH}] ${MODELPARAM_VALUE.ACT_RAM_DEPTH}
}

proc update_MODELPARAM_VALUE.ACT_ADDR_W { MODELPARAM_VALUE.ACT_ADDR_W PARAM_VALUE.ACT_ADDR_W } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ACT_ADDR_W}] ${MODELPARAM_VALUE.ACT_ADDR_W}
}

