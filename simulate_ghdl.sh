#!/bin/bash
#
# This script compiles and runs a VHDL simulation using GHDL.
# It uses arrays to support multiple source files.
#
# To use:
# 1. Set the TB_ENTITY to the name of the testbench you want to run.
# 2. Update the SRC_FILES array to include all dependencies.
#
# Make this script executable:
#   chmod +x simulate.sh
#
# Run this script from the project root:
#   ./simulate.sh
#

# Stop immediately if any command fails
set -e

# --- 1. CONFIGURE YOUR TEST ---
#
# Set the name of the top-level testbench entity
TB_ENTITY="edge_detector_tb"
#
# List all VHDL source files (order doesn't matter)
# These are your 'hardware' modules from src/hdl/
SRC_FILES=(
    "src/hdl/btn_debouncer.vhd"
    "src/hdl/edge_detector.vhd"
)
#
# List all VHDL testbench files
# (Usually just one, but supports more)
TB_FILES=(
    "src/sim/edge_detector_tb.vhd"
)
#
# Define the package file(s). These will be compiled FIRST.
PKG_FILE="src/hdl/drone_utils_pkg.vhd"
#
# --- END OF CONFIGURATION ---


# --- 2. SCRIPT SETUP ---
VHDL_STD="--std=08" # Use VHDL-2008
WAVEFORM_FILE="simulation/waveforms/${TB_ENTITY}.vcd"

# --- 3. CLEANUP ---
mkdir -p simulation/waveforms
echo "--- Cleaning up old files ---"
rm -f *.cf $WAVEFORM_FILE

# --- 4. ANALYZE (Compile) ---
echo "--- Compiling VHDL files ---"

# Compilation order is critical. The package MUST be first.
echo "Compiling package: $PKG_FILE"
ghdl -a $VHDL_STD $PKG_FILE

# Loop and compile all source files
echo "Compiling source files..."
for src_file in "${SRC_FILES[@]}"; do
    echo "  Compiling: $src_file"
    ghdl -a $VHDL_STD "$src_file"
done

# Loop and compile all testbench files
echo "Compiling testbench files..."
for tb_file in "${TB_FILES[@]}"; do
    echo "  Compiling: $tb_file"
    ghdl -a $VHDL_STD "$tb_file"
done

# --- 5. ELABORATE ---
# This builds the simulation executable
echo "--- Elaborating testbench: $TB_ENTITY ---"
ghdl -e $VHDL_STD $TB_ENTITY

# --- 6. RUN ---
# This runs the simulation and dumps the VCD file
echo "--- Running simulation ---"
ghdl -r $VHDL_STD $TB_ENTITY --vcd=$WAVEFORM_FILE

echo "--- Simulation complete ---"
echo "Waveform file generated: $WAVEFORM_FILE"
echo "You can view it with GTKWave:"
echo "  gtkwave $WAVEFORM_FILE"