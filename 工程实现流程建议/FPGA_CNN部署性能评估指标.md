# FPGA CNN 部署性能评估指标

## 1. 评价目标

FPGA CNN 部署不能只看单一指标。一个可交付设计至少需要同时满足：

- 推理 latency 达标。
- FPS 或 frame rate 达标。
- DSP、LUT、FF、BRAM 不超资源预算。
- 时序收敛。
- 功耗可接受。
- AXI/DMA/BRAM 带宽不成为瓶颈。
- Pipeline 和 PE 利用率足够高。

推荐评价层级：

```text
端到端指标：Latency / FPS / Power / Energy
计算指标：Throughput / MAC utilization / PE utilization
资源指标：DSP / LUT / FF / BRAM
存储指标：Bandwidth / Memory efficiency / Burst efficiency
流水指标：II / Pipeline utilization / Stall ratio
```

## 2. 性能指标

### 2.1 Latency

定义：  
从输入数据可用到输出分类结果可用的时间。

公式：

```text
Latency_time = Latency_cycles / Fclk
Latency_ms = Latency_cycles / Fclk_Hz * 1000
```

端到端 latency：

```text
E2E_latency =
  input_acquisition_time
+ preprocessing_time
+ dma_input_time
+ cnn_compute_time
+ result_pack_time
+ wireless_tx_time
+ receiver_apply_time
```

测量方法：

- HLS：查看 `Latency min/max`。
- RTL/Vivado 仿真：在 `start` 和 `done` 之间计数。
- 硬件：加入 cycle counter，记录 `start_cycle` 和 `done_cycle`。
- 系统：在 PS 侧记录 DMA start、CNN done、wireless tx done 时间戳。

Vivado/HLS 报告：

- Vitis HLS `csynth.rpt`
- Vitis HLS co-simulation report
- Vivado ILA 实测波形
- SDK/Vitis 软件计时器

优化方向：

- Conv/activation/pooling fusion。
- Loop pipeline。
- Partial unroll。
- Ping-Pong Buffer 隐藏搬运时间。
- 减少 PS 逐点搬运。

### 2.2 FPS

定义：  
每秒可处理的输入帧数。

公式：

```text
FPS = 1 / frame_period
FPS = Fclk_Hz / effective_cycles_per_frame
```

如果流水线连续处理：

```text
FPS_streaming = Fclk_Hz / II_frame
```

如果按帧顺序执行：

```text
FPS_frame_based = Fclk_Hz / (load_cycles + compute_cycles + store_cycles)
```

Ping-Pong 后：

```text
FPS_pingpong = Fclk_Hz / max(load_cycles, compute_cycles, store_cycles)
```

测量方法：

- 连续输入 N 帧，测量总时间。
- 统计 `frame_done_count / elapsed_time`。
- 硬件中加入 frame counter。

Vivado/HLS 报告：

- HLS Latency 和 II。
- Vivado ILA 观察 frame done 周期。
- PS 软件日志。

优化方向：

- 使用 dataflow。
- 使用 DMA burst。
- 使用 double buffer。
- 降低最慢 stage latency。

### 2.3 Throughput

定义：  
单位时间完成的计算量或数据量。

计算吞吐：

```text
Throughput_OPS = total_operations_per_frame * FPS
Throughput_MACS = total_MACs_per_frame * FPS
```

如果一个 MAC 算作 2 ops：

```text
Throughput_GOPS = 2 * MACs_per_frame * FPS / 1e9
```

理论峰值：

```text
Peak_MACS = num_parallel_MACs * Fclk_Hz
Peak_GOPS = 2 * num_parallel_MACs * Fclk_Hz / 1e9
```

实际效率：

```text
Compute_efficiency = Actual_MACS / Peak_MACS
```

测量方法：

- 根据网络层参数计算 MACs。
- 用实测 FPS 推导实际 MAC/s。
- 与 PE 数和时钟计算出的理论峰值对比。

Vivado/HLS 报告：

- HLS Schedule Viewer。
- HLS resource report。
- 自定义性能计数器。

优化方向：

- 提高 PE utilization。
- 减少 memory stall。
- 提高 II。
- 平衡 layer workload。

## 3. 功耗与能效指标

### 3.1 Power

定义：  
FPGA 运行时平均功耗。

公式：

```text
P_total = P_static + P_dynamic
P_dynamic ~= C * V^2 * f * activity
```

测量方法：

- 估算：Vivado Power Report。
- 实测：开发板电源输入端电流/电压测量。
- 分模块估算：切换不同模块开关，测差分功耗。

Vivado 报告：

- `report_power`
- Vivado Power Analyzer
- SAIF/VCD activity-based power analysis

优化方向：

- 定点化。
- 降低不必要并行度。
- clock gating / enable gating。
- 减少 DDR 访问。
- 降低无线重传。

### 3.2 Energy

定义：  
单帧或单次推理消耗的能量。

公式：

```text
Energy_per_frame = P_avg / FPS
Energy_per_inference = P_avg * Latency_time
Energy_per_MAC = P_avg / Throughput_MACS
```

常用单位：

```text
mJ/frame
nJ/inference
pJ/MAC
```

测量方法：

- 使用实测平均功耗和 FPS 计算。
- 使用 Vivado Power 估算配合 latency 估算。

优化方向：

- 降低外部存储访问。
- 提高 pipeline utilization。
- 避免过度 unroll。
- 权重常驻片上。

## 4. 资源利用率指标

### 4.1 DSP Utilization

公式：

```text
DSP_utilization = Used_DSP / Available_DSP * 100%
```

测量方法：

- Vivado utilization report。
- HLS resource estimate 仅作早期参考，最终以 Vivado implementation 为准。

Vivado 报告：

- `report_utilization`
- `report_utilization -hierarchical`
- HLS `csynth.rpt`

优化方向：

- 降低位宽。
- 使用 DSP48 pipeline。
- 部分乘法映射到 LUT，前提是 LUT 有余量。
- channel folding 降低并行 MAC 数。

### 4.2 LUT Utilization

公式：

```text
LUT_utilization = Used_LUT / Available_LUT * 100%
```

用途：

- 衡量控制逻辑、地址逻辑、加法树、比较器、mux、解码器开销。

优化方向：

- 减少复杂控制。
- 避免过度稀疏解码。
- 使用 BRAM 而不是大量 LUTRAM。
- 约束 unroll factor。

### 4.3 FF Utilization

公式：

```text
FF_utilization = Used_FF / Available_FF * 100%
```

用途：

- 衡量 pipeline register、状态寄存器、FIFO、控制寄存器开销。

优化方向：

- 控制 pipeline depth。
- 避免无意义寄存器复制。
- 检查 HLS array partition 是否导致寄存器爆炸。

### 4.4 BRAM Utilization

公式：

```text
BRAM_utilization = Used_BRAM / Available_BRAM * 100%
```

用途：

- 权重、feature、FIFO、Ping-Pong Buffer、partial sum buffer。

优化方向：

- 权重量化。
- feature streaming。
- layer fusion。
- 合理 buffer depth。
- 避免无约束 double buffer。

## 5. 带宽与存储效率

### 5.1 Bandwidth

输入带宽：

```text
Input_BW = FPS * input_length * input_channels * input_bitwidth / 8
```

输出带宽：

```text
Output_BW = FPS * output_length * output_channels * output_bitwidth / 8
```

权重带宽：

```text
Weight_BW = FPS * weights_loaded_per_frame * weight_bitwidth / 8
```

总外部带宽：

```text
External_BW = Input_BW + Output_BW + Weight_BW + Intermediate_BW
```

AXI 理论峰值：

```text
AXI_peak_BW = AXI_data_width_bits / 8 * AXI_clock_Hz
```

实际带宽：

```text
AXI_actual_BW = bytes_transferred / transfer_time
```

测量方法：

- DMA 传输字节数 / DMA busy 时间。
- AXI Performance Monitor。
- 自定义 byte counter。
- ILA 观察 AXI valid/ready。

Vivado 报告/工具：

- AXI Performance Monitor
- Vivado ILA
- Vitis profiling
- DMA status register

优化方向：

- burst transfer。
- 连续内存布局。
- 权重常驻片上。
- 中间 activation 不落 DDR。
- AXI data width 与 DMA 宽度匹配。

### 5.2 Memory Efficiency

定义：  
有效数据传输占理论带宽或总传输的比例。

公式：

```text
Memory_efficiency = Useful_bytes / Total_transferred_bytes
Bandwidth_efficiency = Actual_BW / Peak_BW
```

Burst 效率：

```text
Burst_efficiency = payload_cycles / total_bus_cycles
```

测量方法：

- 统计 AXI burst 长度。
- 统计 valid/ready 同时为 1 的周期。
- 统计 padding、重复读取、中间写回数据量。

优化方向：

- 增大 burst length。
- 数据对齐。
- 减少小包传输。
- 使用 on-chip cache 和 sliding window。

## 6. Pipeline 与 PE 利用率

### 6.1 Pipeline Utilization

定义：  
pipeline 有效工作的周期占总周期比例。

公式：

```text
Pipeline_utilization = active_cycles / total_cycles
Stall_ratio = stall_cycles / total_cycles
```

对 HLS loop：

```text
Loop_efficiency = ideal_cycles / actual_cycles
ideal_cycles ~= trip_count * II_target
```

测量方法：

- 在 RTL 中加入 `active`、`stall`、`valid_out` counter。
- ILA 观察 `TVALID/TREADY`。
- HLS schedule 查看 II 和 pipeline stall 原因。

Vivado/HLS 报告：

- HLS Schedule Viewer。
- HLS loop analysis。
- ILA。
- 自定义性能计数器。

优化方向：

- 消除 BRAM 端口冲突。
- 增加 FIFO depth。
- 使用 dataflow。
- 平衡 stage latency。

### 6.2 PE Utilization

定义：  
PE 实际执行有效 MAC 的比例。

公式：

```text
PE_utilization = valid_MAC_cycles / (num_PEs * total_cycles)
```

如果按操作数计算：

```text
PE_utilization = actual_MACs / (num_PEs * total_cycles)
```

测量方法：

- 每个 PE 统计 `mac_valid`。
- 汇总有效 MAC 数。
- 与理论 `num_PEs * cycles` 对比。

优化方向：

- 改善 channel folding 调度。
- 减少边界 padding 空算。
- 平衡 output channel tile。
- 避免 PE 等待 weight/feature。

## 7. 时序指标

### 7.1 Clock Frequency

公式：

```text
Fmax ~= 1 / critical_path_delay
```

Vivado 关键指标：

```text
WNS >= 0
TNS = 0
WHS >= 0
```

报告：

- `report_timing_summary`
- `report_timing`
- `report_clock_utilization`

优化方向：

- pipeline critical path。
- 拆分加法树。
- 使用 DSP pipeline register。
- 减少高 fanout 控制信号。
- 合理 floorplanning。

## 8. 推荐 Vivado / Vitis 报告清单

HLS 阶段：

```text
csynth.rpt
cosim report
Schedule Viewer
Dataflow Viewer
Loop analysis
Resource estimate
```

Vivado 综合后：

```text
report_utilization
report_utilization -hierarchical
report_timing_summary
report_clock_utilization
report_drc
```

Vivado 实现后：

```text
report_utilization -hierarchical
report_timing_summary
report_route_status
report_power
report_methodology
```

硬件实测：

```text
ILA waveform
AXI Performance Monitor
cycle counter
frame counter
DMA status
board-level power measurement
```

## 9. 优化优先级

### P0：必须先保证正确和可测

- 建立 golden model。
- 建立 cycle counter、frame counter、stall counter。
- 固定输入输出数据格式。
- 完成定点精度验证。

### P1：优先优化端到端瓶颈

- 如果 `cnn_compute_time` 最大：优化 pipeline、unroll、PE array。
- 如果 `dma_input_time` 最大：优化 burst、Ping-Pong、AXI width。
- 如果 `wireless_tx_time` 最大：减少包大小、降低 ACK 频率、使用 SPI/UDP。
- 如果 `PS overhead` 最大：减少 polling，改为 interrupt 和硬件调度。

### P2：资源受限时优化

- DSP 超限：降低并行度、channel folding、定点位宽优化。
- LUT 超限：减少复杂控制、避免非结构化稀疏、降低 mux 复杂度。
- FF 超限：控制 pipeline depth，避免 complete partition。
- BRAM 超限：feature streaming、weight quantization、减少 double buffer 深度。

### P3：功耗优化

- 减少 DDR 访问。
- 降低无效 PE 活动。
- 降低无线重传。
- 使用 clock enable。
- 在满足 FPS 前提下降低时钟或并行度。

## 10. 推荐评估表

每次 HLS/Vivado 迭代都记录：

| 指标 | 单位 | 来源 | 目标 |
|---|---:|---|---|
| Latency | ms | HLS/Counter/ILA | 满足实时控制 |
| FPS | frames/s | frame counter | 大于目标帧率 |
| Throughput | GOPS | MACs * FPS | 越高越好 |
| Power | W | report_power/实测 | 不超电源/散热 |
| Energy | mJ/frame | Power/FPS | 越低越好 |
| DSP util | % | report_utilization | 留 10%-20% 余量 |
| LUT util | % | report_utilization | 留 20% 以上余量 |
| FF util | % | report_utilization | 留足时序余量 |
| BRAM util | % | report_utilization | 留给 FIFO/debug |
| AXI BW | MB/s | APM/DMA counter | 小于峰值 60%-70% |
| Pipeline util | % | counter/ILA | 越高越好 |
| PE util | % | mac_valid counter | 越高越好 |
| WNS | ns | timing summary | >= 0 |

## 11. 最终建议

第一版部署时必须加入性能计数器，否则只能依赖 HLS 估算，无法定位真实瓶颈。

最小计数器集合：

```text
cycle_counter
frame_counter
cnn_active_cycles
cnn_stall_cycles
dma_busy_cycles
stream_valid_ready_cycles
pe_mac_valid_count
tx_packet_count
retry_count
drop_count
```

实际优化顺序应遵循：

```text
先测量 -> 找最大瓶颈 -> 只优化最大瓶颈 -> 重新测量
```

不要只追求高 GOPS。对手势识别系统，端到端 latency、稳定 FPS、功耗和无线链路稳定性同样重要。
