# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\Intership\emg_gesture_vitis\emg_finger\emg_finger_wrapper\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\Intership\emg_gesture_vitis\emg_finger\emg_finger_wrapper\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {emg_finger_wrapper}\
-hw {D:\Intership\hardware_export\emg_finger_wrapper.xsa}\
-arch {64-bit} -fsbl-target {psu_cortexa53_0} -out {D:/Intership/emg_gesture_vitis/emg_finger}

platform write
domain create -name {standalone_psu_cortexa53_0} -display-name {standalone_psu_cortexa53_0} -os {standalone} -proc {psu_cortexa53_0} -runtime {cpp} -arch {64-bit} -support-app {empty_application}
platform generate -domains 
platform active {emg_finger_wrapper}
domain active {zynqmp_fsbl}
domain active {zynqmp_pmufw}
domain active {standalone_psu_cortexa53_0}
platform generate -quick
platform generate
platform clean
platform generate
platform clean
platform generate
