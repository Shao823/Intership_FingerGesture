# EMG Finger Simulation BD

This simulation validates four representative source cases through the real AXI DMA,
AXI BRAM Controller, AXI-Stream interface, and packaged EMG accelerator.

Selected source cases and expected classes:

| Packed index | Source case | BRAM offset | Expected class |
| ---: | ---: | ---: | ---: |
| 0 | 6 | `0x0000` | 1 |
| 1 | 8 | `0x06CC` | 2 |
| 2 | 0 | `0x0D98` | 3 |
| 3 | 2 | `0x1464` | 4 |

The data generator converts the original time-major interleaved input into the
channel-major layout consumed by the accelerator and packs it into 32-bit
little-endian BRAM words. The testbench writes these words through the native
BRAM port before starting the AXI DMA. It does not modify the read-only COE
properties of the BRAM Controller mode IP.

From the Vivado Tcl Console:

```tcl
source D:/Intership/emg_gesture_vivado/src/sim/emg_finger_sim/setup_emg_finger_simulation.tcl
```

Then run Behavioral Simulation from the GUI. To configure and launch in one step:

```tcl
source D:/Intership/emg_gesture_vivado/src/sim/emg_finger_sim/run_emg_finger_simulation.tcl
```

The expected final message is:

```text
PASS all 4 representative BD DMA test cases
```
