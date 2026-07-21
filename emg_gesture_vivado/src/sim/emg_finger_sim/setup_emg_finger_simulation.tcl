set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ../../..]]
set project_file [file join $project_dir emg_gesture_vivado.xpr]
set bd_file [file join $project_dir emg_gesture_vivado.srcs sim_1 bd emg_finger_sim emg_finger_sim.bd]
set mem_file [file join $script_dir emg_representative_4cases.mem]
set tb_file [file join $script_dir tb_emg_finger_sim.sv]

if {[current_project -quiet] eq ""} {
    open_project $project_file
}

open_bd_design $bd_file

if {[llength [get_files -quiet $mem_file]] == 0} {
    add_files -fileset sim_1 -norecurse $mem_file
}

validate_bd_design
save_bd_design
generate_target all [get_files $bd_file]

set wrapper_files [make_wrapper -files [get_files $bd_file] -top]
foreach wrapper_file $wrapper_files {
    if {[llength [get_files -quiet $wrapper_file]] == 0} {
        add_files -fileset sim_1 -norecurse $wrapper_file
    }
}

if {[llength [get_files -quiet $tb_file]] == 0} {
    add_files -fileset sim_1 -norecurse $tb_file
}

set_property top tb_emg_finger_sim [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "Configured emg_finger_sim representative four-case simulation."
puts "Simulation top: tb_emg_finger_sim"
puts "Input BRAM is initialized by the testbench through the native BRAM port."
puts "Input data file: $mem_file"
puts "Run Flow Navigator -> Simulation -> Run Behavioral Simulation."
