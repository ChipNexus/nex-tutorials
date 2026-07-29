#!/usr/bin/env bash
# Build the flat RTL staging area for the CPU timing-closure project.
# Usage: ./setup_staging.sh <ibex_clone_dir> <staging_dir>
set -euo pipefail
IBEX="${1:?ibex clone dir}"
STAGE="${2:?staging dir}"
ASSETS="$(cd "$(dirname "$0")" && pwd)"

PRIM="$IBEX/vendor/lowrisc_ip/ip/prim/rtl"
PGEN="$IBEX/vendor/lowrisc_ip/ip/prim_generic/rtl"
PXIL="$IBEX/vendor/lowrisc_ip/ip/prim_xilinx/rtl"
DVU="$IBEX/vendor/lowrisc_ip/dv/sv/dv_utils"

mkdir -p "$STAGE"

# Ibex RTL (synthesis subset: no tracer / lockstep / latch register file)
for f in ibex_pkg.sv ibex_alu.sv ibex_branch_predict.sv ibex_compressed_decoder.sv \
         ibex_controller.sv ibex_counter.sv ibex_cs_registers.sv ibex_csr.sv \
         ibex_decoder.sv ibex_dummy_instr.sv ibex_ex_block.sv ibex_fetch_fifo.sv \
         ibex_icache.sv ibex_id_stage.sv ibex_if_stage.sv ibex_load_store_unit.sv \
         ibex_multdiv_fast.sv ibex_multdiv_slow.sv ibex_pmp.sv ibex_prefetch_buffer.sv \
         ibex_register_file_ff.sv ibex_register_file_fpga.sv ibex_wb_stage.sv \
         ibex_core.sv ibex_top.sv; do
  cp "$IBEX/rtl/$f" "$STAGE/"
done

# lowRISC primitive packages + Xilinx technology bindings
cp "$PXIL/prim_pkg.sv" "$PRIM/prim_util_pkg.sv" "$PRIM/prim_secded_pkg.sv" \
   "$PGEN/prim_ram_1p_pkg.sv" \
   "$PXIL/prim_clock_gating.sv" "$PXIL/prim_buf.sv" "$PXIL/prim_flop.sv" "$STAGE/"

# macro headers — staged flat so Vivado resolves `include without include dirs
cp "$PRIM/prim_assert.sv" "$PRIM/prim_assert_standard_macros.svh" \
   "$PRIM/prim_assert_dummy_macros.svh" "$PRIM/prim_assert_sec_cm.svh" \
   "$PRIM/prim_assert_yosys_macros.svh" "$PRIM/prim_flop_macros.sv" \
   "$DVU/dv_fcov_macros.svh" "$STAGE/"

# project integration files
cp "$ASSETS/cpu_wrapper.sv" "$ASSETS/fpga_top.sv" "$STAGE/"

echo "Staged $(ls "$STAGE" | wc -l) files in $STAGE"
