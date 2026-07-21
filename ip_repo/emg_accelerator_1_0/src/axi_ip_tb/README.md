# Targeted AXI IP Tests

These small testbenches validate only the AXI shell and DMA frame controller.
They do not run the full quantized network simulation.

- `tb_emg_dma_pingpong_controller.v`: frame length, backpressure, `TLAST`,
  `TKEEP`, drop/drain, and sticky error clearing.
- `tb_emg_accelerator_s00_axi.v`: eight-register AXI-Lite map and interrupt.
- `tb_emg_accelerator_axi_shell.v`: end-to-end AXI shell with a stub accelerator.
- `tb_emg_accelerator_dma_system.v`: byte-addressed DDR model, DMA MM2S AXIS
  model, AXI-Lite control, the complete AXI shell, and the real accelerator.

## AXI Shell Stub Test

Run the lightweight shell-only test with:

```bash
./ip_repo/emg_accelerator_1_0/src/axi_ip_tb/run_axi_shell_test.sh
```

The test-local `accelerator` stub is compiled only when
`EMG_AXI_SHELL_STUB_ACCELERATOR` is defined. This prevents a duplicate module
declaration if Vivado also compiles the real `src/accelerator.v`.

## DDR + DMA + Real Accelerator Test

Before launching this test in the Vivado Edit Packaged IP project, run:

```tcl
source D:/Intership/ip_repo/emg_accelerator_1_0/prepare_simulation_libraries.tcl
```

This only changes Library properties in the current Vivado project session. It
does not persist Library entries into `component.xml` or the packaged IP.

Run case 0 from the repository root:

```bash
./ip_repo/emg_accelerator_1_0/src/axi_ip_tb/run_dma_system_test.sh
```

Select another one of the ten generated test cases:

```bash
DMA_SYSTEM_TEST_CASE=3 \
  ./ip_repo/emg_accelerator_1_0/src/axi_ip_tb/run_dma_system_test.sh
```

The command-line script always sets `RUN_ALL_CASES=0`, so it only runs the
selected `DMA_SYSTEM_TEST_CASE`. In the Vivado GUI, the testbench parameter
defaults to `RUN_ALL_CASES=1`, so launching
`tb_emg_accelerator_dma_system` runs all ten generated cases sequentially.

The test performs this sequence:

```text
raw_input.mem
  -> DDR byte model with channel-major software layout
  -> DMA MM2S model, 1740 bytes / 435 AXIS beats
  -> S00_AXIS frame controller
  -> real accelerator RTL
  -> AXI-Lite RESULT and IRQ
  -> fc_expected_class.mem comparison
```

The script reuses the main project's behavioral BRAM models from
`tb_stem_dw1_pw1_dw2_pw2_pipeline_top.v`. It therefore verifies the complete
RTL data path and weight contents without requiring generated XCI simulation
products. A separate Vivado/xsim run is still required to validate the packaged
XCI output products themselves.
