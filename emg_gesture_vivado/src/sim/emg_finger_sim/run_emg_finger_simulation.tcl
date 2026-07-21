set script_dir [file dirname [file normalize [info script]]]
close_sim -quiet
catch {reset_simulation -simset sim_1 -mode behavioral}
source [file join $script_dir setup_emg_finger_simulation.tcl]
launch_simulation -simset sim_1 -mode behavioral
run all
