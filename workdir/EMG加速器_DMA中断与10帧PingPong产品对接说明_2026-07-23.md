# EMG 加速器、DMA、中断与 10 帧 Ping-Pong 流水线产品对接说明

## 1. 文档目的

本文档用于说明当前 EMG 手势识别板级系统的软硬件接口和运行流程，供产品经理、PS 软件、PL/RTL、测试和后续驱动开发人员共同使用。

本文档对应已经在真实板卡上验证通过的配置：

```text
10 帧 DMA MM2S 连续搬运
accelerator AUTO_START
accelerator IRQ_ENABLE
DMA IOC 中断
accelerator DONE 中断
内部 activation 双 BRAM bank Ping-Pong
10 帧分类结果全部正确
Error flags = 0x00000000
RESULT = PASS
```

---

## 2. 系统总体结构

```text
PS DDR
  │
  │ AXI DMA MM2S 从 DDR 读取
  ▼
AXI DMA
  │
  │ M_AXIS_MM2S，32-bit AXI-Stream
  ▼
emg_accelerator_v1_0 / S00_AXIS
  │
  │ AXI-Stream 接收控制器
  ▼
activation bank 0 / activation bank 1
  │
  │ accelerator 内部双 BRAM Ping-Pong
  ▼
LightCNN1D 推理流水线
  │
  ├── RESULT / CYCLE_COUNT / STATUS
  ├── class_id / class_valid
  ├── inference_done / inference_busy
  └── accelerator irq
```

AXI-Lite 控制通路：

```text
psu_cortexa53_0
  │ M_AXI_HPM0_LPD
  ▼
AXI-Lite interconnect
  ├── AXI DMA 控制寄存器
  └── emg_accelerator AXI-Lite 控制寄存器
```

### 2.1 地址和中断编号

| 项目 | 地址/编号 | 说明 |
|---|---:|---|
| AXI DMA 基地址 | `0x80000000` | DMA AXI-Lite 控制寄存器基地址 |
| accelerator AXI-Lite 基地址 | `0x80010000` | 自定义 accelerator 控制寄存器基地址 |
| DDR 测试地址空间 | `0x00000000–0x7FFFFFFF` | 当前平台低地址 DDR 窗口 |
| DMA MM2S IRQ | `121` | `XPAR_FABRIC_AXI_DMA_0_MM2S_INTROUT_INTR` |
| accelerator IRQ | `136` | `XPAR_FABRIC_EMG_ACCELERATOR_0_IRQ_INTR` |
| GIC device ID | `0` | `XPAR_SCUGIC_0_DEVICE_ID` |
| PL 时钟 | 约 `100 MHz` | AXI-Lite、AXI-Stream、ILA 使用同一时钟域 |

### 2.2 当前 DMA 配置

```text
Simple DMA
Scatter-Gather disabled
MM2S enabled
S2MM disabled
MM2S stream width = 32 bit
MM2S memory width = 32 bit
TLAST enabled
TKEEP enabled
DRE disabled
```

---

## 3. 一帧数据格式

每帧输入为：

```text
5 个输入通道
348 个时间采样点
INT8 数据
```

因此：

```text
5 × 348 × 1 byte = 1740 bytes
1740 bytes / 4 bytes = 435 AXI-Stream beats
```

### 3.1 32-bit AXI-Stream beat 排列

```text
TDATA[7:0]    = t + 0
TDATA[15:8]   = t + 1
TDATA[23:16]  = t + 2
TDATA[31:24]  = t + 3
```

输入采用 channel-major 排列：一个通道的 348 个时间采样连续排列，再排列下一个通道。

| 信号 | 要求 |
|---|---|
| `TDATA` | 32 bit |
| `TKEEP` | 每个 beat 都是 `4'b1111` |
| `TLAST` | 只在第 435 个 beat，即 beat 434 有效 |
| `TVALID` | DMA 提供 |
| `TREADY` | accelerator 根据 bank 是否可写产生 |

DMA 每次传输长度必须写：

```text
1740 bytes
```

DMA 长度寄存器单位是字节，不是 beat。

---

## 4. Accelerator AXI-Lite 寄存器总览

accelerator AXI-Lite 基地址是 `0x80010000`，实际物理地址为：

```text
寄存器物理地址 = 0x80010000 + 寄存器偏移
```

| 偏移 | 名称 | 软件访问 | 作用 |
|---:|---|---|---|
| `0x00` | `COMMAND` | 写入命令 | START、清 DONE、清错误 |
| `0x04` | `STATUS` | 读取 | 运行、接收、DONE、IRQ、错误状态 |
| `0x08` | `RESULT` | 读取 | 最近一次完成的分类结果 |
| `0x0C` | `FRAME_INFO` | 读取 | 固定帧长度和 beat 数 |
| `0x10` | `RX_STATUS` | 读取 | 已接收帧数和当前 beat 数 |
| `0x14` | `ERROR_STATUS` | 读取 | AXI-Stream 和启动错误原因 |
| `0x18` | `CYCLE_COUNT` | 读取 | 最近一次推理周期数 |
| `0x1C` | `VERSION` | 读取 | accelerator IP 版本 |
| `0x20` | `CONFIG` | 读写 | AUTO_START 和 IRQ_ENABLE |
| 其他 | Reserved | 不使用 | 应保持为 0 或忽略读取值 |

---

## 5. COMMAND 寄存器：`0x00`

COMMAND 是写命令寄存器，不是持久化配置寄存器。W1P 表示 Write One to Pulse，写入 1 后只产生一个命令脉冲。

### 5.1 32 位逐位定义

| 位 | 名称 | 类型 | 含义 |
|---:|---|---|---|
| bit 0 | `START` | W1P | 如果完整帧 ready 且核心空闲，启动一次推理 |
| bit 1 | `CLEAR_DONE` | W1P | 清除 sticky DONE，并撤销 accelerator IRQ |
| bit 2 | `CLEAR_ERRORS` | W1P | 清除接收错误和启动拒绝错误 |
| bit 31:3 | Reserved | - | 应写 0 |

### 5.2 常用写入值

| 写入值 | 含义 |
|---:|---|
| `0x00000001` | 手动 START |
| `0x00000002` | 清除 DONE |
| `0x00000004` | 清除错误 |
| `0x00000006` | 同时清除 DONE 和错误 |

当前 10 帧测试先写：

```text
COMMAND = 0x00000006
```

即：

```text
CLEAR_DONE   = 1
CLEAR_ERRORS = 1
```

随后不写 `COMMAND.START`，因为使用 `AUTO_START`。

COMMAND 读回值为 0。

---

## 6. STATUS 寄存器：`0x04`

### 6.1 32 位逐位定义

| 位 | 名称 | 含义 |
|---:|---|---|
| bit 0 | `BUSY` | accelerator 正在计算一帧 |
| bit 1 | `DONE` | 推理完成 sticky 标志 |
| bit 2 | `FRAME_READY` | 已完整接收一帧，等待启动或自动启动 |
| bit 3 | `RX_ACTIVE` | AXI-Stream 正在接收或丢弃一帧 |
| bit 4 | `ACT_WRITE_READY` | 当前写入 bank 可以接收数据 |
| bit 5 | `CLASS_VALID` | 分类结果有效脉冲，通常为一个时钟周期 |
| bit 6 | `IRQ` | accelerator 当前 IRQ 输出状态 |
| bit 7 | `START_NO_FRAME` | 请求启动时没有完整帧 |
| bit 8 | `START_BUSY` | 请求启动时 accelerator 正忙 |
| bit 9 | `ERROR` | 至少有一个错误标志置位 |
| bit 31:10 | Reserved | 保持 0 或忽略 |

```text
DONE = accelerator 完成过一次推理
IRQ  = IRQ_ENABLE && done_sticky
```

`DONE` 是 sticky 状态，必须写 `COMMAND.CLEAR_DONE=1` 才能清除。

### 6.2 常见 STATUS 值

#### `0x00000011`

```text
bit 4 = ACT_WRITE_READY
bit 0 = BUSY
```

表示 accelerator 正在计算，当前写 bank 可以接受数据。

#### `0x0000001D`

```text
bit 4 = ACT_WRITE_READY
bit 3 = RX_ACTIVE
bit 2 = FRAME_READY
bit 0 = BUSY
```

表示当前帧正在计算，同时另一个 bank 正在接收或已经准备好下一帧。

#### `0x0000005B`

```text
bit 6 = IRQ
bit 4 = ACT_WRITE_READY
bit 3 = RX_ACTIVE
bit 1 = DONE
bit 0 = BUSY
```

表示一帧刚完成并产生 DONE/IRQ，同时 accelerator 已经处于下一帧流水状态。

#### `0x00000053`

```text
bit 6 = IRQ
bit 4 = ACT_WRITE_READY
bit 1 = DONE
bit 0 = BUSY
```

表示当前帧完成并产生 IRQ，下一帧已启动或正在计算，但此刻没有正在接收的 AXI-Stream 数据。

#### `0x00000052`

```text
bit 6 = IRQ
bit 4 = ACT_WRITE_READY
bit 1 = DONE
```

表示推理完成，DONE 和 IRQ 有效，当前没有 BUSY，也没有新的等待帧。最后一帧常见此状态。

---

## 7. RESULT 寄存器：`0x08`

| 位 | 含义 |
|---:|---|
| bit 2:0 | 最近一次完成推理的分类类别 |
| bit 31:3 | Reserved |

RESULT 保存的是**最近一次完成结果**，不是多深度结果 FIFO。因此软件必须在每次 accelerator IRQ 中读取并保存。

当前 10 帧期望类别：

```text
frame 0: 3
frame 1: 3
frame 2: 4
frame 3: 3
frame 4: 3
frame 5: 4
frame 6: 1
frame 7: 3
frame 8: 2
frame 9: 3
```

如果软件长时间停在断点，后续帧可能继续计算并覆盖 RESULT；逐帧断点调试不能把 RESULT 当成 FIFO。

---

## 8. FRAME_INFO 寄存器：`0x0C`

| 位 | 含义 | 当前值 |
|---:|---|---:|
| bit 15:0 | 期望 AXI-Stream beat 数 | `435` |
| bit 31:16 | 期望字节数 | `1740` |

当前：

```text
FRAME_INFO = (1740 << 16) | 435
           = 0x06CC01B3
```

软件启动前应检查：

```text
VERSION    = 0x00010001
FRAME_INFO = 0x06CC01B3
```

---

## 9. RX_STATUS 寄存器：`0x10`

| 位 | 含义 |
|---:|---|
| bit 15:0 | 当前正在接收帧的 beat 计数 |
| bit 31:16 | 已成功接收的完整帧计数，模 65536 |

```text
RX_STATUS[31:16] = frame_count
RX_STATUS[15:0]  = beat_count
```

例如：

```text
RX_STATUS = 0x000A01B3
```

表示：

```text
frame_count = 10
beat_count  = 435
```

```text
RX_STATUS = 0x000A0000
```

表示已经成功接收 10 帧，当前没有正在接收的 beat。

`RX_STATUS` 可以区分：

| 现象 | 可能含义 |
|---|---|
| frame_count 不增加 | DMA 没有送入完整帧，或 TLAST/数据不足 |
| beat_count 长时间不变 | AXI-Stream 被背压，当前 bank 不可写 |
| beat_count 到 435 但 frame_count 不增加 | TLAST 或帧边界异常 |
| frame_count 连续增加 | DMA 和 AXI-Stream 帧接收正常 |

---

## 10. ERROR_STATUS 寄存器：`0x14`

| 位 | 名称 | 含义 |
|---:|---|---|
| bit 0 | `EARLY_TLAST` | 第 435 beat 之前收到 TLAST |
| bit 1 | `MISSING_TLAST` | 第 435 beat 到达时没有 TLAST |
| bit 2 | `BAD_KEEP` | TKEEP 不是 `4'b1111` |
| bit 3 | `DROPPED_FRAME` | 当前帧因格式或接收状态异常被丢弃 |
| bit 4 | `START_NO_FRAME` | 请求 START 时没有完整帧 |
| bit 5 | `START_BUSY` | 请求 START 时 accelerator 正忙 |
| bit 31:6 | Reserved | 保持 0 或忽略 |

正常值：

```text
ERROR_STATUS = 0x00000000
```

清除错误：

```text
COMMAND = 0x00000004
```

或初始化时：

```text
COMMAND = 0x00000006
```

软件不应只看 `STATUS.ERROR`，应继续读取 ERROR_STATUS 具体定位原因。

---

## 11. CYCLE_COUNT 寄存器：`0x18`

该寄存器保存最近一次完成推理的 accelerator 时钟周期数。

当前实测期望值：

```text
CYCLE_COUNT = 40527
```

10 帧测试中每帧均为 40527 cycles。当前 PL 约 100 MHz，因此纯 accelerator 计算时间约为：

```text
40527 / 100 MHz ≈ 405.27 us
```

它可用于检查 RTL 修改、时钟和流水调度是否改变了推理时间。

---

## 12. VERSION 寄存器：`0x1C`

| 位 | 含义 |
|---:|---|
| bit 31:16 | 主版本号 |
| bit 15:0 | 次版本号 |

当前：

```text
VERSION = 0x00010001
major = 1
minor = 1
```

如果 VERSION 不匹配，软件不应继续执行依赖当前寄存器定义的测试。

---

## 13. CONFIG 寄存器：`0x20`

### 13.1 32 位逐位定义

| 位 | 名称 | 类型 | 含义 |
|---:|---|---|---|
| bit 0 | `AUTO_START` | R/W | 完整帧 ready 且核心空闲时自动启动 |
| bit 1 | `IRQ_ENABLE` | R/W | 允许 sticky DONE 驱动 accelerator IRQ |
| bit 31:2 | Reserved | - | 应写 0 |

### 13.2 当前测试的 CONFIG 数值

当前 10 帧测试写入：

```text
CONFIG = 0x00000003
```

32 位展开：

```text
bit 31 ... bit 2 | bit 1 | bit 0
       0          |   1   |   1
```

含义：

```text
bit 0 = 1 → AUTO_START enabled
bit 1 = 1 → IRQ_ENABLE enabled
bit 31:2 = 0
```

即：

```text
0x00000003 = AUTO_START | IRQ_ENABLE
```

### 13.3 典型配置值

| CONFIG 值 | AUTO_START | IRQ_ENABLE | 适用场景 |
|---:|---:|---:|---|
| `0x00000000` | 0 | 0 | 手动启动、轮询调试 |
| `0x00000001` | 1 | 0 | 自动启动、软件轮询 DONE |
| `0x00000002` | 0 | 1 | 手动 START、使用 DONE IRQ |
| `0x00000003` | 1 | 1 | 当前 10 帧连续流水测试 |

COMMAND 和 CONFIG 必须分开：

```text
COMMAND：一次性命令
CONFIG ：持久化配置
```

写 COMMAND.START 不会自动关闭 AUTO_START 或 IRQ_ENABLE。

---

## 14. Accelerator IRQ 详细语义

accelerator IRQ 由硬件产生：

```text
irq = irq_enable && done_sticky
```

其中：

- accelerator 完成一帧时 `done_sticky` 置 1；
- CONFIG bit 1 是 `irq_enable`；
- IRQ 是 level-high sticky 信号，不是一个时钟周期的 pulse；
- 软件读取结果后必须写 `CLEAR_DONE`；
- 不清 DONE，IRQ 会保持有效。

### 14.1 accelerator ISR 顺序

```text
进入 accelerator ISR
    ↓
读取 STATUS
    ↓
读取 RESULT
    ↓
读取 RX_STATUS
    ↓
读取 ERROR_STATUS
    ↓
读取 CYCLE_COUNT
    ↓
保存到 observation[index]
    ↓
写 COMMAND = 0x00000002
    ↓
清除 DONE 和 IRQ
```

accelerator IRQ 只代表：

```text
最近一次推理已经完成，结果寄存器可以读取。
```

它不代表 DMA 刚完成，也不代表 RESULT 是 FIFO。

---

## 15. AXI DMA MM2S 寄存器与中断状态

AXI DMA 基地址：

```text
0x80000000
```

MM2S/TX 通道的寄存器基址为 DMA 基地址加 TX offset `0x00`。

### 15.1 MM2S_DMACR：偏移 `0x00`

| 位 | 名称 | 含义 |
|---:|---|---|
| bit 0 | `RUNSTOP` | 1 运行 DMA，0 停止 |
| bit 2 | `RESET` | DMA 通道复位 |
| bit 3 | `KEYHOLE` | Keyhole 模式，当前不使用 |
| bit 4 | `CYCLIC` | Cyclic 模式，当前不使用 |
| bit 12 | `IOC_IrqEn` | 完成 IOC 中断使能 |
| bit 13 | `Dly_IrqEn` | 延迟中断使能，当前关闭 |
| bit 14 | `Err_IrqEn` | 错误中断使能 |
| bit 23:16 | `IRQThreshold` | 中断合并阈值 |
| bit 31:24 | `IRQDelay` | 延迟计数 |
| 其他 | Reserved | 保持 0 |

当前软件使能：

```text
IOC interrupt = enabled
ERROR interrupt = enabled
Delay interrupt = disabled
```

### 15.2 MM2S_DMASR：偏移 `0x04`

| 位 | 名称 | 含义 |
|---:|---|---|
| bit 0 | `HALTED` | DMA 通道 halted |
| bit 1 | `IDLE` | DMA 当前空闲 |
| bit 4 | `Internal Error` | Datamover 内部错误 |
| bit 5 | `Slave Error` | AXI slave 访问错误 |
| bit 6 | `Decode Error` | AXI 地址译码错误 |
| bit 8 | SG internal error | 当前 SG 关闭，不应出现 |
| bit 9 | SG slave error | 当前 SG 关闭，不应出现 |
| bit 10 | SG decode error | 当前 SG 关闭，不应出现 |
| bit 12 | `IOC_Irq` | 当前 DMA 传输完成中断 |
| bit 13 | `Dly_Irq` | 延迟中断 |
| bit 14 | `Err_Irq` | DMA 错误中断 |
| bit 23:16 | IRQ coalesce counter | 中断合并计数 |
| bit 31:24 | IRQ delay counter | 延迟计数 |
| 其他 | Reserved | 保持 0 |

当前 UART 中 DMA ISR 的：

```text
irq = 0x00001000
```

表示：

```text
bit 12 IOC_Irq = 1
没有 Error IRQ
```

当前记录的：

```text
sr = 0x00000002
```

表示 DMA 已经处于：

```text
IDLE = 1
```

且没有 `0x10`、`0x20`、`0x40` 内部、slave、decode 错误位。

### 15.3 MM2S_SA：偏移 `0x18`

Simple DMA 源地址寄存器：

```text
MM2S_SA = DDR 中当前帧 buffer 地址
```

DRE 关闭时，源地址至少四字节对齐；当前软件数组使用 64-byte 对齐。

### 15.4 MM2S_LENGTH：偏移 `0x28`

Simple DMA 传输长度寄存器，单位为字节：

```text
LENGTH = 1740
```

写入长度后，DMA 开始当前 MM2S 传输。

### 15.5 DMA ISR 顺序

```text
DMA IRQ 进入
    ↓
读取 DMA IRQ status
    ↓
读取 IOC/ERROR 位
    ↓
写 DMASR 清除已处理 IRQ
    ↓
ERROR：记录错误，active = 0
    ↓
IOC：active = 0，completed_count++
    ↓
读取 accelerator STATUS/RX_STATUS 快照
    ↓
主循环根据 active=0 提交下一帧
```

DMA IRQ 只说明本次 DMA 已完成 AXI-Stream 发送，不表示 accelerator 已完成计算。

---

## 16. GIC 和中断连接

当前 PS 使用 `XScuGic` 管理两个 PL 中断：

| 中断源 | GIC ID | 当前用途 |
|---|---:|---|
| AXI DMA MM2S | `121` | DMA IOC 和 DMA ERROR |
| accelerator IRQ | `136` | accelerator sticky DONE |

初始化顺序：

```text
XScuGic_LookupConfig
        ↓
XScuGic_CfgInitialize
        ↓
连接 DMA ISR
        ↓
连接 accelerator ISR
        ↓
设置优先级和 level-high 触发类型
        ↓
Enable 两个 GIC 中断
        ↓
注册 XScuGic_InterruptHandler
        ↓
Xil_ExceptionEnable
```

---

## 17. 内部 Ping-Pong Buffer 机制

accelerator 内部存在两个 activation RAM bank：

```text
bank 0
bank 1
```

硬件内部维护：

```text
activation_read_bank：当前 accelerator 读取的 bank
activation_load_bank：AXI-Stream 正在写入的 bank
```

一帧开始计算时，逻辑等价于：

```text
activation_read_bank = 当前已装满的 bank
activation_load_bank = 切换到另一个 bank
```

因此可以形成：

```text
bank A：被 accelerator 读取
bank B：被 DMA/AXI-Stream 写入
```

当前设计不是无限深度 FIFO，而是：

```text
1 个正在计算的 bank
1 个等待或接收中的 bank
```

如果两个 bank 都不可写：

```text
ACT_WRITE_READY = 0
S_AXIS_TREADY = 0
DMA 保持 active
AXI-Stream 产生背压
```

当前帧完成切换 bank 后，TREADY 恢复，DMA 继续发送被背压的帧。

---

## 18. 10 帧 AUTO_START 具体流程

### 18.1 初始化

```text
1. 使能 A53 I-Cache 和 D-Cache。
2. 初始化 AXI DMA Simple MM2S。
3. 确认 SG 未开启。
4. 复位 DMA。
5. 读取并检查 VERSION。
6. 读取并检查 FRAME_INFO。
7. COMMAND 写 0x00000006，清 DONE 和 ERROR。
8. CONFIG 写 0x00000003，开启 AUTO_START 和 IRQ_ENABLE。
9. 初始化 XScuGic。
10. 连接 DMA IRQ 121。
11. 连接 accelerator IRQ 136。
12. 使能 DMA IOC/ERROR 中断。
13. 使能 GIC 和 CPU 全局中断。
```

### 18.2 frame 0

```text
DDR frame0
    ↓
DCache flush
    ↓
DMA MM2S SimpleTransfer(length=1740)
    ↓
AXI-Stream 435 beats
    ↓
accelerator 接收完整帧
    ↓
FRAME_READY = 1
    ↓
AUTO_START 自动启动 frame0
```

DMA 完成后产生 IOC IRQ，PS 执行：

```text
dma.active = 0
dma.completed_count = 1
```

主循环随后提交 frame1。

### 18.3 frame 1 预取

```text
frame0：bank A，accelerator 正在读取
frame1：bank B，AXI-Stream 正在写入
```

常见状态：

```text
BUSY = 1
RX_ACTIVE = 1
ACT_WRITE_READY = 1
```

frame1 完整接收后 `FRAME_READY=1`，不会破坏正在计算的 frame0。

### 18.4 DONE 和 AUTO_START

frame0 完成后：

```text
core_done = 1
done_sticky = 1
RESULT = frame0 类别
CYCLE_COUNT = frame0 周期数
IRQ = 1
```

如果 frame1 已经 ready，硬件自动：

```text
启动 frame1
read_bank 切换到 frame1 所在 bank
load_bank 切换到空闲 bank
```

PS 同时收到 accelerator IRQ 136，读取并保存 frame0 结果，然后写 `COMMAND=0x00000002` 清 DONE。

### 18.5 frame 2 到 frame 9

accelerator ISR 清除上一帧 DONE 后，主循环提交下一帧：

```text
DMA IOC → 记录 DMA 完成 → 提交后续 DMA
accelerator DONE IRQ → 读取结果 → CLEAR_DONE
AUTO_START → 自动切换下一帧
```

当两个 bank 都暂时不能写时，AXI-Stream 通过 `TREADY=0` 背压，DMA 等待 bank 释放。

### 18.6 10 帧结束

第 10 帧完成后：

```text
dma_started = 10
dma_completed = 10
accelerator_irq_count = 10
accelerator_completed = 10
```

最后一帧通常没有下一帧等待，常见 STATUS 为 `0x00000052`：

```text
DONE = 1
IRQ = 1
BUSY = 0
FRAME_READY = 0
```

软件检查所有 observation 后输出：

```text
Error flags = 0x00000000
RESULT = PASS
```

---

## 19. 已验证的 10 帧结果

真实板卡 UART 已验证：

```text
DMA started              = 10
DMA completed            = 10
Accelerator IRQ count    = 10
Accelerator completed    = 10
DMA while accelerator busy = 10
Queued-frame observations = 9
Autostart overlap count   = 9
Error flags              = 0x00000000
RESULT                   = PASS
```

| 帧序号 | RESULT | CYCLE_COUNT | ERROR_STATUS |
|---:|---:|---:|---:|
| 0 | 3 | 40527 | 0 |
| 1 | 3 | 40527 | 0 |
| 2 | 4 | 40527 | 0 |
| 3 | 3 | 40527 | 0 |
| 4 | 3 | 40527 | 0 |
| 5 | 4 | 40527 | 0 |
| 6 | 1 | 40527 | 0 |
| 7 | 3 | 40527 | 0 |
| 8 | 2 | 40527 | 0 |
| 9 | 3 | 40527 | 0 |

`Queued-frame observations=9` 和 `Autostart overlap count=9` 说明除了启动边界外，后续 9 帧都观察到了稳定的计算/接收重叠。

---

## 20. 软件统计变量

| 变量 | 含义 |
|---|---|
| `g_pipeline.dma_started` | 已向 DMA 提交的帧数 |
| `g_pipeline.dma_completed` | 已收到 DMA IOC 的帧数 |
| `g_pipeline.accelerator_completed` | 已收到 accelerator DONE 的帧数 |
| `g_pipeline.accelerator_irq_count` | accelerator IRQ 进入次数 |
| `g_pipeline.dma_while_busy_count` | DMA 完成时 accelerator BUSY 的次数 |
| `g_pipeline.queued_frame_count` | DMA 完成时同时观察到 BUSY 和 FRAME_READY 的次数 |
| `g_pipeline.autostart_overlap_count` | accelerator DONE 时观察到下一流水状态 BUSY 的次数 |
| `g_pipeline.error_flags` | 软件综合错误标志 |
| `g_pipeline.finished` | 软件测试是否完成 |
| `g_pipeline.passed` | 最终测试是否通过 |

推荐基本判定：

```text
dma_completed == frame_count
accelerator_completed == frame_count
accelerator_irq_count == frame_count
error_flags == 0
```

推荐流水判定：

```text
queued_frame_count > 0
autostart_overlap_count > 0
```

不要把 overlap 次数硬编码为固定值作为唯一 PASS 条件。中断响应延迟和启动边界可能改变采样点；更可靠的判定是 10 帧结果、错误和中断计数正确，并且至少观察到一次真实 queued-frame 重叠。

---

## 21. ILA 对接建议

当前 ILA 重点观察：

```text
class_id
class_valid
inference_done
inference_busy
accelerator_irq
axi_dma_mm2s_introut
```

推荐触发条件：

```text
class_valid == 1
```

重点检查：

```text
class_id 是否正确
inference_done 是否出现脉冲
inference_busy 是否在下一帧期间保持高
accelerator_irq 是否有效
DMA IRQ 是否出现
```

一次 ILA Arm 通常对应一次触发窗口。如果需要逐帧保存 10 个波形，需要每次重新 Arm，或者使用 trigger sequencer/更长采样方案。

A53 在 ISR 断点处暂停时，PL 不会自动暂停；DMA、accelerator 和 ILA 仍可能继续运行，RESULT 可能被后续帧覆盖。因此：

- 验证连续 10 帧吞吐时，不要在 DMA/accelerator ISR 中长时间停住；
- 推荐只在最终 `ValidatePipelineResults()` 处设置断点；
- 逐帧观察应使用单帧调试模式，或接受流水被暂停后结果时序不再保持原始关系。

---

## 22. 故障定位表

| 现象 | 优先检查 |
|---|---|
| VERSION 不匹配 | bitstream、XSA、Vitis platform 是否来自同一版本 |
| FRAME_INFO 不匹配 | DMA 长度、IP 参数、Vitis 头文件 |
| DMA 没有 IOC | DMA MM2S 配置、DDR 地址、IRQ 121、MM2S length |
| DMA ERROR | DMASR bit 4/5/6、地址映射、HP0 DDR、对齐 |
| frame_count 不增加 | TLAST、TKEEP、DMA 到 accelerator AXIS 的连接 |
| ERROR_STATUS bit0 | DMA 提前产生 TLAST |
| ERROR_STATUS bit1 | 第 435 beat 没有 TLAST |
| ERROR_STATUS bit2 | TKEEP 不是 `0xF` |
| FRAME_READY 长时间为 0 | 帧没有收完整或 TLAST 错误 |
| BUSY 长时间为 1 | accelerator 仍在计算或内部流水异常 |
| accelerator IRQ 一直为 1 | 软件没有写 `COMMAND.CLEAR_DONE` |
| DMA=10 但 accelerator<10 | CPU 被断点暂停、IRQ 未处理或 GIC 配置问题 |
| RESULT 与帧序号错位 | CPU 在 ISR 停太久，后续 RESULT 覆盖了前一帧 |
| cycle_count 改变 | RTL 计算、时钟或流水调度改变 |

---

## 23. 正式软件的最小正确流程

```text
1. 初始化 cache。
2. 初始化 DMA Simple MM2S。
3. 初始化 accelerator AXI-Lite。
4. 读取并检查 VERSION。
5. 读取并检查 FRAME_INFO。
6. COMMAND 写 CLEAR_DONE | CLEAR_ERRORS。
7. CONFIG 写 AUTO_START | IRQ_ENABLE，即 0x00000003。
8. 初始化 XScuGic。
9. 连接 DMA IRQ 121。
10. 连接 accelerator IRQ 136。
11. 使能 DMA IOC/ERROR 中断。
12. 使能 GIC 和 CPU 全局中断。
13. 准备 DDR frame buffer。
14. 对每个 buffer 执行 DCache flush。
15. 提交第一个 DMA MM2S，长度 1740。
16. DMA IOC 后提交下一个 DMA。
17. accelerator IRQ 中读取 RESULT、ERROR_STATUS、CYCLE_COUNT。
18. accelerator IRQ 中写 CLEAR_DONE。
19. 持续到 DMA 和 accelerator 各完成 10 次。
20. 检查所有帧结果和错误。
21. 最后关闭 DMA IRQ 和 accelerator CONFIG，或进入下一批任务。
```

---

## 24. 设计边界与后续扩展

当前设计适合：

```text
固定帧长度
固定 435 beat AXI-Stream 包
单个 MM2S DMA 通道
最多一个等待帧 bank
裸机中断驱动测试
```

后续产品化可扩展：

- 用采集设备环形 DDR buffer 替代 10 帧固定数组；
- 将 `g_pipeline` 封装为正式驱动状态；
- 增加应用层 frame ID；
- 增加 DMA 描述符或多通道方案；
- 增加软件超时、DMA reset recovery 和 accelerator reset recovery；
- 增加 AXI-Stream 原始数据 ILA probe；
- 增加结果 FIFO，降低 PS 中断不及时造成 RESULT 覆盖的风险；
- 根据实时采集速率评估更深的 PL FIFO 或多级 Ping-Pong buffer。

当前 `RESULT` 是单个最近结果寄存器，不是结果 FIFO。如果 PS 可能被高优先级任务阻塞，应在 PL 中增加结果 FIFO，或保证 accelerator IRQ 到结果读取之间不会发生下一次结果覆盖。

---

## 25. 结论

```text
DMA IRQ：确认一帧 DDR 数据完成 MM2S 发送，并允许软件提交后续 DMA。

AUTO_START：完整帧进入空闲 activation bank 后，自动启动 accelerator。

Ping-Pong BRAM：计算当前帧的同时接收下一帧。

accelerator IRQ：确认一帧推理完成，允许软件读取 RESULT、ERROR_STATUS 和 CYCLE_COUNT。

CLEAR_DONE：清除 accelerator sticky DONE 和 level-high IRQ。
```

当前真实板卡已经完成：

```text
10 帧 DMA 搬运
10 次 DMA 完成中断
10 次 accelerator 完成中断
9 次 queued-frame 观察
9 次 autostart overlap 观察
10 帧分类结果正确
10 帧 cycle_count 正确
0 个 accelerator 错误
最终 PASS
```

这构成当前 EMG accelerator 从 DDR 到 DMA、AXI-Stream、双 BRAM、神经网络计算、AXI-Lite 结果回读和 PS 中断处理的完整系统级基线。
