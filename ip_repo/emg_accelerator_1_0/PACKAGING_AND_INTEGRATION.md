# Packaging and Block Design Integration

## IP Packager Sources

Do not manually maintain file-level library entries in generated
`component.xml`. The packaged metadata may keep these entries empty.

Before running simulation in the Edit Packaged IP project, source
`prepare_simulation_libraries.tcl`. It temporarily sets the current Vivado
project's Verilog files to `xil_defaultlib` and updates compile order. It does
not call IPX merge/save commands and does not modify package metadata.

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

The current DMA uses a 32-bit MM2S memory interface with a 16-beat maximum
burst. Each upstream DMA burst is therefore 64 bytes. After width conversion
to the 128-bit HP0 interface, that same transaction is four HP0 beats, so the
current SmartConnect `M00_AXI.MAX_BURST_LENGTH=4` is consistent with the DMA.
Increasing only the SmartConnect limit does not merge multiple DMA bursts and
does not reduce the approximately 28 DMA transactions required for 1740
bytes. If measured DMA latency becomes important, evaluate the DMA memory-map
data width, DMA burst size, and SmartConnect downstream limit together.

`S_AXI_HP0_FPD` is not coherent with the APU data cache. Before MM2S starts,
software must make the input buffer visible to DMA:

- Bare-metal: align the buffer and call
  `Xil_DCacheFlushRange((INTPTR)buffer, 1740)` after the final CPU write.
- Linux: use the DMA API, such as a coherent DMA buffer or the appropriate
  streaming-DMA map/sync calls. Do not rely on a normal cached userspace
  mapping being visible to PL DMA automatically.

The DMA has no DRE, so the MM2S source address must be four-byte aligned. The
1740-byte frame length is already a multiple of four.

If the DMA stream clock differs from the AXI-Lite/control clock, insert an
AXI4-Stream Clock Converter before `S00_AXIS` and keep both accelerator clock
ports on the accelerator control clock. This IP version does not contain an
internal clock-domain crossing for control and status signals.

## Runtime Sequence

1. Write `CONFIG.AUTO_START` and `CONFIG.IRQ_ENABLE` as required.
2. Clear stale receive errors and DONE with `COMMAND` if required.
3. Write the input frame to DDR and flush/synchronize the CPU cache for DMA.
4. Start one 1740-byte DMA MM2S transfer.
5. Wait until `STATUS.FRAME_READY` is set when using manual start.
6. Write `COMMAND.START`, or rely on `CONFIG.AUTO_START`.
7. Wait for `STATUS.DONE` or `irq`.
8. Read `RESULT` and `CYCLE_COUNT`.

The accelerator has two internal activation RAM banks. Once a complete frame is
started, the stream receiver can fill the other bank while inference is active.
At most one complete not-yet-started frame is queued, so AXI Stream backpressure
is asserted until that queued frame is consumed.
