# Vivado、Vitis 与 ILA 简化上板测试步骤

日期：2026-07-23  
适用环境：Vivado/Vitis 2022.2、ALINX AXU9EG、`emg_finger` 工程

## 1. 本次测试目标

验证以下完整数据通路：

```text
PS DDR
  → AXI DMA MM2S
  → accelerator AXI-Stream输入
  → accelerator完成推理
  → PS读取分类结果
```

预期结果：

```text
分类类别 = 3
推理周期 ≈ 40527
串口打印 PASS
```

## 2. 当前使用的文件

Vivado bitstream：

```text
D:\Intership\emg_gesture_vivado\emg_gesture_vivado.runs\impl_1\emg_finger_wrapper.bit
```

Vivado ILA probes：

```text
D:\Intership\emg_gesture_vivado\emg_gesture_vivado.runs\impl_1\emg_finger_wrapper.ltx
```

Vitis ELF：

```text
D:\Intership\emg_gesture_vitis\emg_finger\emg_finger_baremetal\Debug\emg_finger_baremetal.elf
```

Vitis workspace：

```text
D:\Intership\emg_gesture_vitis\emg_finger
```

## 3. 连接开发板

先关闭开发板电源，然后：

```text
1. 将开发板启动模式设置为 JTAG Boot。
2. 连接 JTAG USB。
3. 连接 J10 PS UART Mini USB。
4. 打开开发板电源。
```

在 Windows 设备管理器中确认出现 CP210x 串口。

## 4. 打开串口助手

可以使用：

```text
C:\Users\邵卿宇\Desktop\程序 串口调式助手.exe
```

串口设置：

```text
COM端口：设备管理器中的 CP210x COM端口
波特率：115200
数据位：8
停止位：1
校验位：None
流控：None
接收模式：ASCII/文本
```

点击打开串口。此时暂时没有输出是正常的。

## 5. 使用 Vivado 配置 FPGA

在 Vivado 中进入：

```text
Open Hardware Manager
  → Open Target
  → Auto Connect
```

识别到 `xczu9eg` 后，右键 FPGA 器件选择：

```text
Program Device
```

设置：

```text
Bitstream file    = emg_finger_wrapper.bit
Debug probes file = emg_finger_wrapper.ltx
```

点击 `Program`。

这一步配置 FPGA/PL。当前不需要在 Vitis 中再次烧录 FPGA。

## 6. 在 Vitis 中设置断点

打开：

```text
emg_finger_baremetal
  → src
  → main.c
```

在第 92 行设置断点：

```c
XAxiDma_SimpleTransfer(
```

断点位置：

```text
emg_finger_baremetal/src/main.c:92
```

程序停在这里时：

```text
PS和DDR已经初始化
DMA已经初始化
测试数据已经放入DDR缓冲区
D-cache已经Flush
DMA尚未开始传输
```

## 7. 在 Vitis 中启动 PS 程序

右键：

```text
emg_finger_baremetal
```

选择：

```text
Debug As
  → Launch on Hardware (Single Application Debug)
```

目标处理器应为：

```text
psu_cortexa53_0
```

应用 ELF 应为：

```text
emg_finger_baremetal/Debug/emg_finger_baremetal.elf
```

如果 Debug 配置中存在 `Program FPGA` 选项，因为 FPGA 已经由 Vivado配置，所以取消勾选该选项。

Vitis 仍需要完成：

```text
PS初始化
DDR初始化
下载ELF
运行C程序
```

启动 Debug 后，程序应停在 `main.c:92`。

## 8. 检查断点前的串口输出

程序到达断点前，串口应出现类似内容：

```text
========================================
EMG accelerator single-frame board test
========================================
Accelerator VERSION    = 0x00010001
Accelerator FRAME_INFO = 0x06CC01B3

Arm ILA now; DMA transfer starts next.
DMA source = 0x........, bytes = 1740
```

看到这些内容说明：

```text
PS程序已经运行
UART0工作正常
DDR基本可用
accelerator AXI-Lite寄存器可以读取
```

此时先不要在 Vitis 中点击 `Resume`。

## 9. 设置 ILA 触发条件

切换到 Vivado 的 Hardware Manager，打开 ILA Dashboard。

ILA 中的 probe：

```text
probe0[2:0] = class_id
probe1      = class_valid
probe2      = inference_done
probe3      = inference_busy
probe4      = accelerator_irq
probe5      = dma_irq
```

第一次测试只需要设置：

```text
probe1 == 1
```

`probe1` 对应 `class_valid`，表示 accelerator 已经产生有效分类结果。

在 ILA Trigger Setup 中：

```text
1. 找到 probe1。
2. 比较条件选择 ==。
3. 比较值填写 1。
4. 点击 Run Trigger。
5. 确认状态显示 Waiting for Trigger。
```

这里不是手动修改 `class_valid`，也不是手动控制 accelerator。

设置触发条件的含义只是：

> 当硬件中的 `class_valid` 自己变为 1 时，ILA 自动保存这一段波形。

## 10. 让程序继续运行

确认 ILA 显示：

```text
Waiting for Trigger
```

然后切换回 Vitis，点击：

```text
Resume
```

程序会自动执行：

```text
DDR读取测试数据
  → DMA发送1740字节
  → accelerator接收435个32-bit AXIS beat
  → 软件等待FRAME_READY
  → 软件写COMMAND.START
  → accelerator执行推理
  → 软件读取RESULT和CYCLE_COUNT
```

不需要在 ILA 中手动修改任何硬件信号，也不需要手动写 accelerator 寄存器。

## 11. 检查串口结果

正常情况下，串口应继续输出：

```text
DMA MM2S completed
Frame ready; starting accelerator
PASS: case0 class=3 cycles=40527
Board test completed successfully
```

需要重点确认：

```text
VERSION      = 0x00010001
FRAME_INFO   = 0x06CC01B3
DMA完成
FRAME_READY有效
ERROR_STATUS = 0
RESULT       = 3
CYCLE_COUNT  ≈ 40527
最终打印PASS
```

## 12. 检查 ILA 波形

ILA 触发后检查：

```text
probe0 / class_id       = 3
probe1 / class_valid    = 1
probe2 / inference_done = 1或在附近出现完成脉冲
probe3 / inference_busy = 推理结束后回到0
```

建议显示格式：

```text
probe0：Unsigned Decimal
其他probe：Binary
```

当前软件使用轮询模式，并关闭了 DMA 和 accelerator 软件中断，因此：

```text
probe4 / accelerator_irq
probe5 / dma_irq
```

可能一直为 0。这不表示 DMA 或 accelerator 没有工作。

## 13. 最简操作顺序

```text
1. 板卡设置JTAG Boot，连接JTAG和J10 UART。
2. 打开串口助手，设置115200、8N1。
3. Vivado Program Device，选择.bit和.ltx。
4. Vitis在main.c第92行设置断点。
5. Vitis Launch on Hardware，程序停在断点。
6. Vivado ILA设置probe1 == 1。
7. 点击Run Trigger，等待Waiting for Trigger。
8. 回到Vitis点击Resume。
9. 串口检查是否打印PASS。
10. ILA检查class_id是否为3。
```

## 14. 常见问题

### 14.1 串口没有输出

检查：

```text
是否连接J10 PS UART
COM端口是否正确
波特率是否为115200
串口是否已经打开
Vitis是否完成PS初始化并运行ELF
程序是否停在main.c第92行
```

### 14.2 ILA中没有probe

检查：

```text
Program Device时是否选择正确.ltx
.bit和.ltx是否来自同一次Vivado构建
是否在Hardware Manager中Refresh Device
```

### 14.3 ILA一直Waiting for Trigger

检查：

```text
Vitis是否已经点击Resume
触发条件是否为probe1 == 1
串口是否出现DMA或accelerator错误
程序是否仍停在断点
```

### 14.4 串口打印PASS但ILA没有触发

优先检查 `.ltx` 是否与当前下载的 `.bit` 匹配，并确认 `probe1` 的比较条件确实设置为 `== 1`。

## 15. 测试通过标准

同时满足以下条件，即可认为第一阶段真实上板测试通过：

```text
1. UART0能够正常打印。
2. Accelerator VERSION和FRAME_INFO正确。
3. DMA MM2S传输完成。
4. Accelerator收到完整输入帧。
5. ERROR_STATUS为0。
6. RESULT等于3。
7. CYCLE_COUNT接近40527。
8. 串口打印PASS。
9. ILA捕获class_valid，且class_id等于3。
```
