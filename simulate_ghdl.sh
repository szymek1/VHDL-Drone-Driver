#!/bin/bash
#
# This script compiles and runs the VHDL simulation for the
# edge_detector using GHDL. It will generate a VCD waveform
# file that can be viewed with GTKWave.
#
# Make this script executable:
#   chmod +x simulate.sh
#
# Run this script from the project root:
#   ./simulate.sh
#

# Stop immediately if any command fails
set -e

# Define file paths
# Note: This assumes you run this script from the project root
PKG_FILE="src/hdl/drone_utils_pkg.vhd"
SRC_FILE="src/hdl/edge_detector.vhd"
TB_FILE="src/sim/edge_detector_tb.vhd"

# Define the top-level testbench entity
TB_ENTITY="edge_detector_tb"

# Define the output waveform file
WAVEFORM_FILE="simulation/waveforms/${TB_ENTITY}.vcd"
VHDL_STD="--std=08" # Use VHDL-2008 for 'assert ... failure'

# --- 1. CLEANUP ---
# Create directories if they don't exist
mkdir -p simulation/waveforms
# Remove old compiled files and waveform
echo "--- Cleaning up old files ---"
rm -f *.cf $WAVEFORM_FILE

# --- 2. ANALYZE (Compile) ---
# Compilation order is critical. The package MUST be first.
echo "--- Compiling VHDL files ---"
echo "Compiling package: $PKG_FILE"
ghdl -a $VHDL_STD $PKG_FILE

echo "Compiling entity: $SRC_FILE"
ghdl -a $VHDL_STD $SRC_FILE

echo "Compiling testbench: $TB_FILE"
ghdl -a $VHDL_STD $TB_FILE

# --- 3. ELABORATE ---
# This builds the simulation executable
echo "--- Elaborating testbench: $TB_ENTITY ---"
ghdl -e $VHDL_STD $TB_ENTITY

# --- 4. RUN ---
# This runs the simulation and dumps the VCD file
echo "--- Running simulation ---"
ghdl -r $VHDL_STD $TB_ENTITY --vcd=$WAVEFORM_FILE

echo "--- Simulation complete ---"
echo "Waveform file generated: $WAVEFORM_FILE"
echo "You can view it with GTKWave:"
echo "  gtkwave $WAVEFORM_FILE"
