# EMG 1-D CNN 模型结构与输入格式

## 1. 来源文件

本文档总结 `emg_gesture_repro` 工程中的 1-D CNN 模型结构和输入数据格式。

关键源码：

- `emg_gesture_repro/src/emg_gesture/models/cnn1d.py`
- `emg_gesture_repro/src/emg_gesture/training/window_dataset.py`
- `emg_gesture_repro/src/emg_gesture/windowing/canonical.py`
- `emg_gesture_repro/configs/models/cnn1d.yaml`
- `emg_gesture_repro/tests/test_model_shape.py`

## 2. 输入数据结构

### 2.1 原始 EMG 数据

原始数据存储为 HDF5：

```text
/emg         shape = [n_samples, 5]
/timestamps shape = [n_samples]
```

固定为 5 通道 EMG：

```text
channel_count = 5
```

必需 metadata：

```text
subject_id
session_id
record_id
fs_hz
channel_names
device_id
```

### 2.2 CNN 输入窗口

默认窗口长度：

```text
window_samples = 348
hop_samples = 50
```

从 raw HDF5 中抽取的单个窗口形状：

```text
[time, channels] = [348, 5]
```

送入 PyTorch CNN 前会转置：

```text
[channels, time] = [5, 348]
```

批量输入形状：

```text
[batch, channels, time] = [batch, 5, 348]
```

### 2.3 默认归一化

默认 normalization：

```text
per_window_median_standardize
```

处理流程：

```text
1. 对每个窗口、每个通道计算 median
2. samples - median
3. 对每个窗口、每个通道计算 std
4. centered / max(std, 1e-6)
```

特点：

- 不使用跨 subject、跨 split 的全局统计量。
- 防止 train/val/test 之间产生 normalization leakage。
- FPGA 部署时需要决定是否硬件实现 median/std，或改为离线/前处理模块实现。

## 3. 默认模型配置

配置文件：

```text
emg_gesture_repro/configs/models/cnn1d.yaml
```

默认配置：

```yaml
model:
  name: cnn1d
  architecture: light
  in_channels: 5
  window_samples: 348
  num_classes: 5
  embedding_dim: 96
  dropout: 0.15
training:
  batch_size: 64
  epochs: 50
  lr: 0.001
  weight_decay: 0.01
  seed: 0
```

默认部署目标应优先使用：

```text
LightCNN1D
```

原因：

- 参数量小。
- 层结构规则。
- 使用 depthwise separable Conv1d，适合 FPGA 降低 MAC 数。
- 测试锁定默认参数量为 19,973。

## 4. LightCNN1D 结构

### 4.1 模型总览

输入：

```text
x shape = [B, 5, 348]
```

输出：

```text
logits shape = [B, 5]
embedding shape = [B, 96]
```

网络结构：

```text
Input [B, 5, 348]
-> stem
-> block1 depthwise separable conv
-> block1_tail
-> block2 depthwise separable conv
-> block2_tail
-> flatten
-> embedding Linear
-> ReLU
-> classifier Linear
-> logits [B, 5]
```

### 4.2 逐层结构与输出形状

| 阶段 | 层 | 参数 | 输出形状 |
|---|---|---|---|
| input | EMG window | 5 channels, 348 samples | `[B, 5, 348]` |
| stem conv | `Conv1d(5, 32, kernel=7, padding=3, bias=False)` | 1,120 | `[B, 32, 348]` |
| stem bn | `BatchNorm1d(32)` | 64 | `[B, 32, 348]` |
| stem act | `ReLU` | 0 | `[B, 32, 348]` |
| stem dropout | `Dropout(0.15)` | 0 | `[B, 32, 348]` |
| block1 depthwise | `Conv1d(32, 32, kernel=5, padding=2, groups=32, bias=False)` | 160 | `[B, 32, 348]` |
| block1 pointwise | `Conv1d(32, 64, kernel=1, bias=False)` | 2,048 | `[B, 64, 348]` |
| block1 bn | `BatchNorm1d(64)` | 128 | `[B, 64, 348]` |
| block1 act | `ReLU` | 0 | `[B, 64, 348]` |
| block1 pool | `MaxPool1d(kernel=2)` | 0 | `[B, 64, 174]` |
| block2 depthwise | `Conv1d(64, 64, kernel=5, padding=2, groups=64, bias=False)` | 320 | `[B, 64, 174]` |
| block2 pointwise | `Conv1d(64, 96, kernel=1, bias=False)` | 6,144 | `[B, 96, 174]` |
| block2 bn | `BatchNorm1d(96)` | 192 | `[B, 96, 174]` |
| block2 act | `ReLU` | 0 | `[B, 96, 174]` |
| block2 pool | `AdaptiveAvgPool1d(1)` | 0 | `[B, 96, 1]` |
| flatten | `flatten(start_dim=1)` | 0 | `[B, 96]` |
| embedding | `Linear(96, 96)` | 9,312 | `[B, 96]` |
| embedding act | `ReLU` | 0 | `[B, 96]` |
| classifier | `Linear(96, 5)` | 485 | `[B, 5]` |

### 4.3 LightCNN1D 参数量

参数量计算：

```text
stem conv             32 * 5 * 7           = 1,120
stem batchnorm        32 gamma + 32 beta   = 64
block1 depthwise      32 * 1 * 5           = 160
block1 pointwise      64 * 32 * 1          = 2,048
block1 batchnorm      64 gamma + 64 beta   = 128
block2 depthwise      64 * 1 * 5           = 320
block2 pointwise      96 * 64 * 1          = 6,144
block2 batchnorm      96 gamma + 96 beta   = 192
embedding linear      96 * 96 + 96         = 9,312
classifier linear     5 * 96 + 5           = 485
```

总参数量：

```text
LightCNN1D total params = 19,973
```

## 5. DepthwiseSeparableConv1d 结构

源码中的 `DepthwiseSeparableConv1d` 包含两部分：

```text
depthwise Conv1d:
  groups = in_channels
  每个输入通道独立做 1-D 卷积

pointwise Conv1d:
  kernel_size = 1
  做通道混合
```

优势：

- 比普通 Conv1d 明显减少参数量和 MAC 数。
- 对 FPGA 友好，depthwise 和 pointwise 可分别优化。
- depthwise 适合 channel-wise 并行。
- pointwise 适合矩阵乘或 PE array。

## 6. DeeperCNN1D 结构

`DeeperCNN1D` 是较深版本，不是默认配置。

输入：

```text
[B, 5, 348]
```

输出：

```text
logits shape = [B, 5]
embedding shape = [B, 128]
```

逐层结构：

| 阶段 | 层 | 输出形状 |
|---|---|---|
| input | EMG window | `[B, 5, 348]` |
| stem | `Conv1d(5, 32, kernel=9, padding=4)` + BN + ReLU + Dropout | `[B, 32, 348]` |
| block1 | depthwise separable `32 -> 64`, kernel=7 | `[B, 64, 348]` |
| block1 pool | `MaxPool1d(2)` | `[B, 64, 174]` |
| block2 | depthwise separable `64 -> 96`, kernel=5 | `[B, 96, 174]` |
| block2 pool | `MaxPool1d(2)` | `[B, 96, 87]` |
| block3 | depthwise separable `96 -> 128`, kernel=5 | `[B, 128, 87]` |
| avg pool | `AdaptiveAvgPool1d(1)` | `[B, 128]` |
| max pool | `AdaptiveMaxPool1d(1)` | `[B, 128]` |
| concat | avg + max | `[B, 256]` |
| embedding | `Linear(256, 128)` + ReLU + Dropout | `[B, 128]` |
| classifier | `Linear(128, 5)` | `[B, 5]` |

手工核算参数量：

```text
DeeperCNN1D total params = 57,125
```

## 7. 推理时需要保留和移除的算子

FPGA 推理需要保留：

```text
Conv1d
BatchNorm folded into Conv/Linear
ReLU
MaxPool1d
AdaptiveAvgPool1d
Linear
Argmax / confidence
```

FPGA 推理不需要实现：

```text
Dropout
training loss
backpropagation
optimizer
```

BatchNorm 建议在导出权重时折叠：

```text
Conv/Linear + BatchNorm -> folded weight + folded bias
```

这样 FPGA 端不需要单独实现 BatchNorm。

## 8. FPGA 迁移关注点

### 8.1 固定输入规格

硬件输入应固定为：

```text
5 channels x 348 samples
```

推荐内存布局：

```text
channel-major:
ch0[0:347], ch1[0:347], ..., ch4[0:347]

或 time-major:
t0[ch0:ch4], t1[ch0:ch4], ...
```

若直接对接当前 PyTorch 结构，`channel-major` 更接近 `[5, 348]`。

### 8.2 优先迁移 LightCNN1D

原因：

- 默认配置使用 `architecture: light`。
- 参数量只有 19,973。
- 结构比 `DeeperCNN1D` 更适合第一版 FPGA 部署。

### 8.3 最关键的硬件模块

```text
Conv1d engine
Depthwise Conv1d engine
Pointwise Conv1d engine
MaxPool1d engine
Global Average Pool engine
Linear engine
Argmax/confidence engine
```

### 8.4 适合的优化

```text
定点量化
BatchNorm folding
Conv + ReLU fusion
Depthwise/Pointwise 分离优化
Weight stationary
Sliding window buffer
Loop pipelining
Partial loop unrolling
Channel folding
```

## 9. 最终硬件实现建议

第一版 FPGA 目标模型：

```text
LightCNN1D
input = [5, 348]
num_classes = 5
embedding_dim = 96
dropout removed
batchnorm folded
```

推荐硬件数据流：

```text
input window [5, 348]
-> stem Conv1d 5->32 k7
-> ReLU
-> block1 depthwise k5
-> block1 pointwise 32->64
-> ReLU
-> MaxPool1d k2
-> block2 depthwise k5
-> block2 pointwise 64->96
-> ReLU
-> AdaptiveAvgPool1d(1)
-> Linear 96->96
-> ReLU
-> Linear 96->5
-> Argmax
```

输出：

```text
class_id
confidence 或 logits[5]
```
