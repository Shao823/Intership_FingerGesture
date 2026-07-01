# LightCNN1D 流式流水线设计与周期分析

本文根据 2026-07-01 的新设计思路，重新整理 `LightCNN1D` 从模块设计到后续合并成流水线的参数选择和周期估算。配套统计脚本见：

```text
preparation/lightcnn1d_streaming_pipeline_design/cycle_model.py
```

运行：

```bash
python3 preparation/lightcnn1d_streaming_pipeline_design/cycle_model.py
```

本文只讨论新的流式设计，不再依赖旧的单 MAC RTL 基线。

---

## 1. 先校正一个关键概念

这里把 `4x8 systolic / PE array` 定义为：

```text
P_T  = 4    // 并行时间点数
P_OC = 8    // 并行输出通道数
```

所以 `4x8` 的一个 micro-tile 不是直接得到“8 个时间点的全通道数据”，而是得到：

```text
4 个时间点 x 8 个输出通道
```

以 stem 为例：

```text
stem output channels = 32
stem K = input_channel * kernel = 5 * 7 = 35
```

要得到 8 个时间点的 32 个 stem 输出通道，需要：

```text
ceil(8 / 4) * ceil(32 / 8) * 35
= 2 * 4 * 35
= 280 cycles
```

因此后续控制逻辑应该把 `4x8` 视为 PE 内部 micro-tile。流水线跨模块传递的是更大的 time chunk，本文暂定 stem chunk 为 8 个时间点。

---

## 2. Chunk 边界和可产生点数

输入长度：

```text
348 = 43 * 8 + 4
```

因此 stem 时间 chunk 是：

```text
43 个完整 chunk，每个 8 点
1 个 tail chunk，4 点
```

DW1、MaxPool、DW2 的可产生点数如下：

| chunk | stem 新点数 | DW1/PW1 新点数 | Pool 新点数 | DW2/PW2 新点数 |
| --- | ---: | ---: | ---: | ---: |
| first | 8 | 6 | 3 | 1 |
| middle x42 | 8 | 8 | 4 | 4 |
| tail | 4 | 6 | 3 | 5 |
| total | 348 | 348 | 174 | 174 |

这个和你的边界判断一致：

```text
first:
    DW1: 8 + left_pad2 -> 6
    Pool: 6 / 2 -> 3
    DW2: 3 + left_pad2 -> 1

middle:
    DW1: 8
    Pool: 8 / 2 -> 4
    DW2: 4

tail:
    DW1: 4 + right_pad2 -> 6
    Pool: 6 / 2 -> 3
    DW2: 3 + right_pad2 -> 5
```

更细粒度地看，第一批不必等 stem 8 点全算完才启动 DW1。只要 stem 已经有 4 个时间点的全通道数据，DW1 结合左 padding 就能先产出：

```text
2 + 4 - 5 + 1 = 2
```

个 DW1 时间点。后续再用控制信号推进剩余点即可。

---

## 3. 周期公式

GEMM / pointwise / stem 的通用公式：

```text
cycles_gemm = ceil(T / P_T) * ceil(Cout / P_OC) * K
```

其中：

```text
T    = 本 chunk 要计算的时间点数
Cout = 输出通道数
K    = 归约长度
```

各 GEMM 型层：

| 层 | T | Cout | K |
| --- | ---: | ---: | ---: |
| stem | chunk stem 点数 | 32 | 35 |
| PW1 | chunk DW1 点数 | 64 | 32 |
| PW2 | chunk DW2 点数 | 96 | 64 |

Depthwise 假设每个通道 lane 使用 5-tap 并行乘加树：

```text
cycles_dw = T * ceil(channel / P_CH_DW)
```

MaxPool 很轻，假设每拍处理 64 个通道：

```text
cycles_pool = pool_points
```

---

## 4. 你提出的 1x16 PW 参数的问题

参数：

```text
stem: 4x8
DW1/DW2: P_CH_DW=8, 5-tap parallel
PW1: 1x16
PW2: 1x16
```

中间稳定 chunk 的周期：

| stage | middle chunk cycles | utilization at II=1536 |
| --- | ---: | ---: |
| stem | 280 | 18.2% |
| DW1 | 32 | 2.1% |
| PW1 | 1024 | 66.7% |
| Pool | 4 | 0.3% |
| DW2 | 32 | 2.1% |
| PW2 | 1536 | 100.0% |

结论：

```text
PW2 是绝对瓶颈。
整个流水线的稳定 II = 1536 cycles/chunk。
stem 只有约 18% 利用率，大部分时间在等后级。
```

所以 `PW1=1x16, PW2=1x16` 可以作为非常保守的功能验证参数，但不适合作为“计算资源尽量不要停歇”的目标参数。

---

## 5. 如果坚持单时间点 PW 流动

如果 PW1/PW2 必须按“一个时间点全通道输入，输出一个时间点”的方式运行，更平衡的一组参数是：

```text
stem: 4x8
PW1:  1x32
PW2:  1x48
DW:   P_CH_DW=8
```

中间稳定 chunk：

| stage | middle chunk cycles | utilization at II=512 |
| --- | ---: | ---: |
| stem | 280 | 54.7% |
| DW1 | 32 | 6.2% |
| PW1 | 512 | 100.0% |
| Pool | 4 | 0.8% |
| DW2 | 32 | 6.2% |
| PW2 | 512 | 100.0% |

这组参数能把 PW1/PW2 拉平，但 stem 仍会有明显等待。原因是单时间点 PW 阵列丢掉了时间维并行度。

更激进的单点版本是：

```text
PW1: 1x64
PW2: 1x96
```

它可以让 PW1/PW2 接近 stem 的 280 cycle/chunk，但代价是 pointwise 阵列很宽，而且每拍需要大量权重并行读取。

---

## 6. 推荐参数：保留 time-tile 的 PW 阵列

更推荐的第一版流式优化参数：

```text
stem: 4x8
PW1:  4x16
PW2:  4x24
DW1:  P_CH_DW=8, 5-tap parallel
DW2:  P_CH_DW=8, 5-tap parallel
Pool: 64 channels/cycle
```

中间稳定 chunk：

| stage | middle chunk cycles | utilization at II=280 |
| --- | ---: | ---: |
| stem | 280 | 100.0% |
| DW1 | 32 | 11.4% |
| PW1 | 256 | 91.4% |
| Pool | 4 | 1.4% |
| DW2 | 32 | 11.4% |
| PW2 | 256 | 91.4% |

这组参数的稳定流水线间隔：

```text
II = 280 cycles/chunk
```

44 个 chunk 从 stem 到 PW2 的调度完成时间约：

```text
13,139 cycles = 131.39 us @ 100 MHz
```

资源量级：

```text
stem: 32 MAC lanes
PW1:  64 MAC lanes
PW2:  96 MAC lanes
DW1:  8 * 5 = 40 multipliers
DW2:  8 * 5 = 40 multipliers
```

这个版本比 `1x16` 的主要收益是：

```text
1. PW1/PW2 不再按单点串行处理，保留时间维并行。
2. 中间 chunk 下 stem/PW1/PW2 周期接近。
3. DW 和 Pool 仍然是快速 producer，不应围绕它们缩小 PW 阵列。
```

---

## 6.1 4-time stem micro-tile 的交接节拍

如果把 stem 的 `4x8` 阵列按 micro-tile 看：

```text
stem 产生 4 个全通道时间点:
    ceil(4/4) * ceil(32/8) * 35 = 140 cycles

stem 产生 8 个全通道时间点:
    ceil(8/4) * ceil(32/8) * 35 = 280 cycles
```

因此需要单独检查 `DW -> PW` 能不能跟上每 140 cycles 的 stem producer 节奏。

推荐参数下的统计结果：

| 交接 | 产生点数 | DW cycles | PW cycles | producer interval | PW 余量 | 结论 |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| DW1 -> PW1 steady | 4 high-res | 16 | 128 | 140 | 12 | 可以按 4 点交接 |
| DW1 -> PW1 first boundary | 2 high-res | 8 | 128 | 140 | 12 | 可用 valid_count=2 或等待合并 |
| DW1 -> PW1 tail boundary | 6 high-res | 24 | 256 | 140 | -116 | tail 需要两个 PW1 time tile |
| DW2 -> PW2 每 4 high-res | 2 low-res | 16 | 256 | 140 | -116 | 不适合这样交接 |
| DW2 -> PW2 每 8 high-res | 4 low-res | 32 | 256 | 280 | 24 | 推荐交接节拍 |

这里的 `PW 余量` 只比较 PW 计算周期和 producer interval。DW 作为短 producer，应该把输出写入小 FIFO 或 ping-pong buffer，再由 PW 消费。

关键结论：

```text
DW1 -> PW1:
    每 4 个高分辨率时间点交接一次。
    DW1 steady 只需 16 cycles，PW1 需 128 cycles。
    stem 每 140 cycles 产生一批，因此 PW1 有 12 cycles 余量。

DW2 -> PW2:
    Pool 会把 4 个高分辨率点变成 2 个低分辨率点。
    PW2=4x24 需要 4 个低分辨率点才能吃满时间维。
    所以 PW2 应该每两个 stem micro-tile 启动一次，即每 280 cycles 处理 4 个 low-res 点。
```

这说明推荐参数不是所有模块都按同一个 140-cycle 节拍启动：

```text
stem / DW1 / PW1:
    4 high-res 点一拍，约 140 cycles 一个节拍

Pool / DW2 / PW2:
    4 low-res 点一拍，也就是 8 high-res 点一拍，约 280 cycles 一个节拍
```

---

## 6.2 边界启动和收尾：不要把 chunk 边界当成 PW tile 边界

这里需要进一步区分：

```text
chunk 边界:
    stem 每次自然产出 4 或 8 个 high-res 时间点

PW tile 边界:
    PW1/PW2 阵列最好每次吃满 P_T=4 个时间点
```

如果直接在边界 valid_count 不足时启动 PW，就会出现阵列行利用率不足。更推荐的实现是给 PW 前面加一个 **row packer / time-row FIFO**：

```text
DW output rows -> row FIFO -> row packer -> PW array

row packer:
    count >= 4 时启动一次 PW tile
    final_flush 时允许 count < 4，并带 valid mask
```

这样 chunk 只负责持续生产时间行，PW 阵列只关心是否凑够 4 行。

### 6.2.1 第一个 140-cycle stem micro-tile

第一次 stem `4x8` 只得到原始 high-res 时间点：

```text
stem t=0..3
```

由于 DW1 是 `k=5, pad=2`：

```text
DW1 能算:
    t=0,1

DW1 不能算:
    t=2,3
```

因为 `t=2` 需要 stem `t=4`，还没到。

所以第一个 140 cycles 后：

```text
DW1 valid rows = 2
PW1 若立即算 2 rows:
    cycles = ceil(2/4) * ceil(64/16) * 32
           = 1 * 4 * 32
           = 128 cycles
```

这在时间上能放进 140-cycle 节拍，但 `P_T=4` 里只有 2 行有效，利用率只有一半。

MaxPool 后：

```text
PW1 t=0,1 -> pool p=0
```

此时 pool 只有 1 个 low-res 点。DW2 要算第一个输出 `p=0`，由于 `k=5,pad=2`，需要：

```text
pool[-2], pool[-1], pool[0], pool[1], pool[2]
```

其中 `pool[1]` 和 `pool[2]` 还没到，所以：

```text
第一个 140-cycle 节拍内 DW2 不能启动有效计算。
```

### 6.2.2 第一个 280-cycle chunk

第二个 stem micro-tile 完成后：

```text
stem t=0..7 available
```

此时 DW1 总共可以得到：

```text
DW1 t=0..5 = 6 个 high-res 点
```

Pool 可以得到：

```text
pool p=0..2 = 3 个 low-res 点
```

因此 DW2 第一次终于可以算：

```text
DW2 p=0
```

但如果立刻让 `PW2=4x24` 只算这 1 个 low-res 点：

```text
PW2 cycles = ceil(1/4) * ceil(96/24) * 64
           = 1 * 4 * 64
           = 256 cycles
```

这会让 `P_T=4` 中 3 行空转。它不是 140-cycle 节拍能解决的问题，而是边界 warm-up 造成的低利用率。

因此有两种实现选择：

```text
方案 A: eager valid-mask
    一有 p=0 就启动 PW2。
    优点是首个输出延迟低。
    缺点是 PW2 前几行空转。

方案 B: row packer
    把 p=0 先放进 low-res row FIFO。
    等凑够 p=0..3 后再启动 PW2。
    优点是 PW2 tile 满行计算。
    缺点是首个 PW2 输出延迟增加。
```

如果目标是“计算资源尽量不要停歇”，推荐方案 B。

### 6.2.3 最后一个 4-point tail

最后 stem tail 只有：

```text
stem 新点数 = 4
```

但因为右侧 padding，DW1 新输出不是 4 点，而是：

```text
DW1/PW1 新点数 = 6
```

如果按 chunk 边界直接触发 PW1：

```text
PW1 cycles = ceil(6/4) * ceil(64/16) * 32
           = 2 * 4 * 32
           = 256 cycles
```

其中第二个 PW1 tile 只有 2 行有效。

DW2/PW2 tail 更明显：

```text
DW2/PW2 新点数 = 5

PW2 cycles = ceil(5/4) * ceil(96/24) * 64
           = 2 * 4 * 64
           = 512 cycles
```

这是 pipeline drain 阶段。此时 stem 已经没有新输入可算，stem 资源空闲一小段时间是正常现象，不代表稳态参数不合理。

### 6.2.4 推荐边界策略

不建议把 first/middle/tail 的 chunk 直接等价成 PW tile。更推荐：

```text
DW1 -> PW1:
    high-res row FIFO 收集 DW1 输出
    PW1 每凑够 4 个 high-res rows 启动一次
    因为总 high-res 点数 348 正好等于 87 * 4
    所以 PW1 理论上不需要最后 partial flush

Pool/DW2 -> PW2:
    low-res row FIFO 收集 DW2 输出
    PW2 每凑够 4 个 low-res rows 启动一次
    174 = 43 * 4 + 2
    所以最后只需要一个 2-row final flush
```

脚本统计结果：

| layer | eager chunk scheduling | row-packer scheduling | saved cycles | 说明 |
| --- | ---: | ---: | ---: | --- |
| PW1 | 11264 | 11136 | 128 | 348 high-res 点正好是 87 组 4 点 |
| PW2 | 11520 | 11264 | 256 | 174 low-res 点是 43 组 4 点 + 最后 2 点 |

因此推荐 RTL 控制结构是：

```text
DW1 output
 -> highres_row_fifo
 -> pw1_row_packer
 -> PW1 array
 -> BN1/ReLU
 -> pool_pair_buffer
 -> pool output
 -> DW2
 -> lowres_row_fifo
 -> pw2_row_packer
 -> PW2 array
 -> BN2/ReLU
 -> GAP
```

这样边界 warm-up 和 drain 都由 FIFO/packer 吸收，主计算阵列在稳态下仍按：

```text
PW1: 每 140 cycles 吃 4 个 high-res rows
PW2: 每 280 cycles 吃 4 个 low-res rows
```

运行。

---

## 6.3 级间 row buffer 大小规范

由于 PW1/PW2 前面使用 row packer，冷启动和收尾时确实会让数据在级间 FIFO 中等待更久。配套建模脚本：

```text
preparation/lightcnn1d_streaming_pipeline_design/buffer_model.py
```

运行：

```bash
python3 preparation/lightcnn1d_streaming_pipeline_design/buffer_model.py
```

推荐第一版不要把 FIFO 做到刚好够用，而是统一留冗余。按当前参数：

```text
stem: 4 rows / 140 cycles
DW1:  4 cycles / high-res row
PW1:  128 cycles / 4 high-res rows
DW2:  8 cycles / low-res row
PW2:  256 cycles / 4 low-res rows
```

脚本统计：

| buffer | row width | model max rows | recommended rows | recommended size | 说明 |
| --- | ---: | ---: | ---: | ---: | --- |
| stem_to_dw1_window | 32 ch | 5-row window + 4-row burst | 8 | 4096 bit = 512 B | k=5 滑窗、4-row stem burst、边界 padding |
| dw1_to_pw1_row_fifo | 32 ch | 4 | 8 | 4096 bit = 512 B | FIFO 峰值占用 4 行；冷启动首组最大等待约 144 cycles |
| pw1_input_tile_regs | 32 ch | 4-row tile | 4 | 2048 bit = 256 B | PW1 本地输入 tile 寄存器；若 FIFO 不能多读，应和 FIFO 分开 |
| pool_to_dw2_window | 64 ch | 5-row window + 2-row burst | 8 | 8192 bit = 1 KB | k=5 DW2 lookahead，加 pool pair 输出 |
| dw2_to_pw2_row_fifo | 64 ch | 4 | 8 | 8192 bit = 1 KB | FIFO 峰值占用 4 行；首个完整组最大等待约 148 cycles，尾部 final flush 可到 248 cycles |
| pw2_input_tile_regs | 64 ch | 4-row tile | 4 | 4096 bit = 512 B | PW2 本地输入 tile 寄存器；若 FIFO 不能多读，应和 FIFO 分开 |
| pw2_to_gap_optional_fifo | 96 ch | 直接流式累加 | 4 | 6144 bit = 768 B | 可选 debug/backpressure FIFO，正常 GAP 直接累加 |

等待时间推导：

```text
DW1 -> PW1 first group:
    第一个 140 cycles 后，stem 只有 t=0..3
    DW1 只能产出 t=0,1 两行

    row0 arrival = 144
    row1 arrival = 148

    第二个 stem micro-tile 到 280 cycles 后，DW1 继续产出:
    row2 arrival = 284
    row3 arrival = 288

    PW1 row packer 在 t=288 凑够 4 行并启动:
    waits = [288-144, 288-148, 288-284, 288-288]
          = [144, 140, 4, 0]

    所以 DW1->PW1 的 144-cycle 最大等待主要来自冷启动凑不满 4 行，
    不是稳态下 PW1 计算资源长期堵住。
```

```text
DW2 -> PW2 first full group:
    第一个 140 cycles:
        DW2 不能启动

    第一个 280 cycles:
        pool 只有 3 行，DW2 只能逐步形成很少的 low-res 输出

    脚本中的第一组 PW2 4-row tile:
        start = 718
        rows  = [0, 1, 2, 3]
        waits = [148, 140, 8, 0]

    这说明 PW2 的第一次有效完整启动比 PW1 晚很多，
    因为中间经过 Pool /2 和 DW2 k=5 的 lookahead。
```

```text
DW2 -> PW2 worst wait:
    脚本中的最大 248-cycle 等待来自最后 final flush:
        rows  = [172, 173]
        waits = [248, 240]

    这是 tail/drain 阶段，不是中间稳态。
```

结论：

```text
等待会增加首帧 latency，但不会要求大容量整层 buffer。
关键级间 FIFO 用 8 行全通道作为第一版规范深度即可。
PW1/PW2 还需要各自 4 行本地 input tile registers。
```

这里要明确区分：

```text
等待时间:
    某一行数据在 FIFO 里等多久。
    冷启动和 tail 会让等待时间变长。

FIFO 深度:
    同一时刻 FIFO 里最多积压多少行。
    当前模型里 DW1->PW1 和 DW2->PW2 峰值都是 4 行。

本地 tile regs:
    PW 启动后锁住的 4 行输入，用于 K 维连续 32/64 个周期的归约。
    这部分最好不要和 row FIFO 混淆。
```

这里的“8 行”是规范深度，不是理论最小值。理论上：

```text
DW1 -> PW1:
    模型峰值 4 行

DW2 -> PW2:
    模型峰值 4 行
```

但实现时应考虑：

```text
1. 后处理流水 drain 多几拍
2. ready/valid 控制有一两个周期延迟
3. tail flush 时 valid_count 不规则
4. 后续调试时可能临时加入 dump 或断点
```

因此第一版建议：

```text
所有主要 row FIFO 深度先取 8。
如果综合后 BRAM/LUT 压力大，再根据仿真波形降到 4 或 6。
```

必须加的控制信号：

```text
fifo_level
fifo_almost_full
fifo_almost_empty
packer_can_fire = fifo_level >= 4
final_flush
valid_mask[3:0]
```

如果某级 FIFO `almost_full`，上游必须能暂停：

```text
DW1 output FIFO almost_full -> 暂停 DW1 写入
DW2 output FIFO almost_full -> 暂停 DW2 写入
```

不要假设下游永远按理想周期消费。规范深度 8 行是为了让普通边界等待不溢出；异常 stall 仍然要靠 ready/valid 和 backpressure 处理。

---

## 6.4 融合后的总体存储预算

当前假设已经做了如下融合：

```text
stem Conv + BN + ReLU
PW1 + BN + ReLU + MaxPool
PW2 + BN + ReLU + GAP accumulator
```

因此不再保存完整的：

```text
b1pw[64][348]
b2pw[96][174]
```

配套统计脚本：

```text
preparation/lightcnn1d_streaming_pipeline_design/storage_model.py
```

运行：

```bash
python3 preparation/lightcnn1d_streaming_pipeline_design/storage_model.py
```

### 6.4.1 级间和状态存储

| name | rows/lanes | channels/width | storage | 说明 |
| --- | ---: | ---: | ---: | --- |
| input_to_stem_window_optional | 10 rows | 5 ch x 16 bit | 800 bit = 100 B | 完全流式输入时需要；若保留整帧输入 buffer 可替代 |
| stem_to_dw1_window | 8 rows | 32 ch x 16 bit | 4096 bit = 512 B | stem Conv+BN+ReLU 输出窗口 |
| dw1_to_pw1_row_fifo | 8 rows | 32 ch x 16 bit | 4096 bit = 512 B | DW1 到 PW1 row packer |
| pw1_input_tile_regs | 4 rows | 32 ch x 16 bit | 2048 bit = 256 B | PW1 本地输入 tile |
| pool_to_dw2_window | 8 rows | 64 ch x 16 bit | 8192 bit = 1 KB | PW1+BN/ReLU+Pool 输出窗口 |
| dw2_to_pw2_row_fifo | 8 rows | 64 ch x 16 bit | 8192 bit = 1 KB | DW2 到 PW2 row packer |
| pw2_input_tile_regs | 4 rows | 64 ch x 16 bit | 4096 bit = 512 B | PW2 本地输入 tile |
| pw2_to_gap_optional_fifo | 4 rows | 96 ch x 16 bit | 6144 bit = 768 B | 可选；正常 GAP 直接流式累加 |
| gap_sum | 96 lanes | 48 bit accumulator | 4608 bit = 576 B | GAP 累加器 |
| gap_vec | 96 values | 16 bit | 1536 bit = 192 B | GAP 归一化后 Q8.8 向量 |
| fc0_vec | 96 values | 16 bit | 1536 bit = 192 B | FC0+ReLU 输出 |
| logits | 5 values | 16 bit | 80 bit = 10 B | FC1 输出 |

小计：

```text
45,424 bit = 5,678 B
```

如果不做完全流式输入，而是保留完整输入窗：

```text
input_buf[5][348] = 5 * 348 * 16
                  = 27,840 bit
                  = 3,480 B
```

此时可以不单独实现 `input_to_stem_window_optional`，但运行时输入相关存储会更大。

### 6.4.2 计算单元本地寄存器

这部分不是级间 FIFO，而是 PE/DW/FC 单元内部状态，例如 accumulator、当前 activation/weight、BN 参数寄存器、后处理寄存器。

| name | rows/lanes | storage | 说明 |
| --- | ---: | ---: | --- |
| stem_array_local | 4x8 PE | 2496 bit = 312 B | acc + act + weight + BN + post regs |
| dw1_pu_local | 8 ch lanes | 1792 bit = 224 B | 5-tap window/weight + acc + output |
| pw1_array_local | 4x16 PE | 5440 bit = 680 B | acc + act + weight + BN + post/pool regs |
| dw2_pu_local | 8 ch lanes | 1792 bit = 224 B | 5-tap window/weight + acc + output |
| pw2_array_local | 4x24 PE | 7360 bit = 920 B | acc + act + weight + BN + post regs |
| fc_dot_local | 16 out lanes | 1552 bit = 194 B | P_OUT=16 FC dot-product 单元 |
| argmax_local | 1 lane | 19 bit | best index + best value |

小计：

```text
20,451 bit ~= 2,556 B
```

注意：

```text
pw1_input_tile_regs / pw2_input_tile_regs
```

已经在级间和状态存储中单独列出，没有重复算进 `pw1_array_local / pw2_array_local`。

### 6.4.3 参数 ROM 存储

参数 ROM 按 Q8.8 16-bit 估算：

| name | values | storage |
| --- | ---: | ---: |
| stem_weight | 1120 | 17,920 bit = 2,240 B |
| dw1_weight | 160 | 2,560 bit = 320 B |
| pw1_weight | 2048 | 32,768 bit = 4,096 B |
| dw2_weight | 320 | 5,120 bit = 640 B |
| pw2_weight | 6144 | 98,304 bit = 12,288 B |
| fc0_weight | 9216 | 147,456 bit = 18,432 B |
| fc1_weight | 480 | 7,680 bit = 960 B |
| folded_bn_scale_bias | 384 | 6,144 bit = 768 B |
| fc_bias | 101 | 1,616 bit = 202 B |

小计：

```text
319,568 bit = 39,946 B
```

这里 `folded_bn_scale_bias` 包含 stem/PW1/PW2 的两参数 BN：

```text
(32 + 64 + 96) output channels * 2 params/channel
= 384 values
```

### 6.4.4 总结

不含参数 ROM 的运行时存储：

```text
inter-stage/state + compute-local
= 45,424 + 20,451
= 65,875 bit
~= 8,234 B
```

包含参数 ROM：

```text
385,443 bit ~= 48,180 B
```

实现提醒：

```text
1. 运行时级间存储很小，主要参数存储来自 FC0 和 PW2 权重。
2. 若资源紧张，优先优化参数 ROM banking/布局，而不是过早压缩 8-row FIFO。
3. b1pw/b2pw 完整 feature map 不应再保留，否则会破坏当前融合设计的存储收益。
4. pw2_to_gap_optional_fifo 可以先保留用于调试；功能稳定后可以移除，让 GAP 直接流式累加。
```

---

## 6.5 BN/ReLU 与 Conv 的融合方式

BN 推理公式可以离线折叠成两个参数：

```text
y = conv_out * folded_scale[oc] + folded_bias[oc]

folded_scale[oc] = gamma[oc] / sqrt(running_var[oc] + eps)
folded_bias[oc]  = beta[oc] - running_mean[oc] * folded_scale[oc]
```

注意 BN 参数是按输出通道 `oc` 存的，不是按时间点存的。按本文阵列约定：

```text
PE row = time
PE col = output channel
```

因此 BN 参数应该驻留在 `P_OC` 方向，也就是每个输出通道列一组：

```text
bn_scale_reg[col]
bn_bias_reg[col]
```

对同一个 output-channel tile，`P_T` 个时间行共享同一列的 BN 参数：

```text
for row in 0 .. P_T-1:
    for col in 0 .. P_OC-1:
        oc = oc_base + col
        bn_out[row][col] =
            conv_out[row][col] * bn_scale_reg[col]
          + bn_bias_reg[col]
```

如果以后把阵列方向换成“row=output channel, col=time”，原则不变：BN 参数要放在输出通道对应的那一维。

### 6.5.1 后处理 MAC 方式

推荐第一版使用 Conv 后的注册化后处理：

```text
PE acc done
 -> acc_out_reg
 -> BN affine MAC
 -> ReLU / saturate
 -> output FIFO or next row packer
```

每个输出值需要一次：

```text
conv_out * folded_scale + folded_bias
```

如果每个 PE lane 后面都有一个 BN 乘加资源，或者复用 PE 内部 multiplier 做一次额外 MAC，那么理论上每个 tile 只需要额外 1 个 BN-MAC 周期。ReLU 本身只是：

```text
relu_out = max(bn_out, 0)
```

可以和 saturate/writeback 放在同一个轻量流水级，或者为了时序单独打一拍。

实际 RTL 建议按两级写，时序更稳：

```text
cycle K_done:
    acc_tile valid

cycle K+1:
    bn_mul = conv_q8_8 * folded_scale

cycle K+2:
    bn_out = (bn_mul >>> 8) + folded_bias
    relu/saturate/writeback
```

如果 Vivado 时序余量足够，再把 BN add、ReLU 和 writeback 合并。

### 6.5.2 固定点实现选择

当前建议仍沿用 Q8.8：

```text
activation / weight / BN folded_scale / folded_bias: signed Q8.8
accumulator: signed 48-bit
```

保守做法：

```text
conv_q8_8 = saturate(acc >>> 8)
bn_mul    = conv_q8_8 * folded_scale      // Q8.8 * Q8.8 = Q16.16
bn_q8_8   = (bn_mul >>> 8) + folded_bias
relu      = max(bn_q8_8, 0)
```

这个做法简单，适合第一版 RTL 和 Python golden 对齐。

更高精度做法是直接对卷积累加器做 BN：

```text
acc       = sum(Q8.8 * Q8.8)              // Q16.16
bn_mul    = acc * folded_scale            // Q24.24
bn_q8_8   = (bn_mul >>> 16) + folded_bias
relu      = max(bn_q8_8, 0)
```

它少一次中间量化，但需要更宽的乘法结果，并且 golden model 要同步修改。建议先做保守版本。

### 6.5.3 是否进一步折叠进权重

后续还可以把 BN scale 直接折进卷积权重：

```text
w_folded[oc, ic, k] = w[oc, ic, k] * folded_scale[oc]
b_folded[oc]        = folded_bias[oc]
```

这样硬件里 Conv 后只需要加 bias 和 ReLU，不需要额外 BN multiplier。但这会改变权重量化和参数导出流程，第一版不建议立刻做。当前更稳妥路线是：

```text
阶段 1:
    Conv acc -> folded BN affine -> ReLU

阶段 2:
    golden 对齐稳定后，再考虑 BN folding into weights
```

---

## 6.6 小型 FPGA 资源评估和优化建议

前面的存储预算说明，当前融合方案的运行时存储并不大：

```text
runtime storage without parameter ROM ~= 8.2 KB
runtime storage with parameter ROM    ~= 48.2 KB
```

所以对 Zynq-7020 / Artix-7 35T 这类小型端到端 FPGA 来说，第一压力不是 BRAM 容量，而是并行乘法器数量、DSP48 数量、LUT 乘法带来的逻辑和布线压力。

### 6.6.1 当前并行乘法资源估算

按当前推荐参数：

```text
stem: 4x8
DW1/DW2: P_CH_DW=8, 5-tap parallel
PW1: 4x16
PW2: 4x24
FC:  P_OUT=16
```

如果所有 16-bit 乘法都映射到 DSP，则并行乘法数量约为：

| 模块 | 并行乘法数 | 说明 |
| --- | ---: | --- |
| stem `4x8` | 32 | 每个 PE 一个 MAC |
| DW1 `8ch x 5tap` | 40 | 8 个通道，每通道 5-tap 全并行 |
| PW1 `4x16` | 64 | 4 个时间点，16 个输出通道 |
| DW2 `8ch x 5tap` | 40 | 同 DW1 |
| PW2 `4x24` | 96 | 当前最大阵列 |
| FC `P_OUT=16` | 16 | GAP 之后的独立后端 |
| 合计 | 288 | 不含额外 BN multiplier |

其中 GAP 前端卷积流水本身就是：

```text
32 + 40 + 64 + 40 + 96 = 272 multipliers
```

如果目标器件是 Zynq-7020 量级，DSP48 数量约 220 个，则“不复用、全 DSP”的当前设计已经超过 DSP 预算：

```text
272 / 220 ~= 124%   // 仅 GAP 前端
288 / 220 ~= 131%   // 加独立 FC 单元
```

如果目标器件是 Artix-7 35T 这类更小器件，DSP 数量约 90 个，则当前并行度明显过大：

```text
272 / 90 ~= 302%
288 / 90 ~= 320%
```

因此当前参数更像“高吞吐新基线”，不是“小 FPGA 最小资源实现”。

### 6.6.2 DSP + LUT 混合实现的判断

可以把一部分乘法映射到 LUT，但这只能作为局部优化，不能把大量 PW 乘法都搬到 LUT。

以 Zynq-7020 为例，如果希望保持当前 288 个并行乘法，而器件只有约 220 个 DSP，则至少有：

```text
288 - 220 = 68 multipliers
```

需要改用 LUT、复用或移除。一个 16x16 signed multiplier 若由 LUT 实现，经验上可能消耗约：

```text
200 ~ 400 LUT / multiplier
```

那么 68 个 LUT 乘法器会额外消耗约：

```text
13,600 ~ 27,200 LUT
```

这个数字已经很大，并且还没有包含控制逻辑、FIFO、地址生成、ROM 读口、valid/ready、比较器和累加器。大量 LUT 乘法还会明显增加布线压力，并降低最高频率。

推荐映射原则：

| 模块 | 建议 | 原因 |
| --- | --- | --- |
| PW1/PW2 | 优先用 DSP | PW 是吞吐核心，乘法密集，布线和频率风险最大 |
| stem | 优先用 DSP，少量可 LUT | stem 参与前端节拍，不建议大规模 LUT 化 |
| DW1/DW2 | 最适合降并行或部分 LUT | DW 计算量小、结构规则、通道独立 |
| BN affine | 不要常驻独立 DSP | 推荐复用 PE multiplier，或后续折叠进权重 |
| FC | 不建议独立常驻 | GAP 后才运行，可以复用 PW2 或做轻量低并行单元 |

### 6.6.3 优化优先级

第一优先级：BN 不新增独立 multiplier。

```text
Conv/PW acc -> 复用 PE multiplier 做 folded BN affine
```

或者等 golden 对齐稳定后：

```text
folded_scale 直接折进 weight
硬件只做 bias add + ReLU
```

第二优先级：FC 不独立常驻 16 个 DSP。

FC0/FC1 在 GAP 之后才启动，不参与 GAP 前端稳定流水。小 FPGA 版本更推荐：

```text
FC 复用 PW2 阵列或复用其中一部分 PE
```

这样可以直接省掉 `fc_dot_unit` 的 16 个并行乘法资源。代价是单个样本尾部延迟增加，但不会破坏前端卷积模块的正确性。

第三优先级：DW 不做 5-tap 全并行。

当前 DW 资源：

```text
DW1: 8 * 5 = 40 multipliers
DW2: 8 * 5 = 40 multipliers
total DW = 80 multipliers
```

可以改成：

```text
P_CH_DW = 8
P_TAP_DW = 1 or 2
```

则 DW 乘法资源变成：

```text
P_TAP_DW=1: 8 + 8 = 16 multipliers
P_TAP_DW=2: 16 + 16 = 32 multipliers
```

这比把 48~64 个 DW 乘法硬塞到 LUT 更干净。代价是 DW 每个输出点需要 3~5 个小周期完成，但 DW 层本来不是主要 MAC 瓶颈，且可以靠 row FIFO 和 ready/valid 吸收局部延迟。

第四优先级：必要时缩小 PW2。

PW2 是当前最大阵列：

```text
PW2 = 4 * 24 = 96 multipliers
```

若目标器件 DSP 明显不足，可以降为：

```text
PW2 = 4 * 16 = 64 multipliers
```

但这会把 PW2 的 4 行计算周期从约 256 cycles 拉长到约 384 cycles，可能无法继续匹配 280-cycle stem chunk 节拍。因此这是资源换吞吐的选择，不是当前高吞吐基线的首选。

第五优先级：再考虑 PW1/PW2 阵列复用。

如果目标是非常小的 FPGA，不应坚持 GAP 前所有计算资源完全独立。可以考虑让 PW1/PW2 共用一个可配置 `pw_array`，分时执行：

```text
PW array mode 0: Cin=32, Cout=64
PW array mode 1: Cin=64, Cout=96
```

这会降低超级流水并行度，但会显著降低 DSP 和参数读口压力。

### 6.6.4 建议保留两个设计档位

为了后续 RTL 不反复推翻，建议文档中明确区分两个档位。

高吞吐基线：

```text
stem: 4x8
DW:   P_CH_DW=8, P_TAP_DW=5
PW1:  4x16
PW2:  4x24
FC:   P_OUT=16 independent or later reuse
```

这个档位用于验证超级流水、边界控制、级间 FIFO 和融合策略，目标是接近 `II=280 cycles/chunk`。

小 FPGA 收缩版：

```text
stem: 4x8
DW:   P_CH_DW=8, P_TAP_DW=1 or 2
PW1:  4x16 or 4x8
PW2:  4x16
FC:   reuse PW2 or low-parallel FC
BN:   reuse PE multiplier or fold into weights
```

这个档位牺牲部分吞吐，换取更现实的 DSP/LUT/布线资源。实现时建议先完成高吞吐基线的功能级 RTL 和 testbench，再用参数化方式收缩并行度，避免同时调功能正确性和资源优化。

---

## 7. 模块设计指导

### 7.1 stem_conv_array

建议：

```text
P_T=4, P_OC=8
output-stationary
K=35
```

职责：

```text
1. 隐式处理 Conv1d k=7 padding=3，不需要 im2col buffer。
2. 每个 micro-tile 输出 4 time x 8 channel。
3. 累加完成后做 Q8.8 shift/saturate。
4. BN0 + ReLU 可以注册化接在 stem 输出后。
5. 输出写入 stem chunk buffer 或 stream FIFO。
```

地址生成：

```text
k_idx = ic * 7 + kk
src_t = out_t + kk - 3
越界时 activation = 0
```

### 7.2 dw1_slide_pu

DW1 使用 k=5、pad=2。可以把每个通道的时间方向数据放进 5-deep shift register / FIFO-like line buffer。

注意这里的 FIFO 是时间滑窗队列，不是 heap。它只需要保证先进先出地移动时间样本：

```text
x[t-2], x[t-1], x[t], x[t+1], x[t+2]
```

推荐：

```text
P_CH_DW=8
每个通道 lane 5 个 multiplier + adder tree
```

每个时间点需要：

```text
ceil(32 / 8) = 4 cycles
```

中间 chunk 8 个 DW1 输出点：

```text
8 * 4 = 32 cycles
```

DW1 不是瓶颈，不需要把它做得比 PW 更宽。

### 7.3 pw1_array

如果按推荐参数：

```text
P_T=4, P_OC=16
K=32
Cout=64
```

中间 chunk 有 8 个 DW1 时间点：

```text
ceil(8/4) * ceil(64/16) * 32
= 2 * 4 * 32
= 256 cycles
```

PW1 后可接：

```text
BN1 -> ReLU -> Pool input FIFO
```

更推荐直接融合成：

```text
PW1 4x16 tile
 -> BN1 affine
 -> ReLU
 -> MaxPool k=2,stride=2
 -> pool row FIFO
```

因为 PW1 每次正好处理 4 个 high-res 时间点：

```text
t0, t1, t2, t3
```

MaxPool 可以直接生成 2 个 low-res 时间点：

```text
pool[p0]   = max(relu_bn(t0), relu_bn(t1))
pool[p0+1] = max(relu_bn(t2), relu_bn(t3))
```

对每个 output-channel tile：

```text
PW1 tile shape = 4 time x 16 channels = 64 values
Pool output    = 2 time x 16 channels = 32 values
```

周期上，PW1 处理 4 个 high-res rows 的主体计算为：

```text
ceil(4/4) * ceil(64/16) * 32
= 1 * 4 * 32
= 128 cycles
```

stem 每 4 个 high-res rows 的 producer interval 是：

```text
140 cycles
```

所以有约：

```text
140 - 128 = 12 cycles
```

的余量。BN/ReLU/Pool 完全可以放进这个节拍里，但建议满足两个条件：

```text
1. BN/ReLU/Pool 是 PW1 输出后的注册化后处理流水。
2. 后处理不要反压 PW1 主 MAC 阵列。
```

例如 `P_POST=16 values/cycle` 时，一个 `4x16` PW1 输出 tile 的后处理大致为：

```text
BN/ReLU: 64 values / 16 = 4 cycles
Pool:    32 values / 16 = 2 cycles
drain:   约 4~6 cycles
```

这些周期可以和下一组 output-channel tile 的 PW1 计算重叠。最后一个 output-channel tile 只留下很短的 drain，仍可放进 140-cycle 节拍。

因此不要先写完整 `b1pw[64][348]` 再 Pool。Pool 只需要相邻两个高分辨率时间点，应该直接从 PW1 后处理流水产生 `pool_buf / pool_row_fifo`。

### 7.4 maxpool_unit

MaxPool 参数：

```text
k=2
stride=2
channels=64
```

控制条件：

```text
当同一通道的 PW1 t=2p 和 t=2p+1 都 valid 时，输出 pool[p]。
```

中间 chunk 的 8 个 PW1 高分辨率点会产生：

```text
4 个 pool 点
```

Pool 计算量很小，重点是 valid 对齐，不是算力。

### 7.5 dw2_slide_pu

DW2 与 DW1 类似，但输入通道为 64，时间长度为 174：

```text
P_CH_DW=8
每个时间点 cycles = ceil(64 / 8) = 8
```

中间 chunk 的 4 个 DW2 输出点：

```text
4 * 8 = 32 cycles
```

第一批只有 1 个 DW2/PW2 点，tail 有 5 个点。这两个边界需要单独的 valid count 控制。

### 7.6 pw2_array

推荐：

```text
P_T=4, P_OC=24
K=64
Cout=96
```

中间 chunk 有 4 个 DW2 时间点：

```text
ceil(4/4) * ceil(96/24) * 64
= 1 * 4 * 64
= 256 cycles
```

PW2 后面建议直接接：

```text
BN2 -> ReLU -> GAP accumulator
```

如果为了调试，也可以先保留 `b2pw` chunk dump，但目标设计不需要完整 `b2pw[96][174]` 大 buffer。

### 7.7 GAP、FC0 + ReLU、FC1 后端

GAP 可以流式累加：

```text
gap_sum[oc] += relu_bn2_pw2[oc, t]
```

当 174 个 low-resolution 时间点全部完成后：

```text
gap[oc] = gap_sum[oc] / 174
```

除以 174 可后续改成常数乘法近似。GAP 完成后得到：

```text
gap_vec[96]
```

后端网络为：

```text
FC0: 96 -> 96
ReLU
FC1: 96 -> 5
Argmax
```

FC0/FC1 的计算量：

```text
FC0 MAC = 96 * 96 = 9,216
FC1 MAC = 96 * 5  =   480
```

相比 PW1/PW2 很小，不应该为了 FC 反向影响前面卷积流水线参数。

#### 7.7.1 方案 A：复用 PW2 的 4x24 阵列

FC 可以看成 `M=1` 的 GEMM：

```text
FC0:
    A[1,96] * W[96,96] -> Y[1,96]

FC1:
    A[1,96] * W[96,5] -> logits[1,5]
```

如果复用 `PW2: P_T=4, P_OC=24`：

```text
FC0 cycles = ceil(1/4) * ceil(96/24) * 96
           = 1 * 4 * 96
           = 384 cycles

FC1 cycles = ceil(1/4) * ceil(5/24) * 96
           = 1 * 1 * 96
           = 96 cycles
```

优点：

```text
1. 复用已有 PW2 PE array，模块数量少。
2. FC0+FC1 总共 480 cycles，很快。
3. 权重地址生成与 pointwise 类似，控制简单。
```

缺点：

```text
1. FC 只有 M=1，P_T=4 的 4 行里只有 1 行有效。
2. PW2 阵列有 96 个 MAC lanes，但 FC 实际只用到 24 个 output-channel lanes。
3. 如果前端还在处理下一帧，复用 PW2 会和 PW2 卷积资源产生竞争。
```

当前假设“不考虑复用计算资源，不存在资源竞争”时，方案 A 可以作为最快实现。但从模块设计清晰度看，不是最轻量。

#### 7.7.2 方案 B：轻量 FC vector dot-product 单元

更推荐第一版单独做一个轻量后端：

```text
fc_dot_unit
    P_OUT = 16 或 24
    每拍并行计算 P_OUT 个输出神经元的一项 k 维乘加
```

数据流：

```text
for out_base in 0 .. N-1 step P_OUT:
    acc[lane] = bias[out_base + lane] << 8

    for k in 0 .. 95:
        act = input_vec[k]
        for lane in 0 .. P_OUT-1:
            acc[lane] += act * weight[out_base + lane][k]

    output[out_base + lane] = saturate(acc[lane] >>> 8)
```

FC0 后接 ReLU：

```text
fc0_relu[i] = max(fc0_out[i], 0)
```

FC1 后不接 ReLU，直接输出 logits，再做 argmax。

周期公式：

```text
cycles_fc = ceil(N_out / P_OUT) * K
```

几个可选参数：

| P_OUT | FC0 cycles | FC1 cycles | total cycles | MAC lanes | 说明 |
| ---: | ---: | ---: | ---: | ---: | --- |
| 8 | 1,152 | 96 | 1,248 | 8 | 最省资源，延迟仍很小 |
| 16 | 576 | 96 | 672 | 16 | 推荐起点，资源/延迟平衡 |
| 24 | 384 | 96 | 480 | 24 | 与 PW2 的输出通道并行度一致 |

推荐：

```text
第一版:
    P_OUT = 16

如果后端延迟要压低:
    P_OUT = 24
```

`P_OUT=16` 的 672 cycles 在 100 MHz 下约：

```text
6.72 us
```

相对前面卷积流水线十几万 ns 量级很小，通常不会成为瓶颈。

#### 7.7.3 FC 参数存储和读带宽

FC 参数：

```text
fc0_weight[96][96]
fc0_bias[96]
fc1_weight[5][96]
fc1_bias[5]
```

如果 `P_OUT=16`，每拍需要：

```text
1 个 activation
16 个 weight
```

所以 FC weight ROM 建议按输出神经元 lane 分 bank：

```text
fc_weight_bank[lane]
```

地址：

```text
layer = FC0 or FC1
out_idx = out_base + lane
k_idx = 0..95
weight = W[out_idx][k_idx]
```

bias 在每个 output tile 开始时加载到 acc 初值：

```text
acc[lane] = fc_bias[out_idx] <<< 8
```

原因是 bias 是 Q8.8，而 acc 累加的是 Q16.16，需要把 bias 对齐到 Q16.16。

#### 7.7.4 FC0 ReLU 和 FC1 Argmax

FC0 输出写入 `fc0_vec[96]`：

```text
fc0_q8_8 = saturate(acc >>> 8)
fc0_relu = max(fc0_q8_8, 0)
```

FC1 输出 logits：

```text
logits[5] = fc1_out[5]
```

Argmax 很小，可以串行比较：

```text
best_idx = 0
best_val = logits[0]

for i in 1..4:
    if logits[i] > best_val:
        best_val = logits[i]
        best_idx = i
```

最多 4 个比较周期，也可以一拍组合比较。为了时序清晰，第一版用串行 4-cycle 比较即可。

#### 7.7.5 与前端流水线的连接

建议后端接口：

```text
gap_done
gap_vec[96]
fc_start
fc_done
logits[5]
class_id
```

如果后续要连续处理多帧输入，可以加双缓冲：

```text
gap_vec_ping / gap_vec_pong
fc0_vec_ping / fc0_vec_pong
```

这样前端在计算下一帧 GAP 时，后端可以处理上一帧 FC。但第一版不需要过早复杂化：

```text
PW2/GAP 完成当前样本
 -> FC0
 -> ReLU
 -> FC1
 -> Argmax
 -> done
```

#### 7.7.6 FC 是否复用前端计算资源

当前前端流水线在 GAP 之前，主要计算资源基本没有稳定空档：

```text
stem 4x8:
    middle chunk = 280 cycles

PW1 4x16:
    middle chunk = 256 cycles
    slack ~= 24 cycles / 280-cycle chunk

PW2 4x24:
    middle chunk = 256 cycles
    slack ~= 24 cycles / 280-cycle chunk
```

这说明：

```text
stem / PW1 / PW2 三个大阵列在前端稳态中都不适合插入 FC 计算。
```

尤其不要指望在 GAP 之前把 FC0/FC1 塞进 PW1 或 PW2 的空闲周期。前端每 280 cycles 一个稳定节拍，而 FC0 即使用 `P_OUT=24` 也需要：

```text
FC0 = 384 cycles
```

会直接打断前端流水。

资源复用要分两种场景：

```text
单样本低资源版本:
    可以等 PW2/GAP 完成后，复用 PW2 阵列计算 FC0/FC1。
    面积更小，但当前样本完成前不能启动下一帧的 PW2 阶段。

连续流水高吞吐版本:
    不建议复用前端 PW2 阵列。
    应该单独放轻量 fc_dot_unit，让前端处理下一帧时后端处理上一帧。
```

因此当前推荐仍然是：

```text
前端:
    stem_array + DW1_PU + PW1_array + DW2_PU + PW2_array

后端:
    独立轻量 fc_dot_unit, P_OUT=16
```

如果后续 FPGA 资源非常紧张，可以保留一个配置：

```text
USE_SHARED_PW2_FOR_FC = 1
```

在这个模式下：

```text
PW2/GAP done
 -> PW2 array 切换到 FC mode
 -> FC0 + ReLU
 -> FC1 + Argmax
```

但这是低资源模式，不是最高吞吐模式。

---

## 8. 控制信号和流水线合并指导

第一版建议每个模块独立验证，再合并成 valid/ready 风格的局部流水。

每级最少需要：

```text
in_valid
in_ready
out_valid
out_ready
chunk_id
time_base
valid_count
final_chunk
```

关键启动条件：

```text
DW1:
    stem_ready_right >= dw1_t + 2
    或 final_chunk 使用右 padding

PW1:
    DW1 至少准备好 P_T 个时间点
    边界 chunk 允许 valid_count < P_T

Pool:
    PW1 高分辨率 t=2p 和 t=2p+1 均 valid

DW2:
    pool_ready_right >= dw2_t + 2
    或 final_chunk 使用右 padding

PW2:
    DW2 至少准备好 P_T 个时间点
    first/tail 允许 valid_count < P_T
```

建议 buffer：

```text
stem_chunk_fifo / ping-pong buffer
dw1_chunk_fifo
pool_chunk_fifo
dw2_chunk_fifo
postprocess_fifo
gap_sum registers
```

不要把所有模块强行做成“每拍都同步推进”。DW 和 Pool 很快，等待 PW 是正常的。真正要避免的是 stem/PW1/PW2 这些大 MAC 阵列长期空转。

---

## 9. 推荐实施顺序

1. 新建独立 RTL 目录，例如 `rtl/lightcnn1d_stream/`。
2. 先写 `lightcnn1d_stream_defs.vh`，固定网络尺寸和推荐并行度。
3. 单独实现并验证 `stem_conv_array`，输出 chunk 级 stem + BN/ReLU。
4. 实现 `dw_slide_pu`，先复用同一个模块参数化支持 DW1/DW2。
5. 实现 `pw_array`，参数化 `P_T/P_OC/K/Cout`，分别实例化 PW1/PW2。
6. 实现 `pool_unit` 和 `gap_accumulator`。
7. 实现轻量 `fc_dot_unit`，建议先用 `P_OUT=16` 验证 `FC0 + ReLU + FC1 + Argmax`。
8. 用小型手写 testbench 验证每个模块的 valid_count 边界：
   - first chunk
   - middle chunk
   - tail chunk
9. 单独验证后端：
   - GAP 输入 96 维向量
   - FC0 输出 96 维 ReLU 向量
   - FC1 输出 5 个 logits
   - Argmax 输出 class_id
10. 再合并 chunk pipeline scheduler 和后端 FC controller。
11. 最后再考虑更细粒度的“stem 4 点先启动 DW1”早启动优化。

第一版合并流水时，不必追求最细粒度启动。可以先以 8-point chunk 为调度单位，确认所有边界点数和周期统计正确，再逐步把 DW1/PW1/Pool/DW2/PW2 的启动提前。

---

## 10. 当前结论

你的流式边界依赖判断是成立的：

```text
first:  6 -> 3 -> 1
middle: 8 -> 4 -> 4
tail:   6 -> 3 -> 5
```

但 `PW1=1x16, PW2=1x16` 会让 PW2 成为瓶颈：

```text
II = 1536 cycles/chunk
stem utilization ~= 18%
```

当前更推荐的第一版新基线参数是：

```text
stem: 4x8
PW1:  4x16
PW2:  4x24
DW:   P_CH_DW=8
```

注意：这组参数是为了先验证超级流水和边界控制的高吞吐基线，不是小 FPGA 最小资源版本。如果目标器件 DSP 明显不足，应优先采用第 6.6 节的小 FPGA 收缩策略：BN 不独立占 multiplier、FC 复用 PW2、DW 降为 `P_TAP_DW=1/2`，必要时再缩小 PW2。

它的中间 chunk 周期是：

```text
stem = 280
PW1  = 256
PW2  = 256
II   = 280 cycles/chunk
```

这个参数组合更适合作为今天重新设计 RTL 基线的起点。

后端 `FC0 + ReLU + FC1` 不建议反过来决定前端卷积阵列参数。第一版推荐：

```text
fc_dot_unit:
    P_OUT = 16
    FC0 cycles = 576
    FC1 cycles = 96
    total = 672 cycles
```

如果后端延迟要进一步压低，可以把 `P_OUT` 提高到 24：

```text
FC0 + FC1 total = 480 cycles
```

这两种方案都远小于前端卷积流水线延迟，适合作为 GAP 之后的独立轻量后端。
