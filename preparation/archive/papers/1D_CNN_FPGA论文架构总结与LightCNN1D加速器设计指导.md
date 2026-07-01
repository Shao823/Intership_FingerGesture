# 1D-CNN FPGA论文架构总结

本文面向当前 `emg_gesture_vivado/rtl/lightcnn1d_fixed` 中的 EMG 手势识别 1D-CNN RTL 工作，整理 `preparation/` 目录中几份论文和工程资料的核心思想。具体 RTL 架构设计思路已拆分到 `LightCNN1D_RTL加速器当前设计思路.md`。

当前你的网络是一个轻量 1D-CNN：

```text
input [5, 348]
 -> Conv1d 5->32, kernel=7, padding=3
 -> BN + ReLU
 -> DepthwiseConv1d 32->32, kernel=5, padding=2
 -> PointwiseConv1d 32->64, kernel=1
 -> BN + ReLU
 -> MaxPool1d kernel=2
 -> DepthwiseConv1d 64->64, kernel=5, padding=2
 -> PointwiseConv1d 64->96, kernel=1
 -> BN + ReLU
 -> GlobalAvgPool
 -> FC 96->96 + ReLU
 -> FC 96->5
 -> Argmax
```

目前 RTL 基线是：

```text
Q8.8 signed 16-bit fixed point
48-bit accumulator
single-MAC sequential datapath
whole-layer feature map buffering
8组标准测试向量已通过
```

后续优化目标不是先推翻这个基线，而是在保持验证接口和黄金样例不变的前提下，逐步替换内部计算与缓存结构。

---

## 1. 资料总览

`preparation/` 中当前包含：

| 文件 | 类型 | 对当前项目最有价值的点 |
|---|---|---|
| `A_Cost-Effective_CNN_Accelerator_Design_with_Configurable_PU_on_FPGA.pdf` | CNN FPGA 加速器论文 | 可配置 PU、按 kernel 行做 1D tiling、CONV/FC 复用、shift-based PE |
| `Design of lightweight on-chip one-dimensional convolutional neural network accelerators for edge-end chips.pdf` | 1D-CNN 片上加速器论文 | 两级存储、可配置乘加树、比较器阵列、指令式层调度、Conv/ReLU/Pool 融合 |
| `FPGA-based 1D-CNN accelerator for real-time arrhythmia classification.pdf` | 1D-CNN FPGA ECG 加速器论文 | depthwise separable conv、INQ 量化、移位替代乘法、PS-PL 协同 |
| `A_Convolution_Neural_Network_Accelerator_Design_with_Weight_Mapping_and_Pipeline_Optimization.pdf` | DAC 2023 CNN 加速器流水线论文 | weight mapping、load/execute/write-back 解耦、balanced pipeline、瓶颈层资源分配 |
| `如何从零开始将神经网络移植到FPGA(ZYNQ7020)加速...pdf` | 工程实践资料 | PS+PL、BRAM 输入输出、HLS IP 调用、SD/DDR/BRAM 数据路径 |
| `csdn.txt` | 链接文本 | 本地只保存链接，作为工程资料入口，不单独作为论文总结 |

---

## 2. 每篇论文/资料的精髓思想和架构

### 2.1 Cost-Effective CNN Accelerator with Configurable PU

**核心问题**

传统 CNN 加速器经常按输入/输出通道数做 tiling，例如一次并行处理 16 或 32 个通道。但剪枝后的网络通道数可能不规则，这会导致大量 zero padding 和 PE 空转。论文认为，硬件不应该只围绕固定通道 tile 设计，而应该考虑 kernel 维度和 output 维度的灵活映射。

**核心思想**

1. 用 row-based 1D tiling 替代传统通道 tiling 或 2D kernel tiling。
2. 将 kernel 按行处理，缩短 tile 长度，减少 padding 和 PE idle。
3. 设计可配置 PU，一个 PU 内多个 PE 可以合并成一个大计算组，也可以拆成多个小计算组。
4. CONV 和 FC 复用同一套 PU，减少专用硬件。
5. 对 INQ 量化后的 power-of-two 权重，用 shifter 替代 multiplier。

**架构结构**

可以抽象成：

```text
input/layer buffer
 -> configurable PU array
      -> PE group
          -> shifter / add tree
      -> PU buffer
 -> ReLU / MaxPool shared hardware
 -> layer buffer
 -> next layer
```

每个 PU 内包含多个 PE。PE 负责一组 shift-accumulate 或 MAC。PU 可以根据层的 kernel size、feature length、output channel 并行度进行重组：

```text
大 kernel: 多个 PE 合起来算一个输出
小 kernel: 一个 PU 拆成多个小组，同时算多个输出通道或多个位置
FC 层: 把 FC 看成 kernel tiling 后的矩阵乘，复用同一套 PU
```

**对当前项目的启发**

你的网络没有通道剪枝，但存在明显的层间形态差异：

```text
stem:         5输入通道, kernel=7, 输出32通道
depthwise:    每通道 kernel=5, 通道独立
pointwise:    kernel=1, 通道混合, 计算量最大
FC:           96输入, 96/5输出
```

因此不建议为每层都写完全独立的硬件。更合适的是：

```text
统一 MAC/PE 阵列
通过模式选择支持 stem / depthwise / pointwise / FC
对 depthwise 使用时间滑窗
对 pointwise 和 FC 使用同一套 dot-product 引擎
```

尤其要借鉴它的“可配置 PU”思想：不要一开始就做死某个并行度，而是把并行度设计成参数，例如：

```text
P_OC = 4 或 8       // 并行输出通道数
P_IC = 4 或 8       // 并行输入通道归约数
P_T  = 1 或 2       // 并行时间点数
```

---

### 2.2 Lightweight On-Chip 1D-CNN Accelerator for Edge-End Chips

**核心问题**

1D-CNN 用于边缘传感器信号时，模型计算量通常不如 2D-CNN 大，但设备对面积、功耗、SRAM 和总线带宽很敏感。传统大规模 2D CNN 加速器在 1D-CNN 上可能过重。

**核心思想**

1. 用轻量片上架构，而不是大型 systolic array。
2. 用两级存储结构：较大的全局 SRAM + 小容量多端口寄存器组。
3. 用可配置 multiplier-adder tree 支持不同 kernel size。
4. 用 comparator array 支持 ReLU 和 MaxPool。
5. 通过指令式调度支持不同 1D-CNN 层。
6. 通过 operator conversion 和 fusion 降低访存：
   - BN 和 Linear 可转化为类似卷积/乘加操作。
   - Conv + ReLU + Pool 可流水融合。

**架构结构**

论文架构可以抽象成：

```text
CPU/bus config
 -> instruction/register bank
 -> global memory
      input SRAM
      weight SRAM
      bias SRAM
      write-back SRAM
 -> input register group
 -> multiplier-adder tree array
 -> intermediate register group
 -> comparator array for ReLU/MaxPool
 -> write-back SRAM
```

乘加树是可配置的。例如一套 15 个 multiplier/adder 可以配置成：

```text
5组 kernel=3 的小滤波器
或 3组 kernel=5 的滤波器
或多周期处理更大的 kernel
```

**对当前项目的启发**

你的网络是典型小型 1D-CNN，输入固定为 `[5,348]`。相比通用指令式架构，你不一定需要完整 opcode 体系，但非常值得借鉴：

1. 两级缓存：

```text
大缓存: 当前层/下一层 feature map BRAM
小缓存: 当前滑窗、当前通道向量、PE 局部寄存器
```

2. Conv/ReLU/Pool 融合：

当前 RTL 是整层缓存：

```text
block1_pw -> 写完整 b1pw_mem -> 再 maxpool
```

后续可以优化成：

```text
pointwise 输出 t=0 和 t=1
 -> BN + ReLU
 -> 比较得到 pool[0]
 -> 只写 pool_mem
```

这样可以减少 `b1pw_mem` 的长期存储需求，至少减少一大块 BRAM。

3. BN 不应该长期作为独立模块：

当前 RTL 中 BN 已经转化成：

```text
y = (x - mean) * scale + bias
```

下一步可以进一步 folding：

```text
y = x * folded_scale + folded_bias
```

甚至对 Conv 层权重做离线折叠，硬件只保留一套乘加和 ReLU。

---

### 2.3 FPGA-based 1D-CNN Accelerator for Real-Time Arrhythmia Classification

**核心问题**

ECG 是典型 1D 生理信号，和 EMG 很接近。论文目标是把轻量 1D-CNN 部署到资源有限的 Zynq-7Z020 上，实现实时分类、低资源、低功耗。

**核心思想**

1. 网络层面用 depthwise separable convolution 降低参数和计算量。
2. 模型压缩层面结合 pruning 和 INQ 量化。
3. 硬件层面使用 multiplication-free convolution processing unit。
4. 对 power-of-two 权重，用 shift 替代乘法。
5. 使用 PS-PL 协同：
   - PS 控制流程、加载数据/权重。
   - PL 执行卷积/池化/FC 等计算。
6. 可配置卷积 IP 支持：
   - depthwise mode
   - pointwise mode
   - kernel size
   - padding
   - input/output channel
   - input length

**架构结构**

可以抽象成：

```text
PS
 -> SD/DDR 数据和权重管理
 -> 通过 AXI/DMA 配置 PL

PL
 -> configurable convolution core
      mode 0: depthwise convolution
      mode 1: pointwise convolution
 -> ReLU / Pool / FC cores
 -> output result
```

Depthwise 模式下，每个输入通道独立滑窗；Pointwise 模式下，kernel=1，通过跨通道累加完成通道融合。

**对当前项目的启发**

这篇论文和你当前网络最接近，因为你的网络也使用了 depthwise separable conv：

```text
block1 = DW 32,k5 + PW 32->64,k1
block2 = DW 64,k5 + PW 64->96,k1
```

因此你的加速器最好明确支持两种核心模式：

```text
mode_dw:
    每个通道独立做 1D k=5 卷积

mode_pw:
    每个时间点固定，对输入通道做 dot product
```

如果未来将权重量化为 power-of-two，可以进一步把 weight multiplication 替换为 shift-add。但当前已经有 Q8.8 权重量化和 golden vectors，建议不要立刻换 INQ。更稳妥路线是：

```text
阶段1: 保持 Q8.8 乘法，优化缓存和并行度
阶段2: 验证时序和资源
阶段3: 再尝试 power-of-two weight / shift-based PE
```

---

### 2.4 CNN Accelerator with Weight Mapping and Pipeline Optimization

**核心问题**

这篇 DAC 2023 论文讨论的是 NVM/CIM CNN 加速器，但它真正有价值的地方不是存内计算本身，而是它对“流水线为什么会被卡住”的系统级分析。论文指出，很多加速器只关注计算 macro 的吞吐，却忽略了 IFM、OFM、partial sum 的 buffer 访问延迟。这样即使把计算单元做得很并行，流水线仍然会被访存、写回或某个瓶颈层卡住。

论文把之前的流水线问题分成两类：

```text
raw pipeline:
    多层并行执行，但浅层 feature map 大，容易卡住整条流水线

intra-tile pipeline:
    复制瓶颈层权重/计算资源，提高计算吞吐
    但如果 load/write-back 仍然串行，buffer access 仍会成为瓶颈
```

**核心思想**

1. **Matrix-based weight mapping**

   常规卷积映射会在每个滑窗周期读取 `k*k*Cin` 大小的 IFM window。论文提出把卷积核映射成矩阵形式，让相邻滑窗之间的数据在本地复用。对 2D 卷积来说，每次滑动只需要加载 `k*Cin` 级别的数据，再通过连续若干次局部累加得到最终输出。

   对当前 1D-CNN 来说，对应思想是：

   ```text
   不要每算一个输出点都从 BRAM 重读完整 k*Cin window
   应该用 line/window buffer 保留相邻时间点
   stem 和 depthwise 的 k=7/k=5 输入窗口要在本地滑动复用
   ```

2. **Decoupled access and execution**

   论文把单个计算周期拆成：

   ```text
   load input
   execute VMM / MAC
   write output
   ```

   如果三者串行执行，即使计算单元很快，也会有大量空转。因此它提出 load、execute、write-back 解耦，让当前 tile 计算时，下一 tile 的输入已经在加载，上一 tile 的输出已经在写回。

   对当前 RTL 来说，对应结构是：

   ```text
   input/tile ping-pong buffer
   compute tile buffer
   output/writeback FIFO
   ```

3. **Hybrid inter/intra-tile pipeline**

   只把瓶颈层复制在同一个 tile 内，不一定能解决问题，因为 IFM/OFM 访问可能仍然串行。论文建议把瓶颈层的权重副本分布到多个独立 tile 上，让计算和访存压力都被分摊，从而平衡各层 latency。

   对当前项目来说，对应思想是：

   ```text
   如果 PW2 是瓶颈，不只是把 P_OC 做大
   还要确保 weight bank、activation buffer、writeback 带宽能跟上
   必要时 PW2 使用独立 GEMM 阵列或更多输出通道 bank
   ```

4. **Balanced pipeline**

   论文不是追求某一层最快，而是把系统吞吐看成由最慢 stage 决定。它用 latency-area 类指标选择需要复制多少资源，让各层延迟尽量接近。

   这对当前项目非常关键：如果 `stem`、`PW1`、`PW2` 用不同计算资源做跨样本流水，资源分配应该按 stage latency 平衡，而不是平均分配 MAC。

**架构结构**

论文原始架构面向 CIM，可以抽象成：

```text
L2 buffer
 -> tile L1 buffer
 -> CIM macro / VMM engine
 -> output register / partial sum adder
 -> special function units
 -> L2 buffer
```

对应到当前 RTL，可以借鉴为：

```text
feature BRAM / tile buffer
 -> GEMM/Conv PE array
 -> acc_tile register
 -> registered BN/ReLU/Pool/GAP pipeline
 -> writeback buffer
```

**对当前项目的启发**

这篇文章直接修正了一个容易误解的点：流水线不是“一个点算完马上送到下一层”就一定高效。对你的 LightCNN1D 来说，最合理的是 tile 级流水：

```text
DW 生产一个 time tile
PW 消费一个 time tile
BN/ReLU/Pool/GAP 在 PW tile 输出后注册化处理
```

不要为了让 DW 的单点输出立刻进入 PW，而把 PW 阵列缩小到 `P_T=1` 或 `2x2`。因为 PW1/PW2 的跨通道归约才是主要计算瓶颈，PE 阵列应该围绕 `PW` 的高利用率矩阵乘设计。

这篇论文对当前设计的具体指导是：

```text
1. 融合后处理的目的不是拉长组合关键路径，而是减少中间 buffer 读写。
2. PW 后面的 BN/ReLU/Pool/GAP 必须做成带寄存器的后处理流水。
3. time tile 之间用 ping-pong buffer 或 FIFO 解耦，允许 producer/consumer 速度不同。
4. 超级流水线的目标是平衡 stem/PW1/PW2 等大 stage 的 latency。
5. 复制计算资源时必须同时检查 BRAM 端口、weight bank 和 writeback 带宽。
```

---

### 2.5 ZYNQ7020 神经网络移植工程资料

**核心问题**

这份资料不是论文，更像工程实践教程。它强调从训练得到权重，到 HLS IP，再到 PS 端通过 BRAM/AXI 调用 PL 推理。

**核心思想**

1. 训练在 PC 完成，FPGA 只做前向推理。
2. 权重、bias 导出为文件，硬件中固化或加载。
3. PS 负责读 SD 卡、写 BRAM、启动 IP、读取输出。
4. PL 负责神经网络计算。
5. 输入 BRAM 和输出 BRAM 可以分别连接 PS 和加速器。

典型数据路径：

```text
SD card -> PS -> input BRAM -> PL accelerator -> output BRAM -> PS -> UART/display
```

**对当前项目的启发**

你现在已经不打算封装 HLS IP，而是直接写 RTL。这是合理的，但 PS-PL 交互思想仍然有价值。未来如果接入 Zynq，建议把 RTL 顶层接口稳定成下面两类之一：

方案 A：流式输入输出，适合测试和简单集成：

```text
start
in_valid / in_ready / in_data
out_valid / class_id / logits
```

方案 B：BRAM 地址接口，适合 Vivado block design：

```text
input_bram_addr
input_bram_dout
output_bram_addr
output_bram_din
output_bram_we
start/done
```

你现在的 RTL 使用流式输入接口更适合仿真验证；后续要上板时，可以再包一层 BRAM adapter，不要改核心计算模块。

---

后续当前项目的 RTL 设计思路见：`LightCNN1D_RTL加速器当前设计思路.md`。
