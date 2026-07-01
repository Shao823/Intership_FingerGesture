# LightCNN1D RTL加速器当前设计思路

本文只讨论当前 `LightCNN1D` 在 Vivado RTL 中应该怎样搭建计算架构、缓存结构和流水线。论文摘录与资料总结已经保留在 `1D_CNN_FPGA论文架构总结与LightCNN1D加速器设计指导.md` 中。

当前建议不是继续把 HLS 算子封装成 IP，而是在 Vivado 内直接写 RTL 核心。这样顶层接口可以长期稳定，后续改内部 PE 阵列、缓存和流水线时，不需要反复重新封装 HLS IP。

---

## 1. 当前网络结构和计算量

当前网络结构固定为：

```text
input [5, 348]
 -> stem Conv1d:       5 -> 32, kernel=7, padding=3
 -> BN0 + ReLU
 -> block1 DW Conv1d: 32 -> 32, kernel=5, padding=2
 -> block1 PW Conv1d: 32 -> 64, kernel=1
 -> BN1 + ReLU
 -> MaxPool1d: kernel=2, stride=2
 -> block2 DW Conv1d: 64 -> 64, kernel=5, padding=2
 -> block2 PW Conv1d: 64 -> 96, kernel=1
 -> BN2 + ReLU
 -> GlobalAvgPool
 -> FC0: 96 -> 96 + ReLU
 -> FC1: 96 -> 5
 -> Argmax
```

各层输出 shape 和 MAC 数如下：

| 层 | 输出 shape | MAC 数 | 架构判断 |
|---|---:|---:|---|
| stem conv | `[32,348]` | `32*348*5*7 = 389,760` | 可映射成矩阵乘 |
| block1 depthwise | `[32,348]` | `32*348*5 = 55,680` | 适合专用滑窗 PU |
| block1 pointwise | `[64,348]` | `64*348*32 = 712,704` | 主要计算层 |
| maxpool | `[64,174]` | 比较操作 | 应与 BN/ReLU 融合 |
| block2 depthwise | `[64,174]` | `64*174*5 = 55,680` | 适合专用滑窗 PU |
| block2 pointwise | `[96,174]` | `96*174*64 = 1,069,056` | 最大瓶颈 |
| FC0 | `[96]` | `96*96 = 9,216` | 可复用 pointwise/GEMM 阵列 |
| FC1 | `[5]` | `5*96 = 480` | 可复用 pointwise/GEMM 阵列 |

结论：

```text
最需要优化: block2 pointwise
其次:       block1 pointwise
再次:       stem conv
较轻:       depthwise conv, FC, pool, argmax
```

所以硬件不应该平均设计。核心资源应该优先服务 `pointwise`，尤其是 `block2 pointwise`。

---

## 2. 总体架构选择

当前推荐的总体结构是：

```text
lightcnn1d_rtl_top
  |
  +-- input_pingpong_buffer
  |
  +-- layer_scheduler
  |
  +-- feature_buffer_bank
  |     +-- buf_a
  |     +-- buf_b
  |     +-- pool_buf
  |     +-- gap_buf / fc_buf
  |
  +-- weight_rom_bank
  |
  +-- gemm_conv_pe_array
  |     +-- mode_stem
  |     +-- mode_pw
  |     +-- mode_fc
  |
  +-- depthwise_slide_pu
  |     +-- mode_dw1
  |     +-- mode_dw2
  |
  +-- post_process_unit
  |     +-- bn_affine
  |     +-- relu
  |     +-- maxpool
  |     +-- gap_accumulator
  |     +-- argmax
  |
  +-- output_registers
```

这里有两个核心计算单元：

1. `gemm_conv_pe_array`

   这是通用卷积/矩阵乘 PE 阵列，用来处理：

   ```text
   stem conv
   pointwise conv
   FC0
   FC1
   ```

   它借鉴 2.1 论文里的可配置 PU 思想：不要为每一层单独写完全不同的计算硬件，而是用同一组 PE，在不同模式下改变地址生成、归约长度和输出 tile。

2. `depthwise_slide_pu`

   这是专门给 depthwise conv 的滑窗 PU。depthwise 的每个通道互相独立，不需要跨通道归约。如果强行用矩阵乘阵列，会有很多 PE 只能做单通道 k=5 小归约，阵列利用率不高。因此 depthwise 更适合专用 PU。

---

## 3. 通用 GEMM/Conv PE 阵列

### 3.1 为什么用 GEMM/类脉动阵列

`stem conv`、`pointwise conv` 和 `FC` 都可以统一成矩阵乘：

```text
C[M, N] = A[M, K] * B[K, N]
```

映射关系如下：

| 模式 | A 矩阵 | B 矩阵 | C 矩阵 | K 维度 |
|---|---|---|---|---|
| stem conv | `A[348, 5*7]` | `B[35, 32]` | `C[348, 32]` | `35` |
| block1 PW | `A[348, 32]` | `B[32, 64]` | `C[348, 64]` | `32` |
| block2 PW | `A[174, 64]` | `B[64, 96]` | `C[174, 96]` | `64` |
| FC0 | `A[1, 96]` | `B[96, 96]` | `C[1, 96]` | `96` |
| FC1 | `A[1, 96]` | `B[96, 5]` | `C[1, 5]` | `96` |

注意：`stem conv` 不建议真的在 BRAM 里展开 im2col。应该只在地址生成器里隐式展开：

```text
k = ic * 7 + kk
src_t = out_t + kk - 3
if src_t < 0 or src_t >= 348:
    A[out_t, k] = 0
else:
    A[out_t, k] = input[ic, src_t]
```

这样既能按矩阵乘调度，又不需要额外存一份 `348 * 35` 的 im2col buffer。

### 3.2 推荐 PE 阵列形态

初始版本推荐：

```text
P_T  = 4    // 并行时间位置数
P_OC = 4    // 并行输出通道数

PE array = 4 x 4 = 16 MAC
```

如果资源允许，针对 `block2 pointwise` 可以升级为：

```text
P_T  = 4
P_OC = 8

PE array = 4 x 8 = 32 MAC
```

PE 阵列采用 output-stationary 数据流：

```text
PE[row, col] 固定负责一个输出:

out_t = t_base  + row
out_c = oc_base + col

acc[row, col] += activation[out_t, k] * weight[k, out_c]
```

每个输出 tile 的计算流程：

```text
for k in 0 .. K-1:
    读 P_T 个 activation
    读 P_OC 个 weight
    送入 P_T * P_OC 个 PE
    每个 PE 做一次 MAC

K 个周期后:
    得到 P_T * P_OC 个输出
```

这是一种类 systolic 的矩阵乘结构，但不必一开始实现成完整的经典 systolic array。对当前网络来说，output-stationary PE 阵列更直接：

1. 每个 PE 内部保留 accumulator。
2. activation 在同一行 broadcast。
3. weight 在同一列 broadcast。
4. tile 完成后统一写回或送入 BN/ReLU/Pool。

结构示意：

```text
                 weight[oc0] weight[oc1] weight[oc2] weight[oc3]
                     |           |           |           |
act[t0] ----------> PE00        PE01        PE02        PE03
act[t1] ----------> PE10        PE11        PE12        PE13
act[t2] ----------> PE20        PE21        PE22        PE23
act[t3] ----------> PE30        PE31        PE32        PE33

每个 PE:
    acc <= acc + act * weight
```

### 3.3 各模式下的地址生成

#### mode_stem

stem 的计算公式：

```text
y[oc, t] = sum_ic sum_kk x[ic, t + kk - 3] * w[oc, ic, kk]
```

映射成 PE 阵列：

```text
M = time = 348
N = output channel = 32
K = input channel * kernel = 5 * 7 = 35
```

地址生成：

```text
k_idx = 0 .. 34
ic    = k_idx / 7
kk    = k_idx % 7
src_t = out_t + kk - 3

activation = src_t越界 ? 0 : input_mem[ic][src_t]
weight     = stem_weight[oc][ic][kk]
```

stem 的重点不是滑窗缓存，而是 padding 地址判断和 `5*7` 的归约。

#### mode_pw

pointwise 的计算公式：

```text
y[oc, t] = sum_ic x[ic, t] * w[oc, ic]
```

映射：

```text
block1 PW:
    M = 348
    N = 64
    K = 32

block2 PW:
    M = 174
    N = 96
    K = 64
```

地址生成：

```text
activation = feature_in[ic][t]
weight     = pw_weight[oc][ic]
```

这是整个网络最适合 PE 阵列加速的部分。尤其 `block2 PW`，K=64、N=96、M=174，计算量最大，阵列利用率也最好。

#### mode_fc

FC 可以看成 `M=1` 的矩阵乘：

```text
FC0:
    A[1,96] * B[96,96] -> C[1,96]

FC1:
    A[1,96] * B[96,5] -> C[1,5]
```

对于 FC，`P_T=4` 的时间维并行用不上，可以改成：

```text
P_T 实际只使用 row0
P_OC 并行多个输出神经元
K 做 96 轮归约
```

如果后续想提高 FC 利用率，可以让 4 个 row 同时算 4 个输出通道组，但当前 FC 计算量很小，没有必要优先优化。

---

## 4. Depthwise 滑窗 PU

### 4.1 depthwise 的具体计算形式

depthwise conv 的特点是每个输入通道独立卷积，不做跨通道求和：

```text
y[ch, t] = sum_kk x[ch, t + kk - pad] * w[ch, kk]
```

当前两层 depthwise 都是：

```text
kernel = 5
padding = 2
stride = 1
```

所以公式为：

```text
y[ch, t] =
    x[ch, t-2] * w[ch,0] +
    x[ch, t-1] * w[ch,1] +
    x[ch, t  ] * w[ch,2] +
    x[ch, t+1] * w[ch,3] +
    x[ch, t+2] * w[ch,4]
```

越界位置补 0。

这就是 2.3 论文中 `depthwise mode` 的本质：每个输入通道维护自己的滑窗，输出通道和输入通道一一对应。

### 4.2 为什么 depthwise 不优先使用 GEMM 阵列

depthwise 也能被转换成矩阵乘，但它的权重矩阵是稀疏块对角形式：

```text
每个输出通道只连接对应输入通道
不同通道之间没有乘加关系
```

如果用 `4x4` 或 `4x8` GEMM 阵列计算 depthwise，会遇到两个问题：

1. 每个输出只需要 5 个 tap，K 很短。
2. 通道之间没有共享归约，很多 PE 的数据复用价值很低。

因此更实际的方案是给 depthwise 一个轻量专用 PU。

### 4.3 推荐 depthwise PU 结构

推荐参数：

```text
P_CH_DW = 4 或 8    // 并行通道数
K_DW    = 5
```

完全并行 5-tap 版本：

```text
每个通道 5 个 multiplier
每个通道 1 个 adder tree

P_CH_DW = 4 时:
    4 * 5 = 20 个 multiplier

P_CH_DW = 8 时:
    8 * 5 = 40 个 multiplier
```

结构：

```text
for lane in 0 .. P_CH_DW-1:
    ch = ch_base + lane

    win0 = x[ch][t-2]
    win1 = x[ch][t-1]
    win2 = x[ch][t]
    win3 = x[ch][t+1]
    win4 = x[ch][t+2]

    y[ch][t] = win0*w0 + win1*w1 + win2*w2 + win3*w3 + win4*w4
```

如果 DSP 资源紧张，可以改成 5-cycle 串行版本：

```text
每个通道 1 个 multiplier
5 个周期完成一个 y[ch,t]
```

但当前 depthwise 总 MAC 很小，不建议把设计复杂度花在极限压缩 depthwise 上。更合理的是让 depthwise 足够快，不拖住前后 pointwise 流水。

### 4.4 depthwise 和后处理融合

当前网络中：

```text
stem conv -> BN0/ReLU -> DW1
DW1 -> PW1 -> BN1/ReLU/Pool
Pool -> DW2
DW2 -> PW2 -> BN2/ReLU/GAP
```

因此 depthwise 自身后面没有 BN。BN 都跟在 stem、PW1、PW2 后面。

推荐融合关系是：

```text
stem output -> BN0/ReLU -> 写 stem_act_buf -> DW1 读取
PW1 output  -> BN1/ReLU -> MaxPool -> 只写 pool_buf
PW2 output  -> BN2/ReLU -> GAP accumulator
```

depthwise PU 输出可以直接写给下一层 pointwise 输入 buffer。是否把 `DW1 -> PW1` 做成流式连接，要看后续调度复杂度；初版可以先整层写回，验证正确后再融合。

---

## 5. BN、ReLU、Pool、GAP 的处理

### 5.1 BN 参数不是全层一个标量

Conv1d 后的 BatchNorm1d 是按输出通道做归一化。对某一层来说：

```text
bn_mean[oc]
bn_scale[oc]
bn_bias[oc]
```

都是“每个输出通道一个数”。它不是每个 time 一个数，也不是整个层只共用一个数。

推理时可以写成：

```text
y = (x - running_mean[oc]) * gamma[oc] / sqrt(running_var[oc] + eps) + beta[oc]
```

当前 RTL 里等价为：

```text
bn_scale[oc] = gamma[oc] / sqrt(running_var[oc] + eps)
bn_bias[oc]  = beta[oc]

y = (x - bn_mean[oc]) * bn_scale[oc] + bn_bias[oc]
```

更进一步可以离线折叠成：

```text
y = x * folded_scale[oc] + folded_bias[oc]

folded_scale[oc] = gamma[oc] / sqrt(running_var[oc] + eps)
folded_bias[oc]  = beta[oc] - running_mean[oc] * folded_scale[oc]
```

这样硬件里就少一次减法。初期为了和现有黄金模型一致，可以先保留 `mean/scale/bias` 三项；优化稳定后再做 folding。

### 5.2 PW1 + BN + ReLU + MaxPool 融合

block1 pointwise 输出 shape 是：

```text
[64,348]
```

MaxPool 后是：

```text
[64,174]
```

这里的“融合”不是指把 `PW MAC -> BN乘法 -> ReLU -> Pool比较 -> BRAM写入` 全部放进同一个组合逻辑周期。正确含义是 **注册化的流式后处理融合**：

```text
PW acc_tile done
 -> pipeline register
 -> BN affine
 -> pipeline register
 -> ReLU
 -> pipeline register
 -> Pool compare / writeback
```

PE 阵列计算 `tile_n+1` 时，后处理流水可以处理 `tile_n`。这样不会把 PW 的 MAC critical path 拉长。

如果先完整写 `b1pw_mem[64][348]`，再读出来做 BN/ReLU/Pool，会多一次大容量写读。更好的方式是 PE 阵列一次算 4 个时间点：

```text
t = 0, 1, 2, 3
oc = 0, 1, 2, 3
```

得到 4x4 个 PW 输出后，按输出通道做：

```text
a0 = relu(bn(raw[oc][t+0]))
a1 = relu(bn(raw[oc][t+1]))
a2 = relu(bn(raw[oc][t+2]))
a3 = relu(bn(raw[oc][t+3]))

pool[oc][p+0] = max(a0, a1)
pool[oc][p+1] = max(a2, a3)
```

这样 `P_T=4` 与 pool kernel=2 很匹配。一次 tile 可以直接产生每个通道 2 个 pooled 输出。

收益：

```text
少存一整层 b1pw feature map
减少一次 BRAM 读
pool 比较器位于 BN/ReLU 后面的独立流水级
```

### 5.3 PW2 + BN + ReLU + GAP 融合

block2 pointwise 输出 shape 是：

```text
[96,174]
```

后面马上接 GlobalAvgPool：

```text
gap[oc] = sum_t relu(bn(pw2[oc,t])) / 174
```

因此 `PW2` 不一定要完整写 `[96,174]`。可以每次 tile 完成后：

```text
raw -> BN2 -> ReLU -> gap_sum[oc] += value
```

最后对每个输出通道除以 174。硬件中除以 174 可以用定点常数乘法近似：

```text
gap[oc] = gap_sum[oc] * inv_174
```

如果为了调试层级结果，初版可以保留：

```text
b2pw_buf[96][174]
```

等 layerwise 对齐稳定后，再切到流式 GAP。这个顺序更适合当前项目，因为 `174*96` buffer 可以作为 `PW2` 与后续 `GAP/FC` 的清晰验证边界。

---

## 6. 缓存和数据布局

### 6.1 初始稳妥版本

建议第一版优化 RTL 仍然保留清晰的层间 buffer：

```text
input_buf      [5][348]
stem_act_buf  [32][348]
dw1_buf       [32][348]
pool_buf      [64][174]
dw2_buf       [64][174]
gap_buf       [96]
fc_buf        [96]
logits        [5]
```

这会比最终融合版本多用一些 BRAM，但更容易验证。你的现有 8 组标准输入输出样例和 Python layerwise golden model 可以直接用于对齐。

### 6.2 优化后的缓存方向

逐步优化后，目标缓存结构可以变成：

```text
input ping-pong:
    in_buf0 / in_buf1

feature ping-pong:
    feat_buf_a
    feat_buf_b

fixed pool buffer:
    pool_buf[64][174]

small vector buffers:
    gap_sum[96]
    fc_vec[96]
    logits[5]

PE local registers:
    act_tile[P_T]
    weight_tile[P_OC]
    acc_tile[P_T][P_OC]

tile streaming buffers:
    tile_buf_ping
    tile_buf_pong
    post_fifo

debug / first optimized version:
    b2pw_buf[96][174]
```

不要一开始就追求最少 buffer。更好的路线是：

```text
先替换计算核心 -> 再融合后处理 -> 再减少 buffer -> 最后做跨样本流水
```

如果采用 time-tile 流水，tile buffer 需要支持 producer 和 consumer 速度不同。例如 DW 可能很快生产一个 `dw_tile[T_TILE][Cin]`，但 PW 需要更长时间消费这个 tile。此时应该用 ping-pong tile buffer 或小 FIFO 解耦，而不是强行让 DW 和 PW 每个点一拍对齐。

### 6.3 权重 ROM 分 bank

PE 阵列每拍需要：

```text
P_T 个 activation
P_OC 个 weight
```

其中 activation 可以 broadcast，weight 需要并行读多个输出通道。因此权重 ROM 不宜只有单端口大 case。建议按输出通道 bank 化：

```text
weight_bank[oc_parallel_lane]
```

例如 `P_OC=4` 时，每拍读：

```text
w[oc_base+0][k]
w[oc_base+1][k]
w[oc_base+2][k]
w[oc_base+3][k]
```

如果 Vivado 综合时 ROM 端口不足，可以用以下方式之一：

1. 按 `oc % P_OC` 拆成多个 ROM bank。
2. 对小权重复制 ROM，提高读端口。
3. 预取一个 `P_OC` 的 weight tile 到寄存器。

---

## 7. 流水线设计：tile 级流动与 balanced pipeline

### 7.1 先区分三种流水线

当前项目里容易把三种不同层次的流水线混在一起：

```text
1. 算子内部流水:
   multiplier -> accumulator -> shift/saturate

2. tile 级流式流水:
   一个 time tile 从 stem/DW/PW/后处理逐步向后流

3. 跨样本超级流水:
   sample_i 在 PW2 时，sample_i+1 在 PW1，sample_i+2 在 stem
```

第一种几乎一定要做，因为它直接帮助过时钟约束。第二种是当前最值得设计清楚的部分。第三种只有在复制出多套 GEMM/PW 资源后才真正成立。

DAC 2023 那篇 weight mapping and pipeline optimization 论文给当前项目的主要启发是：流水线不能只看计算单元，还要同时看 buffer access。raw inter-layer pipeline 会被瓶颈层卡住；只复制计算单元也不一定够，因为输入读、输出写和 partial sum 访问仍可能串行卡住。

### 7.2 融合不是拉长关键路径

`PW1 + BN + ReLU + MaxPool` 和 `PW2 + BN + ReLU + GAP` 的融合目标是减少中间 feature map 的读写，不是把所有逻辑塞进 PW 的组合路径。

错误理解：

```text
PW MAC combinational
 -> BN multiply combinational
 -> ReLU combinational
 -> Pool compare combinational
 -> BRAM write
```

正确结构：

```text
PW PE array 计算 tile_n+1

同时:
tile_n acc_done
 -> reg
 -> BN affine
 -> reg
 -> ReLU
 -> reg
 -> Pool/GAP/writeback
```

这样关键路径仍然主要在 PE 的乘法、累加、移位和饱和附近。BN/ReLU/Pool 是后面的独立流水级，只要寄存器切分合理，不会拖长 PW 的组合 critical path。

### 7.3 不要做单点级流水，应该做 time tile 级流水

不推荐：

```text
DW 算完 time=t 的所有通道
 -> 立刻开始 PW 的 time=t
```

原因是 PW 的优势来自二维 tile：

```text
P_T 个时间点
P_OC 个输出通道
```

如果每次只喂一个时间点，PW 阵列退化成 `P_T=1` 的 vector-matrix engine，`4x4` 或 `4x8` 阵列的时间维并行价值会下降。

推荐使用：

```text
T_TILE = 4 或 8
```

例如 `T_TILE=4` 时，DW 先生产：

```text
dw_tile[4][Cin]
```

PW 再消费这个 tile：

```text
每个 k/ic 周期:
    读 4 个 activation: x[t0..t3][ic]
    读 P_OC 个 weight:  w[oc0..ocN][ic]
    PE[row,col] 累加一个输出
```

这样 PW 阵列仍然保持 output-stationary 的高利用率。

### 7.4 tile 必须带 halo

如果一个 tile 想从输入一路流到 `PW2`，它不能只包含目标输出时间点本身。因为 stem、DW1、DW2 都有邻域依赖。

假设目标是产生最终 `PW2` 时间位置：

```text
p = p0 .. p0 + T_TILE - 1
```

由于 `DW2 kernel=5 padding=2`，需要 pool 输入：

```text
pool index = p0 - 2 .. p0 + T_TILE + 1
```

pool 的每个位置来自高分辨率时间轴上两个点：

```text
hires index = 2*pool, 2*pool + 1
```

`DW1 kernel=5` 还需要前后 2 个 stem 点，`stem kernel=7` 还需要前后 3 个 input 点。因此粗略需要的原始输入范围是：

```text
input time = 2*p0 - 9  到  2*p0 + 2*T_TILE + 8
```

越界位置按 padding 0 处理。

所以 tile 级流水的正确单位是：

```text
目标输出 tile + 必要 halo
```

不是简单拿 `T_TILE` 个输入点就能一路算到底。第一版如果不想处理复杂 halo，可以先按整层 buffer 验证；后续再把 stem/DW/PW 改成 halo tile 流水。

### 7.5 DW 是快速 producer，PW 是慢速 consumer

以 `T_TILE=4` 粗估：

```text
DW1, P_CH_DW=4:
    4 * ceil(32/4) = 32 cycles

PW1, P_OC=8:
    ceil(64/8) * 32 = 256 cycles

DW2, P_CH_DW=4:
    4 * ceil(64/4) = 64 cycles

PW2, P_OC=8:
    ceil(96/8) * 64 = 768 cycles
```

这说明 DW 很难成为瓶颈。不要为了让 DW 的单点输出立刻进入 PW，而把 PW 阵列缩成 `2x2`。那样会让真正的瓶颈 `PW1/PW2` 变慢。

更合理的结构是：

```text
DW_PU
 -> dw_tile_ping / dw_tile_pong
 -> PW PE array
```

DW 生产一个 tile 后，如果 PW 正在消费另一个 tile，就写到另一个 ping-pong buffer。PW 消费速度慢时，DW 等待是正常的。目标不是让每个小模块永不等待，而是让主要 GEMM/PW 资源尽量持续工作。

### 7.6 access/execute/write-back 解耦

借鉴 DAC 论文的 decoupled access and execution，单个 stage 内不要做：

```text
load tile
 -> compute tile
 -> write tile
 -> load next tile
```

而应该做：

```text
cycle region n:
    load tile_n+1
    compute tile_n
    write tile_n-1
```

在 RTL 里对应：

```text
tile_load_addr_gen
tile_compute_engine
tile_writeback_engine
tile_pingpong_buffer
postprocess_fifo
```

对当前网络，最需要关注的不是 DW 的 load，而是：

```text
PW activation tile 是否能每拍读出 P_T 个值
PW weight ROM 是否能每拍读出 P_OC 个值
PW 输出 tile 是否能不阻塞地写入后处理 FIFO 或 b2pw_buf
```

如果 `P_OC=8`，但 weight ROM 只有一个读端口，PE 阵列就会空转。因此 balanced pipeline 同时要求：

```text
计算并行度
BRAM/ROM bank 数
读写端口
后处理吞吐
```

一起匹配。

### 7.7 两种可实现路线

#### 路线 A：层级顺序 + tile 内流水

资源：

```text
1 套 GEMM/Conv PE array
1 套 depthwise_slide_pu
1 套 registered postprocess pipeline
```

执行方式：

```text
sample 内部仍然按层顺序:
    stem -> DW1 -> PW1/Pool -> DW2 -> PW2/GAP -> FC

每个层内部:
    load tile / compute tile / write tile 解耦
```

这个版本不能实现真正跨样本超级流水，因为同一套 GEMM 阵列不能同时算 `stem`、`PW1` 和 `PW2`。但它已经能减少中间 buffer 访问，并且更容易验证。

#### 路线 B：多计算资源 + 跨样本 balanced pipeline

资源：

```text
GEMM_STEM: 主要算 stem
GEMM_PW1:  主要算 PW1
GEMM_PW2:  主要算 PW2/FC
DW_PU:     算 DW1/DW2，必要时拆成 DW1_PU 和 DW2_PU
```

跨样本时间槽：

```text
slot0:
    sample0 stem

slot1:
    sample1 stem
    sample0 DW1

slot2:
    sample2 stem
    sample1 DW1
    sample0 PW1/Pool

slot3:
    sample3 stem
    sample2 DW1
    sample1 PW1/Pool
    sample0 DW2

slot4:
    sample4 stem
    sample3 DW1
    sample2 PW1/Pool
    sample1 DW2
    sample0 PW2/GAP/FC
```

这才是真正意义上的超级流水线。它的吞吐由最慢 stage 决定，所以资源分配要让主要 stage 延迟尽量接近。

例如：

```text
stem,  P_T=4, P_OC=4: 24,360 cycles
PW1,   P_T=4, P_OC=8: 22,272 cycles
PW2,   P_T=4, P_OC=8: 33,792 cycles
DW1/DW2:               远小于 GEMM stage
```

此时系统吞吐接近 `PW2` 的 33k cycles/sample，而不是所有层串行相加。若继续优化，优先考虑：

```text
1. 给 PW2 更多 P_OC 或复制 PW2 资源
2. 确保 PW2 weight bank 和 activation buffer 能喂满 PE
3. 让 PW2 后处理写入 b2pw_buf 或 gap_sum 时不反压 PE
```

### 7.8 推荐现实路线

当前建议：

```text
阶段 A:
    保留整层 buffer
    实现 GEMM PE array
    先优化 PW2/PW1 的 tile 计算

阶段 B:
    加入 registered BN/ReLU/Pool/GAP 后处理流水
    消除 b1pw 中间大 buffer
    第一版 PW2 可以仍写 b2pw_buf[96][174]

阶段 C:
    引入 time tile + halo
    用 tile ping-pong buffer 让 DW/PW 按 tile 流动

阶段 D:
    如果资源允许，复制 GEMM_STEM/GEMM_PW1/GEMM_PW2
    做跨样本 balanced pipeline
```

不要一开始就追求“每一级完全不等待”。真实硬件里允许局部等待；关键是避免最贵的 PW/GEMM 阵列长期空转，并让主要 stage 的延迟尽量接近。

---

## 8. 关键瓶颈 PW2 的优化

`block2 pointwise` 是最大计算层：

```text
M = 174
N = 96
K = 64
MAC = 174 * 96 * 64 = 1,069,056
```

如果使用 `P_T=4, P_OC=4`：

```text
cycles = ceil(174/4) * ceil(96/4) * 64
       = 44 * 24 * 64
       = 67,584 cycles
```

如果使用 `P_T=4, P_OC=8`：

```text
cycles = ceil(174/4) * ceil(96/8) * 64
       = 44 * 12 * 64
       = 33,792 cycles
```

同样估算其他 GEMM 层：

```text
stem, P_T=4, P_OC=4:
    ceil(348/4) * ceil(32/4) * 35
  = 87 * 8 * 35
  = 24,360 cycles

PW1, P_T=4, P_OC=4:
    ceil(348/4) * ceil(64/4) * 32
  = 87 * 16 * 32
  = 44,544 cycles

PW2, P_T=4, P_OC=4:
    67,584 cycles

PW2, P_T=4, P_OC=8:
    33,792 cycles
```

所以 `P_OC=8` 对 PW2 很有价值。优化优先级：

1. 先保证 PE 阵列能持续喂满 `P_OC` 个 weight。
2. 给 PW2 使用更高输出通道并行度。
3. 将 PW2 后面的 BN/ReLU/GAP 做成注册化流式后处理；第一版可先写回 `[96][174]` 便于验证。
4. 如果时钟约束紧，给 multiplier、accumulator、BN affine 都加 pipeline register。

---

## 9. 状态机和计数器设计

不要写一个巨大的手工嵌套 FSM。建议使用“层状态 + tile 计数器”的结构。

### 9.1 顶层状态

```text
S_IDLE
S_LOAD_INPUT
S_STEM
S_BN0_RELU
S_DW1
S_PW1_POOL
S_DW2
S_PW2_GAP
S_FC0
S_FC1
S_ARGMAX
S_DONE
```

### 9.2 GEMM tile 计数器

GEMM 类状态使用统一计数器：

```text
t_base
oc_base
k_idx
```

伪代码：

```text
if enter_gemm_state:
    t_base  = 0
    oc_base = 0
    k_idx   = 0
    clear acc_tile

each cycle:
    feed activation_tile and weight_tile
    acc_tile += act * weight

    if k_idx == K-1:
        output tile valid
        run postprocess or writeback
        clear acc_tile
        advance oc_base / t_base
    else:
        k_idx++
```

不同层只改变：

```text
M
N
K
activation_address_mode
weight_base
postprocess_mode
writeback_target
```

### 9.3 DW tile 计数器

DW 状态使用：

```text
ch_base
t_idx
```

每拍或每几个周期输出：

```text
P_CH_DW 个通道在同一个 t_idx 的 depthwise 结果
```

伪代码：

```text
for t_idx in 0 .. length-1:
    for ch_base in 0 .. channels-1 step P_CH_DW:
        load 5-tap window for each lane
        multiply and reduce
        write y[ch][t]
```

---

## 10. 固定点数据通路

当前 RTL 已经使用：

```text
activation / weight / BN parameter: signed Q8.8, 16-bit
accumulator: signed 48-bit
```

乘法：

```text
Q8.8 * Q8.8 = Q16.16
```

卷积累加后需要右移 8 位回到 Q8.8：

```text
conv_out_q8_8 = saturate(acc >>> 8)
```

BN affine 如果仍然使用 `mean/scale/bias`：

```text
centered = conv_out - bn_mean[oc]
scaled   = centered * bn_scale[oc]    // Q8.8 * Q8.8 = Q16.16
bn_out   = (scaled >>> 8) + bn_bias[oc]
relu_out = max(bn_out, 0)
```

实现细节：

1. 所有右移都必须保持 signed arithmetic shift。
2. 乘法输出、累加器、BN 中间值要留足位宽。
3. 每个写回点都要做 saturate，避免仿真和综合后溢出行为不一致。

---

## 11. 具体计算例子：PW1 + BN + ReLU + MaxPool

假设使用：

```text
P_T  = 4
P_OC = 4
layer = block1 pointwise
input feature = DW1 output [32,348]
output before pool = [64,348]
output after pool  = [64,174]
```

选择一个 tile：

```text
t_base  = 0
oc_base = 0

需要计算:
    y[oc=0..3, t=0..3]
```

PW1 公式：

```text
y[oc,t] = sum_ic=0..31 dw1[ic,t] * pw1_weight[oc,ic]
```

PE 阵列映射：

```text
PE[0,0] -> y[0,0]
PE[0,1] -> y[1,0]
PE[0,2] -> y[2,0]
PE[0,3] -> y[3,0]

PE[1,0] -> y[0,1]
PE[1,1] -> y[1,1]
...

PE[3,3] -> y[3,3]
```

每个 `ic` 周期：

```text
cycle ic=0:
    row inputs:
        act0 = dw1[0][0]
        act1 = dw1[0][1]
        act2 = dw1[0][2]
        act3 = dw1[0][3]

    col weights:
        w0 = pw1_weight[0][0]
        w1 = pw1_weight[1][0]
        w2 = pw1_weight[2][0]
        w3 = pw1_weight[3][0]

    all PE do:
        acc[row,col] += act[row] * w[col]

cycle ic=1:
    act0 = dw1[1][0]
    act1 = dw1[1][1]
    act2 = dw1[1][2]
    act3 = dw1[1][3]

    w0 = pw1_weight[0][1]
    w1 = pw1_weight[1][1]
    w2 = pw1_weight[2][1]
    w3 = pw1_weight[3][1]

    acc += act * w

...

cycle ic=31:
    完成 32 个输入通道归约
```

32 个周期后得到 16 个 raw 输出：

```text
raw[t0][oc0], raw[t0][oc1], raw[t0][oc2], raw[t0][oc3]
raw[t1][oc0], raw[t1][oc1], raw[t1][oc2], raw[t1][oc3]
raw[t2][oc0], raw[t2][oc1], raw[t2][oc2], raw[t2][oc3]
raw[t3][oc0], raw[t3][oc1], raw[t3][oc2], raw[t3][oc3]
```

然后对每个输出通道分别使用对应 BN 参数：

```text
bn[t][oc] = (raw[t][oc] - bn1_mean[oc]) * bn1_scale[oc] + bn1_bias[oc]
act[t][oc] = relu(bn[t][oc])
```

再做 pool：

```text
pool[oc][0] = max(act[0][oc], act[1][oc])
pool[oc][1] = max(act[2][oc], act[3][oc])
```

最后只写：

```text
pool_buf[oc=0..3][p=0..1]
```

而不是写完整：

```text
b1pw_buf[oc=0..3][t=0..3]
```

这个例子体现了当前设计的三个核心点：

1. `pointwise` 使用 PE 阵列做高利用率矩阵乘。
2. PE 使用 output-stationary，累加结果保留在本地寄存器直到 K 维结束。
3. BN/ReLU/Pool 位于 PE 输出后的注册化后处理流水，减少中间 feature map 写回。

---

## 12. 推荐 RTL 模块拆分

建议文件结构可以逐步演进为：

```text
rtl/lightcnn1d_opt/
  lightcnn1d_opt_defs.vh
  lightcnn1d_opt_top.v
  lightcnn1d_scheduler.v
  lightcnn1d_feature_buffers.v
  lightcnn1d_weight_rom.v
  gemm_conv_pe_array.v
  gemm_addr_gen.v
  depthwise_slide_pu.v
  bn_relu_unit.v
  pool_gap_unit.v
  argmax_unit.v
  tb/lightcnn1d_opt_tb.v
```

每个模块职责：

| 模块 | 职责 |
|---|---|
| `lightcnn1d_opt_top` | 顶层接口、start/done、输入输出寄存 |
| `lightcnn1d_scheduler` | 层状态机和 tile 计数器配置 |
| `feature_buffers` | 输入、层间、pool、gap buffer |
| `weight_rom` | 参数 ROM，按层和输出通道 bank 化 |
| `gemm_conv_pe_array` | stem/PW/FC 通用计算阵列 |
| `gemm_addr_gen` | 不同 mode 下的 activation/weight 地址生成 |
| `depthwise_slide_pu` | DW1/DW2 k=5 滑窗计算 |
| `bn_relu_unit` | BN affine、定点右移、饱和、ReLU |
| `pool_gap_unit` | MaxPool 和 GAP 累加 |
| `argmax_unit` | 5 类 logits 比较 |

---

## 13. 实施顺序

推荐按以下顺序改，不要同时改太多：

1. 保留现有 baseline RTL 和 8 组标准测试向量。
2. 新建 `lightcnn1d_opt`，先复制顶层接口和测试输入输出协议。
3. 先实现 `gemm_conv_pe_array`，只替换 `PW2`，因为它计算量最大且形态最规整。
4. 用 Python golden 或现有 layer dump 对齐 `PW2` 单层输出。
5. 再让同一个 PE 阵列支持 `PW1` 和 `stem`。
6. 实现 `depthwise_slide_pu`，替换 DW1/DW2。
7. 加入注册化的 `PW1 + BN/ReLU + MaxPool` 后处理流水。
8. 加入 `PW2 + BN/ReLU + GAP` 后处理流水；第一版可保留 `b2pw_buf[96][174]`。
9. 再引入 time tile + halo 的 tile 级流水。
10. 最后再考虑复制 PE 阵列做跨样本 balanced pipeline。

验证规则：

```text
每改一个层或融合一个后处理模块，都必须跑:
    1. 8 组标准输入输出 testbench
    2. 对应层的 Python fixed-point golden 对比
```

如果最终分类对了但中间层错了，不能认为架构正确。中间层逐层对齐才是可靠验证。

---

## 14. 当前推荐结论

当前最合适的设计不是“所有层都各写一套专用硬件”，也不是“一套完全通用但利用率很低的硬件”。推荐方案是：

```text
通用 output-stationary GEMM/Conv PE 阵列
    负责 stem / pointwise / FC

专用 depthwise k=5 滑窗 PU
    负责 DW1 / DW2

轻量后处理流水
    BN / ReLU / Pool / GAP

输入与 feature ping-pong buffer
    支持后续 tile 级流水和跨样本流水
```

第一版目标应当是：

```text
P_T=4, P_OC=4 的 PE 阵列
P_CH_DW=4 的 depthwise PU
保留足够 buffer 便于验证
PW1/Pool 和 PW2/GAP 先作为注册化后处理流水目标
```

第二版再考虑：

```text
P_OC=8 加速 PW2
权重 ROM bank 化
去掉 b1pw 大中间 buffer
用 tile ping-pong + halo 做层间流动
复制 GEMM 资源做跨样本 balanced pipeline
```
