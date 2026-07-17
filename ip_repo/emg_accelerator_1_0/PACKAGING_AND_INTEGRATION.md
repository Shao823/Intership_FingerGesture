# Packaging and Block Design Integration

## IP Packager Sources

When editing this packaged IP in Vivado, add these files to the synthesis and
simulation source groups:

- `hdl/*.v`
- `src/*.v`
- `src/blk_mem_gen_*/*.xci`
- `src/weight_data/**/*`

Do not add `src/axi_ip_tb` to the synthesis source group. The optional
`sync_package_sources.tcl` script performs the source merge, refreshes top-level
ports and parameters, and registers `irq` as a level-high interrupt interface.

After merging changes, set `emg_accelerator_v1_0` as the synthesis top, run IP
Packager validation, and re-package the core. Generate output products for the
nine packaged `.xci` files inside the IP editing project; do not reuse the main
project's `.gen` directory.

## Block Design Connections

- Connect AXI DMA `M_AXIS_MM2S` to `S00_AXIS`.
- Configure a 32-bit MM2S stream with `TLAST` enabled.
- Program each DMA transfer length as 1740 bytes.
- Connect `S00_AXI` to the processor control interconnect.
- Connect `irq` to an interrupt concat/controller input if interrupts are used.
- Drive `s00_axi_aclk` and `s00_axis_aclk` from the same clock source.
- Assert and release both active-low resets together.

If the DMA stream clock differs from the AXI-Lite/control clock, insert an
AXI4-Stream Clock Converter before `S00_AXIS` and keep both accelerator clock
ports on the accelerator control clock. This IP version does not contain an
internal clock-domain crossing for control and status signals.

## Runtime Sequence

1. Clear stale receive errors and DONE if required.
2. Start one 1740-byte DMA MM2S transfer.
3. Wait until `STATUS.FRAME_READY` is set.
4. Write `CONTROL.START`, or enable `CONTROL.AUTO_START` in advance.
5. Wait for `STATUS.DONE` or `irq`.
6. Read `RESULT` and `CYCLE_COUNT`.

The accelerator has two internal activation RAM banks. Once a complete frame is
started, the stream receiver can fill the other bank while inference is active.
At most one complete not-yet-started frame is queued, so AXI Stream backpressure
is asserted until that queued frame is consumed.
