# Vivado 2022.2、Vitis与ILA上板操作指南

日期：2026-07-21

适用工程：

```text
Vivado工程：emg_gesture_vivado
Block Design：emg_finger
综合顶层：emg_finger_wrapper
器件：xczu7ev-ffvc1156-1-i
PS：Zynq UltraScale+ MPSoC
软件目标：A53 standalone bare-metal
```

本文分为两部分：

```text
第一部分：解决“Vitis IDE launch failed”和只有Vitis HLS的问题。
第二部分：拿到bitstream后，使用Vitis PS程序和Vivado ILA完成上板验证。
```

---

## 1. 当前问题的直接结论

如果 Windows 开始菜单中只有：

```text
Vitis HLS 2022.2
```

而没有：

```text
Vitis 2022.2
```

并且 Vivado 中：

```text
Tools -> Launch Vitis IDE
```

提示：

```text
Vitis IDE launch failed
```

最可能的原因是：

```text
当前只安装了Vivado和Vitis HLS，
没有安装完整的Vitis Embedded Development环境。
```

`Vitis HLS 2022.2` 的用途是：

```text
C/C++算法 -> RTL/IP
```

它不是用于以下工作的 Embedded IDE：

```text
从XSA创建platform
创建standalone BSP/domain
创建A53 bare-metal application
生成xparameters.h
使用XAxiDma/XScuGic驱动
下载ELF到ZynqMP PS
调试PS端main.c
```

因此在 Vitis HLS 中找不到 Application Project、Platform Project 和 Launch on Hardware 是正常现象。

---

## 2. 先确认完整Vitis是否存在

### 2.1 检查安装目录

在 Windows 文件资源管理器中检查：

```text
C:\Xilinx\Vitis\2022.2\bin\vitis.bat
```

如果工具安装在其他盘，也检查：

```text
D:\Xilinx\Vitis\2022.2\bin\vitis.bat
```

完整 Vitis 应包含：

```text
Vitis\2022.2\bin\vitis.bat
```

Vitis HLS 通常包含：

```text
Vitis_HLS\2022.2\bin\vitis_hls.bat
```

二者不是同一个程序。

### 2.2 使用CMD检查

打开普通 Windows CMD，执行：

```bat
where vitis
where vitis.bat
where vitis_hls
where vitis_hls.bat
```

再检查环境变量：

```bat
echo %XILINX_VITIS%
echo %XILINX_VIVADO%
```

判断方法：

```text
能够找到vitis.bat：完整Vitis可能已经安装，进入第4节排查启动问题。

只能找到vitis_hls.bat：没有完整Vitis，进入第3节补充安装。

两个都找不到：安装不完整或环境变量没有加载。
```

### 2.3 检查开始菜单

完整安装后，Windows 开始菜单中通常应存在类似入口：

```text
Xilinx Design Tools 2022.2
  Vitis 2022.2
  Vitis HLS 2022.2
  Vivado 2022.2
  Xilinx Design Tools Command Prompt 2022.2
```

如果只有 Vivado 和 Vitis HLS，基本可以确定 Embedded Vitis 没有安装。

---

## 3. 没有完整Vitis时的处理

### 3.1 不需要卸载当前Vivado

不建议直接卸载 Vivado 2022.2。

应重新运行 AMD/Xilinx 2022.2 Unified Installer，对现有安装执行：

```text
Modify Installation
```

或：

```text
Add Design Tools or Devices
```

不同安装器界面文字可能略有差异。

### 3.2 需要安装的组件

至少选择：

```text
Vitis
Vitis Embedded Development
Zynq UltraScale+ MPSoC device support
ARM A53/AArch64 standalone toolchain
Cable Drivers
```

可以保留已经安装的：

```text
Vivado
Vitis HLS
xczu7ev器件支持
```

安装器中如果只有产品级选择，选择完整的：

```text
Vitis Unified Software Platform
```

不要只选：

```text
Vitis HLS
```

### 3.3 版本必须一致

建议保持：

```text
Vivado 2022.2
Vitis 2022.2
```

不要使用：

```text
Vivado 2022.2 + Vitis 2023.x
Vivado 2022.2 + Vitis 2024.x
```

因为当前 XSA、BSP、驱动和 launch flow 都应使用同版本工具。

### 3.4 安装完成后的验证

确认文件存在：

```text
C:\Xilinx\Vitis\2022.2\bin\vitis.bat
```

然后从 Windows CMD 执行：

```bat
call C:\Xilinx\Vitis\2022.2\settings64.bat
vitis -version
```

再尝试启动：

```bat
vitis -workspace D:\VitisWS\emg_finger
```

如果安装在其他盘，应替换路径。

---

## 4. vitis.bat存在但Vivado仍启动失败

如果：

```text
Vitis\2022.2\bin\vitis.bat存在
```

但 Vivado 仍显示：

```text
Vitis IDE launch failed
```

按以下顺序排查。

### 4.1 从命令行直接启动

打开：

```text
Xilinx Design Tools Command Prompt 2022.2
```

执行：

```bat
vitis -workspace D:\VitisWS\emg_finger
```

如果命令行能启动，说明 Vitis 本体正常，问题主要在 Vivado 启动环境或 workspace。

### 4.2 使用简单ASCII workspace

不要先使用包含中文、空格或过长路径的 workspace。

推荐：

```text
D:\VitisWS\emg_finger
```

不推荐第一版使用：

```text
C:\Users\中文用户名\Documents\实习工程\Vitis 工作区
```

Vitis 2022.2 基于 Eclipse，workspace metadata 对路径和异常退出较敏感。

### 4.3 workspace metadata损坏

如果某个 workspace 启动失败，但新的空 workspace 能启动，可能是：

```text
.metadata损坏
```

处理方式：

```text
1. 关闭Vitis。
2. 备份原workspace。
3. 将原workspace中的.metadata重命名为.metadata_backup。
4. 重新启动Vitis并重新import工程。
```

不要删除 application 的 `src/` 源文件。

### 4.4 检查环境变量

在 Xilinx Design Tools Command Prompt 中执行：

```bat
echo %XILINX_VITIS%
echo %XILINX_VIVADO%
where vitis.bat
```

期望类似：

```text
XILINX_VITIS=C:\Xilinx\Vitis\2022.2
XILINX_VIVADO=C:\Xilinx\Vivado\2022.2
```

如果 `XILINX_VITIS` 指向旧版本、已删除目录或 Vitis HLS，需要修正安装或启动环境。

### 4.5 检查日志

Vitis workspace 日志通常位于：

```text
<workspace>\.metadata\.log
```

如果 Vitis 闪退或启动失败，优先检查其中的：

```text
Java exception
workspace lock
plugin load failure
permission denied
path not found
```

### 4.6 Vivado中重新启动

完整 Vitis 能手动启动后，再打开 Vivado 2022.2：

```text
Tools -> Launch Vitis IDE
```

如果该菜单仍失败，不影响后续工作。可以始终手动启动完整 Vitis，然后选择同一个 XSA。

---

## 5. 上板前需要的Vivado产物

Generate Bitstream 后至少需要：

```text
emg_finger_wrapper.bit
对应的debug probes文件.ltx
emg_finger.xsa
```

`.bit` 和 `.ltx` 必须来自同一次 implementation/bitstream。

不能混用：

```text
新.bit + 旧.ltx
旧.bit + 新.ltx
```

否则可能出现：

```text
ILA UUID mismatch
找不到debug core
probe不匹配
```

---

## 6. Vivado导出包含bitstream的XSA

在 Vivado 2022.2 中：

```text
File
  -> Export
  -> Export Hardware
```

选择：

```text
Fixed hardware platform
Include bitstream
```

建议输出：

```text
D:\Intership\hardware_export\emg_finger.xsa
```

如果已经导出过旧 XSA，在寄存器映射、AXI IP 或 bitstream 更新后应重新导出。

---

## 7. 使用完整Vitis 2022.2创建PS工程

### 7.1 Workspace

建议：

```text
D:\VitisWS\emg_finger
```

### 7.2 创建Application Project

Vitis：

```text
File
  -> New
  -> Application Project
```

选择：

```text
Create a new platform from hardware (XSA)
```

XSA：

```text
D:\Intership\hardware_export\emg_finger.xsa
```

配置：

```text
Application Name = emg_finger_baremetal
Processor        = psu_cortexa53_0
Operating System = standalone
Architecture     = 64-bit
Template         = Empty Application
```

如果向导不能直接创建 platform，先执行：

```text
File -> New -> Platform Project
```

从 XSA 创建：

```text
emg_finger_platform
```

然后再创建 Application Project。

### 7.3 PS代码写在哪里

主程序：

```text
emg_finger_baremetal/src/main.c
```

后续推荐结构：

```text
emg_finger_baremetal/src/
  main.c
  emg_accelerator.c
  emg_accelerator.h
  emg_testdata.c
  emg_testdata.h
```

PS 软件不要放在：

```text
emg_gesture_vivado/src
ip_repo
```

### 7.4 Linker Script

检查：

```text
lscript.ld
```

确认程序和输入 buffer 主要映射到：

```text
psu_ddr_0_MEM_0
```

不要让1740-byte输入和较大测试数组全部放入OCM。

---

## 8. 当前硬件地址和寄存器

Block Design 地址：

```text
AXI DMA          = 0x8000_0000
EMG Accelerator  = 0x8001_0000
```

软件优先使用 `xparameters.h` 自动生成的宏，不要直接硬编码。

Accelerator寄存器：

| Offset | Name |
| ---: | --- |
| `0x00` | COMMAND |
| `0x04` | STATUS |
| `0x08` | RESULT |
| `0x0C` | FRAME_INFO |
| `0x10` | RX_STATUS |
| `0x14` | ERROR_STATUS |
| `0x18` | CYCLE_COUNT |
| `0x1C` | VERSION |
| `0x20` | CONFIG |

预期：

```text
VERSION    = 0x0001_0001
FRAME_INFO = 0x06CC_01B3
```

其中：

```text
0x06CC = 1740 bytes
0x01B3 = 435 beats
```

---

## 9. 第一版PS程序推荐流程

第一版先使用：

```text
单帧
轮询
手动START
IRQ关闭
AUTO_START关闭
```

程序顺序：

```text
1. 初始化UART。
2. 初始化AXI DMA。
3. 检查DMA不是Scatter-Gather模式。
4. 读取VERSION。
5. 读取FRAME_INFO。
6. 写COMMAND清DONE和ERROR。
7. 准备1740-byte case0输入。
8. 执行Xil_DCacheFlushRange。
9. 启动DMA MM2S 1740 bytes。
10. 等待DMA完成。
11. 检查FRAME_READY和ERROR_STATUS。
12. 写COMMAND.START。
13. 等待STATUS.DONE。
14. 读取RESULT和CYCLE_COUNT。
15. 打印结果。
16. 写COMMAND.CLEAR_DONE。
```

case0预期：

```text
RESULT      = 3
CYCLE_COUNT = 40527附近
ERROR_STATUS = 0
```

---

## 10. PS程序常用头文件

轮询版本：

```c
#include "xparameters.h"
#include "xaxidma.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xstatus.h"
#include "sleep.h"
```

中断版本后续加入：

```c
#include "xscugic.h"
#include "xil_exception.h"
```

---

## 11. 输入数据和Cache

第一版可以定义：

```c
static int8_t input_frame[1740] __attribute__((aligned(64)));
```

输入格式必须为 channel-major：

```text
ch0[0..347]
ch1[0..347]
ch2[0..347]
ch3[0..347]
ch4[0..347]
```

DMA启动前：

```c
Xil_DCacheFlushRange((UINTPTR)input_frame, 1740);
```

当前 DMA 通过 HP0 从 DDR 读取，不是 cache coherent 路径。

如果不 flush，可能出现：

```text
DMA完成
Accelerator完成
ERROR_STATUS为0
但分类结果错误
```

---

## 12. Vitis下载和调试PS程序

### 12.1 Build

右键 application：

```text
Build Project
```

确认生成：

```text
emg_finger_baremetal.elf
```

### 12.2 设置断点

在第一版 `main.c` 中，把断点设置在：

```text
Xil_DCacheFlushRange之后
XAxiDma_SimpleTransfer之前
```

这样可以先让 PS、DDR、UART 和 PL clock 完成初始化，再去 Vivado arm ILA。

### 12.3 Launch on Hardware

右键 application：

```text
Debug As
  -> Launch on Hardware (Single Application Debug)
```

或：

```text
Run
  -> Debug Configurations
  -> Single Application Debug
```

第一次可以选择：

```text
Program FPGA
Reset processor/system
Stop at main
```

Vitis 会执行 ZynqMP PS initialization、配置 DDR，并下载 ELF 到 A53。

---

## 13. Vivado Hardware Manager连接开发板

### 13.1 板卡连接

建议：

```text
1. 开发板断电。
2. Boot Mode设置为JTAG。
3. 连接JTAG USB。
4. 连接UART USB。
5. 开发板上电。
```

### 13.2 打开Hardware Manager

Vivado：

```text
Flow Navigator
  -> PROGRAM AND DEBUG
  -> Open Hardware Manager
```

然后：

```text
Open Target
  -> Auto Connect
```

应看到：

```text
hw_server
  -> JTAG target
     -> xczu7ev_0
```

### 13.3 Program Device

右键 FPGA device：

```text
Program Device
```

设置：

```text
Bitstream file    = emg_finger_wrapper.bit
Debug probes file = 对应的.ltx
```

如果已经由 Vitis 使用 XSA 中的 bitstream 编程，可以在 Vivado 中：

```text
Refresh Device
```

并关联正确 `.ltx`。

不要在 PS 程序正在访问 DMA/accelerator 时随意重新 Program Device，因为重新配置 PL 会复位数据通路。

---

## 14. 为什么要先启动Vitis再操作ILA

当前 ILA 时钟来自：

```text
PS pl_clk0 = 100 MHz
```

因此 PS 必须完成初始化，PL clock 才能稳定工作。

推荐顺序：

```text
1. Vitis Launch on Hardware。
2. 程序停在DMA启动前断点。
3. Vivado Hardware Manager连接或Refresh Device。
4. 设置并arm ILA。
5. 回到Vitis Resume。
```

如果只在 Vivado 下载 bitstream，但没有初始化 PS，可能出现：

```text
ILA clock stopped
Run Trigger Immediate不返回
ILA一直Waiting
```

---

## 15. 当前ILA探针

| Probe | 信号 | 含义 |
| --- | --- | --- |
| `probe0[2:0]` | `class_id` | 分类结果 |
| `probe1` | `class_valid` | 分类结果有效脉冲 |
| `probe2` | `inference_done` | 推理完成脉冲 |
| `probe3` | `inference_busy` | 推理运行状态 |
| `probe4` | `accelerator_irq` | Accelerator完成中断 |
| `probe5` | `dma_irq` | DMA MM2S完成中断 |

配置：

```text
Data Depth = 4096
Clock      = 100 MHz
```

采样时间窗口：

```text
4096 / 100 MHz = 40.96 us
```

单帧推理约：

```text
40527 / 100 MHz = 405.27 us
```

因此当前 ILA 不能一次捕获完整推理，需要分多次触发。

---

## 16. 第一次测试ILA是否正常

进入 ILA Dashboard 后点击：

```text
Run Trigger Immediate
```

如果能马上完成并显示波形，说明：

```text
.bit/.ltx匹配
ILA debug core存在
pl_clk0工作
JTAG连接正常
```

如果 Immediate 都不返回，先检查：

```text
PS是否初始化
PL clock是否工作
reset是否释放
.bit/.ltx是否匹配
device是否需要Refresh
```

---

## 17. ILA测试1：DMA完成

Basic Trigger Setup：

```text
probe5 == 1
```

建议：

```text
Trigger Position = 2048
```

点击：

```text
Run Trigger
```

确认状态：

```text
Waiting for Trigger
```

回到 Vitis，Resume 程序，执行 DMA。

预期：

```text
probe5出现DMA IRQ脉冲
```

PS软件同时检查：

```text
DMA status
STATUS.FRAME_READY
RX_STATUS
ERROR_STATUS
```

DMA IRQ 只代表 MM2S 事务结束，不代表推理完成。

---

## 18. ILA测试2：Accelerator开始计算

重新设置：

```text
probe3 == 1
```

点击：

```text
Run Trigger
```

然后在 PS 软件中写：

```text
COMMAND.START
```

预期：

```text
probe3/inference_busy从0变1
```

如果 DMA 已完成但 busy 不变，检查：

```text
STATUS.FRAME_READY
ERROR_STATUS
START是否写到0x00 COMMAND
STATUS.BUSY是否原来已经为1
是否错误使用昨天旧版CONTROL常量
```

---

## 19. ILA测试3：分类结果

设置：

```text
probe1 == 1
```

即：

```text
class_valid == 1
```

点击 Run Trigger，然后重新执行完整单帧测试。

case0预期：

```text
probe0/class_id       = 3
probe1/class_valid    = 1个周期脉冲
probe2/inference_done = 完成脉冲
probe3/inference_busy = 随后回到0
```

如果：

```text
CONFIG.IRQ_ENABLE = 1
```

完成后还应观察：

```text
probe4/accelerator_irq = 1
```

该 IRQ 会保持到软件写：

```text
COMMAND.CLEAR_DONE
```

---

## 20. ILA波形查看

触发后：

```text
1. 找到Trigger Marker。
2. probe0 radix设置为Unsigned Decimal。
3. 其他probe设置为Binary。
4. 点击Zoom Fit。
5. 检查trigger附近的class_valid、done、busy和irq。
```

需要保存时导出：

```text
CSV
VCD
Native ILA Data
```

---

## 21. 使用当前ILA间接验证Ping-Pong

当前 ILA 没有直接观察：

```text
activation_load_bank
activation_read_bank
frame_ready
act_wr_ready
S_AXIS_TREADY
```

但可以间接验证第二帧在第一帧计算期间完成DMA。

软件设置：

```text
CONFIG.AUTO_START = 1
CONFIG.IRQ_ENABLE = 1
```

运行：

```text
1. DMA发送case0。
2. case0自动开始计算。
3. case0 busy期间，软件启动DMA发送case1。
```

ILA触发：

```text
probe5 == 1
```

检查触发时：

```text
probe3/inference_busy == 1
probe5/dma_irq == 1
```

如果成立，说明：

```text
第一帧正在计算
第二帧DMA已经完成
第二帧进入了另一个activation bank
```

由于 ILA 窗口只有40.96 us，而推理约405.27 us，需要多次触发，不能一次看到完整两帧过程。

---

## 22. 推荐上板测试顺序

### 阶段1：PS基础

```text
Hello World
UART
DDR
Vitis下载和断点
```

### 阶段2：寄存器读取

```text
VERSION = 0x00010001
FRAME_INFO = 0x06CC01B3
```

### 阶段3：单帧DMA

```text
probe5触发
DMA完成
FRAME_READY=1
ERROR_STATUS=0
```

### 阶段4：手动START

```text
probe3触发
busy进入1
```

### 阶段5：分类结果

```text
probe1触发
class_id=3
CYCLE_COUNT约40527
```

### 阶段6：中断

```text
DMA IRQ
Accelerator IRQ
CLEAR_DONE撤销IRQ
```

### 阶段7：两帧Ping-Pong

```text
case0计算时发送case1
检查dma_irq出现时busy仍为1
```

### 阶段8：十帧连续运行

```text
AUTO_START
逐帧DMA提交
保存10个RESULT
检查10组golden class
```

---

## 23. 常见问题

### 23.1 Vivado显示Vitis IDE launch failed

```text
先检查Vitis\2022.2\bin\vitis.bat。

不存在：补充安装完整Vitis Embedded Development。

存在：使用Xilinx Command Prompt手动启动，检查workspace和.metadata日志。
```

### 23.2 只有Vitis HLS

```text
Vitis HLS不能创建A53 bare-metal工程。
必须安装完整Vitis 2022.2。
```

### 23.3 Hardware Manager看不到ILA

```text
检查bit/ltx匹配。
运行Vitis初始化PS和PL clock。
Refresh Device。
检查是否使用当前bitstream。
```

### 23.4 ILA一直Waiting

先测试：

```text
Run Trigger Immediate
```

Immediate也不完成：检查clock和reset。

Immediate能完成：检查trigger条件和PS程序运行位置。

### 23.5 程序太快来不及arm ILA

```text
在XAxiDma_SimpleTransfer之前设置断点。
Vitis运行到断点。
Vivado点击Run Trigger。
确认Waiting for Trigger。
回Vitis Resume。
```

### 23.6 Vivado和Vitis争用JTAG

二者尽量连接同一个本地：

```text
hw_server
localhost:3121
```

不要反复启动多个 hw_server。

如果 Vitis 已经编程 FPGA，Vivado 一般只需要连接、Refresh Device 和关联 `.ltx`。

---

## 24. 当前最优先动作

根据当前“只有 Vitis HLS 2022.2”的现象，优先级为：

```text
P0. 检查C:\Xilinx\Vitis\2022.2\bin\vitis.bat是否存在。

P1. 如果不存在，使用2022.2 Unified Installer补充安装完整Vitis Embedded Development。

P2. 使用Xilinx Design Tools Command Prompt执行vitis -version。

P3. 使用简单ASCII workspace手动启动完整Vitis。

P4. Vivado生成bitstream并导出包含bitstream的XSA。

P5. 在完整Vitis中创建psu_cortexa53_0 standalone 64-bit应用。

P6. 先完成单帧轮询和ILA三阶段验证。

P7. 再做中断、两帧ping-pong和十帧连续测试。
```

---

## 25. 官方文档索引

建议使用与工具版本一致的官方文档：

```text
UG1400：Vitis Unified Software Platform Documentation 2022.2
UG908：Vivado Programming and Debugging 2022.2
UG973：Vivado Design Suite Release Notes, Installation and Licensing 2022.2
UG1085：Zynq UltraScale+ Device Technical Reference Manual
PG021：AXI DMA Product Guide
```

优先查看章节：

```text
Vivado Export Hardware/XSA
Creating a Platform Project from XSA
Creating a Standalone Application
Launch on Hardware/Single Application Debug
Hardware Manager Program Device
ILA Basic Trigger and Waveform
```
