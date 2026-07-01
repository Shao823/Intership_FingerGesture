# 1-D CNN FPGA 硬件优化技术全集

## 1. 总体原则

1-D CNN 的 FPGA 优化应围绕三个核心瓶颈展开：

```text
计算瓶颈：MAC 数量、pipeline II、DSP 数量、加法树深度
存储瓶颈：权重读取、activation 读取、中间 feature 写回、BRAM 端口冲突
系统瓶颈：DMA 带宽、PS 干预、帧级调度、无线输出速率
```

优化优先级建议：

```text
先做数据流和片上复用
再做 pipeline 和受控 parallelism
最后做复杂阵列、压缩和高级调度
```

## 2. 计算架构类优化

### 2.1 Systolic Array

原理：  
将多个 PE 以规则阵列连接，数据和 partial sum 在阵列中按节拍流动，减少全局存储访问，提高 MAC 阵列利用率。

适用场景：  
通道数较多、卷积层规模稳定、需要高吞吐的 1-D CNN。适合多 output channel 和多 input channel 的卷积。

Vivado 实现方法：  
使用 Verilog/VHDL 或 HLS 构建 PE mesh。每个 PE 包含乘法、累加、寄存器转发。使用 AXI4-Stream 输入 feature 和 weight，输出 partial sum 或 final result。HLS 中可用 `DATAFLOW`、`PIPELINE`、`ARRAY_PARTITION` 描述。

预期加速：  
中高。若 PE 利用率高，可接近 PE 数量级加速，例如 8-32 个 PE 带来约 4-20 倍有效吞吐提升。

资源开销：  
DSP、FF、LUT 随 PE 数量线性上升；需要额外 FIFO 和寄存器转发网络；BRAM bank 数也要增加。

### 2.2 PE Array

原理：  
构建并行 Processing Element 阵列，每个 PE 执行一个或多个 MAC。PE Array 比 systolic array 更泛化，可采用 broadcast、shared buffer、local buffer 或 tree reduction。

适用场景：  
需要灵活调整 output channel parallelism、kernel parallelism、input channel folding 的 1-D CNN。

Vivado 实现方法：  
在 HLS 中用 loop unrolling 生成 PE array；或 RTL 手写 `generate` 多个 PE。配套 weight bank、feature bank、partial sum buffer。

预期加速：  
与有效 PE 数成正比，但受 BRAM 端口和 AXI 带宽限制。实际常见 2-16 倍。

资源开销：  
DSP 和 FF 增加明显；LUT 用于控制、mux、地址生成；BRAM 需分 bank。

### 2.3 SIMD

原理：  
单条控制流驱动多个 lane 同时处理多个数据元素，例如多个 kernel tap、多个 channel 或多个 output channel。

适用场景：  
模型结构规则、各 lane 工作负载一致、数据位宽较低的定点 1-D CNN。

Vivado 实现方法：  
HLS 中使用 `UNROLL factor=N` 生成 SIMD lane；RTL 中多个 MAC lane 共享控制 FSM。可使用 DSP SIMD 模式或低位宽乘法打包。

预期加速：  
近似等于 SIMD lane 数，但受存储端口限制。常见 2-8 倍。

资源开销：  
DSP/LUT/FF 增加；如果做低位宽打包，可降低 DSP 开销但控制复杂度上升。

### 2.4 MIMD

原理：  
多个独立计算单元执行不同任务或不同层，每个单元有独立控制流。

适用场景：  
多分支网络、不同层并行处理不同帧、或者多个手势通道独立处理。

Vivado 实现方法：  
实例化多个 accelerator core 或多个 layer engine。用 Instruction Controller 分发任务，用 FIFO/BRAM 解耦。

预期加速：  
取决于任务并行度。多帧流水可提升系统 throughput，但单帧 latency 不一定下降。

资源开销：  
高。多个核心会复制 DSP、BRAM、控制逻辑和 AXI 接口。

### 2.5 Spatial Parallelism

原理：  
用更多硬件同时计算多个输出点、多个通道、多个 kernel tap 或多个层。

适用场景：  
DSP/BRAM 有余量，目标是降低 latency 或提升 frame rate。

Vivado 实现方法：  
loop unrolling、PE array、多个 conv engine、multi-bank memory。HLS 使用 `UNROLL` 和 `ARRAY_PARTITION`。

预期加速：  
高。理论上与并行硬件数量成正比，实际受 memory bandwidth 限制。

资源开销：  
高。DSP、LUT、FF、BRAM 均会上升。

### 2.6 Temporal Parallelism

原理：  
通过 pipeline 让不同输入帧或不同阶段在不同周期重叠执行。

适用场景：  
连续流式手势识别，要求高吞吐但允许 pipeline startup latency。

Vivado 实现方法：  
HLS `PIPELINE`、`DATAFLOW`，RTL 多级寄存器流水。层间用 FIFO 连接。

预期加速：  
对 throughput 提升大，常可把 II 降到 1 或接近 1。

资源开销：  
FF 增加，少量 LUT 增加，FIFO/BRAM 可能增加。

## 3. Dataflow 类优化

### 3.1 Dataflow Architecture

原理：  
将 load、compute、store 或多个 layer stage 拆成并行任务，用 FIFO 串接，使数据连续流动。

适用场景：  
多层 1-D CNN，输入连续、层间数据可流式传递。

Vivado 实现方法：  
HLS 使用 `#pragma HLS DATAFLOW`，每个函数代表一个 stage。RTL 中用 AXI4-Stream 或自定义 valid/ready FIFO。

预期加速：  
高。可隐藏 load/store 时间，使 throughput 接近最慢 stage。

资源开销：  
需要 FIFO、控制逻辑、更多 FF/BRAM。调试复杂度增加。

### 3.2 Weight Stationary

原理：  
权重常驻 PE 或本地 weight buffer，输入 activation 流过计算单元，减少权重反复读取。

适用场景：  
权重可放入片上 BRAM/ROM，输入连续帧很多，权重复用次数高。

Vivado 实现方法：  
将 weight 初始化到 BRAM/ROM；按 PE 分 bank。HLS 中使用 static const array 或 BRAM resource 绑定。

预期加速：  
中高。主要降低 memory bandwidth 和功耗，提升 PE 利用率。

资源开销：  
BRAM 增加；若复制权重支持多 PE 并行，BRAM 进一步增加。

### 3.3 Output Stationary

原理：  
partial sum 留在 PE 或本地 buffer 中，直到一个输出点累加完成再写回。

适用场景：  
input channel 多、kernel tap 多、partial sum 写回频繁的卷积层。

Vivado 实现方法：  
PE 内部 accumulator 寄存器或 partial sum BRAM。循环顺序调整为固定 output index，遍历 input channel 和 kernel。

预期加速：  
中。减少 partial sum 读写，降低 BRAM/DDR 访问。

资源开销：  
FF 或 BRAM 增加；accumulator 位宽较大时 FF 成本明显。

### 3.4 Row Stationary

原理：  
同时平衡 weight、activation、partial sum 的局部复用。对 1-D CNN 可理解为 window stationary 或 segment stationary：保持一段输入窗口和对应权重在片上，多次复用。

适用场景：  
kernel size 较大、stride 小、相邻输出窗口高度重叠的 1-D CNN。

Vivado 实现方法：  
构建 sliding window buffer，权重分 bank，partial sum 本地累加。按输出位置逐步滑动窗口。

预期加速：  
中高。对 stride=1 的 Conv1D 尤其有效。

资源开销：  
BRAM/LUTRAM 增加；地址生成和边界处理逻辑增加。

## 4. 缓冲与存储复用

### 4.1 Ping Pong Buffer

原理：  
两个 buffer 交替工作，一个用于 DMA/输入写入，另一个用于 CNN 计算读取，实现搬运与计算重叠。

适用场景：  
帧式输入、窗口式推理、DMA 与 CNN 计算时间可重叠。

Vivado 实现方法：  
两个 BRAM buffer 或 DDR 两段地址。Instruction Controller 管理 buffer ownership。DMA done 和 CNN done 触发切换。

预期加速：  
中高。端到端 throughput 可接近 `max(compute_time, transfer_time)`，而不是二者相加。

资源开销：  
BRAM 或 DDR buffer 翻倍；控制 FSM 增加。

### 4.2 Double Buffer

原理：  
泛指双缓冲，常用于 weight tile、feature tile、output tile。与 Ping Pong Buffer 类似，但粒度可以是 tile 而不是整帧。

适用场景：  
layer tiling、channel tiling、weight tile 从 DDR 加载的场景。

Vivado 实现方法：  
为每类 tile 建两个 buffer。HLS DATAFLOW 中 load/compute/store 三阶段并行。

预期加速：  
中高。可隐藏 weight/feature tile 加载延迟。

资源开销：  
BRAM 增加约 2 倍；控制复杂度增加。

### 4.3 On-chip Cache

原理：  
将热点数据，如权重、滑窗 activation、partial sum，缓存在片上 BRAM/LUTRAM。

适用场景：  
权重和 activation 有明显复用；DDR 带宽成为瓶颈。

Vivado 实现方法：  
BRAM/LUTRAM buffer、line/window buffer、weight cache、partial sum cache。可用 HLS array + resource pragma。

预期加速：  
中高。减少外部访问，降低功耗。

资源开销：  
BRAM/LUTRAM 增加；cache controller 增加 LUT/FF。

### 4.4 Memory Banking

原理：  
将 memory 拆成多个 bank，允许多个 PE/lane 同周期并行读取。

适用场景：  
loop unroll 后 BRAM 端口不够，II 受 memory port 限制。

Vivado 实现方法：  
HLS `ARRAY_PARTITION cyclic/block` 或 RTL 多 BRAM bank。按 channel、kernel tap、output channel 分 bank。

预期加速：  
中高。可解除端口冲突，使 pipeline II 接近 1。

资源开销：  
BRAM 数增加；地址译码和 mux 增加 LUT。

## 5. 循环变换类优化

### 5.1 Loop Tiling

原理：  
将大循环拆成小 tile，在片上缓存一个 tile 的输入、权重和输出，提升局部性。

适用场景：  
完整 feature map 或 weight 无法一次放入片上 BRAM。

Vivado 实现方法：  
按 output channel、input channel、time dimension 切 tile。HLS 中重构循环层级，load tile -> compute tile -> store tile。

预期加速：  
中。主要减少外部带宽压力，模型越大收益越明显。

资源开销：  
tile buffer、地址生成、边界处理增加。

### 5.2 Loop Fusion

原理：  
将相邻循环合并，减少中间结果写回和重复遍历。

适用场景：  
Conv1D 后接 BN、Activation、Pooling，或简单后处理。

Vivado 实现方法：  
在 HLS 中把多个 stage 写在同一 streaming loop 中；RTL 中合并 pipeline stage。

预期加速：  
中。减少 memory access 和 control overhead。

资源开销：  
少量 LUT/FF 增加；模块边界变复杂。

### 5.3 Loop Unrolling

原理：  
展开循环生成多个并行硬件实例。

适用场景：  
DSP/BRAM 有余量，内层循环是主要瓶颈。

Vivado 实现方法：  
HLS `#pragma HLS UNROLL factor=N`；RTL 使用 `generate` 多 lane。配合 memory banking。

预期加速：  
理论接近 factor 倍，实际受数据供给限制。常用 2-8 倍起步。

资源开销：  
DSP/LUT/FF 近似按 factor 上升；BRAM 端口压力增加。

### 5.4 Loop Pipelining

原理：  
让循环不同迭代重叠执行，降低 II。

适用场景：  
Conv1D MAC、activation、pooling、packing/unpacking。

Vivado 实现方法：  
HLS `#pragma HLS PIPELINE II=1`；RTL 多级流水寄存器。

预期加速：  
高。对长循环可从串行 latency 转换为每周期/每数周期输出。

资源开销：  
FF 增加；可能增加控制 LUT；深 pipeline 增加调试复杂度。

## 6. 外部存储与 DMA 优化

### 6.1 Off-chip Memory Optimization

原理：  
减少 DDR 访问次数，提升 burst 连续性，避免随机小访问。

适用场景：  
输入/输出或权重需要经过 DDR，且 AXI 带宽影响吞吐。

Vivado 实现方法：  
连续内存布局、cache line 对齐、AXI HP/HPC 端口、outstanding transaction、data width matching。

预期加速：  
中高。可显著提高有效带宽。

资源开销：  
低到中。主要是 DMA、FIFO、宽数据通路和地址控制。

### 6.2 Burst Transfer

原理：  
用长 burst 替代大量单次读写，提升 AXI 总线效率。

适用场景：  
输入 feature 连续存放、输出结果批量写回、weight tile 加载。

Vivado 实现方法：  
AXI DMA、AXI DataMover 或 HLS `m_axi` burst。保证地址连续和长度对齐。

预期加速：  
中。对小包随机访问可能提升数倍有效带宽。

资源开销：  
DMA/FIFO/AXI adapter 增加 BRAM/LUT/FF。

### 6.3 DMA Scheduling

原理：  
调度 MM2S、S2MM、compute 的启动顺序，让数据搬运和计算重叠。

适用场景：  
连续帧处理、tile-based CNN、Ping-Pong Buffer。

Vivado 实现方法：  
PS 软件调度或 PL Instruction Controller 调度。使用 DMA interrupt、buffer state machine、frame counter。

预期加速：  
中高。吞吐可从 `transfer + compute` 优化到接近 `max(transfer, compute)`。

资源开销：  
控制 FSM、中断、状态寄存器增加；buffer 资源增加。

## 7. 并行模型选择

### 7.1 Weight Parallelism

原理：  
同一输入 activation 同时与多个 output channel 权重相乘。

适用场景：  
output channel 多，输入复用高。

Vivado 实现方法：  
多个 PE 分别对应不同 output channel，输入 broadcast，权重分 bank。

预期加速：  
中高，取决于 output channel parallel factor。

资源开销：  
DSP 和 weight bank 增加。

### 7.2 Activation Parallelism

原理：  
同一权重或多个权重同时处理多个时间位置的 activation。

适用场景：  
序列长度大、kernel 小、需要提高每帧吞吐。

Vivado 实现方法：  
多窗口并行、多个 sliding window buffer 或 vectorized input lane。

预期加速：  
中。可提高时间维吞吐。

资源开销：  
feature buffer 和 PE 数增加。

### 7.3 Kernel Parallelism

原理：  
同时计算多个 kernel tap 的乘法，再通过加法树规约。

适用场景：  
kernel size 中等，DSP 有余量。

Vivado 实现方法：  
kernel loop unroll + pipelined adder tree。

预期加速：  
中。最多接近 kernel size 倍，但加法树和数据读取会限制收益。

资源开销：  
DSP 增加，加法树 LUT/FF 增加。

## 8. 技术对比总表

| 技术 | 适用场景 | 预期加速 | 资源开销 |
|---|---|---:|---|
| Systolic Array | 通道多、规则卷积 | 高 | DSP/FF/LUT/BRAM 高 |
| Dataflow Architecture | 多 stage 流水 | 高 | FIFO/BRAM/控制 中 |
| Weight Stationary | 权重复用高 | 中高 | BRAM 中 |
| Output Stationary | partial sum 多 | 中 | FF/BRAM 中 |
| Row/Window Stationary | stride 小、窗口重叠 | 中高 | BRAM/地址逻辑 中 |
| Ping Pong Buffer | 帧级搬运计算重叠 | 中高 | Buffer 翻倍 |
| Double Buffer | tile 级搬运计算重叠 | 中高 | Buffer 翻倍 |
| Loop Tiling | 模型大于片上存储 | 中 | 控制/BRAM 中 |
| Loop Fusion | 相邻算子可合并 | 中 | LUT/FF 小升 |
| Loop Unrolling | DSP 有余量 | 中高 | DSP/LUT/FF 高 |
| Loop Pipelining | 长循环 | 高 | FF 中 |
| Memory Banking | BRAM 端口瓶颈 | 中高 | BRAM/LUT 中 |
| PE Array | 可规则并行计算 | 高 | DSP/BRAM 高 |
| SIMD | 规则低位宽计算 | 中高 | DSP/LUT/FF 中高 |
| MIMD | 多任务/多帧并行 | 中 | 资源高 |
| Spatial Parallelism | 低 latency 目标 | 高 | 资源高 |
| Temporal Parallelism | 高 throughput 目标 | 高 | FF/FIFO 中 |
| On-chip Cache | 数据复用明显 | 中高 | BRAM 中 |
| Off-chip Optimization | DDR 带宽瓶颈 | 中高 | DMA/FIFO 中 |
| Burst Transfer | 连续内存访问 | 中 | DMA/FIFO 中 |
| DMA Scheduling | 连续帧/tile | 中高 | 控制/buffer 中 |

## 9. 针对当前项目的推荐组合

第一阶段推荐：

```text
Loop Pipelining
Dataflow Architecture
Weight Stationary
Window/Row Stationary
Ping Pong Buffer
Memory Banking
Burst Transfer
DMA Scheduling
```

第二阶段推荐：

```text
PE Array
SIMD
Partial Loop Unrolling
Channel Folding
Double Buffer for Weight/Feature Tile
```

第三阶段再评估：

```text
Systolic Array
MIMD Multi-core
Advanced Off-chip Weight Streaming
```

## 10. 关键落地建议

- 不要先追求最大 PE 数，先保证 `II`、BRAM 端口和 DMA 数据供给稳定。
- 对 1-D CNN，`Window Stationary + Weight Stationary + Dataflow` 通常比复杂 systolic array 更快落地。
- `Loop Unrolling` 必须和 `Memory Banking` 同时设计，否则容易出现 DSP 有余量但 BRAM 端口不足。
- `Ping Pong Buffer` 和 `DMA Scheduling` 是系统吞吐优化的关键，收益往往不低于计算核优化。
- 如果目标是实时手势控制，应优先优化端到端 latency 和稳定帧率，而不是只优化单层 GOPS。
