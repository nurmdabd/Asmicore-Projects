# ==============================================================================
# OpenROAD Flow Scripts (ORFS) Configuration for CVA6 (Ariane) Core
# Target Platform: ASAP7 (7nm Predictive FinFET PDK)
# ==============================================================================

export DESIGN_NAME     = cva6
export PLATFORM        = asap7

# ------------------------------------------------------------------------------
# 1. Base Directory Paths
# ------------------------------------------------------------------------------
export CVA6_REPO_DIR    = /home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Other_runs/cva6
PULP_COMMON_CELLS = $(CVA6_REPO_DIR)/vendor/pulp-platform/common_cells
PULP_AXI          = $(CVA6_REPO_DIR)/vendor/pulp-platform/axi

# ------------------------------------------------------------------------------
# 2. Global Core Architecture Setup
# ------------------------------------------------------------------------------
export TARGET_CFG      = cv32a60x

# ------------------------------------------------------------------------------
# 3. Verilog Include Directories
# ------------------------------------------------------------------------------
export VERILOG_INCLUDE_DIRS = \
    $(CVA6_REPO_DIR)/core/include \
    $(CVA6_REPO_DIR)/common/local/util \
    $(PULP_COMMON_CELLS)/include \
    $(PULP_COMMON_CELLS)/src \
    $(PULP_AXI)/include \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/include \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/ecc

# ------------------------------------------------------------------------------
# 4. Global Compiler & Synthesis Flags
# ------------------------------------------------------------------------------
export SYNTH_HDL_FRONTEND = slang
# Increase the memory inference limit to allow CVA6 internal arrays to map to flip-flops
export SYNTH_MEMORY_MAX_BITS = 65536

# ------------------------------------------------------------------------------
# 5. Core Source Files List (Strict Comprehensive Compilation Order)
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# 5. Core Source Files List (Strict Comprehensive Compilation Order)
# ------------------------------------------------------------------------------
export VERILOG_FILES = \
    $(CVA6_REPO_DIR)/core/include/config_pkg.sv \
    $(CVA6_REPO_DIR)/core/include/$(TARGET_CFG)_config_pkg.sv \
    $(CVA6_REPO_DIR)/core/include/riscv_pkg.sv \
    $(CVA6_REPO_DIR)/core/include/ariane_pkg.sv \
    $(PULP_AXI)/src/axi_pkg.sv \
    $(CVA6_REPO_DIR)/core/include/wt_cache_pkg.sv \
    $(CVA6_REPO_DIR)/core/include/std_cache_pkg.sv \
    $(CVA6_REPO_DIR)/core/include/build_config_pkg.sv \
    $(CVA6_REPO_DIR)/core/include/aes_pkg.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_pkg.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_pkg.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/ecc/prim_secded_pkg.sv \
    $(CVA6_REPO_DIR)/core/cvxif_example/include/cvxif_instr_pkg.sv \
    $(PULP_COMMON_CELLS)/src/cf_math_pkg.sv \
    $(CVA6_REPO_DIR)/core/cva6_accel_first_pass_decoder_stub.sv \
    $(PULP_COMMON_CELLS)/src/fifo_v3.sv \
    $(PULP_COMMON_CELLS)/src/lfsr.sv \
    $(PULP_COMMON_CELLS)/src/lfsr_8bit.sv \
    $(PULP_COMMON_CELLS)/src/stream_arbiter.sv \
    $(PULP_COMMON_CELLS)/src/stream_arbiter_flushable.sv \
    $(PULP_COMMON_CELLS)/src/stream_mux.sv \
    $(PULP_COMMON_CELLS)/src/stream_demux.sv \
    $(PULP_COMMON_CELLS)/src/lzc.sv \
    $(PULP_COMMON_CELLS)/src/rr_arb_tree.sv \
    $(PULP_COMMON_CELLS)/src/shift_reg.sv \
    $(PULP_COMMON_CELLS)/src/popcount.sv \
    $(PULP_COMMON_CELLS)/src/unread.sv \
    $(CVA6_REPO_DIR)/core/cva6_fifo_v3.sv \
    $(CVA6_REPO_DIR)/core/cva6_rvfi_probes.sv \
    $(CVA6_REPO_DIR)/core/cvxif_fu.sv \
    $(CVA6_REPO_DIR)/core/cvxif_compressed_if_driver.sv \
    $(CVA6_REPO_DIR)/core/cvxif_issue_register_commit_if_driver.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_resp_demux.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_to_axi_read.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_to_axi_write.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_req_read_arbiter.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/hpdcache_mem_req_write_arbiter.sv \
    $(CVA6_REPO_DIR)/vendor/pulp-platform/fpga-support/rtl/SyncSpRam.sv \
    $(CVA6_REPO_DIR)/vendor/pulp-platform/fpga-support/rtl/SyncSpRamBeNx64.sv \
    $(CVA6_REPO_DIR)/common/local/util/hpdcache_sram_1rw.sv \
    $(CVA6_REPO_DIR)/common/local/util/hpdcache_sram_wbyteenable_1rw.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_arb.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hwpf_stride/hwpf_stride_wrapper.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_demux.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_lfsr.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sync_buffer.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fifo_reg.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fifo_reg_initialized.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_fxarb.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_rrarb.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_mux.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_decoder.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_1hot_to_binary.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_prio_1hot_encoder.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_prio_bin_encoder.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram_wbyteenable.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_sram_wmask.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_regbank_wbyteenable_1rw.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_regbank_wmask_1rw.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_downsize.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_upsize.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/common/hpdcache_data_resize.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_amo.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_cmo.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_core_arbiter.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_ctrl.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_ctrl_pe.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_memctrl.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_miss_handler.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_mshr.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_rtab.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_uncached.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_plru.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_random.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_victim_sel.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_wbuf.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_flush.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/hpdcache_cbuf.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/ecc/prim_secded_36_29_dec.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/ecc/prim_secded_36_29_enc.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/ecc/prim_secded_39_32_dec.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/ecc/prim_secded_39_32_enc.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/ecc/prim_secded_55_48_dec.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/ecc/prim_secded_55_48_enc.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/ecc/prim_secded_72_64_dec.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/hpdcache/rtl/src/utils/ecc/prim_secded_72_64_enc.sv \
    $(CVA6_REPO_DIR)/core/alu.sv \
    $(CVA6_REPO_DIR)/core/alu_wrapper.sv \
    $(CVA6_REPO_DIR)/core/aes.sv \
    $(CVA6_REPO_DIR)/core/branch_unit.sv \
    $(CVA6_REPO_DIR)/core/compressed_decoder.sv \
    $(CVA6_REPO_DIR)/core/controller.sv \
    $(CVA6_REPO_DIR)/core/csr_buffer.sv \
    $(CVA6_REPO_DIR)/core/csr_regfile.sv \
    $(CVA6_REPO_DIR)/core/decoder.sv \
    $(CVA6_REPO_DIR)/core/ex_stage.sv \
    $(CVA6_REPO_DIR)/core/acc_dispatcher.sv \
    $(CVA6_REPO_DIR)/core/instr_realign.sv \
    $(CVA6_REPO_DIR)/core/id_stage.sv \
    $(CVA6_REPO_DIR)/core/issue_read_operands.sv \
    $(CVA6_REPO_DIR)/core/issue_stage.sv \
    $(CVA6_REPO_DIR)/core/load_unit.sv \
    $(CVA6_REPO_DIR)/core/load_store_unit.sv \
    $(CVA6_REPO_DIR)/core/lsu_bypass.sv \
    $(CVA6_REPO_DIR)/core/mult.sv \
    $(CVA6_REPO_DIR)/core/multiplier.sv \
    $(CVA6_REPO_DIR)/core/serdiv.sv \
    $(CVA6_REPO_DIR)/core/perf_counters.sv \
    $(CVA6_REPO_DIR)/core/ariane_regfile_ff.sv \
    $(CVA6_REPO_DIR)/core/scoreboard.sv \
    $(CVA6_REPO_DIR)/core/raw_checker.sv \
    $(CVA6_REPO_DIR)/core/store_buffer.sv \
    $(CVA6_REPO_DIR)/core/amo_buffer.sv \
    $(CVA6_REPO_DIR)/core/store_unit.sv \
    $(CVA6_REPO_DIR)/core/commit_stage.sv \
    $(CVA6_REPO_DIR)/core/axi_shim.sv \
    $(CVA6_REPO_DIR)/core/frontend/btb.sv \
    $(CVA6_REPO_DIR)/core/frontend/bht.sv \
    $(CVA6_REPO_DIR)/core/frontend/bht2lvl.sv \
    $(CVA6_REPO_DIR)/core/frontend/ras.sv \
    $(CVA6_REPO_DIR)/core/frontend/instr_scan.sv \
    $(CVA6_REPO_DIR)/core/frontend/instr_queue.sv \
    $(CVA6_REPO_DIR)/core/frontend/frontend.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/wt_dcache_ctrl.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/wt_dcache_mem.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/wt_dcache_missunit.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/wt_dcache_wbuffer.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/wt_dcache.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/cva6_icache.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/wt_cache_subsystem.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/wt_axi_adapter.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/tag_cmp.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/axi_adapter.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/miss_handler.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/cache_ctrl.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/cva6_icache_axi_wrapper.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/std_cache_subsystem.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/std_nbdcache.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/cva6_hpdcache_subsystem.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/cva6_hpdcache_if_adapter.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/cva6_hpdcache_subsystem_axi_arbiter.sv \
    $(CVA6_REPO_DIR)/core/cache_subsystem/cva6_hpdcache_wrapper.sv \
    $(CVA6_REPO_DIR)/core/pmp/src/pmp.sv \
    $(CVA6_REPO_DIR)/core/pmp/src/pmp_entry.sv \
    $(CVA6_REPO_DIR)/core/pmp/src/pmp_data_if.sv \
    $(CVA6_REPO_DIR)/common/local/util/sram.sv \
    $(CVA6_REPO_DIR)/common/local/util/tc_sram_wrapper.sv \
    $(CVA6_REPO_DIR)/common/local/util/sram_cache.sv \
    $(CVA6_REPO_DIR)/common/local/util/tc_sram_wrapper_cache_techno.sv \
    $(CVA6_REPO_DIR)/core/cva6.sv
# ------------------------------------------------------------------------------
# 6. Design Timing Constraints & Hardware Pins
# ------------------------------------------------------------------------------
export SDC_FILE    = /home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Other_runs/OpenRoad/cva6/configs/constraint.sdc
export CLK_PIN     = clk_i
export RESET_PIN   = rst_ni

# ------------------------------------------------------------------------------
# 7. Physical Design Parameters for ASAP7 (Initial Sizing Guide)
# ------------------------------------------------------------------------------
export CORE_UTILIZATION   = 45
export CORE_ASPECT_RATIO  = 1
export CORE_MARGIN        = 10
export PLACE_DENSITY      = 0.40

# Comment out fixed coordinates to resolve the initialization conflict
# export DIE_AREA         = 0 0 1400 1400
# export CORE_AREA        = 12 12 1388 1388

# export PLACE_PINS_ARGS    = -edge left -edge right
