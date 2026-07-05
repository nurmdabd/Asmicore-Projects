# ==============================================================================
# Simplified Initial SDC for CVA6 Bringup
# Time Unit: ps (2000 ps = 2 ns / 500 MHz)
# ==============================================================================

current_design cva6

# Create master clock on the actual top-level port
create_clock [get_ports clk_i] -period 2000
