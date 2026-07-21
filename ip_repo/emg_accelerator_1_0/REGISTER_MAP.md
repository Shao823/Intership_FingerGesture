# EMG Accelerator AXI-Lite Register Map

The first IP version requires `s00_axi_aclk` and `s00_axis_aclk` to be connected
to the same clock source. Their active-low resets must also be asserted and
released together. If the DMA uses another clock, place an AXI4-Stream Clock
Converter before `S00_AXIS`; do not drive the two IP clocks independently.

The AXI Stream input is one fixed-size packet per inference:

- Input tensor layout: NCT, channel outer and time index inner.
- Frame size: 5 x 348 signed INT8 samples.
- Stream width: 32 bits, four consecutive time samples per beat.
- Frame length: 435 beats / 1740 bytes.
- `TLAST` must be asserted on beat 434.
- `TKEEP` must be `4'b1111` for every beat.

The input byte order is channel-major. For each channel, one stream beat packs
four consecutive signed INT8 time samples: sample `t+0` in `TDATA[7:0]`,
sample `t+1` in `TDATA[15:8]`, sample `t+2` in `TDATA[23:16]`, and sample
`t+3` in `TDATA[31:24]`.

The IP also exposes the minimum direct functional outputs for downstream PL
logic and ILA observation:

| Port | Width | Description |
| --- | ---: | --- |
| `class_id` | 3 | Current classification result. Valid when `class_valid` is asserted. |
| `class_valid` | 1 | One-cycle classification result valid pulse. |
| `inference_done` | 1 | One-cycle inference completion pulse. |
| `inference_busy` | 1 | High while the accelerator is processing a frame. |

## 0x00 COMMAND

| Bit | Name | Access | Description |
| ---: | --- | --- | --- |
| 0 | START | W1P | Start inference if a complete frame is ready and the core is idle. |
| 1 | CLEAR_DONE | W1P | Clear the sticky DONE status and deassert the completion IRQ. |
| 2 | CLEAR_ERRORS | W1P | Clear receive and rejected-start error flags. |

Reads return zero. Command writes do not modify persistent configuration.

## 0x04 STATUS

| Bit | Name | Description |
| ---: | --- | --- |
| 0 | BUSY | Accelerator is processing a frame. |
| 1 | DONE | Sticky inference completion flag. |
| 2 | FRAME_READY | One complete input frame is waiting. |
| 3 | RX_ACTIVE | A frame is currently being received or discarded. |
| 4 | ACT_WRITE_READY | The accelerator input bank can accept a write. |
| 5 | CLASS_VALID | Raw one-cycle class result valid pulse. |
| 6 | IRQ | Current interrupt output state. |
| 7 | START_NO_FRAME | Software requested start without a complete frame. |
| 8 | START_BUSY | Software requested start while the core was busy. |
| 9 | ERROR | At least one receive or start error is set. |

## 0x08 RESULT

Bits `[2:0]` contain the most recently completed class index.

## 0x0C FRAME_INFO

- Bits `[15:0]`: expected words, 435.
- Bits `[31:16]`: expected bytes, 1740.

## 0x10 RX_STATUS

- Bits `[15:0]`: current accepted beat count.
- Bits `[31:16]`: successfully received frame count modulo 65536.

## 0x14 ERROR_STATUS

| Bit | Name |
| ---: | --- |
| 0 | EARLY_TLAST |
| 1 | MISSING_TLAST |
| 2 | BAD_KEEP |
| 3 | DROPPED_FRAME |
| 4 | START_NO_FRAME |
| 5 | START_BUSY |

## 0x18 CYCLE_COUNT

Cycle count of the most recently completed inference.

## 0x1C VERSION

IP version encoded as `major.minor` in bits `[31:16]` and `[15:0]`.

## 0x20 CONFIG

| Bit | Name | Access | Description |
| ---: | --- | --- | --- |
| 0 | AUTO_START | R/W | Automatically start whenever a complete frame is ready. |
| 1 | IRQ_ENABLE | R/W | Enable `irq` while sticky DONE is set. |

Separating `COMMAND` from `CONFIG` prevents a `START` or clear command from
accidentally disabling `AUTO_START` or `IRQ_ENABLE`.
