####################################################################################
# Company: ISAE
# Engineer: Szymon Bogus
# 
# Create Date: 07.12.25
# Design Name: 
# Module Name: 
# Project Name: drone_basys3
# Target Devices: Basys 3
# Tool Versions: 
# Description: Makefile based build system using GHDL to simulate testbenches.
#			   Run: $ make <tb_name>
# 
# Dependencies: for .OUTPUT_SYNC: target make 4.0+ is required
# 
# Revision:
# Revision 0.01 - File Created
# Additional Comments:
# 
####################################################################################

GHDL        := ghdl
FLAGS       := --std=08

BUILD_ROOT  := build
SRC_DIR     := src/hdl
SIM_DIR     := src/sim
SIM_OUT_DIR := simulation
LOG_DIR     := log

ALL_SRCS := $(wildcard $(SRC_DIR)/*.vhd)

# Exclude files here (those which don't work; without it Make will make GHDL include them and things will fail)
# IGNORE_SRCS := \
#     $(SRC_DIR)/display_controller.vhd \
# 	$(SRC_DIR)/screen_utils_pkg.vhd

# SRCS := $(filter-out $(IGNORE_SRCS), $(ALL_SRCS))
SRCS := $(ALL_SRCS)

TBS_SRCS  := $(wildcard $(SIM_DIR)/*_tb.vhd)
TBS_NAMES := $(basename $(notdir $(TBS_SRCS)))

.PHONY: all clean help

.OUTPUT_SYNC: target

help:
	@echo "Usage:"
	@echo "  make <tb_name>     : Run specific TB"
	@echo "  make -j<N> all     : Run all testbenches in parallel (N = num cores)"
	@echo "  make clean         : Clean workspace"

all: $(TBS_NAMES)

%_tb:
	@# 1. Define a private build dir for this specific job to avoid GHDL collisions
	$(eval CURRENT_WORKDIR := $(BUILD_ROOT)/$@)
	
	@echo "--- Starting $@ (PID: $$$$) ---"
	
	@mkdir -p $(CURRENT_WORKDIR)
	@mkdir -p $(SIM_OUT_DIR)/$@
	@mkdir -p $(LOG_DIR)/$@

	@# 2. Import Sources into private workdir
	@# We pipe output to /dev/null to keep parallel terminal output clean
	@echo "  [$@] Importing..."
	@$(GHDL) -i --workdir=$(CURRENT_WORKDIR) $(FLAGS) $(SRCS) $(SIM_DIR)/$@.vhd

	@# 3. Compile and Elaborate
	@echo "  [$@] Compiling..."
	@$(GHDL) -m --workdir=$(CURRENT_WORKDIR) $(FLAGS) $@ > $(LOG_DIR)/$@/build.log 2>&1
	
	@# Move executable
	@mv $@ $(SIM_OUT_DIR)/$@/ 2>/dev/null || true

	@# 4. Run Simulation
	@echo "  [$@] Simulating..."
	@$(GHDL) -r --workdir=$(CURRENT_WORKDIR) $(FLAGS) $@ --vcd=$(SIM_OUT_DIR)/$@/$@.vcd >> $(LOG_DIR)/$@/simulation.log 2>&1
	
	@echo "SUCCESS: $@ finished."


#
# ================ MISC ================
#

.PHONY: clean
clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_ROOT) $(SIM_OUT_DIR) $(LOG_DIR) *.cf
