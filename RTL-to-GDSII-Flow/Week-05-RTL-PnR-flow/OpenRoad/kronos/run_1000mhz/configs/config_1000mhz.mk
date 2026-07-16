export PLATFORM = asap7
export DESIGN_NAME = kronos_core
export SYNTH_HDL_FRONTEND = slang

# Define Base Paths
BASE_DIR  = /home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/kronos
RTL_DIR  = $(BASE_DIR)/rtl/core

CONFIG_DIR = $(BASE_DIR)/run_1000mhz/configs

export SDC_FILE = $(CONFIG_DIR)/constraint_1000mhz.sdc

export FLOW_VARIANT=1000mhz

export VERILOG_FILES = \
    $(RTL_DIR)/kronos_types.sv \
    $(RTL_DIR)/kronos_counter64.sv \
    $(RTL_DIR)/kronos_branch.sv \
    $(RTL_DIR)/kronos_alu.sv \
    $(RTL_DIR)/kronos_agu.sv \
    $(RTL_DIR)/kronos_hcu.sv \
    $(RTL_DIR)/kronos_csr.sv \
    $(RTL_DIR)/kronos_lsu.sv \
    $(RTL_DIR)/kronos_RF.sv \
    $(RTL_DIR)/kronos_IF.sv \
    $(RTL_DIR)/kronos_ID.sv \
    $(RTL_DIR)/kronos_EX.sv \
    $(RTL_DIR)/kronos_core.sv

# Physical Design Configurations
export CORE_UTILIZATION = 45
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 2
export PLACE_DENSITY = 0.60
