# 1-D CNN FPGA 优化优先级清单

## 1. 优化目标

当前 1-D CNN 已经可以正确工作，后续优化目标不是重设计算法，而是面向 FPGA 部署提升工程指标：

- 降低端到端 latency。
- 降低功耗。
- 控制 DSP、BRAM、LUT、FF 使用率。
- 提升 pipeline efficiency。
- 降低 memory bandwidth 压力。
- 提高 weight reuse 和 activation reuse。
- 保持分类准确率可接受。

推荐优化顺序：

```text
P0 必做：Quantization -> BN Folding -> Operator Fusion -> Loop Pipelining -> On-chip Buffer/Reuse
P1 重点做：Loop Unrolling -> Channel Folding -> DMA/Ping-Pong -> Memory Layout
P2 视资源做：Pruning -> Weight Compression -> Mixed Precision
P3 谨慎评估：Winograd -> FFT Convolution
```

## 2. P0 必做优化

### 2.1 Quantization

优先级：P0  
为什么：浮点乘加会大量消耗 DSP 和 LUT，且功耗高、时序压力大。1-D CNN 部署到 Zynq-7020 这类中小 FPGA 时，定点化通常是第一优先级。  
预期收益：DSP 使用下降，LUT/FF 可控，功耗下降，Fmax 更容易收敛；如果位宽合适，准确率损失通常可控制在很小范围。  
硬件成本：需要定点乘法器、定点累加器、饱和/舍入逻辑。BRAM 宽度可能下降，缓存效率提升。  
实现复杂度：中高。需要统计输入、权重、bias、activation、accumulator 动态范围，建立 PC 端定点仿真。  
可能缺点：位宽过小会造成溢出、饱和、精度损失；位宽过大则资源节省不明显。

建议动作：

- 输入、权重、activation 优先尝试 8-16 bit。
- accumulator 使用更宽位宽，例如 24-32 bit。
- 对不同层采用 mixed precision，而不是全网络统一位宽。

### 2.2 Batch Normalization Folding

优先级：P0  
为什么：推理阶段 BN 可以折叠进卷积或全连接层的 weight 和 bias，避免额外乘加、减法、除法。  
预期收益：减少算子数量、减少 latency、降低 DSP/LUT/FF 使用，简化数据流。  
硬件成本：几乎无新增硬件，只改变离线权重生成流程。  
实现复杂度：低到中。需要在导出权重时完成公式转换，并验证折叠前后输出一致。  
可能缺点：如果后续还要在线更新 BN 参数，则折叠不适用；定点折叠后可能放大权重动态范围，需要重新量化。

建议动作：

- 在 PC 端导出 FPGA 权重前完成 BN folding。
- 折叠后重新统计权重范围，并更新定点位宽。

### 2.3 Operator Fusion

优先级：P0  
为什么：将 `Conv1D + BN + Activation`、`Conv1D + Activation + Pooling` 等相邻算子融合，可以减少中间 activation 写回和读回。  
预期收益：降低 BRAM/DDR 访问，减少 latency，提高 streaming pipeline 连续性，降低功耗。  
硬件成本：融合后的模块控制逻辑略复杂，可能增加少量 LUT/FF。  
实现复杂度：中。需要明确每层数据依赖和边界条件。  
可能缺点：模块复用性下降；调试时不容易逐层观察中间结果。

建议动作：

- 优先融合无分支、无复杂跨层依赖的连续算子。
- 保留 debug 开关或仿真输出点，便于逐层验证。

### 2.4 Loop Pipelining

优先级：P0  
为什么：卷积和全连接核心循环如果不 pipeline，会导致吞吐很低。对内层 MAC 循环做 `PIPELINE` 是 HLS 加速的基本手段。  
预期收益：显著降低 initiation interval，提高吞吐；对实时连续手势识别非常关键。  
硬件成本：增加寄存器和控制逻辑，可能增加 FF/LUT；如果 II 设得过低，可能增加 DSP 并行需求。  
实现复杂度：中。需要处理循环依赖、数组端口冲突和累加依赖。  
可能缺点：pipeline depth 增加后，单帧首样本 latency 可能上升；过度 pipeline 可能导致 routing 压力。

建议动作：

- 先对最内层 MAC 循环 pipeline。
- 用 HLS report 检查 II、latency、resource。
- 如果 II 受 BRAM 端口限制，优先调整 array partition 或 buffer layout。

### 2.5 On-chip Buffer 与 Weight/Activation Reuse

优先级：P0  
为什么：1-D CNN 的卷积窗口天然适合滑窗缓存。每个输入样本可被多个 kernel tap 复用，权重也可在多个 time step 中复用。  
预期收益：显著降低 DDR/AXI 带宽压力，提高吞吐，降低功耗。  
硬件成本：增加 BRAM 或 LUTRAM；需要地址生成逻辑和 line/window buffer。  
实现复杂度：中高。需要根据 kernel size、channel 数、stride 设计缓存结构。  
可能缺点：BRAM 使用上升；buffer 边界和 padding 逻辑容易出错。

建议动作：

- 对输入序列建立 sliding window buffer。
- 权重优先常驻 BRAM/ROM，避免每帧重复从外部加载。
- 中间 activation 尽量流式传递，必要时只缓存一层最小工作集。

## 3. P1 重点优化

### 3.1 Loop Unrolling

优先级：P1  
为什么：unroll 可以增加并行 MAC 数量，降低单层计算 latency。  
预期收益：卷积层和全连接层 latency 下降，吞吐提升。  
硬件成本：DSP、LUT、FF 近似按 unroll factor 上升；BRAM 端口压力增加。  
实现复杂度：中。需要选择合适 unroll factor，并配合 array partition。  
可能缺点：过度展开会导致 DSP 超标、LUT 超标或 routing/timing fail。

建议动作：

- 不要直接 complete unroll。
- 先尝试 factor=2、4、8，并记录 DSP/LUT/BRAM/latency。
- 对资源紧张层使用 partial unroll。

### 3.2 Channel Folding

优先级：P1  
为什么：channel folding 用较少的并行计算单元分时处理多个通道，是资源和吞吐之间的主要折中手段。  
预期收益：在 DSP/BRAM 有限时保持可部署性；可通过 folding factor 控制资源。  
硬件成本：需要通道调度 FSM、partial sum buffer、累加控制逻辑。  
实现复杂度：中高。  
可能缺点：folding factor 越大，latency 越高；partial sum 存储和读写控制复杂。

建议动作：

- 先根据 DSP 预算确定并行 MAC 数。
- 对输入 channel 和输出 channel 分别评估 folding。
- 将 folding factor 设计为可配置参数，便于资源/性能扫描。

### 3.3 Memory Layout 与 Burst/DMA 优化

优先级：P1  
为什么：即使 CNN IP 足够快，如果输入输出通过 PS 逐点搬运或 AXI burst 不连续，系统吞吐仍会受限。  
预期收益：提高有效带宽，降低 PS 负载，减少端到端 latency。  
硬件成本：需要 DMA、AXI Stream、FIFO、Ping-Pong Buffer。  
实现复杂度：中高。  
可能缺点：调试复杂度上升，cache coherency 和 buffer ownership 容易出错。

建议动作：

- 输入采用连续内存布局，便于 DMA burst。
- 输出结果使用小型 AXI-Lite 或 Stream 都可，关键是输入特征流不能逐点寄存器写。
- 使用 Ping-Pong Buffer 隐藏数据搬运时间。

### 3.4 Pipeline Depth 管理

优先级：P1  
为什么：pipeline 越深，Fmax 可能越好，但寄存器、控制复杂度和首帧 latency 也会上升。  
预期收益：改善 timing closure，提高 clock frequency。  
硬件成本：FF 增加，部分 LUT 控制逻辑增加。  
实现复杂度：中。  
可能缺点：过深 pipeline 会增加调试难度和控制延迟；对低吞吐单帧任务收益有限。

建议动作：

- 以系统吞吐为主，不只看单模块 Fmax。
- 记录每层 pipeline latency 和 II。
- 对 critical path 做定点加法树拆分或 DSP pipeline。

## 4. P2 视资源采用

### 4.1 Pruning

优先级：P2  
为什么：剪枝可以减少无效权重和 MAC 数量，降低计算量。  
预期收益：理论上 latency、DSP、功耗下降；结构化剪枝收益更稳定。  
硬件成本：非结构化剪枝需要稀疏索引、跳零控制，可能增加 LUT/FF 和控制复杂度。结构化剪枝硬件成本较低。  
实现复杂度：中高。需要重新训练或微调。  
可能缺点：非结构化稀疏在 FPGA 上不一定省资源，可能因为控制开销抵消收益；准确率可能下降。

建议动作：

- 优先做结构化剪枝，例如减少 channel、kernel 或 neuron。
- 不建议第一阶段做非结构化随机稀疏。

### 4.2 Weight Compression

优先级：P2  
为什么：压缩权重可以降低 BRAM/DDR 存储和带宽需求。  
预期收益：BRAM 使用下降，外部加载时间下降。  
硬件成本：需要解码逻辑；如果运行时解压，可能增加 LUT/FF 和 latency。  
实现复杂度：中。  
可能缺点：对小模型收益有限；解压逻辑可能成为瓶颈。

建议动作：

- 优先使用低位宽量化作为“简单压缩”。
- Huffman/RLE 等复杂压缩只在 BRAM 明显不足时考虑。
- 若使用压缩，尽量离线解压到 BRAM，而不是每次 MAC 时动态解码。

### 4.3 Mixed Precision

优先级：P2  
为什么：不同层对精度敏感度不同，统一位宽可能浪费资源。  
预期收益：进一步降低 DSP/LUT/BRAM 和功耗，同时保留准确率。  
硬件成本：不同层需要不同数据类型和转换逻辑。  
实现复杂度：中。  
可能缺点：工程维护复杂度增加，接口转换容易出错。

建议动作：

- 第一层和最后一层通常更敏感，可保留更高位宽。
- 中间层逐步降低位宽做 sensitivity analysis。

## 5. P3 谨慎评估

### 5.1 Winograd Convolution

优先级：P3  
为什么：Winograd 可减少小卷积核乘法次数，常用于 2-D CNN 的 3x3 卷积。  
预期收益：理论上减少乘法数量，降低 DSP 使用。  
硬件成本：需要额外 transform、逆变换和中间 buffer，LUT/FF/BRAM 增加。  
实现复杂度：高。  
可能缺点：对 1-D CNN 不一定划算；定点数值范围更难控制；小模型上 transform 开销可能超过收益。

建议动作：

- 只有在 kernel size 和 channel 规模足够大、MAC 成本明显占主导时再评估。
- 第一阶段不建议作为主优化路径。

### 5.2 FFT Convolution

优先级：P3  
为什么：FFT convolution 对长序列、大 kernel 卷积可能降低计算复杂度。  
预期收益：长 kernel 场景下减少直接卷积计算量。  
硬件成本：FFT/IFFT、复数乘法、buffer、调度逻辑开销很大。  
实现复杂度：很高。  
可能缺点：短 kernel 的 1-D CNN 通常不划算；latency 和 BRAM 压力可能上升；定点误差更复杂。

建议动作：

- 只有在 kernel size 很大、序列很长、直接卷积无法满足性能时考虑。
- 当前阶段优先直接卷积 + pipeline + reuse。

## 6. 推荐落地顺序

### 第一轮：建立可综合低风险版本

```text
Quantization
-> BN Folding
-> Conv/Activation/Pooling Fusion
-> Loop Pipelining
-> Weight/Activation Buffer
```

目标：保证准确率接近原始模型，同时让资源和时序进入可控范围。

### 第二轮：资源/性能扫描

```text
Partial Unroll
-> Channel Folding
-> Array Partition
-> DMA Burst
-> Ping-Pong Buffer
```

目标：在 DSP、BRAM、LUT、FF 预算内找到最优吞吐点。

### 第三轮：模型结构压缩

```text
Structured Pruning
-> Mixed Precision
-> Weight Compression
```

目标：进一步降低功耗和资源，但必须以准确率回归验证为前提。

### 第四轮：特殊算法评估

```text
Winograd
-> FFT Convolution
```

目标：只在直接卷积无法满足要求且模型形态适合时评估。

## 7. 优先级总表

| 优化项 | 优先级 | 主要收益 | 主要资源影响 | 复杂度 | 推荐结论 |
|---|---:|---|---|---|---|
| Quantization | P0 | 降低 DSP/功耗/带宽 | 减少 DSP/BRAM，增加少量转换逻辑 | 中高 | 必做 |
| BN Folding | P0 | 减少算子和延迟 | 基本无新增硬件 | 低中 | 必做 |
| Operator Fusion | P0 | 降低中间访存 | 少量 LUT/FF 增加 | 中 | 必做 |
| Loop Pipelining | P0 | 提高吞吐 | FF/LUT 增加 | 中 | 必做 |
| Weight/Activation Reuse | P0 | 降低带宽和功耗 | BRAM 增加 | 中高 | 必做 |
| Loop Unrolling | P1 | 降低计算延迟 | DSP/LUT/FF 增加 | 中 | 受资源约束逐步做 |
| Channel Folding | P1 | 控制资源 | 控制逻辑和 partial sum buffer 增加 | 中高 | 中小 FPGA 推荐 |
| DMA/Ping-Pong | P1 | 提高端到端吞吐 | DMA/FIFO/BRAM 增加 | 中高 | 系统级必做 |
| Pipeline Depth 管理 | P1 | 改善 Fmax | FF 增加 | 中 | 结合 timing 做 |
| Pruning | P2 | 减少计算量 | 结构化剪枝硬件友好 | 中高 | 优先结构化 |
| Weight Compression | P2 | 降低存储 | 解码逻辑可能增加 | 中 | BRAM 紧张时做 |
| Mixed Precision | P2 | 进一步省资源 | 转换逻辑增加 | 中 | 第二阶段做 |
| Winograd | P3 | 理论减少乘法 | transform 和 buffer 增加 | 高 | 谨慎 |
| FFT Convolution | P3 | 长 kernel 可能收益大 | FFT/IFFT 成本高 | 很高 | 当前不优先 |

## 8. 最终建议

当前阶段最合理的技术路线是：

```text
定点化
-> BN 折叠
-> 算子融合
-> 卷积滑窗缓存
-> 内层 MAC pipeline
-> 受控 partial unroll
-> channel folding
-> DMA + Ping-Pong
-> Vivado implementation 后按报告迭代
```

不要优先投入 Winograd、FFT convolution 或复杂非结构化稀疏。它们在 1-D CNN 和中小 FPGA 上不一定带来净收益，容易增加控制复杂度和验证成本。
