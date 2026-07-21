set configured_files {}

foreach fileset_name {sources_1 sim_1} {
    set fileset_object [get_filesets -quiet $fileset_name]
    if {[llength $fileset_object] == 0} {
        continue
    }

    foreach file_object [get_files -quiet -of_objects $fileset_object] {
        set file_name [get_property NAME $file_object]
        set extension [string tolower [file extension $file_name]]
        if {$extension eq ".v" || $extension eq ".sv" || $extension eq ".vh"} {
            set_property LIBRARY xil_defaultlib $file_object
            lappend configured_files $file_name
        }
    }
}

foreach fileset_name {sources_1 sim_1} {
    if {[llength [get_filesets -quiet $fileset_name]] != 0} {
        update_compile_order -fileset $fileset_name
    }
}

puts "Configured [llength [lsort -unique $configured_files]] Verilog files as xil_defaultlib for the current Vivado project session."
puts "No IP-XACT metadata or component.xml content was modified."
