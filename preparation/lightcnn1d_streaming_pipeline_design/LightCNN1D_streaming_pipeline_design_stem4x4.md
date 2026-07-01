# LightCNN1D streaming pipeline design, stem 4x4 balanced version

本文是 `stem conv` 使用 `4x4` systolic / PE array 后的资源平衡版设计指导。上一版把 DW 写成 `P_TAP_DW=1`，所以 DW1/DW2 的周期被算成 320 cycles；这对应 tap 串行微架构，不是“5-tap 并行”的 DW。若 DW 仍保持 5-tap parallel，则你的计算是正确的：

```text
DW1 middle = 8 time rows * ceil(32 / 4) = 64 cycles
DW2 middle = 4 time rows * ceil(64 / 4) = 64 cycles
```

因此本文把默认推荐修正为：`stem 4x4 + PW1 4x8 + PW2 4x12 + DW P_CH=4/P_TAP=5`。`P_TAP=1` 只作为进一步省 DSP 的可选版本。

配套脚本：

```bash
python3 preparation/lightcnn1d_streaming_pipeline_design/param_sweep_stem4x4.py
python3 preparation/lightcnn1d_streaming_pipeline_design/cycle_model.py --stem-poc 4 --pw1-poc 8 --pw2-poc 12 --dw-pch 4 --dw-ptap 5 --recommended-only
python3 preparation/lightcnn1d_streaming_pipeline_design/buffer_model.py --stem-poc 4 --pw1-poc 8 --pw2-poc 12 --dw-pch 4 --dw-ptap 5
python3 preparation/lightcnn1d_streaming_pipeline_design/storage_model.py --stem-poc 4 --pw1-poc 8 --pw2-poc 12 --dw-pch 4 --dw-ptap 5
```

---

## 1. 推荐参数

网络尺寸不变：

```text
input: 5 x 348
stem: 5 -> 32, k=7, pad=3
DW1: 32 ch, k=5, pad=2
PW1: 32 -> 64
MaxPool: k=2, stride=2
DW2: 64 ch, k=5, pad=2
PW2: 64 -> 96
GAP: 174 -> 1
FC0: 96 -> 96
FC1: 96 -> 5
```

默认硬件参数：

```text
stem: 4x4
DW1:  P_CH_DW=4, P_TAP_DW=5
PW1:  4x8
DW2:  P_CH_DW=4, P_TAP_DW=5
PW2:  4x12
FC:   P_OUT=16, 后续可复用 PW2 或降并行
```

并行乘法资源：

| 模块 | 并行乘法数 |
| --- | ---: |
| stem `4x4` | 16 |
| DW1 `P_CH=4, P_TAP=5` | 20 |
| PW1 `4x8` | 32 |
| DW2 `P_CH=4, P_TAP=5` | 20 |
| PW2 `4x12` | 48 |
| GAP 前端合计 | 136 |
| 独立 FC `P_OUT=16` | 16 |
| 总计 | 152 |

这组参数相比原高吞吐版：

```text
原高吞吐版:
    stem 4x8 + DW P_CH=8/P_TAP=5 + PW1 4x16 + PW2 4x24
    GAP 前端并行乘法 = 272

stem4x4 平衡版:
    stem 4x4 + DW P_CH=4/P_TAP=5 + PW1 4x8 + PW2 4x12
    GAP 前端并行乘法 = 136
```

即前端乘法资源约减半，同时 PW1/PW2 的计算周期仍接近 stem 的 560-cycle chunk 节拍。

---

## 2. 参数扫描结论

脚本 `param_sweep_stem4x4.py` 输出的关键候选：

| candidate | PW1 | PW2 | DW | frontend mult | II | stem | DW1 | PW1 | DW2 | PW2 | 说明 |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| keep old PW/DW | 4x16 | 4x24 | P_CH=8, P_TAP=5 | 256 | 560 | 560 | 32 | 256 | 32 | 256 | PW/DW 资源偏大，PW 利用率低 |
| resize PW only | 4x8 | 4x12 | P_CH=8, P_TAP=5 | 176 | 560 | 560 | 32 | 512 | 32 | 512 | PW 匹配 stem，但 DW 仍过度并行 |
| balanced full-tap | 4x8 | 4x12 | P_CH=4, P_TAP=5 | 136 | 560 | 560 | 64 | 512 | 64 | 512 | 推荐第一版 RTL |
| tap-serial squeeze | 4x8 | 4x12 | P_CH=4, P_TAP=1 | 104 | 560 | 560 | 320 | 512 | 320 | 512 | 可选省 DSP，但改变 DW 微架构 |
| tiny DW bottleneck | 4x8 | 4x12 | P_CH=2, P_TAP=1 | 100 | 640 | 560 | 640 | 512 | 640 | 512 | DW 变成瓶颈 |
| smaller PW2 | 4x8 | 4x10 | P_CH=4, P_TAP=1 | 96 | 640 | 560 | 320 | 512 | 320 | 640 | PW2 变成瓶颈 |

推荐 `balanced full-tap` 作为第一版 RTL：

```text
stem 4x4
PW1 4x8
PW2 4x12
DW P_CH=4, P_TAP=5
```

理由：

```text
1. II 仍由 stem 决定，为 560 cycles/chunk。
2. PW1/PW2 中间 chunk 周期为 512 cycles，利用率 91.4%。
3. DW1/DW2 中间 chunk 周期为 64 cycles，虽然利用率只有 11.4%，但 DW 资源只有 40 个乘法器总计，且不会成为瓶颈。
4. 若后续 DSP 仍紧，再把 DW 改成 P_TAP=1；不要一开始就混淆 full-tap 和 tap-serial 两种实现。
```

这里 DW 的“低全局利用率”不是问题。DW 是 PW 前面的快速轻量 producer，它的目标不是吃满 `560-cycle` 系统节拍，而是尽快把 row 写进 `DW->PW` packer，让 PW 尽早凑满 4 行启动。`P_CH=4/P_TAP=5` 每层只需要：

```text
4 channels * 5 taps = 20 multipliers
```

这个规模和 `stem 4x4` 的 16 MAC/cycle 峰值是同一量级，但它显著降低了首包等待：

```text
DW full-tap:
    PW1 first group start = 576 cycles

DW tap-serial P_TAP=1:
    PW1 first group start = 640 cycles
```

因此第一版不需要为了提高 DW 的利用率而主动把 tap 串行化。tap 串行应该作为 DSP 更紧张时的后续压缩选项。

---

## 3. Chunk 和边界点数

仍以 8 个 high-resolution 时间点作为主 chunk：

```text
348 = 43 * 8 + 4
```

边界点数不随硬件并行度变化：

| chunk | stem 新点数 | DW1/PW1 新点数 | Pool 新点数 | DW2/PW2 新点数 |
| --- | ---: | ---: | ---: | ---: |
| first | 8 | 6 | 3 | 1 |
| middle x42 | 8 | 8 | 4 | 4 |
| tail | 4 | 6 | 3 | 5 |
| total | 348 | 348 | 174 | 174 |

---

## 4. 周期统计

公式：

```text
cycles_gemm = ceil(T / P_T) * ceil(Cout / P_OC) * K
cycles_dw   = T * ceil(channel / P_CH_DW) * ceil(5 / P_TAP_DW)
```

stem：

```text
4 rows:
    ceil(4 / 4) * ceil(32 / 4) * 35 = 280 cycles

8 rows:
    ceil(8 / 4) * ceil(32 / 4) * 35 = 560 cycles
```

PW1：

```text
4 high-res rows:
    ceil(4 / 4) * ceil(64 / 8) * 32 = 256 cycles

8 high-res rows:
    2 * 256 = 512 cycles
```

PW2：

```text
4 low-res rows:
    ceil(4 / 4) * ceil(96 / 12) * 64 = 512 cycles
```

DW 保持 5-tap parallel：

```text
DW1 middle:
    8 rows * ceil(32 / 4) * ceil(5 / 5)
    = 8 * 8 * 1
    = 64 cycles

DW2 middle:
    4 rows * ceil(64 / 4) * ceil(5 / 5)
    = 4 * 16 * 1
    = 64 cycles
```

脚本结果：

| stage | first chunk | middle chunk | tail chunk | steady util at II=560 |
| --- | ---: | ---: | ---: | ---: |
| stem | 560 | 560 | 280 | 100.0% |
| DW1 | 48 | 64 | 48 | 11.4% |
| PW1 | 512 | 512 | 512 | 91.4% |
| Pool | 3 | 4 | 3 | 0.7% |
| DW2 | 16 | 64 | 80 | 11.4% |
| PW2 | 512 | 512 | 1024 | 91.4% |

中间 chunk：

```text
II = 560 cycles/chunk
bottleneck = stem
```

粗粒度按 chunk 调度到 PW2 完成的保守估算：

```text
26,275 cycles ~= 262.75 us @100 MHz
```

最终 `GAP/AveragePool` 输入数据收齐时间以 `buffer_model.py` 的逐行事件模型为准。该模型会显式模拟 `DW->PW` row packer 的等待、PW 满 4 行启动、以及最后 2 行 partial flush。

---

## 5. 4-row 交接节拍

`stem 4x4` 每 280 cycles 产生 4 个 full-channel high-resolution rows。

| handoff | produced points | DW cycles | PW cycles | producer interval | slack | 说明 |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| DW1 -> PW1 steady | 4 high-res | 32 | 256 | 280 | 24 | 4-row PW1 tile 能跟上 |
| DW1 -> PW1 first boundary | 2 high-res | 16 | 256 | 280 | 24 | 推荐等 row packer 凑 4 行 |
| DW1 -> PW1 tail boundary | 6 high-res | 48 | 512 | 280 | -232 | tail drain，stem 已无新工作 |
| DW2 -> PW2 每 4 high-res | 2 low-res | 32 | 512 | 280 | -232 | 不推荐按半满 PW2 tile 启动 |
| DW2 -> PW2 每 8 high-res | 4 low-res | 64 | 512 | 560 | 48 | 推荐满 4 行 PW2 tile |

调度策略：

```text
DW1 -> PW1:
    PW1 每凑够 4 个 high-res rows 启动一次。

Pool/DW2/PW2:
    Pool 每两个 high-res rows 产生一个 low-res row。
    PW2 每凑够 4 个 low-res rows 启动一次。
    最后 2 个 low-res rows 用 valid_mask flush。
```

---

## 6. Buffer 和级间存储

脚本假设：

```text
stem 4x4: 4 rows / 280 cycles
DW:       P_CH=4, P_TAP=5
PW1:      4x8,  256 cycles / 4 high-res rows
PW2:      4x12, 512 cycles / 4 low-res rows
```

推荐 buffer 仍保持 8 rows：

| buffer | row width | model max rows | recommended rows | size |
| --- | ---: | ---: | ---: | ---: |
| stem_to_dw1_window | 32 ch | 5-row window + 4-row burst | 8 | 4096 bit = 512 B |
| dw1_to_pw1_row_fifo | 32 ch | 4 | 8 | 4096 bit = 512 B |
| pw1_input_tile_regs | 32 ch | 4-row tile | 4 | 2048 bit = 256 B |
| pool_to_dw2_window | 64 ch | 5-row window + 2-row pool burst | 8 | 8192 bit = 1024 B |
| dw2_to_pw2_row_fifo | 64 ch | 4 | 8 | 8192 bit = 1024 B |
| pw2_input_tile_regs | 64 ch | 4-row tile | 4 | 4096 bit = 512 B |
| pw2_to_gap_optional_fifo | 96 ch | debug/backpressure | 4 | 6144 bit = 768 B |

Packer 仿真结果：

```text
DW1->PW1 groups = 87
DW1->PW1 max FIFO rows = 4
DW1->PW1 max wait = 288 cycles

DW2->PW2 groups = 44
DW2->PW2 max FIFO rows = 4
DW2->PW2 max wait = 496 cycles
DW2->PW2 final partial rows = 2
```

第一个 PW1 group：

```text
DW1 row arrivals:
    row0 @ 288
    row1 @ 296
    row2 @ 568
    row3 @ 576

start = 576
rows  = [0, 1, 2, 3]
waits = [288, 280, 8, 0]
```

第一个 PW2 group：

```text
DW2 row arrivals:
    row0 @ 1134
    row1 @ 1150
    row2 @ 1414
    row3 @ 1430

start = 1430
rows  = [0, 1, 2, 3]
waits = [296, 280, 16, 0]
```

最差 PW2 等待发生在最终 partial flush：

```text
rows  = [172, 173]
waits = [496, 480]
```

到 `GAP/AveragePool` 输入收齐为止：

```text
Stem last 4-row micro-tile done:        24360 cycles
DW1 last row produced:                  24408 cycles
PW1/Pool all low-resolution rows:       24894 cycles
DW2 last row produced:                  24958 cycles
PW2 final group starts:                 25438 cycles
PW2/GAP receives all 174 rows:          25950 cycles
Drain after final stem micro-tile:       1590 cycles
```

因此在 `stem` 连续计算、`PW1/PW2` 均等待 4 行再启动的策略下，前端到 `AveragePool/GAP` 数据全部到齐需要：

```text
25,950 cycles ~= 259.50 us @100 MHz
```

这个时间点不包含 `GAP` 最后除以 174 或乘常数缩放的固定尾延迟；如果后续把平均缩放也放入 `GAP` 模块，只需要再加一个很小的 per-channel 归一化/写出周期。

---

## 7. 融合后的总体存储预算

本节按第一版 RTL 更容易实现的口径统计：

```text
activation / weight / folded BN / bias: 16-bit Q8.8
accumulator:                            48-bit
```

融合策略：

```text
stem Conv + BN + ReLU
PW1 + BN + ReLU + MaxPool
PW2 + BN + ReLU + GAP accumulator
```

不保存完整中间 feature map：

```text
b1pw[64][348]
b2pw[96][174]
```

如果保存完整中间 feature map，仅这两个张量就需要：

| feature map | shape | storage |
| --- | ---: | ---: |
| b1pw | 348 x 64 x 16 bit | 356,352 bit = 44,544 B |
| b2pw | 174 x 96 x 16 bit | 267,264 bit = 33,408 B |
| total avoided | - | 623,616 bit = 77,952 B |

因此当前 streaming 设计只保留滑窗、row FIFO、PW 输入 tile 和少量状态。

### 7.1 级间缓存本体

这张表只统计卷积流水线级间真正需要的缓存，不含参数 ROM，不含计算阵列内部寄存器。

| buffer | formula | storage | 作用 |
| --- | ---: | ---: | --- |
| stem_to_dw1_window | 8 x 32 x 16 | 4,096 bit = 512 B | DW1 的 k=5 滑窗和边界冗余 |
| dw1_to_pw1_row_fifo | 8 x 32 x 16 | 4,096 bit = 512 B | DW1 输出等待 PW1 凑 4 行 |
| pw1_input_tile_regs | 4 x 32 x 16 | 2,048 bit = 256 B | PW1 计算期间锁住 4 行输入 |
| pool_to_dw2_window | 8 x 64 x 16 | 8,192 bit = 1,024 B | DW2 的 k=5 滑窗和 pool 输出冗余 |
| dw2_to_pw2_row_fifo | 8 x 64 x 16 | 8,192 bit = 1,024 B | DW2 输出等待 PW2 凑 4 行 |
| pw2_input_tile_regs | 4 x 64 x 16 | 4,096 bit = 512 B | PW2 计算期间锁住 4 行输入 |
| required subtotal | - | 30,720 bit = 3,840 B | 必需级间缓存 |

可选缓存：

| buffer | formula | storage | 作用 |
| --- | ---: | ---: | --- |
| input_to_stem_window_optional | 10 x 5 x 16 | 800 bit = 100 B | 原始输入完全流式进入时使用；若输入先存在片上 RAM，可不用 |
| pw2_to_gap_optional_fifo | 4 x 96 x 16 | 6,144 bit = 768 B | debug/backpressure FIFO；正常情况下 GAP 可直接累加 |
| optional subtotal | - | 6,944 bit = 868 B | 非必需 |

所以级间缓存可以按两个口径理解：

```text
只算必需级间缓存:               30,720 bit = 3,840 B
加 optional input/debug FIFO:   37,664 bit = 4,708 B
```

如果后续选择把完整输入窗口 `input[5][348]` 也全部放在片上，再额外增加：

```text
5 x 348 x 16 = 27,840 bit = 3,480 B
```

### 7.2 GAP/FC 运行时状态

这些不是级间卷积缓存，而是 PW2 后面的累加和向量状态。

| state | formula | storage | 作用 |
| --- | ---: | ---: | --- |
| gap_sum | 96 x 48 | 4,608 bit = 576 B | 174 个 PW2 输出行的逐通道累加 |
| gap_vec | 96 x 16 | 1,536 bit = 192 B | GAP 缩放后的 96 维向量 |
| fc0_vec | 96 x 16 | 1,536 bit = 192 B | FC0 + ReLU 输出 |
| logits | 5 x 16 | 80 bit = 10 B | FC1 输出 |
| subtotal | - | 7,760 bit = 970 B | GAP/FC 状态 |

因此脚本中的 `inter-stage/state subtotal` 是：

```text
必需级间缓存 30,720
+ optional FIFO 6,944
+ GAP/FC state 7,760
= 45,424 bit = 5,678 B
```

计算单元本地寄存器主要项：

| unit | 内容 | storage |
| --- | --- | ---: |
| stem_array_local `4x4` | acc + activation + active weight + BN/post regs | 1,280 bit = 160 B |
| dw1_pu_local `4ch x 5tap` | 5-tap window + active weights + acc + output | 896 bit = 112 B |
| pw1_array_local `4x8` | acc + activation + active weight + BN/ReLU/Pool regs | 2,752 bit = 344 B |
| dw2_pu_local `4ch x 5tap` | 5-tap window + active weights + acc + output | 896 bit = 112 B |
| pw2_array_local `4x12` | acc + activation + active weight + BN/ReLU regs | 3,712 bit = 464 B |
| fc_dot_local `P_OUT=16` | acc + activation + active weight + bias + output | 1,552 bit = 194 B |
| argmax_local | best index + best value | 19 bit ~= 2.4 B |
| subtotal | - | 11,107 bit ~= 1,388 B |

### 7.3 参数 ROM 全片上存储

如果所有权重均以 16-bit Q8.8 放在片上 ROM：

| ROM | values | formula | storage |
| --- | ---: | ---: | ---: |
| stem_weight | 1,120 | 32 x 5 x 7 x 16 | 17,920 bit = 2,240 B |
| dw1_weight | 160 | 32 x 5 x 16 | 2,560 bit = 320 B |
| pw1_weight | 2,048 | 64 x 32 x 16 | 32,768 bit = 4,096 B |
| dw2_weight | 320 | 64 x 5 x 16 | 5,120 bit = 640 B |
| pw2_weight | 6,144 | 96 x 64 x 16 | 98,304 bit = 12,288 B |
| fc0_weight | 9,216 | 96 x 96 x 16 | 147,456 bit = 18,432 B |
| fc1_weight | 480 | 5 x 96 x 16 | 7,680 bit = 960 B |
| weight ROM subtotal | 19,488 | - | 311,808 bit = 38,976 B |

再加上 folded BN 和 FC bias：

| ROM | values | formula | storage |
| --- | ---: | ---: | ---: |
| folded_bn_scale_bias | 384 | `(32 + 64 + 96) x 2 x 16` | 6,144 bit = 768 B |
| fc_bias | 101 | `(96 + 5) x 16` | 1,616 bit = 202 B |
| non-weight param subtotal | 485 | - | 7,760 bit = 970 B |

所以片上参数 ROM 总量为：

```text
weight only:                  311,808 bit = 38,976 B
weight + folded BN + bias:    319,568 bit = 39,946 B
```

参数 ROM 不随阵列并行度变小而减少，因为网络权重总数不变。阵列变小真正减少的是同时激活的 PE 本地状态、乘法器数量和参数读口宽度。

### 7.4 总量口径

| 口径 | storage |
| --- | ---: |
| 必需级间缓存 | 30,720 bit = 3,840 B |
| 级间/state subtotal，含 optional FIFO | 45,424 bit = 5,678 B |
| 计算单元本地寄存器 | 11,107 bit ~= 1,388 B |
| 参数 ROM，含 weight + folded BN + bias | 319,568 bit = 39,946 B |
| runtime without parameter ROM | 56,531 bit ~= 7,066 B |
| runtime with parameter ROM | 376,099 bit ~= 47,012 B |

最后一行是当前脚本的全包含估计：级间/state、optional FIFO、计算本地寄存器、全部片上参数 ROM 都算进去。实际综合时 BRAM/LUTRAM/register 会按端口数、banking 和字宽对齐，物理占用会比这个 bit-level 统计略有上浮。

---

## 8. 计算资源落地性和优化路线

当前 stem4x4 平衡版的前端并行乘法资源为：

| 模块 | 并行乘法数 | 建议初始映射 |
| --- | ---: | --- |
| stem `4x4` | 16 | DSP 优先，也可后续转 LUT |
| DW1 `P_CH=4,P_TAP=5` | 20 | LUT/常系数乘法优先考虑 |
| PW1 `4x8` | 32 | DSP 优先 |
| DW2 `P_CH=4,P_TAP=5` | 20 | LUT/常系数乘法优先考虑 |
| PW2 `4x12` | 48 | DSP 优先 |
| GAP 前端合计 | 136 | 第一版 all-DSP 可验证功能 |
| 独立 FC `P_OUT=16` | 16 | 建议复用 PW2 或单独轻量实现 |

判断：

```text
1. 对 Zynq-7020 / Artix-7 100T 这类 150 到 220+ DSP 级别器件：
   当前 136 个前端乘法器可以落地，但 DSP 占用不低。

2. 对 80 到 100 DSP 级别的小 FPGA：
   如果全部 16-bit 乘法都走 DSP，当前设计偏紧甚至放不下。

3. 对几十个 DSP 的更小 FPGA：
   必须降低并行度、复用 PW 计算资源、降低精度或牺牲 II；
   不能同时保持当前 560-cycle/chunk 节拍和当前 16-bit 全并行映射。
```

因此第一版 RTL 可以先按“功能正确 + 时序容易收敛”做 all-DSP 原型；如果目标板 DSP 紧张，再按下面顺序压缩。

### 8.1 首选优化：FC 复用 PW2

FC0/FC1 在 `GAP` 收齐之后才启动，不和 GAP 前的卷积流水线同时处于高吞吐稳态。若不是多窗口重叠推理，FC 没必要独占 16 个乘法器。

建议：

```text
FC0/FC1 复用 PW2 的部分 PE，或复用一个 4x12 阵列中的 output-channel lanes。
```

效果：

```text
独立 FC: 额外 16 multipliers
复用 PW2: 额外 0 multipliers
```

这样总乘法资源按前端 136 个估算，而不是 152 个。

### 8.2 第二步：DW 乘法转 LUT 或常系数乘法

DW1/DW2 的全局利用率只有 11.4%，但 full-tap 版本占 40 个乘法器：

```text
DW1 = 4 channels x 5 taps = 20
DW2 = 4 channels x 5 taps = 20
```

DW 权重在推理时固定，非常适合做：

```text
1. LUT multiplier
2. constant-coefficient multiplier
3. CSD/shift-add multiplier
4. 小权重量化后的 shift-add 近似
```

若 PW 和 stem 仍走 DSP，DW 转 LUT 后 DSP 数变为：

```text
stem + PW1 + PW2 = 16 + 32 + 48 = 96 DSP
DW1/DW2 = LUT/shift-add
```

这条路线保持原来的 DW full-tap 周期：

```text
DW1 middle = 64 cycles
DW2 middle = 64 cycles
II 仍由 stem 决定，为 560 cycles/chunk
```

代价是 LUT 和布线压力上升，尤其 16x16 通用 LUT 乘法面积不小。更推荐在参数导出时把 DW 权重做常系数优化，而不是让综合器推断普通 16x16 LUT multiplier。

### 8.3 第三步：DW tap 串行

如果 DSP 或 LUT 都紧张，可以把 DW 改成：

```text
P_CH_DW = 4
P_TAP_DW = 1
```

这会把 DW 乘法器从：

```text
DW1 + DW2 = 20 + 20 = 40 multipliers
```

降到：

```text
DW1 + DW2 = 4 + 4 = 8 multipliers
```

但周期变为：

```text
DW1 middle = 320 cycles
DW2 middle = 320 cycles
```

它仍低于 `560-cycle` stem chunk，不会成为瓶颈，但这是新的 DW 微架构，控制复杂度更高。第一版 RTL 建议先保留 5-tap parallel，等功能稳定后再做这个压缩。

如果这 8 个 DW 乘法也转 LUT，则 DSP 继续按：

```text
stem + PW1 + PW2 = 96 DSP
```

如果 DW tap 串行仍走 DSP，则：

```text
stem + DW1 + PW1 + DW2 + PW2 = 16 + 4 + 32 + 4 + 48 = 104 DSP
```

两种方案都保持中间 chunk 不被 DW 卡住，但 tap 串行会增加 DW 控制复杂度，并推迟冷启动时 PW1/PW2 第一次凑满 4 行的时间。

### 8.4 第四步：stem 乘法转 LUT

若目标只有约 90 个 DSP，`DW 转 LUT` 后的 96 DSP 仍可能偏高。下一步可以考虑把 stem 的 16 个乘法器也转 LUT：

```text
PW1 + PW2 = 32 + 48 = 80 DSP
stem + DW = LUT/shift-add
```

这时 DSP 数可以进入 80 级别，但风险明显增加：

```text
1. stem 是每 280 cycles 固定产出 4 行的源头，时序差会直接影响全流水。
2. stem 的 16-bit 乘法若直接用 LUT 推断，LUT 占用和组合延迟都可能较大。
3. 更合理的方式是固定权重后做常系数乘法、CSD 表达，或降低 stem 权重量化位宽。
```

因此不建议第一版就把 stem 放到 LUT。先验证全 DSP 或 DW-LUT 版本，再压 stem。

### 8.5 不推荐优先做的优化

不要优先减小 `PW1/PW2` 的 output-channel 并行度，因为当前参数已经基本是保持 560-cycle/chunk 的下限：

```text
PW1 4x8:
    8 high-res rows = 512 cycles
    若降到 4x7，则 ceil(64/7)=10，
    8 rows 需要 640 cycles，超过 stem 的 560 cycles。

PW2 4x12:
    4 low-res rows = 512 cycles
    若降到 4x11，则 ceil(96/11)=9，
    4 rows 需要 576 cycles，已经略超 560 cycles。
```

也就是说，在保持 `stem 4x4` 和不 backpressure 的前提下：

```text
PW1 P_OC=8  基本是下限
PW2 P_OC=12 基本是下限
```

若继续减 PW，就必须接受：

```text
1. stem 停顿/backpressure；
2. 更大的级间 FIFO；
3. 更长的整窗推理时间；
4. 或者把 stem 也降速，让系统 II 重新匹配。
```

### 8.6 低精度和 DSP packing

当前文档按 16-bit Q8.8 计算。如果后续量化验证允许，可以把部分层降到：

```text
activation: 8~12 bit
weight:     8~12 bit
acc:        32~48 bit
```

潜在收益：

```text
1. 8-bit weight/activation 可显著降低 LUT multiplier 面积。
2. 某些 FPGA DSP 可以做窄位宽乘法打包，提升每个 DSP 的有效吞吐。
3. 参数 ROM 和级间缓存也会下降。
```

但这不是纯硬件优化，需要重新做量化误差评估。第一版建议保留 16-bit Q8.8，等 RTL 功能和逐层误差闭环后，再做低比特实验。

### 8.7 推荐实现顺序

| 版本 | DSP 估算 | LUT 压力 | II | 适用场景 |
| --- | ---: | --- | ---: | --- |
| all-DSP prototype，FC 独立 | 152 | 低 | 560 | 快速验证功能和时序 |
| all-DSP frontend，FC 复用 | 136 | 低 | 560 | 150+ DSP 器件 |
| DW full-tap 转 LUT，FC 复用 | 96 | 中 | 560 | 100 DSP 左右器件 |
| DW tap 串行 + DW LUT，FC 复用 | 96 | 低到中 | 560 | LUT 也较紧但希望保持 II |
| stem + DW 转 LUT，FC 复用 | 80 | 高 | 560 | 90 DSP 左右器件，需重点看时序 |
| PW 资源复用/降并行 | 48~80 | 中 | >560 | 几十个 DSP 的更小器件，牺牲吞吐 |

当前最稳妥的路线是：

```text
第一版: all-DSP frontend + FC 复用或独立均可
第二版: DW 转 LUT/常系数乘法
第三版: DW tap 串行
第四版: stem 转 LUT 或低比特量化
```

真正需要优先保 DSP 的是 `PW1/PW2`，因为它们占主要 MAC 工作量且利用率高；DW 的计算量小、权重固定、全局利用率低，是最适合从 DSP 中移出去的部分。

---

## 9. 模块设计指导

### 9.1 stem_conv_array_4x4

```text
tile: 4 time rows x 4 output channels
K: 5 input channels * 7 kernel = 35
4 rows all 32 output channels = 280 cycles
8-row chunk = 560 cycles
```

仍采用 output-stationary：

```text
acc[row][oc_lane] += input[row + k][ic] * weight[oc][ic][k]
```

BN 参数按 output-channel lane 驻留：

```text
bn_scale_reg[4]
bn_bias_reg[4]
```

### 9.2 dw_slide_pu

DW1/DW2 共用参数化模块：

```text
P_CH_DW = 4
P_TAP_DW = 5
K = 5
padding = 2
```

每个通道 lane 有 5 个 tap multiplier：

```text
acc[ch_lane] =
    window[ch_lane][0] * weight[ch_lane][0]
  + window[ch_lane][1] * weight[ch_lane][1]
  + window[ch_lane][2] * weight[ch_lane][2]
  + window[ch_lane][3] * weight[ch_lane][3]
  + window[ch_lane][4] * weight[ch_lane][4]
```

周期：

```text
DW1 one row = ceil(32 / 4) = 8 cycles
DW2 one row = ceil(64 / 4) = 16 cycles
```

### 9.3 pw1_array_4x8 + MaxPool

```text
P_T = 4
P_OC = 8
Cin = 32
Cout = 64

4 rows = ceil(4 / 4) * ceil(64 / 8) * 32
       = 256 cycles
```

融合顺序：

```text
PW1 conv -> folded BN -> ReLU -> MaxPool pair buffer
```

### 9.4 pw2_array_4x12 + GAP

```text
P_T = 4
P_OC = 12
Cin = 64
Cout = 96

4 rows = ceil(4 / 4) * ceil(96 / 12) * 64
       = 512 cycles
```

融合顺序：

```text
PW2 conv -> folded BN -> ReLU -> GAP accumulator
```

最后 2 个 low-res rows：

```text
valid_mask = 4'b0011
```

### 9.5 FC0 + ReLU + FC1

第一版可保留独立轻量 FC：

```text
P_OUT = 16
FC0 cycles = ceil(96 / 16) * 96 = 576
FC1 cycles = ceil(5 / 16) * 96 = 96
total = 672 cycles
```

如果继续压资源，FC 优先复用 PW2 或复用其中一部分 PE。

---

## 10. 控制信号和合并流水

核心状态：

```text
stem_ready_right
dw1_ready_right
pool_ready_right
dw2_ready_right
gap_count
```

启动条件：

```text
DW1:
    stem_ready_right >= dw1_out_index + 2
    or final_stem_done

PW1:
    dw1_to_pw1_fifo_level >= 4

Pool:
    PW1 rows 2p and 2p+1 are valid

DW2:
    pool_ready_right >= dw2_out_index + 2
    or final_pool_done

PW2:
    dw2_to_pw2_fifo_level >= 4
    or final_dw2_done and dw2_to_pw2_fifo_level > 0
```

所有级间 FIFO：

```text
valid
ready
level
almost_full
```

---

## 11. 当前结论

本版稳定节拍：

```text
stem = 560 cycles / 8 high-res rows
DW1  = 64 cycles / 8 high-res rows
PW1  = 512 cycles / 8 high-res rows
DW2  = 64 cycles / 4 low-res rows
PW2  = 512 cycles / 4 low-res rows
II   = 560 cycles / chunk
```

判断：

```text
1. DW1/DW2 如果保持 5-tap parallel，利用率确实只有 11.4%，不是 57.1%。
2. PW1/PW2 已经按 stem4x4 重新匹配，利用率为 91.4%。
3. 默认第一版建议保留 DW 5-tap parallel，因为 DW 总共 40 个乘法器，不是主要瓶颈。
4. 若后续 DSP 仍紧，再启用 P_TAP=1 的 DW tap 串行方案，可把 DW 乘法器从 40 降到 8。
5. 8-row 级间 FIFO 仍然足够，存储压力继续很小。
6. all-DSP frontend 需要 136 个 DSP，适合 150+ DSP 级别器件；对 80~100 DSP 小 FPGA 偏紧。
7. 最优先保 DSP 的是 PW1/PW2；DW 和后续可能的 stem 常系数乘法更适合转 LUT/shift-add。
```
