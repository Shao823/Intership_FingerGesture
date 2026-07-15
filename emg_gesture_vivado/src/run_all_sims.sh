#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-/mnt/d/Intership}"

modules=(
  dw_conv1_4ch_5tap
  dw_conv2_4ch_5tap
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

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_pw_conv2_array_4x12_compute.vvp \
  "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_array_4x12_compute.v" \
  "${SCRIPT_DIR}/pw_conv2_array_4x12/tb_pw_conv2_array_4x12_compute.v"
vvp /tmp/tb_pw_conv2_array_4x12_compute.vvp

python3 "${SCRIPT_DIR}/fc_classifier_96_5/gen_testdata.py"

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_fc_classifier_96_5_compute.vvp \
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_classifier_96_5_compute.v" \
  "${SCRIPT_DIR}/fc_classifier_96_5/tb_fc_classifier_96_5_compute.v"
vvp /tmp/tb_fc_classifier_96_5_compute.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_fc_weight_controller.vvp \
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_weight_controller.v" \
  "${SCRIPT_DIR}/fc_classifier_96_5/tb_fc_weight_controller.v"
vvp /tmp/tb_fc_weight_controller.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -DFC_MOCK_WEIGHT_ROM \
  -o /tmp/tb_fc_weight_controller_with_rom_mock.vvp \
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_weight_controller.v" \
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_weight_controller_with_rom.v" \
  "${SCRIPT_DIR}/fc_classifier_96_5/tb_fc_weight_controller_with_rom.v"
vvp /tmp/tb_fc_weight_controller_with_rom_mock.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_fc_classifier_96_5_mock.vvp \
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_classifier_96_5_compute.v" \
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_weight_controller.v" \
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_weight_controller_with_rom.v" \
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_classifier_96_5.v" \
  "${SCRIPT_DIR}/fc_classifier_96_5/tb_fc_classifier_96_5.v"
vvp /tmp/tb_fc_classifier_96_5_mock.vvp

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
  -o /tmp/tb_pw_conv2_weight_controller_l1.vvp \
  "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_weight_controller.v" \
  "${SCRIPT_DIR}/pw_conv2_array_4x12/tb_pw_conv2_weight_controller.v"
vvp /tmp/tb_pw_conv2_weight_controller_l1.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -P tb_pw_conv2_weight_controller.BRAM_READ_LATENCY=2 \
  -o /tmp/tb_pw_conv2_weight_controller_l2.vvp \
  "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_weight_controller.v" \
  "${SCRIPT_DIR}/pw_conv2_array_4x12/tb_pw_conv2_weight_controller.v"
vvp /tmp/tb_pw_conv2_weight_controller_l2.vvp

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

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_dw1_to_pw1_buffer_l1.vvp \
  "${SCRIPT_DIR}/dw1_to_pw1_buffer/dw1_to_pw1_buffer.v" \
  "${SCRIPT_DIR}/dw1_to_pw1_buffer/tb_dw1_to_pw1_buffer.v"
vvp /tmp/tb_dw1_to_pw1_buffer_l1.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -P tb_dw1_to_pw1_buffer.BRAM_READ_LATENCY=2 \
  -o /tmp/tb_dw1_to_pw1_buffer_l2.vvp \
  "${SCRIPT_DIR}/dw1_to_pw1_buffer/dw1_to_pw1_buffer.v" \
  "${SCRIPT_DIR}/dw1_to_pw1_buffer/tb_dw1_to_pw1_buffer.v"
vvp /tmp/tb_dw1_to_pw1_buffer_l2.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_dw2_to_pw2_buffer_l1.vvp \
  "${SCRIPT_DIR}/dw2_to_pw2_buffer/dw2_to_pw2_buffer.v" \
  "${SCRIPT_DIR}/dw2_to_pw2_buffer/tb_dw2_to_pw2_buffer.v"
vvp /tmp/tb_dw2_to_pw2_buffer_l1.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -P tb_dw2_to_pw2_buffer.BRAM_READ_LATENCY=2 \
  -o /tmp/tb_dw2_to_pw2_buffer_l2.vvp \
  "${SCRIPT_DIR}/dw2_to_pw2_buffer/dw2_to_pw2_buffer.v" \
  "${SCRIPT_DIR}/dw2_to_pw2_buffer/tb_dw2_to_pw2_buffer.v"
vvp /tmp/tb_dw2_to_pw2_buffer_l2.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -o /tmp/tb_pw1_to_dw2_buffer_l1.vvp \
  "${SCRIPT_DIR}/pw1_to_dw2_buffer/pw1_to_dw2_buffer.v" \
  "${SCRIPT_DIR}/pw1_to_dw2_buffer/tb_pw1_to_dw2_buffer.v"
vvp /tmp/tb_pw1_to_dw2_buffer_l1.vvp

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -P tb_pw1_to_dw2_buffer.BRAM_READ_LATENCY=2 \
  -o /tmp/tb_pw1_to_dw2_buffer_l2.vvp \
  "${SCRIPT_DIR}/pw1_to_dw2_buffer/pw1_to_dw2_buffer.v" \
  "${SCRIPT_DIR}/pw1_to_dw2_buffer/tb_pw1_to_dw2_buffer.v"
vvp /tmp/tb_pw1_to_dw2_buffer_l2.vvp

stem_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_stem_weight"
stem_ip_run_dir="${SCRIPT_DIR}/../emg_gesture_vivado.ip_user_files/sim_scripts/blk_mem_gen_stem_weight/xsim"
act_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_stem_activation"
act_ip_run_dir="${SCRIPT_DIR}/../emg_gesture_vivado.ip_user_files/sim_scripts/blk_mem_gen_stem_activation/xsim"
stem_to_dw1_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_stem_to_dw_conv1"
dw1_to_pw1_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_dw_to_pw_conv1"
dw2_to_pw2_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_dw_to_pw_conv2"
pw1_to_dw2_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_pw_to_dw_conv2"
pw1_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_pw_conv1_weight"
pw1_ip_run_dir="${SCRIPT_DIR}/../emg_gesture_vivado.ip_user_files/sim_scripts/blk_mem_gen_pw_conv1_weight/xsim"
pw2_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_pw_conv2_weight"
pw2_ip_run_dir="${SCRIPT_DIR}/../emg_gesture_vivado.ip_user_files/sim_scripts/blk_mem_gen_pw_conv2_weight/xsim"
fc_ip_root="${SCRIPT_DIR}/../emg_gesture_vivado.gen/sources_1/ip/blk_mem_gen_fc_weight"
fc_ip_run_dir="${SCRIPT_DIR}/../emg_gesture_vivado.ip_user_files/sim_scripts/blk_mem_gen_fc_weight/xsim"

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

if [[ -f "${dw1_to_pw1_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${dw1_to_pw1_ip_root}/sim/blk_mem_gen_dw_to_pw_conv1.v" ]]; then
  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -I "${SCRIPT_DIR}/dw1_to_pw1_buffer" \
    -o /tmp/tb_dw1_to_pw1_buffer_with_ram.vvp \
    "${dw1_to_pw1_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${dw1_to_pw1_ip_root}/sim/blk_mem_gen_dw_to_pw_conv1.v" \
    "${SCRIPT_DIR}/dw1_to_pw1_buffer/dw1_to_pw1_buffer.v" \
    "${SCRIPT_DIR}/dw1_to_pw1_buffer/dw1_to_pw1_buffer_with_ram.v" \
    "${SCRIPT_DIR}/dw1_to_pw1_buffer/tb_dw1_to_pw1_buffer_with_ram.v"
  vvp /tmp/tb_dw1_to_pw1_buffer_with_ram.vvp
else
  echo "SKIP dw1_to_pw1 buffer IP simulation: generated dw1_to_pw1 IP simulation files not found"
fi

if [[ -f "${dw2_to_pw2_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${dw2_to_pw2_ip_root}/sim/blk_mem_gen_dw_to_pw_conv2.v" ]]; then
  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -I "${SCRIPT_DIR}/dw2_to_pw2_buffer" \
    -o /tmp/tb_dw2_to_pw2_buffer_with_ram.vvp \
    "${dw2_to_pw2_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${dw2_to_pw2_ip_root}/sim/blk_mem_gen_dw_to_pw_conv2.v" \
    "${SCRIPT_DIR}/dw2_to_pw2_buffer/dw2_to_pw2_buffer.v" \
    "${SCRIPT_DIR}/dw2_to_pw2_buffer/dw2_to_pw2_buffer_with_ram.v" \
    "${SCRIPT_DIR}/dw2_to_pw2_buffer/tb_dw2_to_pw2_buffer_with_ram.v"
  vvp /tmp/tb_dw2_to_pw2_buffer_with_ram.vvp
else
  echo "SKIP dw2_to_pw2 buffer IP simulation: generated dw2_to_pw2 IP simulation files not found"
fi

if [[ -f "${pw1_to_dw2_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${pw1_to_dw2_ip_root}/sim/blk_mem_gen_pw_to_dw_conv2.v" ]]; then
  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -DUSE_PW1_TO_DW2_WITH_RAM \
    -DPW1_TO_DW2_TB_MODULE=tb_pw1_to_dw2_buffer_with_ram \
    -s tb_pw1_to_dw2_buffer_with_ram \
    -o /tmp/tb_pw1_to_dw2_buffer_with_ram.vvp \
    "${pw1_to_dw2_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${pw1_to_dw2_ip_root}/sim/blk_mem_gen_pw_to_dw_conv2.v" \
    "${SCRIPT_DIR}/pw1_to_dw2_buffer/pw1_to_dw2_buffer.v" \
    "${SCRIPT_DIR}/pw1_to_dw2_buffer/pw1_to_dw2_buffer_with_ram.v" \
    "${SCRIPT_DIR}/pw1_to_dw2_buffer/tb_pw1_to_dw2_buffer.v"
  vvp /tmp/tb_pw1_to_dw2_buffer_with_ram.vvp
else
  echo "SKIP pw1_to_dw2 buffer IP simulation: generated pw1_to_dw2 IP simulation files not found"
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

if [[ -f "${pw2_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${pw2_ip_root}/sim/blk_mem_gen_pw_conv2_weight.v" \
      && -f "${pw2_ip_run_dir}/blk_mem_gen_pw_conv2_weight.mif" ]]; then
  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -o /tmp/tb_pw_conv2_weight_controller_with_rom.vvp \
    "${pw2_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${pw2_ip_root}/sim/blk_mem_gen_pw_conv2_weight.v" \
    "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_weight_controller.v" \
    "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_weight_controller_with_rom.v" \
    "${SCRIPT_DIR}/pw_conv2_array_4x12/tb_pw_conv2_weight_controller_with_rom.v"
  (cd "${pw2_ip_run_dir}" && vvp /tmp/tb_pw_conv2_weight_controller_with_rom.vvp)

  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -o /tmp/tb_pw_conv2_array_4x12.vvp \
    "${pw2_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${pw2_ip_root}/sim/blk_mem_gen_pw_conv2_weight.v" \
    "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_array_4x12_compute.v" \
    "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_weight_controller.v" \
    "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_weight_controller_with_rom.v" \
    "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_array_4x12.v" \
    "${SCRIPT_DIR}/pw_conv2_array_4x12/tb_pw_conv2_array_4x12.v"
  (cd "${pw2_ip_run_dir}" && vvp /tmp/tb_pw_conv2_array_4x12.vvp)
else
  echo "SKIP PW2 ROM IP simulations: generated PW2 weight IP simulation files not found"
fi

if [[ -f "${fc_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${fc_ip_root}/sim/blk_mem_gen_fc_weight.v" \
      && -f "${fc_ip_run_dir}/blk_mem_gen_fc_weight.mif" ]]; then
  fc_real_run_dir="/tmp/emg_fc_real_ip"
  mkdir -p "${fc_real_run_dir}"
  cp "${fc_ip_run_dir}/blk_mem_gen_fc_weight.mif" "${fc_real_run_dir}/"

  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -DUSE_REAL_IP \
    -o /tmp/tb_fc_weight_controller_with_rom_real.vvp \
    "${fc_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${fc_ip_root}/sim/blk_mem_gen_fc_weight.v" \
    "${SCRIPT_DIR}/fc_classifier_96_5/fc_weight_controller.v" \
    "${SCRIPT_DIR}/fc_classifier_96_5/fc_weight_controller_with_rom.v" \
    "${SCRIPT_DIR}/fc_classifier_96_5/tb_fc_weight_controller_with_rom.v"
  (cd "${fc_real_run_dir}" && vvp /tmp/tb_fc_weight_controller_with_rom_real.vvp)

  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -DUSE_REAL_IP \
    -o /tmp/tb_fc_classifier_96_5_real.vvp \
    "${fc_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${fc_ip_root}/sim/blk_mem_gen_fc_weight.v" \
    "${SCRIPT_DIR}/fc_classifier_96_5/fc_classifier_96_5_compute.v" \
    "${SCRIPT_DIR}/fc_classifier_96_5/fc_weight_controller.v" \
    "${SCRIPT_DIR}/fc_classifier_96_5/fc_weight_controller_with_rom.v" \
    "${SCRIPT_DIR}/fc_classifier_96_5/fc_classifier_96_5.v" \
    "${SCRIPT_DIR}/fc_classifier_96_5/tb_fc_classifier_96_5.v"
  (cd "${fc_real_run_dir}" && vvp /tmp/tb_fc_classifier_96_5_real.vvp)
else
  echo "SKIP FC ROM IP simulations: generated FC weight IP simulation files not found"
fi

full_top_dir="${SCRIPT_DIR}/top/accelerator"
full_top_case_limit="${FULL_TOP_RUN_CASE_LIMIT:-1}"
full_top_real_case_limit="${FULL_TOP_RUN_REAL_CASE_LIMIT:-1}"

python3 "${full_top_dir}/gen_testdata.py"

full_top_rtl=(
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_conv_array_4x4_compute.v"
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller.v"
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_weight_controller_with_rom.v"
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller.v"
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_activation_controller_with_ram.v"
  "${SCRIPT_DIR}/stem_conv_array_4x4/stem_conv_array_4x4.v"
  "${SCRIPT_DIR}/stem_to_dw1_buffer/stem_to_dw1_buffer.v"
  "${SCRIPT_DIR}/stem_to_dw1_buffer/stem_to_dw1_buffer_with_ram.v"
  "${SCRIPT_DIR}/dw_conv1_4ch_5tap/dw_conv1_4ch_5tap.v"
  "${SCRIPT_DIR}/dw1_to_pw1_buffer/dw1_to_pw1_buffer.v"
  "${SCRIPT_DIR}/dw1_to_pw1_buffer/dw1_to_pw1_buffer_with_ram.v"
  "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_array_4x8_compute.v"
  "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_weight_controller.v"
  "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_weight_controller_with_rom.v"
  "${SCRIPT_DIR}/pw_conv1_array_4x8/pw_conv1_array_4x8.v"
  "${SCRIPT_DIR}/pw1_to_dw2_buffer/pw1_to_dw2_buffer.v"
  "${SCRIPT_DIR}/pw1_to_dw2_buffer/pw1_to_dw2_buffer_with_ram.v"
  "${SCRIPT_DIR}/dw_conv2_4ch_5tap/dw_conv2_4ch_5tap.v"
  "${SCRIPT_DIR}/dw2_to_pw2_buffer/dw2_to_pw2_buffer.v"
  "${SCRIPT_DIR}/dw2_to_pw2_buffer/dw2_to_pw2_buffer_with_ram.v"
  "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_array_4x12_compute.v"
  "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_weight_controller.v"
  "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_weight_controller_with_rom.v"
  "${SCRIPT_DIR}/pw_conv2_array_4x12/pw_conv2_array_4x12.v"
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_classifier_96_5_compute.v"
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_weight_controller.v"
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_weight_controller_with_rom.v"
  "${SCRIPT_DIR}/fc_classifier_96_5/fc_classifier_96_5.v"
  "${SCRIPT_DIR}/emg_stream_fifo_slice.v"
  "${full_top_dir}/stem_dw1_pw1_dw2_pw2_pipeline_top.v"
  "${full_top_dir}/tb_stem_dw1_pw1_dw2_pw2_pipeline_top.v"
)

iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
  -P tb_stem_dw1_pw1_dw2_pw2_pipeline_top.RUN_CASE_LIMIT="${full_top_case_limit}" \
  -P tb_stem_dw1_pw1_dw2_pw2_pipeline_top.RUN_CONTINUOUS_START_CASE=0 \
  -P tb_stem_dw1_pw1_dw2_pw2_pipeline_top.RUN_MID_RESET_CASE=0 \
  -o /tmp/tb_stem_dw1_pw1_dw2_pw2_pipeline_top_mock.vvp \
  "${full_top_rtl[@]}"
vvp /tmp/tb_stem_dw1_pw1_dw2_pw2_pipeline_top_mock.vvp

if [[ -f "${stem_ip_root}/simulation/blk_mem_gen_v8_4.v" \
      && -f "${stem_ip_root}/sim/blk_mem_gen_stem_weight.v" \
      && -f "${act_ip_root}/sim/blk_mem_gen_stem_activation.v" \
      && -f "${stem_to_dw1_ip_root}/sim/blk_mem_gen_stem_to_dw_conv1.v" \
      && -f "${dw1_to_pw1_ip_root}/sim/blk_mem_gen_dw_to_pw_conv1.v" \
      && -f "${pw1_ip_root}/sim/blk_mem_gen_pw_conv1_weight.v" \
      && -f "${pw1_to_dw2_ip_root}/sim/blk_mem_gen_pw_to_dw_conv2.v" \
      && -f "${dw2_to_pw2_ip_root}/sim/blk_mem_gen_dw_to_pw_conv2.v" \
      && -f "${pw2_ip_root}/sim/blk_mem_gen_pw_conv2_weight.v" \
      && -f "${fc_ip_root}/sim/blk_mem_gen_fc_weight.v" \
      && -f "${stem_ip_run_dir}/blk_mem_gen_stem_weight.mif" \
      && -f "${pw1_ip_run_dir}/blk_mem_gen_pw_conv1_weight.mif" \
      && -f "${pw2_ip_run_dir}/blk_mem_gen_pw_conv2_weight.mif" \
      && -f "${fc_ip_run_dir}/blk_mem_gen_fc_weight.mif" ]]; then
  full_top_real_run_dir="/tmp/emg_full_fc_real_ip"
  mkdir -p "${full_top_real_run_dir}"
  cp \
    "${stem_ip_run_dir}/blk_mem_gen_stem_weight.mif" \
    "${pw1_ip_run_dir}/blk_mem_gen_pw_conv1_weight.mif" \
    "${pw2_ip_run_dir}/blk_mem_gen_pw_conv2_weight.mif" \
    "${fc_ip_run_dir}/blk_mem_gen_fc_weight.mif" \
    "${full_top_real_run_dir}/"

  iverilog -g2012 -Wall "-DPROJECT_ROOT=\"${PROJECT_ROOT}\"" \
    -DUSE_REAL_IP \
    -P tb_stem_dw1_pw1_dw2_pw2_pipeline_top.RUN_CASE_LIMIT="${full_top_real_case_limit}" \
    -P tb_stem_dw1_pw1_dw2_pw2_pipeline_top.RUN_CONTINUOUS_START_CASE=0 \
    -P tb_stem_dw1_pw1_dw2_pw2_pipeline_top.RUN_MID_RESET_CASE=0 \
    -o /tmp/tb_stem_dw1_pw1_dw2_pw2_pipeline_top_real.vvp \
    "${stem_ip_root}/simulation/blk_mem_gen_v8_4.v" \
    "${stem_ip_root}/sim/blk_mem_gen_stem_weight.v" \
    "${act_ip_root}/sim/blk_mem_gen_stem_activation.v" \
    "${stem_to_dw1_ip_root}/sim/blk_mem_gen_stem_to_dw_conv1.v" \
    "${dw1_to_pw1_ip_root}/sim/blk_mem_gen_dw_to_pw_conv1.v" \
    "${pw1_ip_root}/sim/blk_mem_gen_pw_conv1_weight.v" \
    "${pw1_to_dw2_ip_root}/sim/blk_mem_gen_pw_to_dw_conv2.v" \
    "${dw2_to_pw2_ip_root}/sim/blk_mem_gen_dw_to_pw_conv2.v" \
    "${pw2_ip_root}/sim/blk_mem_gen_pw_conv2_weight.v" \
    "${fc_ip_root}/sim/blk_mem_gen_fc_weight.v" \
    "${full_top_rtl[@]}"
  (cd "${full_top_real_run_dir}" && vvp /tmp/tb_stem_dw1_pw1_dw2_pw2_pipeline_top_real.vvp)
else
  echo "SKIP full FC pipeline real IP simulation: generated IP simulation files or ROM MIFs not found"
fi
