#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-/mnt/d/Intership}"

modules=(
  dw_conv1_4ch_5tap
  pw_conv1_array_4x8
  dw_conv2_4ch_5tap
  pw_conv2_array_4x12
  fc_classifier_96_5
)

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_stem_conv_array_4x4_compute.vvp \
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_conv_array_4x4_compute.v" \
  "${SCRIPT_DIR}/stem_conv_array_4x4/tb_stem_conv_array_4x4_compute.v"
vvp /tmp/tb_stem_conv_array_4x4_compute.vvp

for module in "${modules[@]}"; do
  rtl="${SCRIPT_DIR}/${module}/${module}.v"
  tb="${SCRIPT_DIR}/${module}/tb_${module}.v"
  out="/tmp/tb_${module}.vvp"

  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" -o "${out}" "${rtl}" "${tb}"
  vvp "${out}"
done

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_stem_weight_controller_l1.vvp \
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller.v" \
  "${SCRIPT_DIR}/stem_conv_array_4x4/tb_stem_weight_controller.v"
vvp /tmp/tb_stem_weight_controller_l1.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -P tb_stem_weight_controller.BRAM_READ_LATENCY=2 \
  -o /tmp/tb_stem_weight_controller_l2.vvp \
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller.v" \
  "${SCRIPT_DIR}/stem_conv_array_4x4/tb_stem_weight_controller.v"
vvp /tmp/tb_stem_weight_controller_l2.vvp

stem_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_stem_weight"
stem_ip_run_dir="${SCRIPT_DIR}/../emg_gesture_vivado.ip_user_files/sim_scripts/blk_mem_gen_stem_weight/xsim"
if [[ -f "${stem_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${stem_ip_root}/sim/blk_mem_gen_stem_weight.v" \
      && -f "${stem_ip_run_dir}/blk_mem_gen_stem_weight.mif" ]]; then
  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -o /tmp/tb_stem_conv_array_4x4.vvp \
    "${stem_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${stem_ip_root}/sim/blk_mem_gen_stem_weight.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_conv_array_4x4_compute.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller_with_rom.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_conv_array_4x4.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/tb_stem_conv_array_4x4.v"
  (cd "${stem_ip_run_dir}" && vvp /tmp/tb_stem_conv_array_4x4.vvp)

  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -o /tmp/tb_stem_weight_controller_with_rom.vvp \
    "${stem_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${stem_ip_root}/sim/blk_mem_gen_stem_weight.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller_with_rom.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/tb_stem_weight_controller_with_rom.v"
  (cd "${stem_ip_run_dir}" && vvp /tmp/tb_stem_weight_controller_with_rom.vvp)
else
  echo "SKIP stem ROM IP simulations: generated stem weight IP simulation files not found"
fi
