#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IP_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT="/tmp/tb_emg_accelerator_axi_shell.vvp"

iverilog -g2012 -Wall \
  -DEMG_AXI_SHELL_STUB_ACCELERATOR \
  -s tb_emg_accelerator_axi_shell \
  -o "${OUTPUT}" \
  "${IP_ROOT}/src/emg_dma_pingpong_controller.v" \
  "${IP_ROOT}/hdl/emg_accelerator_v1_0_S00_AXIS.v" \
  "${IP_ROOT}/hdl/emg_accelerator_v1_0_S00_AXI.v" \
  "${IP_ROOT}/hdl/emg_accelerator_v1_0.v" \
  "${SCRIPT_DIR}/tb_emg_accelerator_axi_shell.v"

vvp "${OUTPUT}"
