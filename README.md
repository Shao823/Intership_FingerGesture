# EMG Gesture FPGA Accelerator

基于 Zynq UltraScale+ MPSoC 的 INT8 LightCNN1D EMG 手势识别加速系统。工程包含可打包的自定义 AXI accelerator IP、Vivado Block Design、Vitis A53 bare-metal 测试程序、量化权重和 RTL 仿真源码。

## 当前状态

- 输入：5 通道 × 348 点 signed INT8 EMG 数据。
- 网络：Stem、DW1、PW1、MaxPool、DW2、PW2、GAP、FC0、FC1、Argmax。
- 数据路径：DDR → AXI DMA MM2S → AXI4-Stream → accelerator。
- 控制路径：A53 → AXI4-Lite → DMA/accelerator 寄存器。
- 输入缓存：accelerator 内部双 BRAM Ping-Pong。
- 调度：DMA 中断、accelerator 中断和 `AUTO_START`。
- 时钟：PL 约 100 MHz。
- 单帧计算：40527 cycles，约 405.27 µs。
- 真实板卡连续10帧测试：`PASS`。

已验证的10帧分类结果：

```text
3, 3, 4, 3, 3, 4, 1, 3, 2, 3
```

## 仓库结构

```text
ip_repo/emg_accelerator_1_0/
    当前可打包的 AXI accelerator IP、RTL、BRAM IP 和寄存器说明

emg_gesture_vivado/
    Vivado 2022.2 主工程、手写 RTL、主 Block Design 和约束

emg_gesture_vitis/emg_finger/
    Vitis 2022.2 A53 bare-metal 工程和 PS 端测试源码

weight_data/
    INT8 权重、INT32 bias、Q15 multiplier、right shift 和 ROM 初始化文件
```

本地工作日志、研究资料、截图、生成报告、bitstream、XSA、ELF 和 Vivado/Vitis 缓存不纳入远程仓库。

## 主要硬件接口

### 输入帧

```text
Tensor layout : channel-major [5][348]
Frame bytes   : 1740
AXIS width    : 32 bits
Frame beats   : 435
TKEEP         : 4'b1111
TLAST         : beat 434
```

每个 AXI4-Stream beat 打包同一通道的4个连续 INT8 时间样本：

```text
TDATA[7:0]   = sample[t+0]
TDATA[15:8]  = sample[t+1]
TDATA[23:16] = sample[t+2]
TDATA[31:24] = sample[t+3]
```

### AXI4-Lite 地址

当前 BSP 地址：

```text
AXI DMA      : 0x80000000
Accelerator  : 0x80010000
```

Accelerator 主要寄存器：

| Offset | Register | 作用 |
|---:|---|---|
| `0x00` | COMMAND | START、CLEAR_DONE、CLEAR_ERRORS |
| `0x04` | STATUS | BUSY、DONE、FRAME_READY、IRQ 和错误汇总 |
| `0x08` | RESULT | 最近一次分类结果 |
| `0x0C` | FRAME_INFO | 435 beats / 1740 bytes |
| `0x10` | RX_STATUS | beat count / frame count |
| `0x14` | ERROR_STATUS | TLAST、TKEEP、丢帧和启动错误 |
| `0x18` | CYCLE_COUNT | 最近一次推理周期数 |
| `0x1C` | VERSION | 当前版本 `0x00010001` |
| `0x20` | CONFIG | AUTO_START、IRQ_ENABLE |

完整位定义参见：

```text
ip_repo/emg_accelerator_1_0/REGISTER_MAP.md
```

## 环境要求

- Vivado 2022.2。
- Vitis 2022.2，包含完整 Embedded Software Development 支持。
- 与工程配置匹配的 Zynq UltraScale+ MPSoC 开发板。
- JTAG 下载器。
- 可选 USB-UART，串口参数为 `115200 8N1`。
- 可选 Icarus Verilog，用于运行 RTL 回归脚本。

## 快速开始

### 1. 打开 Vivado 工程

使用 Vivado 2022.2 打开：

```text
emg_gesture_vivado/emg_gesture_vivado.xpr
```

如果 IP Catalog 没有自动识别自定义 IP，在：

```text
Tools → Settings → IP → Repository
```

加入：

```text
ip_repo
```

随后执行：

1. 打开 `emg_finger` Block Design。
2. `Validate Design`。
3. 必要时重新生成 IP Output Products。
4. 运行 Synthesis。
5. 运行 Implementation。
6. 生成 Bitstream。

### 2. 导出硬件平台

在 Vivado 中导出包含 bitstream 的 XSA：

```text
File → Export → Export Hardware
```

### 3. 打开或重建 Vitis 工程

现有软件工程位于：

```text
emg_gesture_vitis/emg_finger/
```

如果硬件 XSA 已更新，应在 Vitis 2022.2 中更新或重新创建平台，然后确认应用目标为：

```text
psu_cortexa53_0
standalone
64-bit
```

PS 应用源码：

```text
emg_gesture_vitis/emg_finger/emg_finger_baremetal/src/
```

### 4. 上板运行

1. 连接板卡电源和 JTAG。
2. 可选连接 USB-UART，并打开 `115200 8N1` 串口终端。
3. 在 Vivado Hardware Manager 中 Program Device。
4. 在 Vitis 中通过 `Launch on Hardware` 启动 A53 ELF。
5. 不要在 DMA 或 accelerator ISR 中逐帧停断点。
6. 等待 UART 输出最终结果。

正确输出应包含：

```text
DMA started              = 10
DMA completed            = 10
Accelerator IRQ count    = 10
Accelerator completed    = 10
Error flags              = 0x00000000
RESULT                   = PASS
```

## RTL 仿真

安装 Icarus Verilog 后，可在仓库根目录运行：

```bash
bash emg_gesture_vivado/src/run_all_sims.sh
```

AXI IP 的系统级 testbench 位于：

```text
ip_repo/emg_accelerator_1_0/src/axi_ip_tb/
```

其中包含 AXI-Lite shell、输入 Ping-Pong、mock DDR 和 mock DMA MM2S 测试。

## 注意事项

- 当前输入规格固定为5通道 × 348点；修改通道数需要同步更新模型、权重、帧长度、activation BRAM、软件常量和 bitstream。
- DMA 当前只启用 MM2S，分类结果通过 AXI4-Lite `RESULT` 读取。
- Ping-Pong 最多容纳“一帧计算 + 一帧等待”，不是任意深度输入队列。
- JTAG 断点只暂停 A53，不暂停 PL；运行流水期间停在 ISR 可能导致软硬件状态不同步。
- `bit/.ltx/.xsa/.elf` 必须来自相互匹配的硬件和软件版本。

## 许可证

本仓库当前未声明开源许可证。未经项目所有者明确授权，不应视为允许复制、分发或商用。
