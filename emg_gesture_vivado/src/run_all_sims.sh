#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-/mnt/d/Intership}"

modules=(
  dw_conv1_4ch_5tap
  dw_conv2_4ch_5tap
  pw_conv2_array_4x12
  fc_classifier_96_5
)

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_stem_conv_array_4x4_compute.vvp \
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_conv_array_4x4_compute.v" \
  "${SCRIPT_DIR}/stem_conv_array_4x4/tb_stem_conv_array_4x4_compute.v"
vvp /tmp/tb_stem_conv_array_4x4_compute.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_pw_conv1_array_4x8_compute.vvp \
  "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_array_4x8_compute.v" \
  "${SCRIPT_DIR}/pw_conv1_array_4x8/tb_pw_conv1_array_4x8_compute.v"
vvp /tmp/tb_pw_conv1_array_4x8_compute.vvp

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

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_stem_activation_controller_l1.vvp \
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller.v" \
  "${SCRIPT_DIR}/stem_conv_array_4x4/tb_stem_activation_controller.v"
vvp /tmp/tb_stem_activation_controller_l1.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -P tb_stem_activation_controller.BRAM_READ_LATENCY=2 \
  -o /tmp/tb_stem_activation_controller_l2.vvp \
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller.v" \
  "${SCRIPT_DIR}/stem_conv_array_4x4/tb_stem_activation_controller.v"
vvp /tmp/tb_stem_activation_controller_l2.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_pw_conv1_weight_controller_l1.vvp \
  "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_weight_controller.v" \
  "${SCRIPT_DIR}/pw_conv1_array_4x8/tb_pw_conv1_weight_controller.v"
vvp /tmp/tb_pw_conv1_weight_controller_l1.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -P tb_pw_conv1_weight_controller.BRAM_READ_LATENCY=2 \
  -o /tmp/tb_pw_conv1_weight_controller_l2.vvp \
  "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_weight_controller.v" \
  "${SCRIPT_DIR}/pw_conv1_array_4x8/tb_pw_conv1_weight_controller.v"
vvp /tmp/tb_pw_conv1_weight_controller_l2.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -DPW1_MOCK_WEIGHT_ROM -DPW1_MOCK_ROM_READ_LATENCY=2 \
  -P tb_pw_conv1_array_4x8.BRAM_READ_LATENCY=2 \
  -o /tmp/tb_pw_conv1_array_4x8_mock_l2.vvp \
  "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_array_4x8_compute.v" \
  "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_weight_controller.v" \
  "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_weight_controller_with_rom.v" \
  "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_array_4x8.v" \
  "${SCRIPT_DIR}/pw_conv1_array_4x8/tb_pw_conv1_array_4x8.v"
vvp /tmp/tb_pw_conv1_array_4x8_mock_l2.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_stem_to_dw1_buffer_l1.vvp \
  "${SCRIPT_DIR}/stem_to_dw1_buffer/stem_to_dw1_buffer.v" \
  "${SCRIPT_DIR}/stem_to_dw1_buffer/tb_stem_to_dw1_buffer.v"
vvp /tmp/tb_stem_to_dw1_buffer_l1.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -P tb_stem_to_dw1_buffer.BRAM_READ_LATENCY=2 \
  -o /tmp/tb_stem_to_dw1_buffer_l2.vvp \
  "${SCRIPT_DIR}/stem_to_dw1_buffer/stem_to_dw1_buffer.v" \
  "${SCRIPT_DIR}/stem_to_dw1_buffer/tb_stem_to_dw1_buffer.v"
vvp /tmp/tb_stem_to_dw1_buffer_l2.vvp

stem_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_stem_weight"
stem_ip_run_dir="${SCRIPT_DIR}/../emg_gesture_vivado.ip_user_files/sim_scripts/blk_mem_gen_stem_weight/xsim"
act_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_stem_activation"
act_ip_run_dir="${SCRIPT_DIR}/../emg_gesture_vivado.ip_user_files/sim_scripts/blk_mem_gen_stem_activation/xsim"
stem_to_dw1_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_stem_to_dw_conv1"
pw1_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_pw_conv1_weight"
pw1_ip_run_dir="${SCRIPT_DIR}/../emg_gesture_vivado.ip_user_files/sim_scripts/blk_mem_gen_pw_conv1_weight/xsim"

if [[ -f "${stem_to_dw1_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${stem_to_dw1_ip_root}/sim/blk_mem_gen_stem_to_dw_conv1.v" ]]; then
  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -I "${SCRIPT_DIR}/stem_to_dw1_buffer" \
    -o /tmp/tb_stem_to_dw1_buffer_with_ram.vvp \
    "${stem_to_dw1_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${stem_to_dw1_ip_root}/sim/blk_mem_gen_stem_to_dw_conv1.v" \
    "${SCRIPT_DIR}/stem_to_dw1_buffer/stem_to_dw1_buffer.v" \
    "${SCRIPT_DIR}/stem_to_dw1_buffer/stem_to_dw1_buffer_with_ram.v" \
    "${SCRIPT_DIR}/stem_to_dw1_buffer/tb_stem_to_dw1_buffer_with_ram.v"
  vvp /tmp/tb_stem_to_dw1_buffer_with_ram.vvp
else
  echo "SKIP stem_to_dw1 buffer IP simulation: generated stem_to_dw1 IP simulation files not found"
fi

if [[ -f "${act_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${act_ip_root}/sim/blk_mem_gen_stem_activation.v" ]]; then
  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -o /tmp/tb_stem_activation_controller_with_ram.vvp \
    "${act_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${act_ip_root}/sim/blk_mem_gen_stem_activation.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller_with_ram.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/tb_stem_activation_controller_with_ram.v"
  (cd "${act_ip_run_dir}" && vvp /tmp/tb_stem_activation_controller_with_ram.vvp)
else
  echo "SKIP stem activation RAM IP simulations: generated stem activation IP simulation files not found"
fi

if [[ -f "${stem_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${stem_ip_root}/sim/blk_mem_gen_stem_weight.v" \
      && -f "${act_ip_root}/sim/blk_mem_gen_stem_activation.v" \
      && -f "${stem_ip_run_dir}/blk_mem_gen_stem_weight.mif" ]]; then
  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -o /tmp/tb_stem_conv_array_4x4.vvp \
    "${stem_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${stem_ip_root}/sim/blk_mem_gen_stem_weight.v" \
    "${act_ip_root}/sim/blk_mem_gen_stem_activation.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_conv_array_4x4_compute.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller_with_rom.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller_with_ram.v" \
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

if [[ -f "${pw1_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${pw1_ip_root}/sim/blk_mem_gen_pw_conv1_weight.v" \
      && -f "${pw1_ip_run_dir}/blk_mem_gen_pw_conv1_weight.mif" ]]; then
  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -o /tmp/tb_pw_conv1_weight_controller_with_rom.vvp \
    "${pw1_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${pw1_ip_root}/sim/blk_mem_gen_pw_conv1_weight.v" \
    "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_weight_controller.v" \
    "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_weight_controller_with_rom.v" \
    "${SCRIPT_DIR}/pw_conv1_array_4x8/tb_pw_conv1_weight_controller_with_rom.v"
  (cd "${pw1_ip_run_dir}" && vvp /tmp/tb_pw_conv1_weight_controller_with_rom.vvp)

  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -o /tmp/tb_pw_conv1_array_4x8.vvp \
    "${pw1_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${pw1_ip_root}/sim/blk_mem_gen_pw_conv1_weight.v" \
    "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_array_4x8_compute.v" \
    "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_weight_controller.v" \
    "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_weight_controller_with_rom.v" \
    "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_array_4x8.v" \
    "${SCRIPT_DIR}/pw_conv1_array_4x8/tb_pw_conv1_array_4x8.v"
  (cd "${pw1_ip_run_dir}" && vvp /tmp/tb_pw_conv1_array_4x8.vvp)
else
  echo "SKIP PW1 ROM IP simulations: generated PW1 weight IP simulation files not found"
fi

if [[ -f "${stem_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${stem_ip_root}/sim/blk_mem_gen_stem_weight.v" \
      && -f "${act_ip_root}/sim/blk_mem_gen_stem_activation.v" \
      && -f "${stem_to_dw1_ip_root}/sim/blk_mem_gen_stem_to_dw_conv1.v" \
      && -f "${stem_ip_run_dir}/blk_mem_gen_stem_weight.mif" ]]; then
  python3 "${SCRIPT_DIR}/top/stem_dw1_pipeline/gen_testdata.py"

  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -o /tmp/tb_stem_dw1_pipeline_top.vvp \
    "${stem_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${stem_ip_root}/sim/blk_mem_gen_stem_weight.v" \
    "${act_ip_root}/sim/blk_mem_gen_stem_activation.v" \
    "${stem_to_dw1_ip_root}/sim/blk_mem_gen_stem_to_dw_conv1.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_conv_array_4x4_compute.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller_with_rom.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller_with_ram.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_conv_array_4x4.v" \
    "${SCRIPT_DIR}/stem_to_dw1_buffer/stem_to_dw1_buffer.v" \
    "${SCRIPT_DIR}/stem_to_dw1_buffer/stem_to_dw1_buffer_with_ram.v" \
    "${SCRIPT_DIR}/dw_conv1_4ch_5tap/dw_conv1_4ch_5tap.v" \
    "${SCRIPT_DIR}/top/stem_dw1_pipeline/stem_dw1_pipeline_top.v" \
    "${SCRIPT_DIR}/top/stem_dw1_pipeline/tb_stem_dw1_pipeline_top.v"
  (cd "${stem_ip_run_dir}" && vvp /tmp/tb_stem_dw1_pipeline_top.vvp)

  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -P tb_stem_dw1_pipeline_top.DUT_PENDING_DEPTH=33 \
    -P tb_stem_dw1_pipeline_top.WATERMARK_STRESS_ONLY=1 \
    -o /tmp/tb_stem_dw1_pipeline_top_watermark.vvp \
    "${stem_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${stem_ip_root}/sim/blk_mem_gen_stem_weight.v" \
    "${act_ip_root}/sim/blk_mem_gen_stem_activation.v" \
    "${stem_to_dw1_ip_root}/sim/blk_mem_gen_stem_to_dw_conv1.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_conv_array_4x4_compute.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller_with_rom.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller_with_ram.v" \
    "${SCRIPT_DIR}/stem_conv_array_4x4/stem_conv_array_4x4.v" \
    "${SCRIPT_DIR}/stem_to_dw1_buffer/stem_to_dw1_buffer.v" \
    "${SCRIPT_DIR}/stem_to_dw1_buffer/stem_to_dw1_buffer_with_ram.v" \
    "${SCRIPT_DIR}/dw_conv1_4ch_5tap/dw_conv1_4ch_5tap.v" \
    "${SCRIPT_DIR}/top/stem_dw1_pipeline/stem_dw1_pipeline_top.v" \
    "${SCRIPT_DIR}/top/stem_dw1_pipeline/tb_stem_dw1_pipeline_top.v"
  (cd "${stem_ip_run_dir}" && vvp /tmp/tb_stem_dw1_pipeline_top_watermark.vvp)
else
  echo "SKIP stem-DW1 top IP simulation: generated IP simulation files not found"
fi
