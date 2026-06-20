export PLATFORM = asap7
export DESIGN_NAME = tpu

# Define Base Paths
BASE_DIR  = /home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-04-RTL-Synthesis/OpenRoad/tiny-tpu
RTL_DIR   = $(BASE_DIR)/rtl

CONFIG_DIR = $(BASE_DIR)/extra_run_1.5GHz/configs

export SDC_FILE = $(CONFIG_DIR)/constraint_1.5GHz.sdc

export VERILOG_FILES = \
    $(RTL_DIR)/fixedpoint_simple.v \
    $(RTL_DIR)/control_unit.v \
    $(RTL_DIR)/loss_child.v \
    $(RTL_DIR)/loss_parent.v \
    $(RTL_DIR)/leaky_relu_derivative_child.v \
    $(RTL_DIR)/leaky_relu_derivative_parent.v \
    $(RTL_DIR)/leaky_relu_child.v \
    $(RTL_DIR)/leaky_relu_parent.v \
    $(RTL_DIR)/bias_child.v \
    $(RTL_DIR)/bias_parent.v \
    $(RTL_DIR)/vpu.v \
    $(RTL_DIR)/gradient_descent.v \
    $(RTL_DIR)/unified_buffer.v \
    $(RTL_DIR)/pe.v \
    $(RTL_DIR)/systolic.v \
    $(RTL_DIR)/tpu.v

# Physical Design Configurations
export CORE_UTILIZATION = 50
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 2
export PLACE_DENSITY = 0.40





