# weight_data

LightCNN1D checkpoint 权重的硬件友好格式存储。每个计算模块一个子目录，含其计算时直接读取的 `.mem` 文件；顶层 `manifest.json` 是机器可读的完整索引。

## 来源

- **checkpoint**：`emg_gesture_repro/checkpoint_best.pt`
- **epoch**：34
- **best_val_macro_f1**：0.9037
- **class_labels**：[1, 2, 3, 4, 5]
- **模型**：`emg_gesture_repro/src/emg_gesture/models/cnn1d.py::LightCNN1D`
- **布局参考**：`workdir/参数与激活读取策略_2026-07-06.md`

## 目录结构

```
weight_data/
├── README.md             ← 本文件
├── manifest.json         ← 机器可读索引（路径、shape、布局、量化统计）
├── export_weights.py     ← 可复现的生成脚本
├── raw/                  ← 原始 per-tensor hex（PyTorch 自然顺序，调试用）
│   ├── metadata.json
│   ├── stem_conv_weight.hex
│   ├── ...（21 个 hex 文件，对应每个原始 tensor）
├── stem/                 ← stem_conv_array_4x4 读取
│   ├── weight_packed.mem   (280 words × 64-bit)
│   ├── bn_scale.mem        (32 entries)
│   └── bn_bias.mem         (32 entries)
├── dw1/                  ← dw_conv1_4ch_5tap 读取
│   └── weight.mem          (160 entries)
├── pw1/                  ← pw_conv1_array_4x8 读取
│   ├── weight_packed.mem   (256 words × 128-bit)
│   ├── bn_scale.mem        (64 entries)
│   └── bn_bias.mem         (64 entries)
├── dw2/                  ← dw_conv2_4ch_5tap 读取
│   └── weight.mem          (320 entries)
├── pw2/                  ← pw_conv2_array_4x12 读取
│   ├── weight_packed.mem   (512 words × 192-bit)
│   ├── bn_scale.mem        (96 entries)
│   └── bn_bias.mem         (96 entries)
├── fc0/                  ← fc_classifier_96_5 FC0 portion 读取
│   └── weight.mem          (9312 entries = 96 out × 97 k, k=96 is bias)
└── fc1/                  ← fc_classifier_96_5 FC1 portion 读取
    └── weight.mem          (485 entries = 5 out × 97 k, k=96 is bias)
```

## 量化格式

- **每个数值**：16-bit signed，2's complement，Q8.8（8 位小数）
- **1 LSB = 1/256 ≈ 0.00390625**
- **表示范围**：[-128.0, +127.99609375]
- **量化公式**：`q_int16 = round(float_value × 256)`，饱和到 `[-32768, +32767]`
- **文件中每行**：1 个值（4 位大写 hex）或 1 个 packed word（4N 位 hex）

## packed word 布局（systolic array weight ROM 用）

```
word[lane*16 +: 16] = lane_value
```

- `lane 0` 位于 LSB（hex 字符串最右 4 个字符）
- `lane 1` 位于 `[31:16]`（hex 字符串从右往左第 5–8 个字符）
- 依此类推

例子：4-lane word（stem，64-bit），`lanes = [0x0015, 0xFFFA, 0x000F, 0x1234]`
- 文件中 hex 字符串：`1234` `000F` `FFFA` `0015`（拼接为 `1234000FFFFA0015`）
- Verilog 读入 `reg [63:0]` 后：
  - `word[15:0]`  = `0x0015`（lane 0）
  - `word[31:16]` = `0xFFFA`（lane 1，负数）
  - `word[47:32]` = `0x000F`（lane 2）
  - `word[63:48]` = `0x1234`（lane 3）

## BN 折叠（folded BN scale/bias）

每个有 BN 的 conv 模块（stem、PW1、PW2）输出两个文件：

```
bn_scale[oc] = gamma[oc] / sqrt(var[oc] + eps)
bn_bias[oc]  = beta[oc]  - mean[oc] * bn_scale[oc]
```

`eps = 1e-5`（PyTorch BatchNorm1d 默认值）。

DW1、DW2 没有独立 BN（PyTorch block1/block2 的 BN 在 PW 之后），BN 折叠进了 PW1/PW2。FC0/FC1 没有 BN。

## 每个模块的文件与加载方式

### stem (stem_conv_array_4x4)

| 文件 | 内容 | shape | 元素数 |
|---|---|---|---|
| `weight_packed.mem` | 8 oc_groups × 35 k_flat packed words | [8, 35] | 280 words × 4 lanes = 1120 weights |
| `bn_scale.mem` | folded BN scale per output channel | [32] | 32 |
| `bn_bias.mem` | folded BN bias per output channel | [32] | 32 |

**寻址**：`address = oc_group * 35 + k_flat`，其中 `oc_group = weight_req_oc_base / 4`，`k_flat = weight_req_k`（0..34）

**lane 映射**：`lane[i] = W_stem[oc_group*4 + i][k_flat/7][k_flat%7]`

**k_flat 解码**：`input_channel = k_flat / 7`，`tap = k_flat % 7`

### dw1 (dw_conv1_4ch_5tap)

| 文件 | 内容 | 元素数 |
|---|---|---|
| `weight.mem` | 32 ch × 5 tap，row-major（ch 外 tap 内） | 160 |

**加载方式**：通过 `weight_we / weight_ch / weight_tap / weight_wdata` 端口逐条写入 `weight_mem[ch][tap]`。

文件第 `ch*5 + tap + 1` 行即 `weight_mem[ch][tap]`。

### pw1 (pw_conv1_array_4x8)

| 文件 | 内容 | shape | 元素数 |
|---|---|---|---|
| `weight_packed.mem` | 8 oc_groups × 32 k packed words | [8, 32] | 256 words × 8 lanes = 2048 weights |
| `bn_scale.mem` | folded BN scale | [64] | 64 |
| `bn_bias.mem` | folded BN bias | [64] | 64 |

**寻址**：`address = oc_group * 32 + k`，其中 `oc_group = weight_req_oc_base / 8`，`k = weight_req_k`（0..31）

**lane 映射**：`lane[i] = W_pw1[oc_group*8 + i][k]`

### dw2 (dw_conv2_4ch_5tap)

| 文件 | 内容 | 元素数 |
|---|---|---|
| `weight.mem` | 64 ch × 5 tap，row-major | 320 |

加载方式同 dw1，但 `weight_mem[64][5]`。

### pw2 (pw_conv2_array_4x12)

| 文件 | 内容 | shape | 元素数 |
|---|---|---|---|
| `weight_packed.mem` | 8 oc_groups × 64 k packed words | [8, 64] | 512 words × 12 lanes = 6144 weights |
| `bn_scale.mem` | folded BN scale | [96] | 96 |
| `bn_bias.mem` | folded BN bias | [96] | 96 |

**寻址**：`address = oc_group * 64 + k`，其中 `oc_group = weight_req_oc_base / 12`，`k = weight_req_k`（0..63）

**lane 映射**：`lane[i] = W_pw2[oc_group*12 + i][k]`

### fc0 (fc_classifier_96_5 FC0 portion)

| 文件 | 内容 | shape | 元素数 |
|---|---|---|---|
| `weight.mem` | 96 out × 97 k row-major，k=0..95 是 weight，k=96 是 bias | [96, 97] | 9312 |

**寻址**：`line = out_idx * 97 + k`，其中 `out_idx` ∈ [0, 95]，`k` ∈ [0, 96]

**加载方式**：通过 `(fc0_weight_out, fc0_weight_k, fc0_weight_wdata)` 端口逐条写入 `fc0_weight_mem[out][k]`。当 `fc0_weight_k = 96` 时，硬件写入 bias slot（`fc0_weight_mem[out][FC0_IN=96]`）。

模块在 `STATE_FC0_INIT` 时执行 `fc0_acc[j] <= bias_to_acc(fc0_weight_mem[fc0_base_reg + j][FC0_IN])`，即从 k=96 槽位读取 bias 初始化累加器。

**写入保护**：`(state == STATE_IDLE) && !start` 时才接受写入（与 DW1/DW2/PW1/PW2 一致）。

### fc1 (fc_classifier_96_5 FC1 portion)

| 文件 | 内容 | shape | 元素数 |
|---|---|---|---|
| `weight.mem` | 5 out × 97 k row-major，k=0..95 是 weight，k=96 是 bias | [5, 97] | 485 |

**寻址**：`line = out_idx * 97 + k`，其中 `out_idx` ∈ [0, 4]，`k` ∈ [0, 96]

**加载方式**：通过 `(fc1_weight_out, fc1_weight_k, fc1_weight_wdata)` 端口写入。当 `fc1_weight_k = 96` 时写入 bias slot。

注意：FC1 模块在硬件里 5 个输出神经元**全部并行计算**（不是 16-lane systolic），所以 FC1 不需要 packed 格式。

## 量化质量

| 统计 | 数值 |
|---|---|
| 总采样数（含 raw + packed + folded BN） | 19973 |
| RMSE | 0.001122 |
| 最大绝对误差 | 0.001953 (= 0.5 LSB) |
| Overflow 计数 | 0 |
| BN scale 量化范围 absmax | ~5.35（远在 Q8.8 ±128 内） |
| BN bias 量化范围 absmax | ~3.81 |

所有权重和 folded BN 参数都无饱和。

## Verilog 加载示例

### stem weight ROM controller

```verilog
reg [63:0] stem_weight_rom [0:279];
initial $readmemh("weight_data/stem/weight_packed.mem", stem_weight_rom);

// When stem_conv issues weight_req_valid:
//   oc_group = weight_req_oc_base / 4
//   k_flat   = weight_req_k
//   word = stem_weight_rom[oc_group * 35 + k_flat]
//   weight_vec[lane*16 +: 16] = word[lane*16 +: 16]
```

### fc0/fc1 local weight_mem init

```verilog
integer o, k;
reg [15:0] fc0_w [0:9311];
initial $readmemh("weight_data/fc0/weight.mem", fc0_w);

always @(posedge clk) begin
  // setup phase: pulse writes through the (out, k, wdata) port
  for (o = 0; o < 96; o = o + 1)
    for (k = 0; k <= 96; k = k + 1) begin
      // fc0_weight_we = 1; fc0_weight_out = o; fc0_weight_k = k;
      // fc0_weight_wdata = fc0_w[o*97 + k];
      // wait one clock;
    end
  // Same pattern for FC1: 5 out x 97 k = 485 entries
end
```

注意：`k=96` 的写入会被 `fc0_weight_mem[o][96]` 接收，这就是 bias。`FC0_IN=96`，`fc0_weight_k <= FC0_IN` 是允许的范围（包含等号）。

### dw1 local weight_mem init

### stem folded BN scale/bias

```verilog
reg signed [15:0] stem_bn_scale [0:31];
reg signed [15:0] stem_bn_bias  [0:31];
initial $readmemh("weight_data/stem/bn_scale.mem", stem_bn_scale);
initial $readmemh("weight_data/stem/bn_bias.mem",  stem_bn_bias);

// Inside PE: conv_q = (acc >>> FRAC_BITS); y = sat_q8_8(conv_q * stem_bn_scale[oc] >>> 8) + stem_bn_bias[oc]
```

## 复现

```bash
cd /mnt/d/Intership/weight_data
python3 export_weights.py
```

会重新生成 `raw/`、所有模块子目录、`manifest.json`。需先安装 `torch`。

## 关于 `raw/`

`raw/` 保留 PyTorch 原始 (out, in, k) 顺序的 per-tensor hex（一行一个值）。它的用途：

1. 调试：直接 $readmemh 进 Verilog 后用 (out, in, k) 三层 for 循环索引
2. 算法验证：Python 端可以重新加载并比对量化误差
3. 重建：`raw/` 是 packed 文件的"源数据"，需要重建任何 packed layout 时从这里出发

`raw/metadata.json` 记录每个 tensor 的原始 PyTorch key、shape、absmax 和 overflow 计数。
