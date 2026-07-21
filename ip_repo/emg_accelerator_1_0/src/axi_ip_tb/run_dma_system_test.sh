#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IP_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROJECT_ROOT="$(cd "${IP_ROOT}/../.." && pwd)"
MAIN_MOCK_TB="${PROJECT_ROOT}/emg_gesture_vivado/src/top/accelerator/tb_stem_dw1_pw1_dw2_pw2_pipeline_top.v"
OUTPUT="/tmp/tb_emg_accelerator_dma_system.vvp"
TEST_CASE="${DMA_SYSTEM_TEST_CASE:-0}"

rtl_files=(
  "${IP_ROOT}/src/stem_conv_array_4x4_compute.v"
  "${IP_ROOT}/src/stem_weight_controller.v"
  "${IP_ROOT}/src/stem_weight_controller_with_rom.v"
  "${IP_ROOT}/src/stem_activation_controller.v"
  "${IP_ROOT}/src/stem_activation_controller_with_ram.v"
  "${IP_ROOT}/src/stem_conv_array_4x4.v"
  "${IP_ROOT}/src/stem_to_dw1_buffer.v"
  "${IP_ROOT}/src/stem_to_dw1_buffer_with_ram.v"
  "${IP_ROOT}/src/dw_conv1_4ch_5tap.v"
  "${IP_ROOT}/src/dw1_to_pw1_buffer.v"
  "${IP_ROOT}/src/dw1_to_pw1_buffer_with_ram.v"
  "${IP_ROOT}/src/pw_conv1_array_4x8_compute.v"
  "${IP_ROOT}/src/pw_conv1_weight_controller.v"
  "${IP_ROOT}/src/pw_conv1_weight_controller_with_rom.v"
  "${IP_ROOT}/src/pw_conv1_array_4x8.v"
  "${IP_ROOT}/src/pw1_to_dw2_buffer.v"
  "${IP_ROOT}/src/pw1_to_dw2_buffer_with_ram.v"
  "${IP_ROOT}/src/dw_conv2_4ch_5tap.v"
  "${IP_ROOT}/src/dw2_to_pw2_buffer.v"
  "${IP_ROOT}/src/dw2_to_pw2_buffer_with_ram.v"
  "${IP_ROOT}/src/pw_conv2_array_4x12_compute.v"
  "${IP_ROOT}/src/pw_conv2_weight_controller.v"
  "${IP_ROOT}/src/pw_conv2_weight_controller_with_rom.v"
  "${IP_ROOT}/src/pw_conv2_array_4x12.v"
  "${IP_ROOT}/src/fc_classifier_96_5_compute.v"
  "${IP_ROOT}/src/fc_weight_controller.v"
  "${IP_ROOT}/src/fc_weight_controller_with_rom.v"
  "${IP_ROOT}/src/fc_classifier_96_5.v"
  "${IP_ROOT}/src/emg_stream_fifo_slice.v"
  "${IP_ROOT}/src/accelerator.v"
  "${IP_ROOT}/src/emg_dma_pingpong_controller.v"
  "${IP_ROOT}/hdl/emg_accelerator_v1_0_S00_AXIS.v"
  "${IP_ROOT}/hdl/emg_accelerator_v1_0_S00_AXI.v"
  "${IP_ROOT}/hdl/emg_accelerator_v1_0.v"
  "${SCRIPT_DIR}/emg_ddr_model.v"
  "${SCRIPT_DIR}/axi_dma_mm2s_model.v"
  "${SCRIPT_DIR}/tb_emg_accelerator_dma_system.v"
  "${MAIN_MOCK_TB}"
)

iverilog -g2012 -Wall \
  "-DPROJECT_ROOT=\"${IP_ROOT}/src\"" \
  "-DEMG_TEST_PROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -s tb_emg_accelerator_dma_system \
  -P tb_emg_accelerator_dma_system.TEST_CASE="${TEST_CASE}" \
  -P tb_emg_accelerator_dma_system.RUN_ALL_CASES=0 \
  -o "${OUTPUT}" \
  "${rtl_files[@]}"

vvp "${OUTPUT}"
