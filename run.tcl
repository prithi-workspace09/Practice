# ============================================================================
# run.tcl - Cadence Genus synthesis for AxPPA-LF 8-bit (K = 4)
# Usage : genus -files run.tcl -log genus_axppa
# ============================================================================

# ---------------- user settings (EDIT LIBRARY PATHS) ----------------
set DESIGN axppa_lf8_top

# gsclib045 root (found with: find / -name gsclib045.fixed.lef)
set LIBS_ROOT "/home/c2suser16/cadence/FOUNDRY/digital/45nm/LIBS"

# LEF (physical) file - this is a FILE, not the .lib search path
set LEF_FILE  "$LIBS_ROOT/lef/gsclib045.fixed.lef"

# Liberty (timing) library directory - confirmed: $LIBS_ROOT/lib/max/slow.lib
set LIB_PATH  "$LIBS_ROOT/lib/max"
set LIB_FILE  "slow.lib"

set RTL_FILES [list axppa_lf8.v]
set SDC_FILE  constraints.sdc
set RPT_DIR   reports
set OUT_DIR   outputs

file mkdir $RPT_DIR
file mkdir $OUT_DIR

# ---------------- setup ----------------
set_db init_lib_search_path $LIB_PATH
set_db init_hdl_search_path .
set_db information_level 7

read_libs $LIB_FILE

# Physical info (optional for plain synthesis, needed for physical-aware flows)
if {[file exists $LEF_FILE]} {
    read_physical -lef $LEF_FILE
} else {
    puts "WARNING: LEF not found: $LEF_FILE"
}

# ---------------- read + elaborate ----------------
read_hdl $RTL_FILES
elaborate $DESIGN
check_design -unresolved > $RPT_DIR/check_design.rpt

# ---------------- constraints ----------------
read_sdc $SDC_FILE
report_timing -lint > $RPT_DIR/timing_lint.rpt

# ---------------- synthesis ----------------
set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

syn_generic
syn_map
syn_opt

# ---------------- optional: switching activity from simulation ----------------
# Simulate with +define+DUMP_VCD, then uncomment (command name varies by Genus version):
# read_stimulus -file axppa_lf8.vcd -dut_instance tb_axppa_lf8/dut_top -format vcd
# compute_power -mode average

# ---------------- reports ----------------
report_timing -max_paths 10 > $RPT_DIR/timing.rpt
report_area > $RPT_DIR/area.rpt
report_gates > $RPT_DIR/gates.rpt
report_power > $RPT_DIR/power.rpt
report_qor > $RPT_DIR/qor.rpt

# ---------------- outputs (for gate-level sim / Innovus) ----------------
write_hdl > $OUT_DIR/${DESIGN}_netlist.v
write_sdc > $OUT_DIR/${DESIGN}.sdc
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge > $OUT_DIR/${DESIGN}.sdf

puts "==== Synthesis of $DESIGN complete ===="
gui_show
