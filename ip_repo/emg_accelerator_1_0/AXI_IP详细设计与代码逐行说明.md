# EMG Accelerator AXI IP 详细设计与代码逐行说明

> 文档日期：2026-07-17  
> 适用目录：`ip_repo/emg_accelerator_1_0`  
> 行号基于 2026-07-17 当前源码版本，后续修改 RTL 后需要重新核对。

> 2026-07-20 更新：AXI-Lite 写地址与写数据通道现已分别锁存，允许
> AW/W 独立到达；持久配置已从 `0x00 COMMAND` 拆分到 `0x20 CONFIG`。
> 本文早期章节中的旧 CONTROL 位定义和源码行号仅作为历史说明，最新
> 软件接口以 `REGISTER_MAP.md` 为准。

## 1. 说明范围

本文解释以下模块：

| 模块 | 文件 | 作用 |
|---|---|---|
| AXI IP 顶层 | `hdl/emg_accelerator_v1_0.v` | 连接 AXI-Lite、AXI-Stream、controller 和 accelerator |
| AXI-Lite 从接口 | `hdl/emg_accelerator_v1_0_S00_AXI.v` | 寄存器写入、读回、sticky 状态和中断 |
| AXI-Stream 从接口 | `hdl/emg_accelerator_v1_0_S00_AXIS.v` | AXIS 接口包装 |
| DMA 帧 controller | `src/emg_dma_pingpong_controller.v` | 接收 435 拍输入帧并生成 activation RAM 写请求 |
| 计算核心 | `src/accelerator.v` | activation bank 切换和 CNN 流水线 |
| activation 双 bank | `src/stem_activation_controller_with_ram.v` | 两块输入 BRAM 和读写冲突保护 |

本文使用三类握手概念：

```text
AXI-Lite 通道握手：VALID && READY
AXI-Stream 数据握手：TVALID && TREADY
内部数据流握手：valid && ready
```

`start/busy/done` 不是 valid/ready 流接口，而是：

```text
start：一拍启动脉冲
busy：任务执行期间保持为高
done：任务完成时拉高一拍
```

---

## 2. 总体结构

```text
PS/CPU
  |
  | AXI-Lite
  v
+---------------------+
| S00_AXI             |
| 控制/状态/结果/irq  |
+----------+----------+
           |
           | start/clear/status
           v
+---------------------+         +----------------------+
| AXI IP 顶层         |-------->| accelerator          |
| 启动仲裁/周期计数   |         | 双 activation bank   |
+----------+----------+         | CNN pipeline         |
           ^                    +----------------------+
           |
+----------+----------+
| S00_AXIS            |
| DMA frame controller|
+----------+----------+
           ^
           | AXI-Stream
        AXI DMA
```

数据路径：

```text
DMA -> S00_AXIS -> emg_dma_pingpong_controller
    -> act_wr_en/act_wr_addr/act_wr_data
    -> accelerator activation_load_bank
```

控制路径：

```text
CPU -> S00_AXI CONTROL
    -> start_pulse/auto_start/clear_errors
    -> 顶层 core_start
    -> accelerator.start
```

状态路径：

```text
controller/accelerator
    -> frame_ready/busy/done/class/error/count
    -> S00_AXI 读数据复用器
    -> CPU
```

---

## 3. 顶层 `emg_accelerator_v1_0.v`

### 3.1 第 3～8 行：参数

```verilog
3  module emg_accelerator_v1_0 #(
4      parameter integer C_S00_AXI_DATA_WIDTH = 32,
5      parameter integer C_S00_AXI_ADDR_WIDTH = 6,
6      parameter integer C_S00_AXIS_TDATA_WIDTH = 32,
7      parameter integer C_FRAME_WORDS = 435,
8      parameter integer C_FRAME_BYTES = 1740
```

含义：

```text
AXI-Lite 数据宽度 = 32 bit
AXI-Lite 地址宽度 = 5 bit，可覆盖 0x00～0x1F
AXI-Stream 数据宽度 = 32 bit
一帧 = 435 个 32-bit word = 1740 byte
```

### 3.2 第 10～40 行：外部接口

第 10 行 `irq` 是高电平有效中断。

第 12～32 行是 AXI-Lite 五个通道：

```text
AW：写地址
W ：写数据
B ：写响应
AR：读地址
R ：读数据
```

第 34～40 行是 AXI-Stream slave：

```text
s00_axis_tdata  数据
s00_axis_tkeep  byte 有效标记
s00_axis_tlast  帧尾
s00_axis_tvalid 上游数据有效
s00_axis_tready 本 IP 可以接收
```

AXIS 只在以下上升沿传输一拍：

```verilog
s00_axis_tvalid && s00_axis_tready
```

### 3.3 第 43～44 行：activation 地址宽度

```verilog
ACT_ADDR_WIDTH = $clog2(435) = 9
```

所以地址总线可以表示 0～511，当前合法地址为 0～434。

### 3.4 第 46～77 行：内部连线

第 46～49 行为 AXI-Lite 输出控制：

```text
ctrl_start_pulse   软件 START 一拍脉冲
ctrl_auto_start    自动启动持久位
ctrl_clear_errors  清错误一拍脉冲
ctrl_irq_enable    中断使能
```

第 51～54 行为 activation 写口：

```text
act_wr_en
act_wr_addr
act_wr_data
act_wr_ready
```

其内部写握手为：

```verilog
act_wr_en && act_wr_ready
```

第 56～63 行为帧状态和 AXIS 错误。

第 65～73 行为 accelerator 启动、状态和复位。

第 75～77 行为推理周期计数寄存器。

### 3.5 第 79～87 行：复位与启动仲裁

第 79 行：

```verilog
combined_reset_n = s00_axi_aresetn && s00_axis_aresetn;
```

任意一个外部复位拉低，数据面进入复位。

第 80 行：

```verilog
data_plane_rst_n = data_plane_reset_sync[1];
```

S00_AXIS 和 accelerator 使用同步释放后的复位。

第 81～83 行：

```verilog
core_start = !core_busy
          && frame_ready
          && (ctrl_start_pulse || ctrl_auto_start);
```

启动必须满足：

```text
accelerator idle
controller 已有完整帧
软件 START 或 AUTO_START 有效
```

第 84 行：

```verilog
start_reject_busy = ctrl_start_pulse && core_busy;
```

第 85～87 行：

```verilog
start_reject_no_frame = ctrl_start_pulse
    && !core_busy
    && !frame_ready;
```

busy 情况优先，只报告 `START_BUSY`，不会同时报告无帧。

### 3.6 第 89～99 行：参数检查

检查：

```text
AXI-Lite 必须为 32 bit
AXI-Stream 必须为 32 bit
FRAME_BYTES 必须等于 FRAME_WORDS×4
```

当前 `1740=435×4`。

### 3.7 第 101～107 行：复位同步释放

```verilog
always @(posedge s00_axis_aclk or negedge combined_reset_n)
```

实现：

```text
异步拉低复位
经过两个 s00_axis_aclk 上升沿后同步释放
```

复位时 `data_plane_reset_sync=00`；释放后依次变为 `01`、`11`。

### 3.8 第 109～123 行：周期计数

复位清零。

`core_start` 时重新从 0 开始；`core_busy` 时每拍加一；`core_done` 时把计数锁存到 `inference_cycles`。

CPU 从 `0x18 CYCLE_COUNT` 读取该值。

### 3.9 第 125～174 行：S00_AXI 实例

第 131～135 行输出：

```text
start_pulse/auto_start/clear_errors_pulse/irq_enable/irq
```

第 136～152 行输入 accelerator/controller 状态。

第 153～173 行透传 AXI-Lite 五通道。

寄存器真正的写入和读回都发生在 `emg_accelerator_v1_0_S00_AXI.v`，不在顶层。

### 3.10 第 176～202 行：S00_AXIS 实例

第 181～187 行连接外部 AXIS。

第 188～191 行连接 activation 写口。

第 192 行：

```verilog
.frame_consume(core_start)
```

`core_start` 同时代表 accelerator 接受帧，以及 controller 释放该帧。

第 193 行把 AXI-Lite 的清错误脉冲送入 controller。

### 3.11 第 204～216 行：accelerator 实例

accelerator 使用 `s00_axis_aclk` 和 `data_plane_rst_n`。

```text
core_start -> start
core_busy <- busy
core_done <- done
act_wr_* -> activation 写口
act_wr_ready <- RAM 写口可用
core_class_valid/core_class_idx <- 分类结果
```

---

## 4. AXI-Lite 寄存器模块 `emg_accelerator_v1_0_S00_AXI.v`

### 4.1 第 3～8 行：参数

```text
C_S_AXI_DATA_WIDTH = 32
C_S_AXI_ADDR_WIDTH = 6
FRAME_WORDS = 435
FRAME_BYTES = 1740
IP_VERSION = 0x0001_0001
```

### 4.2 第 10～32 行：用户逻辑接口

输出控制：

```text
start_pulse        一拍
auto_start         持久位
clear_errors_pulse 一拍
irq_enable         持久位
irq                组合输出
```

输入状态包括：

```text
core_busy/core_done/core_class_valid/core_class_idx
frame_ready/rx_active/act_wr_ready
beat_count/frame_count
四类接收错误
start accept/reject
inference_cycles
```

### 4.3 第 34～54 行：AXI-Lite 五通道

```text
AWADDR/AWVALID/AWREADY
WDATA/WSTRB/WVALID/WREADY
BRESP/BVALID/BREADY
ARADDR/ARVALID/ARREADY
RDATA/RRESP/RVALID/RREADY
```

`AWPROT`、`ARPROT` 当前未使用。

### 4.4 第 57～58 行：地址译码

```verilog
ADDR_LSB = (32/32)+1 = 2
REG_ADDR_BITS = 3
```

地址低两位为 byte offset，寄存器编号来自地址 `[4:2]`：

```text
0x00 -> 0
0x04 -> 1
0x08 -> 2
0x0C -> 3
0x10 -> 4
0x14 -> 5
0x18 -> 6
0x1C -> 7
```

### 4.5 第 60～69 行：协议寄存器

```text
axi_awready/axi_wready/axi_awaddr
axi_bresp/axi_bvalid
axi_arready/axi_araddr
axi_rdata/axi_rresp/axi_rvalid
```

它们保存 AXI 通道状态，不是用户可见的八个寄存器。

### 4.6 第 71～74 行：真正保存的用户状态

当前没有 `slv_reg0～slv_reg7` 数组。

真正物理保存的用户状态为：

```text
auto_start
irq_enable
done_sticky
result_class_idx
start_reject_no_frame_sticky
start_reject_busy_sticky
```

`STATUS`、`FRAME_INFO`、`RX_STATUS`、`ERROR_STATUS` 等大部分读数据是实时输入信号的组合拼接。

### 4.7 第 76～80 行：内部控制线

```text
slv_reg_wren  一次写事务成立
slv_reg_rden  一次读事务成立
write_index   写地址编号
read_index    读地址编号
error_any     所有错误 OR
```

### 4.8 第 82～89 行：对外输出绑定

外部 AXI 输出直接绑定内部协议寄存器。

### 4.9 第 91～102 行：事务成立

写事务：

```verilog
slv_reg_wren = axi_awready && S_AXI_AWVALID
            && axi_wready  && S_AXI_WVALID;
```

读事务：

```verilog
slv_reg_rden = axi_arready && S_AXI_ARVALID && !axi_rvalid;
```

第 94～95 行从锁存地址取 `[4:2]`。

第 96～101 行把全部错误 OR 成 `error_any`。

第 102 行：

```verilog
irq = irq_enable && done_sticky;
```

### 4.10 第 104～116 行：AWREADY

复位时 `axi_awready=0`、地址清零。

正常情况下仅当：

```text
AWVALID=1
WVALID=1
当前没有 BVALID
```

才拉高 AWREADY 并锁存 AWADDR。

AWREADY 只保持一拍。

### 4.11 第 118～129 行：WREADY

逻辑与 AWREADY 对称，也要求 AWVALID 和 WVALID 同时存在。

### 当前 AXI-Lite 限制

AXI4-Lite 标准允许 AW 和 W 独立到达。当前实现把两个通道耦合，要求 master 保持两边 VALID，直到同时看到 READY。

Xilinx 常用 master 通常会保持 VALID，因此可以工作；更通用的工业实现应分别锁存 AW 和 W，等两者都到齐后再写寄存器。

### 4.12 第 131～142 行：写响应 B

`slv_reg_wren=1` 时：

```text
BVALID=1
BRESP=2'b00，即 OKAY
```

master 拉高 `BREADY` 后清除 BVALID。

当前写任意地址都返回 OKAY，没有 SLVERR/DECERR。

### 4.13 COMMAND 与 CONFIG 写入

第 145～153 行为复位值。

第 155～156 行每拍默认：

```verilog
start_pulse <= 0;
clear_errors_pulse <= 0;
```

所以这两个信号是单周期脉冲。

`0x00 COMMAND` 的低 byte 定义为：`WDATA[0]=START`、
`WDATA[1]=CLEAR_DONE`、`WDATA[2]=CLEAR_ERRORS`。这些位均为 W1P 命令，
读回为 0。CLEAR_ERRORS 同时清除两个 start reject sticky bit。

`0x20 CONFIG` 的低 byte 定义为：`WDATA[0]=AUTO_START`、
`WDATA[1]=IRQ_ENABLE`。这两个位持久保存，直到下一次 CONFIG 写或复位。

#### 第 172～174 行

`start_accept`，即 `core_start`，会清除上一帧的 `done_sticky`。

#### 第 175～180 行

把一拍的 `start_reject_no_frame/busy` 锁存为软件可读 sticky 状态。

#### 第 181～183 行

`core_class_valid` 时锁存 `core_class_idx` 到 `result_class_idx`。

#### 第 184～186 行

`core_done` 时置位 `done_sticky`。

### COMMAND 不覆盖 CONFIG

START、CLEAR_DONE 和 CLEAR_ERRORS 不再修改 AUTO_START/IRQ_ENABLE，软件无需
为了发命令而拼接完整持久控制字。

### 4.14 第 190～202 行：ARREADY

当没有未消费的 RVALID 且 ARVALID=1 时：

```text
ARREADY 拉高一拍
锁存 ARADDR
```

### 4.15 第 204～255 行：八寄存器读回位置

`slv_reg_rden=1` 时：

```text
RVALID=1
RRESP=OKAY
case(read_index) 生成 RDATA
```

master 完成 `RVALID&&RREADY` 后清除 RVALID。

#### 0x00 CONTROL，第 214～221 行

```text
bit 0 = 0，START 不保存
bit 1 = auto_start
bit 2 = 0，CLEAR_DONE 不保存
bit 3 = 0，CLEAR_ERRORS 不保存
bit 4 = irq_enable
bit 31:5 = 0
```

#### 0x04 STATUS，第 222～234 行

```text
bit 0 core_busy
bit 1 done_sticky
bit 2 frame_ready
bit 3 rx_active
bit 4 act_wr_ready
bit 5 core_class_valid
bit 6 irq
bit 7 start_reject_no_frame_sticky
bit 8 start_reject_busy_sticky
bit 9 error_any
bit 31:10 = 0
```

`core_class_valid` 是一拍实时信号，软件不应依赖一定能读到它，应使用 RESULT 和 sticky DONE。

#### 0x08 RESULT，第 235 行

```text
bit 2:0 = result_class_idx
```

#### 0x0C FRAME_INFO，第 236 行

```text
bit 15:0  = FRAME_WORDS = 435
bit 31:16 = FRAME_BYTES = 1740
```

#### 0x10 RX_STATUS，第 237 行

```text
bit 15:0  = beat_count
bit 31:16 = frame_count
```

#### 0x14 ERROR_STATUS，第 238～246 行

```text
bit 0 early TLAST
bit 1 missing TLAST
bit 2 bad TKEEP
bit 3 dropped frame
bit 4 start no frame
bit 5 start busy
```

#### 0x18 CYCLE_COUNT，第 247 行

返回 `inference_cycles`。

#### 0x1C VERSION，第 248 行

返回 `0x0001_0001`。

#### 0x20 CONFIG

返回 `{IRQ_ENABLE, AUTO_START}`。

---

## 5. AXI-Lite 写事务时序示例

CPU 已通过 `CONFIG=0x2` 使能中断，随后写 `COMMAND=0x1` 启动：

```text
AW 和 W 可以同拍或分别到达，slave 分别锁存地址和数据
两个 hold register 都有效后：执行 COMMAND 写入，start_pulse=1
随后：BVALID=1，BRESP=OKAY
后续：master 拉高 BREADY，写响应结束
```

顶层在 `start_pulse=1` 的周期检查 `frame_ready` 和 `core_busy`，决定是否生成 `core_start`。

---

## 6. AXI-Lite 读事务时序示例

CPU 读取 `STATUS 0x04`：

```text
周期 A：ARVALID=1，ARADDR=0x04
周期 B：ARREADY=1，锁存地址
周期 C：slv_reg_rden=1，read_index=1，RDATA 拼接 STATUS，RVALID=1
周期 D：RREADY&&RVALID，读事务结束
```

---

## 7. S00_AXIS 包装 `emg_accelerator_v1_0_S00_AXIS.v`

### 第 3～7 行

参数固定为：

```text
32-bit stream
435 words/frame
9-bit activation address
```

### 第 9～33 行

第 9～15 行为 AXIS。

第 17～20 行为 activation 写口。

第 22～23 行为 `frame_consume` 和 `clear_errors`。

第 25～33 行为帧状态和错误。

### 第 35～41 行

静态检查 stream 必须为 32 bit、帧必须为 435 word。

### 第 43～69 行

实例化 `emg_dma_pingpong_controller`。

该包装模块本身没有 FIFO、计数器或状态机。实际接收逻辑全部在 controller 内。

---

## 8. DMA controller `emg_dma_pingpong_controller.v`

### 8.1 第 3～6 行：参数

```text
DATA_WIDTH=32
FRAME_WORDS=435
ADDR_WIDTH=9
```

### 8.2 第 8～33 行：端口

AXIS：

```text
s_axis_tdata/tkeep/tlast/tvalid/tready
```

activation 写口：

```text
act_wr_en/addr/data/ready
```

控制：

```text
frame_consume
clear_errors
```

状态：

```text
frame_ready
rx_active
beat_count
frame_count
四类错误
```

### 8.3 第 36 行：FULL_KEEP

32-bit stream 对应 4 个 byte，所以完整 beat 要求：

```verilog
TKEEP = 4'b1111
```

1740 可以被 4 整除，最后一拍也必须完整有效。

### 8.4 第 38 行：drop_until_tlast

检测坏帧后继续接收并丢弃，直到看到 TLAST，重新建立帧边界。

### 8.5 第 40～43 行：组合控制

```text
axis_fire  AXIS 真正传输一拍
bad_keep   TKEEP 不是全 1
final_word beat_count==434
write_fire 真正写 activation RAM
```

### 8.6 第 45～47 行：TREADY

```verilog
s_axis_tready = rst_n && (
    drop_until_tlast ? 1'b1
                     : (!frame_ready && act_wr_ready)
);
```

复位期间 TREADY=0，防止上游把首拍误认为已接收。

正常接收要求：

```text
没有完整待处理帧
activation 写 bank 可写
```

丢弃坏帧时强制 TREADY=1，因为不访问 RAM。

### 8.7 第 48 行：AXIS fire

```verilog
axis_fire = s_axis_tvalid && s_axis_tready;
```

只有 fire 时状态才前进。

### 8.8 第 49～50 行

```verilog
bad_keep = s_axis_tkeep != FULL_KEEP;
final_word = beat_count == 434;
```

`beat_count` 同时是当前准备写入的 activation 地址。

### 8.9 第 51～54 行：write_fire

```verilog
write_fire = axis_fire
          && !drop_until_tlast
          && !bad_keep
          && !frame_ready;
```

注意：early TLAST 那一拍、missing TLAST 的第 435 拍可能已经写入 RAM，但该帧不会置 `frame_ready`，下一帧会从地址 0 完整覆盖，因此不会被 accelerator 使用。

### 8.10 第 56～59 行：写口

```text
act_wr_en = write_fire
act_wr_addr = beat_count
act_wr_data = TDATA
```

`rx_active` 当前实现为：

```verilog
drop_until_tlast || beat_count!=0
```

所以完整帧等待启动时 `beat_count=435`，`RX_ACTIVE` 仍为 1。当前实际语义更接近“已有接收进度或正在丢弃”，不严格等于总线正在传输。

### 8.11 第 61～70 行：复位

清除 frame ready、计数器、drop 状态和全部错误。

### 8.12 第 72～77 行：清错误

`clear_errors=1` 清除四个 sticky 接收错误。

若同一拍又产生新错误，always 块后面的置位赋值会使该错误重新置位。

### 8.13 第 79～82 行：frame consume

```verilog
if (frame_consume && frame_ready) begin
    frame_ready <= 0;
    beat_count <= 0;
end
```

顶层把 `frame_consume` 连接为 `core_start`。

`frame_ready=1` 时正常 TREADY=0，所以消费帧的同一拍不会接收新 beat。

### 8.14 第 84～115 行：接收状态机

#### 第 85～89 行：drop 状态

继续丢弃，看到 TLAST 后退出 drop，地址回 0。

#### 第 90～96 行：BAD_KEEP

```text
error_bad_keep=1
error_dropped_frame=1
beat_count=0
非 TLAST 时进入 drop_until_tlast
```

#### 第 97～107 行：第 435 拍

如果 TLAST=1：

```text
frame_ready=1
frame_count++
beat_count=435
```

如果 TLAST=0：

```text
error_missing_tlast=1
error_dropped_frame=1
drop_until_tlast=1
beat_count=0
```

#### 第 108～111 行：EARLY_TLAST

地址 0～433 看到 TLAST：

```text
error_early_tlast=1
error_dropped_frame=1
beat_count=0
```

TLAST 已提供帧尾，不需要继续 drop。

#### 第 112～114 行：普通 beat

`beat_count++`，下一拍写下一个地址。

---

## 9. 输入数据与 RAM 地址

张量布局为 channel-major：

```text
channel 0 的 t=0..347
channel 1 的 t=0..347
...
channel 4 的 t=0..347
```

每拍：

```text
TDATA[7:0]   = sample t+0
TDATA[15:8]  = sample t+1
TDATA[23:16] = sample t+2
TDATA[31:24] = sample t+3
```

每通道 `348/4=87` word：

| 地址 | 内容 |
|---:|---|
| 0～86 | channel 0 |
| 87～173 | channel 1 |
| 174～260 | channel 2 |
| 261～347 | channel 3 |
| 348～434 | channel 4 |

DMA 每次必须按此布局搬运 1740 byte。

---

## 10. 真正的 activation ping-pong

controller 本身没有两块大 RAM。真正的 bank 在 `stem_activation_controller_with_ram.v`，bank 所有权在 `accelerator.v`。

### 10.1 accelerator 第 105～106 行

```verilog
reg activation_load_bank;
reg activation_read_bank;
```

```text
load_bank：DMA 写入
read_bank：stem 读取
```

### 10.2 accelerator 第 494～536 行

`u_stem` 接收：

```text
act_wr_en/addr/data
act_wr_bank=activation_load_bank
act_rd_bank=activation_read_bank
act_rd_active=busy||start
act_wr_ready 返回顶层
```

### 10.3 accelerator 第 949～950 行

复位时 load=0、read=0。第一次 START 前读端 inactive，因此允许 DMA 写 bank0。

### 10.4 accelerator 第 1002～1007 行

START 时：

```verilog
activation_read_bank <= activation_load_bank;
activation_load_bank <= !activation_load_bank;
```

第一次：

```text
启动前 load=0
启动后 read=0，load=1
```

第二次：

```text
启动前 load=1
启动后 read=1，load=0
```

### 10.5 activation RAM 第 75～78 行

```verilog
wr_hits_active_read_bank = act_rd_active
    && act_wr_bank==act_rd_bank;
act_wr_ready = !wr_hits_active_read_bank;
act_wr_fire = act_wr_en && act_wr_ready;
```

如果想写正在读取的 bank，就拉低 `act_wr_ready`，最终通过 controller 拉低 AXIS TREADY。

### 10.6 activation RAM 第 80～100 行

根据 `act_rd_bank` 路由读请求，根据 `act_wr_bank` 路由写请求。

每个 BRAM 的 Port A 在外部写和 controller read0 之间复用，Port B 用于 controller read1。

### 10.7 activation RAM 第 102～131 行

读取采用两阶段握手：

```text
请求：act_req_valid && act_req_ready
返回：act_vec_valid && act_vec_ready
```

中间有 BRAM read latency。

### 10.8 activation RAM 第 133～161 行

物理实例：

```text
u_stem_activation_bank0
u_stem_activation_bank1
```

---

## 11. `core_start` 同一拍发生什么

假设 `frame_ready=1`、`core_busy=0`，CPU 写 START。

同一个 `core_start` 上升沿：

```text
S00_AXI：start_accept=1，清上一帧 done_sticky
controller：frame_consume=1，清 frame_ready 和 beat_count
accelerator：busy=1，read_bank取当前load_bank，load_bank翻转
内部流水线：清 buffer/pending 状态，开始新 inference
```

帧所有权和 bank 所有权使用同一个脉冲切换，不需要软件直接操作 bank。

---

## 12. accelerator 内部握手

### 12.1 第 311～312 行：结果

```verilog
class_valid = fc_result_valid;
class_idx = fc_class_idx;
```

FC 结果直接送 AXI-Lite 结果锁存器。

### 12.2 第 314 行：调度 active

```verilog
schedule_active = busy && !pw2_gap_done_seen && !fc_started;
```

### 12.3 第 316～326 行：任务 FIFO

`dw1_pending`、`dw2_pending` 保存 metadata，不保存大数据。

```text
pending_empty：没有任务
pending_room：仍可入队
count_after_pop：允许同拍 pop 后再判断空间
```

### 12.4 第 332～360 行：start 条件

```text
stem_issue_now：stem idle、还有 tile、DW1 pending 有空间
dw1_start_now：DW1 pending 非空、DW1 idle
pw1_start_now：PW1 tile 在范围、PW1 idle
dw2_start_now：DW2 pending 非空、DW2 idle
pw2_start_now：PW2 tile 在范围、PW2 idle、GAP 不在 clear
```

这些是组合条件，主 always 块把对应 `*_start` 拉高一拍。

### 12.5 第 362～376 行：Stem -> DW1

Stem 输出 payload：

```text
tile_t_base + tile_oc_base + tile data
```

先进入 `u_stem_to_dw1_ready_slice`，再进入真实 buffer。

真实进入 buffer 的握手：

```verilog
stem_to_dw1_in_valid && stem_to_dw1_in_ready
```

### 12.6 第 378～384 行：DW1 pending

```verilog
dw1_pending_push = busy
    && stem_to_dw1_in_valid
    && stem_to_dw1_in_ready;
```

只有数据真正进入 buffer 后才产生 DW1 任务票。

```verilog
dw1_pending_pop = dw1_start_now;
```

### 12.7 第 386～400 行：DW1 -> PW1

```text
DW1 mid_out valid/ready
-> ready slice
-> dw1_to_pw1 buffer valid/ready
```

### 12.8 第 402～420 行：PW1 -> DW2

```verilog
pw1_to_dw2_in_valid = slice_valid && dw2_pending_room;
pw1_to_dw2_out_ready = buffer_ready && dw2_pending_room;
```

DW2 任务 FIFO 满时，即使数据 buffer 可写，也反压 PW1。

真实写入后：

```verilog
dw2_pending_push = pw1_to_dw2_in_valid && pw1_to_dw2_in_ready;
```

### 12.9 第 422～441 行：DW2 -> PW2

结构为：

```text
DW2 output
-> ready slice
-> dw2_to_pw2 buffer
-> PW2 request/response
```

---

## 13. accelerator 各实例接口

### 13.1 u_stem，第 494～537 行

```text
job：stem_start/busy/done
activation request/return：内部由 stem controller 完成
输出：stem_out_valid && stem_to_buffer_ready
```

### 13.2 u_stem_to_dw1_ready_slice，第 539～553 行

标准 FIFO：

```text
入口 fire = in_valid && in_ready
出口 fire = out_valid && out_ready
```

### 13.3 u_stem_to_dw1，第 555～587 行

三组握手：

```text
写入 tile：stem_out_valid/ready
DW1 窗口请求：dw1_win_req_valid/ready
DW1 窗口返回：dw1_win_vec_valid/ready
```

### 13.4 u_dw1，第 589～629 行

```text
start/busy/done
win_req_valid/ready
win_vec_valid/ready
mid_out_valid/ready
```

### 13.5 u_dw1_to_pw1_ready_slice，第 630～645 行

DW1 输出 ready slice。

### 13.6 u_dw1_to_pw1，第 646～681 行

```text
接收 DW1：dw1_out_valid/ready
PW1 tile 请求：tile_req_valid/ready
activation 请求：act_req_valid/ready
activation 返回：act_vec_valid/ready
```

### 13.7 u_pw1，第 682～724 行

`pw1_start` 启动 job，通过 request/response 读取输入，通过 `out_valid/out_ready` 输出。

### 13.8 u_pw1_to_dw2_ready_slice，第 725～740 行

PW1 输出 ready slice。

### 13.9 u_pw1_to_dw2，第 741～776 行

接收 PW1 tile，为 DW2 提供 window request/return。

### 13.10 u_dw2，第 777～817 行

与 DW1 同类：start/busy/done、window 请求/返回、mid output valid/ready。

### 13.11 u_dw2_to_pw2_ready_slice，第 818～832 行

DW2 输出 ready slice。

### 13.12 u_dw2_to_pw2，第 834～870 行

接收 DW2 输出，为 PW2 提供 tile 和 activation request/return。

### 13.13 u_pw2，第 872～913 行

PW2 结果直接累积到 GAP：

```text
gap_frame_done
gap_count
gap_sum_vec
```

### 13.14 u_fc，第 915～941 行

GAP 完成后启动 FC。

`result_ready=1`，所以最终结果无下游反压：

```text
result_valid -> class_valid
class_idx -> RESULT 锁存器
```

---

## 14. accelerator 主状态机，第 943～1136 行

### 第 943～987 行：复位

清除 busy/done、所有 start、bank、调度地址、pending FIFO、GAP/FC 状态。

### 第 989～996 行：一拍信号默认清零

```text
done
stem_start/dw1_start/pw1_start/dw2_start/pw2_start/fc_start
pw2_gap_clear
```

后续条件再置 1，因此都是单周期 pulse。

### 第 998～1000 行

`buffer_clear` 启动后只保持一拍。

### 第 1002～1025 行：新 inference

`start && !busy` 时：

```text
busy=1
清各 buffer/GAP
交换 activation bank
重置所有 tile/ch 指针
清 pending FIFO
清 FC/GAP 完成状态
```

### 第 1026～1128 行：busy 调度

```text
1027～1029：锁存 GAP 完成
1031～1049：发 stem job
1051～1060：DW1 metadata 入队
1062～1071：DW1 metadata 出队并启动
1073～1082：发 PW1 job
1084～1095：DW2 metadata 入队
1097～1106：DW2 metadata 出队并启动
1108～1119：发 PW2 job
1121～1122：更新 pending count
1124～1127：GAP 完成后启动 FC
```

### 第 1129～1133 行：网络完成

`fc_done=1` 时：

```text
busy=0
done=1，一拍
fc_started=0
```

S00_AXI 随后锁存 DONE 和分类结果。

---

## 15. 连续两帧时序

### 帧 A 装载

```text
load_bank=0
DMA 写 bank0
frame_ready=1
```

### 启动帧 A

```text
read_bank=0
load_bank=1
busy=1
frame_ready=0
```

### 帧 A 计算期间装载帧 B

```text
accelerator 读 bank0
DMA 写 bank1
```

帧 B 完整后：

```text
frame_ready=1
TREADY=0
```

若 AUTO_START=1，帧 A 完成后自动启动帧 B：

```text
read_bank=1
load_bank=0
```

所以最多支持：

```text
1 帧计算中
1 帧完整等待中
```

第三帧通过 TREADY 反压。

---

## 16. 时钟域要求

虽然有 `s00_axi_aclk` 和 `s00_axis_aclk`，但控制和状态目前直接连接，没有完整 CDC：

```text
start_pulse/auto_start/clear_errors
busy/done/class
frame_ready/count/error
```

因此当前版本必须：

```text
s00_axi_aclk == s00_axis_aclk
```

两个 reset 也应同时控制。

如果 DMA stream 是另一时钟，应在本 IP 外部加入 AXI4-Stream Clock Converter。

---

## 17. 当前工程限制

### 17.1 AW/W 通道已解耦

写地址和写数据分别由 `aw_hold_*` 与 `w_hold_*` 寄存器接收。AW 先到、
W 先到和同拍到达均可完成一次写事务；两个 payload 都锁存后才执行寄存器写并产生 BVALID。

### 17.2 COMMAND 与 CONFIG 可写

`0x00 COMMAND` 只产生 START、CLEAR_DONE、CLEAR_ERRORS 脉冲；`0x20 CONFIG`
保存 AUTO_START 和 IRQ_ENABLE。写其他地址不改变状态，但仍返回 OKAY。

### 17.3 RX_ACTIVE 实际语义

完整帧等待时 RX_ACTIVE 仍为 1。若希望只表示“正在接收”，可以后续改为：

```verilog
drop_until_tlast || (!frame_ready && beat_count!=0)
```

### 17.4 frame_count

只在 reset 清零，成功帧加一，16 bit 回绕，CLEAR_ERRORS 不清计数器。

### 17.5 没有 M_AXIS result

最终只有 3-bit class，当前通过 AXI-Lite RESULT 返回。

### 17.6 结果覆盖

AUTO_START 连续运行时，`result_class_idx` 保存最近一次结果。若软件不能及时读取，后续应增加 result FIFO 或 sequence number。

---

## 18. 软件操作流程

### 手动模式

```text
1. 写 CLEAR_ERRORS 和 CLEAR_DONE
2. 写 CONFIG 设置 IRQ_ENABLE，AUTO_START 保持 0
3. CPU 写完 DDR 后 flush cache
4. 启动 DMA MM2S，length=1740 byte
5. 等待 STATUS.FRAME_READY
6. 写 COMMAND.START
7. 等待 STATUS.DONE 或 irq
8. 读取 RESULT 和 CYCLE_COUNT
9. 写 COMMAND.CLEAR_DONE 清 irq
```

### 自动模式

```text
1. 写 CONFIG 设置 AUTO_START/IRQ_ENABLE
2. CPU 写完每帧 DDR 数据后 flush cache
3. 每次提交 1740-byte DMA frame
4. frame_ready 且 core idle 时自动启动
5. 通过 DONE/irq 读取结果
```

---

## 19. 精确代码索引

| 功能 | 位置 |
|---|---|
| core_start 仲裁 | `hdl/emg_accelerator_v1_0.v:81` |
| start reject | `hdl/emg_accelerator_v1_0.v:84` |
| 复位同步 | `hdl/emg_accelerator_v1_0.v:101` |
| 周期计数 | `hdl/emg_accelerator_v1_0.v:109` |
| S00_AXI 实例 | `hdl/emg_accelerator_v1_0.v:125` |
| S00_AXIS 实例 | `hdl/emg_accelerator_v1_0.v:176` |
| accelerator 实例 | `hdl/emg_accelerator_v1_0.v:204` |
| AXI 写成立 | `hdl/emg_accelerator_v1_0_S00_AXI.v:91` |
| AXI 读成立 | `hdl/emg_accelerator_v1_0_S00_AXI.v:93` |
| 地址译码 | `hdl/emg_accelerator_v1_0_S00_AXI.v:94` |
| AWREADY | `hdl/emg_accelerator_v1_0_S00_AXI.v:104` |
| WREADY | `hdl/emg_accelerator_v1_0_S00_AXI.v:118` |
| B 响应 | `hdl/emg_accelerator_v1_0_S00_AXI.v:131` |
| CONTROL 写入 | `hdl/emg_accelerator_v1_0_S00_AXI.v:158` |
| sticky 状态 | `hdl/emg_accelerator_v1_0_S00_AXI.v:172` |
| ARREADY | `hdl/emg_accelerator_v1_0_S00_AXI.v:190` |
| 八寄存器读复用 | `hdl/emg_accelerator_v1_0_S00_AXI.v:204` |
| controller 实例 | `hdl/emg_accelerator_v1_0_S00_AXIS.v:43` |
| AXIS TREADY | `src/emg_dma_pingpong_controller.v:45` |
| AXIS fire | `src/emg_dma_pingpong_controller.v:48` |
| RAM write fire | `src/emg_dma_pingpong_controller.v:51` |
| frame consume | `src/emg_dma_pingpong_controller.v:79` |
| TLAST/TKEEP 状态机 | `src/emg_dma_pingpong_controller.v:84` |
| bank 寄存器 | `src/accelerator.v:105` |
| 内部调度 | `src/accelerator.v:314` |
| valid/ready 拼接 | `src/accelerator.v:362` |
| activation 接口 | `src/accelerator.v:494` |
| accelerator 主状态机 | `src/accelerator.v:943` |
| bank 交换 | `src/accelerator.v:1002` |
| 最终 done | `src/accelerator.v:1129` |
| RAM 写冲突保护 | `src/stem_activation_controller_with_ram.v:75` |
| bank0 BRAM | `src/stem_activation_controller_with_ram.v:133` |
| bank1 BRAM | `src/stem_activation_controller_with_ram.v:148` |

---

## 20. 总结

当前 IP 的模块边界为：

```text
S00_AXI：控制、状态、结果和中断
S00_AXIS：AXIS 包装
DMA controller：帧检查、计数和 activation 地址生成
accelerator：bank 所有权切换和 CNN 计算
activation controller：两块物理 BRAM 和读写冲突保护
```

三个关键握手：

```verilog
AXI-Lite 写：
AWVALID && AWREADY && WVALID && WREADY

AXI-Stream 输入：
TVALID && TREADY

activation RAM 写：
act_wr_en && act_wr_ready
```

最关键的原子切换：

```text
core_start 同时：
1. 消费 controller.frame_ready
2. accelerator.read_bank 取得当前 load_bank
3. accelerator.load_bank 翻转
4. 启动神经网络计算
```

因此该版本可以实现帧 A 计算期间装载帧 B，并通过 AXI-Stream TREADY 对更多输入自动反压。
