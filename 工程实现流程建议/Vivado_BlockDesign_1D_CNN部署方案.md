# Vivado Block Design：1-D CNN 加速器部署方案

## 1. 设计目标

本方案面向已有可工作的 1-D CNN 手势识别网络，目标是在 Zynq FPGA 上完成工程化部署。

核心目标：

- PS 负责控制、配置、状态读取、无线协议和调试。
- PL 负责高吞吐 1-D CNN 推理。
- 输入特征流通过 DMA 或 AXI Stream 进入 CNN Accelerator。
- 权重尽量常驻片上 Weight Memory，减少外部存储访问。
- Feature Memory 使用 BRAM/URAM/FIFO/Ping-Pong Buffer 支撑连续帧处理。
- 通过 pipelining、parallel MAC、channel folding 和 double buffering 最大化吞吐。

## 2. 推荐总体架构

推荐主架构：

```text
PS DDR
  |
  | AXI HP/HPC
  v
AXI DMA <-> AXI Interconnect <-> Processing System
  |
  | AXI4-Stream
  v
Stream FIFO / Ping-Pong Feature Buffer
  |
  v
Instruction Controller -> CNN Accelerator -> Result FIFO/BRAM
          |                    |
          |                    v
          |              Weight Memory
          |
          v
     Status/Interrupt
```

如果输入来自 ADC/预处理模块，推荐让 ADC/Preprocess 在 PL 内直接输出 AXI4-Stream，绕过 PS 逐点搬运：

```text
ADC -> Preprocess -> AXI4-Stream -> CNN Accelerator -> Result -> Wireless/PS
```

PS 仍可通过 AXI4-Lite 配置 CNN 参数、启动推理、读取状态和处理中断。

## 3. ASCII Block Diagram

```text
                         +--------------------------------------+
                         |          Processing System           |
                         |                                      |
                         |  ARM CPU                             |
                         |  DDR Controller                      |
                         |  UART                                |
                         |  SD / Debug                          |
                         |  IRQ Input                           |
                         +----+-------------+-------------+-----+
                              |             |             |
                 AXI GP       |             | AXI HP/HPC  | UART
              Control Path    |             | Data Path   |
                              v             v             v
                      +---------------+   +----------------------+
                      | AXI Interconn |   |       AXI DMA         |
                      | /SmartConnect |   | MM2S + S2MM Optional |
                      +---+-------+---+   +-----+-----------+----+
                          |       |             |           |
          AXI4-Lite       |       | AXI4-Lite   | AXI-Stream| AXI-Stream
                          |       |             v           v
                          |       |      +-------------+  +-------------+
                          |       |      | Stream FIFO |  | Result FIFO |
                          |       |      | /Ping-Pong  |  | /Result Mem |
                          |       |      +------+------+  +------+------+
                          |       |             |                |
                          |       |             v                |
                          |       |      +-------------+         |
                          |       +----->| Instruction |<--------+
                          |              | Controller  |
                          |              +------+------+ 
                          |                     |
                          |                     | control/config
                          |                     v
                          |              +-------------+
                          +------------->| CNN         |
                          AXI4-Lite      | Accelerator |
                                         +------+------+ 
                                                |
                         +----------------------+----------------+
                         |                      |                |
                         v                      v                v
                  +-------------+        +-------------+   +-------------+
                  | Weight Mem  |        | Feature Mem |   | Wireless IF |
                  | BRAM/ROM    |        | BRAM/FIFO   |   | UART/SPI/RF |
                  +-------------+        +-------------+   +-------------+

              +-------------+        +-------------+
              | Clock Wizard|------->| proc_sys_rst|
              +-------------+        +-------------+
```

## 4. 模块说明

### 4.1 Processing System

用途：

- 运行裸机或 Linux 软件。
- 配置 CNN Accelerator、DMA、Instruction Controller。
- 维护输入/输出 buffer 地址。
- 处理 DMA done、CNN done、Wireless done 中断。
- 通过 UART 输出调试信息。

建议：

- 使用 AXI GP 端口连接 AXI4-Lite 控制寄存器。
- 使用 AXI HP/HPC 端口连接 DMA 到 DDR。
- 若系统以低延迟为主，尽量减少 PS 参与每帧数据搬运。

### 4.2 AXI Interconnect / SmartConnect

用途：

- 汇聚 PS AXI GP master 到多个 AXI4-Lite slave。
- 连接 DMA、CNN Accelerator、Instruction Controller、Wireless Interface、BRAM Controller 的寄存器空间。

建议：

- 控制路径和数据路径分离。
- 控制路径使用 AXI4-Lite，低带宽。
- 数据路径使用 AXI4 或 AXI4-Stream，避免与控制寄存器抢带宽。

### 4.3 AXI DMA

用途：

- MM2S：从 DDR 读取输入特征帧，转换为 AXI4-Stream 输入 CNN。
- S2MM：把 CNN 输出或中间结果写回 DDR。若输出只有分类结果，可不用 S2MM，直接通过 AXI4-Lite/BRAM/FIFO 读取。

建议：

- 输入特征推荐使用 MM2S。
- 输出分类结果很小，优先 Result FIFO/BRAM + interrupt。
- 如果需要保存中间 feature map 或批量结果，再启用 S2MM。

### 4.4 BRAM Controller

用途：

- PS 访问片上 BRAM，用于调试、权重加载、小规模 feature/result 缓存。
- 可作为参考工程中 BRAM 访问方式的延续。

建议：

- 不建议用 PS 逐点写 BRAM 作为主输入通路，带宽和 CPU 开销都不理想。
- BRAM Controller 更适合作为配置、调试、少量结果读取、离线权重加载路径。

### 4.5 CNN Accelerator

用途：

- 实现 1-D CNN 推理，包括 Conv1D、Activation、Pooling、Fully Connected、Classifier。
- 接收 AXI4-Stream 输入，输出分类结果或 logits。

建议接口：

- `s_axis_feature`：输入特征流。
- `m_axis_result`：输出结果流，可选。
- `s_axi_control`：配置寄存器，包括 start、done、frame_len、layer_cfg、buffer_addr、interrupt enable。
- `weight_mem_if`：连接 Weight Memory。
- `feature_mem_if`：连接 Feature Memory。

### 4.6 Instruction Controller

用途：

- 控制 CNN Accelerator 的层执行顺序。
- 管理 layer configuration、feature buffer 切换、weight address、channel folding、interrupt。
- 将复杂调度从 PS 软件中下沉到 PL，减少每层软件干预。

建议：

- 第一版可以用简单 FSM。
- 后续可升级为 micro-instruction controller，每条指令描述 layer type、input offset、output offset、weight offset、loop bounds、folding factor。

### 4.7 Weight Memory

用途：

- 存储卷积层和全连接层权重。
- 支持 CNN Accelerator 多端口或分 bank 读取。

实现选择：

- 小模型：BRAM ROM，bitstream 初始化。
- 中等模型：BRAM RAM，PS 启动时加载权重。
- 权重大于片上存储：DDR + weight cache，但会增加带宽压力。

建议：

- 优先常驻片上。
- 按 output channel、input channel、kernel tap 做 bank 化，服务并行 MAC。

### 4.8 Feature Memory

用途：

- 缓存输入窗口、中间 activation、partial sum、输出 feature。
- 支持 Ping-Pong Buffer。

建议：

- Conv1D 使用 sliding window buffer，减少重复读取。
- 中间层尽量 stream 化，减少完整 feature map 落 BRAM。
- 需要跨层复用时再落 Feature Memory。

### 4.9 UART

用途：

- 调试输出、状态打印、简单指令控制。
- 可作为 PC 端低速通信链路。

限制：

- UART 带宽低，不适合作为高频 feature 输入或大量结果输出。
- 适合控制和日志，不适合作为主数据通路。

### 4.10 Wireless Interface

用途：

- 将分类结果发送到 PC/Game。
- 可通过 UART、SPI、GPIO 或自定义 RF 模块连接。

建议：

- 只传输分类 ID、confidence、timestamp、frame counter、checksum。
- 不传输大规模 feature map。
- 使用小 FIFO 解耦 CNN result 和无线发送速率。

### 4.11 Clock Wizard

用途：

- 生成 PL 侧工作时钟，如 50 MHz、100 MHz、150 MHz。
- 根据 CNN Accelerator 时序能力选择频率。

建议：

- 第一版用保守频率，例如 50 MHz 或 100 MHz。
- 时序稳定后再提高频率。
- AXI DMA、CNN、Wireless 可按需要分时钟域，但跨时钟域必须加 FIFO 或 CDC。

### 4.12 Reset Module

用途：

- 使用 `proc_sys_reset` 产生同步复位。
- 为 AXI、DMA、CNN、FIFO、Wireless 提供稳定 reset。

建议：

- 每个 clock domain 配一个 reset module。
- 避免异步复位直接进入深 pipeline。

### 4.13 Interrupt Controller

用途：

- 汇聚 DMA done、CNN done、Wireless done、error interrupt。
- 将中断送到 PS。

建议：

- 裸机可用 `xlconcat` + PS IRQ。
- 多中断源复杂时使用 AXI Interrupt Controller。

## 5. AXI 接口说明

### 5.1 AXI4-Lite Control Interface

连接对象：

- PS AXI GP -> AXI Interconnect -> CNN Accelerator / Instruction Controller / DMA / Wireless / BRAM Controller。

用途：

- 配置寄存器。
- 启动/停止。
- 状态查询。
- 中断使能。
- layer 参数配置。

带宽要求：

- 很低。通常每帧只需几十到几百字节控制写入。

注意点：

- 控制寄存器不要承载大规模 feature 数据。

### 5.2 AXI4 Memory Mapped Interface

连接对象：

- AXI DMA M_AXI_MM2S / M_AXI_S2MM -> PS HP/HPC -> DDR。

用途：

- 从 DDR 读取输入特征。
- 可选写回输出 feature 或结果。

带宽要求：

- 与输入帧大小、帧率、数据位宽相关。
- 估算公式：

```text
Input_BW = frame_rate * input_length * input_channels * input_bitwidth / 8
Output_BW = frame_rate * output_size * output_bitwidth / 8
Weight_BW = frame_rate * weight_size_per_frame
```

如果权重常驻片上，则 `Weight_BW` 接近 0。

### 5.3 AXI4-Stream Feature Interface

连接对象：

- AXI DMA MM2S -> Stream FIFO/Ping-Pong -> CNN Accelerator。
- 或 ADC/Preprocess -> CNN Accelerator。

用途：

- 连续传输输入 feature。
- 使用 `TVALID/TREADY` 做反压。
- 使用 `TLAST` 标记一帧结束。

注意点：

- CNN Accelerator 必须能处理 backpressure。
- 如果 CNN 消耗速度低于 DMA 发送速度，需要 FIFO 或 buffer。

### 5.4 AXI4-Stream Result Interface

连接对象：

- CNN Accelerator -> Result FIFO -> DMA S2MM 或 Wireless Interface。

用途：

- 输出 logits、class ID、confidence。

建议：

- 分类结果很小时，可直接进入 Result FIFO 和 Wireless。
- 需要保存全量输出时再走 DMA S2MM。

### 5.5 BRAM Native Interface

连接对象：

- CNN Accelerator -> Weight Memory / Feature Memory。
- BRAM Controller -> Debug BRAM。

用途：

- 低延迟片上访问。
- 多 bank 权重读取。
- feature ping-pong。

注意点：

- BRAM 端口数量有限，loop unroll 后容易端口冲突。
- 需要 array partition、banking 或复制权重解决多读端口需求。

## 6. Dataflow

### 6.1 DDR 输入模式

```text
1. PS 从采集/预处理结果准备 input buffer。
2. PS 配置 DMA MM2S 源地址和长度。
3. PS 配置 CNN Accelerator frame_len、channel、layer cfg。
4. PS 启动 DMA 和 CNN。
5. DMA 通过 AXI4-Stream 发送 feature。
6. CNN 使用 Feature Memory 形成滑窗，读取 Weight Memory 执行推理。
7. CNN 输出 result 到 Result FIFO/BRAM。
8. CNN done interrupt 进入 PS。
9. PS 读取结果或让 Wireless Interface 自动发送结果。
```

### 6.2 PL 直连输入模式

```text
ADC -> Preprocess -> AXI4-Stream -> CNN Accelerator -> Result FIFO -> Wireless/PS
```

优势：

- 端到端 latency 更低。
- DDR 带宽压力更小。
- PS 干预更少。

风险：

- CDC、帧同步、backpressure 处理更复杂。

## 7. 带宽需求分析

关键原则：

- 输入 feature 带宽通常不大，但必须连续稳定。
- 权重带宽如果从 DDR 每帧读取，会成为瓶颈。
- 中间 activation 如果频繁写回 DDR，会严重拉低吞吐并增加功耗。

建议目标：

```text
权重：常驻 BRAM/ROM
输入：DMA burst 或 PL stream
中间 activation：片上 buffer 或 stream
输出：小结果 FIFO/BRAM/Wireless
```

带宽估算示例：

```text
input_length = L
input_channels = C
data_width = W bits
frame_rate = F frames/s

Input_BW = L * C * W / 8 * F
```

CNN 内部 MAC 需求：

```text
MACs_per_conv = output_length * output_channels * input_channels * kernel_size
Required_MAC_rate = MACs_per_frame * frame_rate
```

并行 MAC 数估算：

```text
Parallel_MACs >= Required_MAC_rate / clock_frequency
```

## 8. Timing Bottlenecks

### 8.1 MAC Accumulation Path

风险：

- 卷积累加链过长。
- 定点 accumulator 位宽过大。
- unroll 后加法树太深。

优化：

- 使用 pipelined adder tree。
- 分段累加 partial sum。
- DSP48 pipeline 打开。
- 控制 accumulator 位宽。

### 8.2 BRAM Read Port Conflict

风险：

- 多个 MAC 并行读取同一个 weight/feature bank。
- HLS II 无法降到 1。

优化：

- Weight Memory bank 化。
- Feature buffer array partition。
- 权重复制换取多读端口。

### 8.3 AXI Stream Backpressure

风险：

- CNN 处理速度低于 DMA 或 ADC 输入速度。
- FIFO 溢出或上游阻塞。

优化：

- 增加 Stream FIFO 深度。
- 使用 Ping-Pong Buffer。
- 提高 CNN II。
- 降低输入 burst 粒度。

### 8.4 Cross Clock Domain

风险：

- ADC、CNN、DMA、Wireless 不同频率。
- CDC 不正确导致偶发错误。

优化：

- AXI Clock Converter。
- Async FIFO。
- 每个时钟域独立 reset。

## 9. 应该 Pipeline 的模块

必须 pipeline：

- Conv1D 内层 MAC loop。
- Activation stage。
- Pooling stage。
- Fully Connected MAC loop。
- AXI Stream input unpack。
- Result packing。

建议 pipeline：

- Weight read + multiply + accumulate。
- Sliding window update。
- Partial sum writeback。
- Wireless packet formatter。

不建议过度 pipeline：

- AXI4-Lite control register path。
- 低频状态机。
- 一次性初始化逻辑。

## 10. 应该 Parallelize 的模块

优先并行：

- Output channel 方向。
- Kernel tap 方向。
- Input channel 方向的部分并行。
- 多个 activation lane。

谨慎并行：

- 全 input channel complete unroll，资源容易爆。
- 全 output channel complete unroll，BRAM/DSP 压力大。

推荐策略：

```text
Parallel_MACs = output_channel_parallel * input_channel_parallel * kernel_parallel
```

先固定 DSP 预算，再决定三者的并行度。

## 11. 最大化吞吐的方法

### 11.1 数据通路层面

- 输入使用 AXI DMA burst 或 PL AXI-Stream。
- 使用 Stream FIFO 吸收速率抖动。
- 使用 Ping-Pong Buffer 重叠 DMA 搬运和 CNN 计算。
- 输出小结果直接进入 Wireless FIFO，避免 DDR 往返。

### 11.2 计算层面

- 定点化降低单 MAC 成本。
- Conv + BN + Activation fusion。
- Sliding window buffer 提高 activation reuse。
- Weight Memory bank 化提高 weight reuse。
- 内层 loop pipeline，目标 II=1 或接近 1。
- 根据资源做 partial unroll。
- 使用 channel folding 在资源和吞吐之间折中。

### 11.3 系统调度层面

- Instruction Controller 管理 layer 调度，减少 PS 每层干预。
- PS 只做帧级控制。
- 中断驱动，不做长时间 polling。
- 记录 frame counter、cycle counter、DMA busy、CNN busy，用实测数据定位瓶颈。

## 12. 资源影响总结

| 优化/模块 | LUT | FF | DSP | BRAM | Latency | Throughput | Power |
|---|---:|---:|---:|---:|---:|---:|---:|
| Quantization | 下降 | 下降或小升 | 下降 | 下降 | 下降 | 上升 | 下降 |
| Loop Pipeline | 上升 | 上升 | 可能不变 | 不变 | 可能小升 | 上升 | 可能上升 |
| Loop Unroll | 上升 | 上升 | 上升 | 可能上升 | 下降 | 上升 | 上升 |
| Channel Folding | 上升少量 | 上升少量 | 下降 | partial sum 增加 | 上升 | 下降 | 下降 |
| Weight Reuse | 控制逻辑上升 | 上升 | 不变 | 上升 | 下降 | 上升 | 下降 |
| DMA/Ping-Pong | 上升 | 上升 | 不变 | 上升 | 下降 | 上升 | 下降 |
| Operator Fusion | 小升 | 小升 | 下降或不变 | 下降 | 下降 | 上升 | 下降 |

## 13. 推荐实现阶段

### 第一阶段：可运行 Block Design

```text
PS
AXI SmartConnect
AXI DMA MM2S
CNN Accelerator AXI4-Stream input
Result BRAM/FIFO
UART debug
Clock Wizard
proc_sys_reset
interrupt
```

目标：跑通单帧推理。

### 第二阶段：高吞吐数据通路

```text
Ping-Pong Feature Buffer
Weight Memory bank
Instruction Controller
DMA interrupt
Wireless FIFO
```

目标：连续帧推理，减少 PS 干预。

### 第三阶段：性能收敛

```text
partial unroll
channel folding
array partition
pipelined adder tree
clock frequency tuning
power analysis
```

目标：达到资源、时序、延迟、功耗平衡。

## 14. 最终建议

最推荐的 Vivado BD 主线是：

```text
PS + AXI SmartConnect + AXI DMA + AXI4-Stream CNN Accelerator
+ Weight BRAM/ROM + Feature Ping-Pong Buffer
+ Instruction Controller + Result FIFO
+ UART/Wireless + Clock/Reset/Interrupt
```

不要把 PS 逐点写 BRAM 作为长期主数据通路。它适合早期调试，但不适合实时手势识别。最终应让输入数据以 DMA 或 PL Stream 连续进入 CNN Accelerator，权重常驻片上，中间 activation 尽量不落 DDR，输出结果直接进入 Wireless 或小型 Result FIFO。
