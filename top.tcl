# set project name
set PROJECT_NAME "rtl_simulation"
set TOP_MODULE_SRC "top"
set TOP_MODULE_SIM "tb_top"
set SRC_DIR "./vsrc"
set SIM_DIR "./vsrc/tb"
set REPORT_DIR "./reports"
set PROJECT_DIR "./vivado_sim"
set FPGA_PART "xc7z020clg484-1"
set SIM_RESULT "simulation_results.log"
set XDC_DIR "./sdc"

# set source file list
set SRC_FILELIST [glob $SRC_DIR/*.v]
set SIM_FILELIST [glob $SIM_DIR/*.v]
set XDC_FILELIST [glob $XDC_DIR/*.xdc]

# initialize
set CLEAN_FILELIST {*.backup.jou *.backup.log *.backup.str}
foreach cleanfile $CLEAN_FILELIST {
    set files [glob -nocomplain ./$cleanfile]
    if {[llength $files] == 0} {
        puts "No files found for pattern: $cleanfile"
    } else {
        foreach file $files {
            file delete -force $file
            puts "Deleted file: $file"
        }
    }
}

set SIMWV_EXTLIST {*.wdb *.vcd *.wcfg *.bmp}
foreach fileEXT $SIMWV_EXTLIST {
    set files [glob -nocomplain $REPORT_DIR/$fileEXT]
    if {[llength $files] == 0} {
        puts "No files found for pattern: $fileEXT"
    } else {
        foreach file $files {
            file delete -force $file
            puts "Deleted file: $file"
        }
    }
}

set DIRLIST [list $REPORT_DIR $SRC_DIR $SIM_DIR]
foreach dir $DIRLIST {
    if {$dir eq ""} {
        puts "## Error: One of the directory variables is empty. Aborting..."
        exit
    }
    if {![file isdirectory $dir]} {
        if {[catch {file mkdir $dir} result]} {
            puts "## Error: Failed to create directory $dir. Reason: $result"
        } else {
            puts "## Directory $dir created successfully."
        }
    }
}

create_project -force $PROJECT_NAME $PROJECT_DIR -part $FPGA_PART

# add source files
foreach file $SRC_FILELIST {
    add_files -fileset sources_1 $file
    add_files -fileset sim_1 $file
}

foreach file $SIM_FILELIST {
    add_files -fileset sim_1 $file
}

foreach file $XDC_FILELIST {
    add_files -fileset constrs_1 $file
}

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# set top module
set_property top $TOP_MODULE_SRC [get_filesets sources_1]
set_property top $TOP_MODULE_SIM [get_filesets sim_1]

# sim
launch_simulation

# vcd
if {![file isdirectory $REPORT_DIR]} {
    file mkdir $REPORT_DIR
    puts "Created directory: $REPORT_DIR"
}
open_vcd $REPORT_DIR/sim_waveform_behav.vcd
log_vcd /$TOP_MODULE_SIM
restart
run all
close_vcd

# wcfg
save_wave_config $REPORT_DIR/sim_waveform_behav.wcfg

# stop
stop
close_sim

# check
set sim_log_file "$PROJECT_DIR/${PROJECT_NAME}.sim/sim_1/behav/xsim/simulation_results.log"
if {[file exists $sim_log_file]} {
    file copy -force $sim_log_file $REPORT_DIR/sim_results_behav.log
} else {
    puts "Warning: Simulation log file not found at $sim_log_file"
}

# Step 9: Run synthesis
launch_runs synth_1
# This runs the synthesis step for the design.

# Step 10: Wait for synthesis to complete
wait_on_run synth_1
# This waits for the synthesis to complete before continuing.

# Step 11: Export synthesis reports
open_run synth_1
report_utilization -file $REPORT_DIR/utilization_report.rpt
report_timing_summary -file $REPORT_DIR/timing_report.rpt
# These commands export the utilization report and the timing summary report.

# Optional Step: If you want to export the synthesized design netlist (optional)
# write_checkpoint -force $REPORT_DIR/${TOP_MODULE_SRC}_synth.dcp
# This exports the synthesized netlist to a DCP (Design Checkpoint) file.

exit