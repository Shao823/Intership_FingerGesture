set ip_root [file normalize [file dirname [info script]]]
set hdl_root [file join $ip_root hdl]
set src_root [file join $ip_root src]
set tb_root [file join $src_root axi_ip_tb]
set weight_root [file join $src_root weight_data]

proc add_files_if_missing {files fileset} {
    foreach source_file $files {
        if {[llength [get_files -quiet $source_file]] == 0} {
            add_files -fileset $fileset -norecurse $source_file
        }
    }
}

proc configure_verilog_files {files used_in} {
    foreach source_file $files {
        set file_object [get_files -quiet $source_file]
        if {[llength $file_object] != 0} {
            set_property USED_IN $used_in $file_object
        }
    }
}

proc remove_stale_testbench_copies {src_root} {
    foreach testbench_name {
        axi_dma_mm2s_model.v
        emg_ddr_model.v
        tb_emg_accelerator_axi_shell.v
        tb_emg_accelerator_dma_system.v
        tb_emg_accelerator_s00_axi.v
        tb_emg_dma_pingpong_controller.v
    } {
        set stale_path [file join $src_root $testbench_name]
        set stale_file [get_files -quiet $stale_path]
        if {[llength $stale_file] != 0} {
            remove_files -quiet $stale_file
        }
    }
}

proc remove_stale_weight_coe_files {weight_root} {
    foreach relative_path {
        stem/weight_packed.coe
        pw1/weight_packed.coe
        pw2/weight_packed.coe
    } {
        set stale_path [file join $weight_root $relative_path]
        set stale_file [get_files -quiet $stale_path]
        if {[llength $stale_file] != 0} {
            remove_files -quiet $stale_file
        }
    }
}

proc ensure_irq_interface {core} {
    set irq_interface [ipx::get_bus_interfaces -quiet irq -of_objects $core]
    if {[llength $irq_interface] == 0} {
        set irq_interface [ipx::add_bus_interface irq $core]
    }

    set_property abstraction_type_vlnv xilinx.com:signal:interrupt_rtl:1.0 $irq_interface
    set_property bus_type_vlnv xilinx.com:signal:interrupt:1.0 $irq_interface
    set_property interface_mode master $irq_interface

    set irq_port_map [ipx::get_port_maps -quiet INTERRUPT -of_objects $irq_interface]
    if {[llength $irq_port_map] == 0} {
        set irq_port_map [ipx::add_port_map INTERRUPT $irq_interface]
    }
    set_property physical_name irq $irq_port_map
}

set rtl_files [concat \
    [glob -nocomplain -types f -directory $hdl_root *.v] \
    [glob -nocomplain -types f -directory $src_root *.v]]
remove_stale_testbench_copies $src_root
add_files_if_missing $rtl_files sources_1
configure_verilog_files $rtl_files {synthesis implementation simulation}

set tb_files [glob -nocomplain -types f -directory $tb_root *.v]
add_files_if_missing $tb_files sim_1
configure_verilog_files $tb_files {simulation}

set xci_files {}
foreach ip_dir [glob -nocomplain -types d -directory $src_root blk_mem_gen_*] {
    set xci_files [concat $xci_files [glob -nocomplain -types f -directory $ip_dir *.xci]]
}
foreach xci_file $xci_files {
    if {[llength [get_files -quiet $xci_file]] == 0} {
        read_ip $xci_file
    }
}

set data_files [glob -nocomplain -types f -directory $weight_root *]
foreach data_dir [glob -nocomplain -types d -directory $weight_root *] {
    set data_files [concat $data_files [glob -nocomplain -types f -directory $data_dir *]]
}
remove_stale_weight_coe_files $weight_root
add_files_if_missing $data_files sources_1

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set core [ipx::current_core]
if {$core eq ""} {
    error "No IP packager core is currently open"
}

ipx::merge_project_changes files $core
ipx::merge_project_changes ports $core
ipx::merge_project_changes parameters $core
ensure_irq_interface $core
ipx::update_checksums $core
ipx::save_core $core

puts "Synchronized [llength $rtl_files] RTL files, [llength $tb_files] simulation files, [llength $xci_files] XCI files, and [llength $data_files] data files."
