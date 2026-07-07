"""Export LightCNN1D checkpoint weights to hardware-friendly Q8.8 packed files.

Output structure (under weight_data/):
  raw/                  Per-tensor hex files, one Q8.8 value per line.
                        Original PyTorch natural (out, in, k) order. Useful for
                        debugging or rebuilding any packed file by hand.
  stem/                 stem_conv_array_4x4 specific files:
    weight_packed.mem     8 oc_groups x 35 k_flat, 4 lanes/word, 64-bit words
    bn_scale.mem          32 entries, folded BN scale per output channel
    bn_bias.mem           32 entries, folded BN bias per output channel
  dw1/
    weight.mem            32 ch x 5 tap, one Q8.8 value per line (ch outer, tap inner)
  pw1/
    weight_packed.mem     8 oc_groups x 32 k, 8 lanes/word, 128-bit words
    bn_scale.mem          64 entries
    bn_bias.mem           64 entries
  dw2/
    weight.mem            64 ch x 5 tap, one Q8.8 value per line
  pw2/
    weight_packed.mem     8 oc_groups x 64 k, 12 lanes/word, 192-bit words
    bn_scale.mem          96 entries
    bn_bias.mem           96 entries
  fc0/
    weight.mem            96 out x 97 k, row-major, k=96 is bias
  fc1/
    weight.mem            5 out x 97 k, row-major, k=96 is bias
  manifest.json         Top-level manifest: file paths + per-module layout specs

Quantization: Q8.8 signed int16, two's complement, FRAC_BITS=8.
Packed word layout: word[lane*16 +: 16] = lane_value (lane 0 at LSB).
  In the hex string, lane 0 is the rightmost 4 chars, lane 1 the next 4, etc.
BN fold (eps=1e-5):
    scale[oc] = gamma[oc] / sqrt(var[oc] + eps)
    bias[oc]  = beta[oc]  - mean[oc] * scale[oc]

Layouts follow workdir/参数与激活读取策略_2026-07-06.md.
Reproducible: re-running this script regenerates all files from checkpoint.
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path

import torch

CHECKPOINT_PATH = "/mnt/d/Intership/emg_gesture_repro/checkpoint_best.pt"
OUTPUT_DIR = Path("/mnt/d/Intership/weight_data")
RAW_DIR = OUTPUT_DIR / "raw"
BN_EPS = 1e-5  # PyTorch BatchNorm1d default

FRAC_BITS = 8
Q_SCALE = 1 << FRAC_BITS
INT16_MIN = -(1 << 15)
INT16_MAX = (1 << 15) - 1


# ---------- quantization helpers ----------

def q88(value: float) -> int:
    """Quantize float to Q8.8, return unsigned 16-bit pattern (two's complement)."""
    scaled = int(round(value * Q_SCALE))
    if scaled > INT16_MAX:
        scaled = INT16_MAX
    elif scaled < INT16_MIN:
        scaled = INT16_MIN
    return scaled & 0xFFFF


def hex16(value: int) -> str:
    """4-char uppercase hex of a Q8.8 16-bit value."""
    return f"{value & 0xFFFF:04X}"


def hex_packed_word(lanes: list[int]) -> str:
    """Pack N 16-bit lane values into one hex string.
    lane[0] goes to LSB (rightmost in the string), lane[N-1] to MSB (leftmost).
    """
    return "".join(hex16(v) for v in reversed(lanes))


def write_lines(path: Path, lines: list[str]) -> None:
    with path.open("w") as fp:
        for ln in lines:
            fp.write(ln + "\n")


def fold_bn(gamma_t, beta_t, mean_t, var_t, eps: float = BN_EPS):
    scale = gamma_t / torch.sqrt(var_t + eps)
    bias = beta_t - mean_t * scale
    return scale, bias


def stats_q88(float_list: list[float]) -> dict:
    overflow = sum(
        1 for v in float_list
        if abs(int(round(v * Q_SCALE))) > INT16_MAX
    )
    absmax = max((abs(v) for v in float_list), default=0.0)
    return {"absmax_input": absmax, "absmax_q88": absmax * Q_SCALE, "overflow_count": overflow}


# ---------- raw per-tensor export ----------

RAW_TENSOR_MAP = {
    "stem.0.weight":               "stem_conv_weight",
    "stem.1.weight":               "stem_bn_gamma",
    "stem.1.bias":                 "stem_bn_beta",
    "stem.1.running_mean":         "stem_bn_mean",
    "stem.1.running_var":          "stem_bn_var",
    "block1.depthwise.weight":     "dw1_weight",
    "block1.pointwise.weight":     "pw1_weight",
    "block1_tail.0.weight":        "bn1_gamma",
    "block1_tail.0.bias":          "bn1_beta",
    "block1_tail.0.running_mean":  "bn1_mean",
    "block1_tail.0.running_var":   "bn1_var",
    "block2.depthwise.weight":     "dw2_weight",
    "block2.pointwise.weight":     "pw2_weight",
    "block2_tail.0.weight":        "bn2_gamma",
    "block2_tail.0.bias":          "bn2_beta",
    "block2_tail.0.running_mean":  "bn2_mean",
    "block2_tail.0.running_var":   "bn2_var",
    "embedding.weight":            "fc0_weight",
    "embedding.bias":              "fc0_bias",
    "classifier.weight":           "fc1_weight",
    "classifier.bias":             "fc1_bias",
}


def export_raw(state: dict) -> dict:
    if RAW_DIR.exists():
        shutil.rmtree(RAW_DIR)
    RAW_DIR.mkdir(parents=True)
    metadata = {
        "format": "Q8.8 signed int16, one value per line, PyTorch natural (out, in, k) C-order flatten",
        "tensors": {},
        "skipped": [],
    }
    for key, stem in RAW_TENSOR_MAP.items():
        t = state[key]
        flat = t.detach().cpu().float().flatten().tolist()
        qvals = [q88(v) for v in flat]
        write_lines(RAW_DIR / f"{stem}.hex", [hex16(v) for v in qvals])
        metadata["tensors"][stem] = {
            "pytorch_key": key,
            "hex_file": f"{stem}.hex",
            "shape": list(t.shape),
            "num_elements": len(flat),
            **stats_q88(flat),
        }
    for key in state.keys():
        if key in RAW_TENSOR_MAP:
            continue
        if key.endswith("num_batches_tracked"):
            metadata["skipped"].append({"key": key, "reason": "BN counter, not a weight"})
        else:
            metadata["skipped"].append({"key": key, "reason": "not in TENSOR_MAP"})
    with (RAW_DIR / "metadata.json").open("w") as fp:
        json.dump(metadata, fp, indent=2)
    return metadata


# ---------- per-module exports ----------

def _reset_module_dir(name: str) -> Path:
    out = OUTPUT_DIR / name
    if out.exists():
        shutil.rmtree(out)
    out.mkdir()
    return out


def export_stem(state, modules):
    out = _reset_module_dir("stem")
    w = state['stem.0.weight']           # (32, 5, 7)
    g, b = state['stem.1.weight'], state['stem.1.bias']
    m, v = state['stem.1.running_mean'], state['stem.1.running_var']

    P_OUT = 4
    K_FLAT = 35  # 5 in_channels × 7 taps
    OC_GROUPS = 32 // P_OUT  # 8

    lines = []
    for ocg in range(OC_GROUPS):
        for k_flat in range(K_FLAT):
            in_ch, tap = k_flat // 7, k_flat % 7
            lanes = [q88(w[ocg * P_OUT + lane, in_ch, tap].item()) for lane in range(P_OUT)]
            lines.append(hex_packed_word(lanes))
    write_lines(out / "weight_packed.mem", lines)

    scale, bias = fold_bn(g, b, m, v)
    scale_flat, bias_flat = scale.tolist(), bias.tolist()
    write_lines(out / "bn_scale.mem", [hex16(q88(x)) for x in scale_flat])
    write_lines(out / "bn_bias.mem", [hex16(q88(x)) for x in bias_flat])

    modules["stem"] = {
        "module": "stem_conv_array_4x4",
        "files": {
            "weight_packed": "stem/weight_packed.mem",
            "bn_scale": "stem/bn_scale.mem",
            "bn_bias": "stem/bn_bias.mem",
        },
        "specs": {
            "weight_packed": {
                "shape": [OC_GROUPS, K_FLAT],
                "lanes_per_word": P_OUT,
                "word_width_bits": P_OUT * 16,
                "total_words": OC_GROUPS * K_FLAT,
                "addressing": "address = oc_group * 35 + k_flat",
                "ranges": "oc_group in [0, 7], k_flat in [0, 34]",
                "lane_mapping": "lane[i] = W_stem[oc_group*4 + i][k_flat/7][k_flat%7] for i in [0..3]",
                "k_flat_decode": "input_channel = k_flat / 7, tap = k_flat % 7",
                **stats_q88(w.flatten().tolist()),
            },
            "bn_scale": {
                "shape": [32], "element_width_bits": 16, "total_elements": 32,
                "formula": "scale[oc] = stem_bn_gamma[oc] / sqrt(stem_bn_var[oc] + 1e-5)",
                **stats_q88(scale_flat),
            },
            "bn_bias": {
                "shape": [32], "element_width_bits": 16, "total_elements": 32,
                "formula": "bias[oc] = stem_bn_beta[oc] - stem_bn_mean[oc] * scale[oc]",
                **stats_q88(bias_flat),
            },
        },
    }
    print(f"  stem/: weight_packed.mem ({len(lines)} words x {P_OUT*16}b), bn_scale.mem, bn_bias.mem")


def export_dw1(state, modules):
    out = _reset_module_dir("dw1")
    w = state['block1.depthwise.weight']  # (32, 1, 5)

    CHANNELS, K = 32, 5
    lines = []
    for ch in range(CHANNELS):
        for tap in range(K):
            lines.append(hex16(q88(w[ch, 0, tap].item())))
    write_lines(out / "weight.mem", lines)

    modules["dw1"] = {
        "module": "dw_conv1_4ch_5tap",
        "files": {"weight": "dw1/weight.mem"},
        "specs": {
            "weight": {
                "shape": [CHANNELS, K],
                "element_width_bits": 16,
                "total_elements": CHANNELS * K,
                "layout": "row-major (ch outer, tap inner); load via (weight_ch, weight_tap, weight_wdata) port to weight_mem[ch][tap]",
                **stats_q88(w.flatten().tolist()),
            },
        },
        "notes": "DW1 has no BatchNorm (BN is folded into PW1 in this architecture).",
    }
    print(f"  dw1/: weight.mem ({len(lines)} entries)")


def export_pw1(state, modules):
    out = _reset_module_dir("pw1")
    w = state['block1.pointwise.weight']  # (64, 32, 1)
    g, b = state['block1_tail.0.weight'], state['block1_tail.0.bias']
    m, v = state['block1_tail.0.running_mean'], state['block1_tail.0.running_var']

    P_OUT = 8
    K = 32  # input channels
    OC_GROUPS = 64 // P_OUT  # 8

    lines = []
    for ocg in range(OC_GROUPS):
        for k in range(K):
            lanes = [q88(w[ocg * P_OUT + lane, k, 0].item()) for lane in range(P_OUT)]
            lines.append(hex_packed_word(lanes))
    write_lines(out / "weight_packed.mem", lines)

    scale, bias = fold_bn(g, b, m, v)
    scale_flat, bias_flat = scale.tolist(), bias.tolist()
    write_lines(out / "bn_scale.mem", [hex16(q88(x)) for x in scale_flat])
    write_lines(out / "bn_bias.mem", [hex16(q88(x)) for x in bias_flat])

    modules["pw1"] = {
        "module": "pw_conv1_array_4x8",
        "files": {
            "weight_packed": "pw1/weight_packed.mem",
            "bn_scale": "pw1/bn_scale.mem",
            "bn_bias": "pw1/bn_bias.mem",
        },
        "specs": {
            "weight_packed": {
                "shape": [OC_GROUPS, K],
                "lanes_per_word": P_OUT,
                "word_width_bits": P_OUT * 16,
                "total_words": OC_GROUPS * K,
                "addressing": "address = oc_group * 32 + k",
                "ranges": "oc_group in [0, 7], k in [0, 31]",
                "lane_mapping": "lane[i] = W_pw1[oc_group*8 + i][k] for i in [0..7]",
                **stats_q88(w.flatten().tolist()),
            },
            "bn_scale": {
                "shape": [64], "element_width_bits": 16, "total_elements": 64,
                "formula": "scale[oc] = bn1_gamma[oc] / sqrt(bn1_var[oc] + 1e-5)",
                **stats_q88(scale_flat),
            },
            "bn_bias": {
                "shape": [64], "element_width_bits": 16, "total_elements": 64,
                "formula": "bias[oc] = bn1_beta[oc] - bn1_mean[oc] * scale[oc]",
                **stats_q88(bias_flat),
            },
        },
        "notes": "PW1 applies folded BN + ReLU + MaxPool(k=2, stride=2) after pointwise conv.",
    }
    print(f"  pw1/: weight_packed.mem ({len(lines)} words x {P_OUT*16}b), bn_scale.mem, bn_bias.mem")


def export_dw2(state, modules):
    out = _reset_module_dir("dw2")
    w = state['block2.depthwise.weight']  # (64, 1, 5)

    CHANNELS, K = 64, 5
    lines = []
    for ch in range(CHANNELS):
        for tap in range(K):
            lines.append(hex16(q88(w[ch, 0, tap].item())))
    write_lines(out / "weight.mem", lines)

    modules["dw2"] = {
        "module": "dw_conv2_4ch_5tap",
        "files": {"weight": "dw2/weight.mem"},
        "specs": {
            "weight": {
                "shape": [CHANNELS, K],
                "element_width_bits": 16,
                "total_elements": CHANNELS * K,
                "layout": "row-major (ch outer, tap inner); load via (weight_ch, weight_tap, weight_wdata) port to weight_mem[ch][tap]",
                **stats_q88(w.flatten().tolist()),
            },
        },
        "notes": "DW2 has no BatchNorm (BN is folded into PW2 in this architecture).",
    }
    print(f"  dw2/: weight.mem ({len(lines)} entries)")


def export_pw2(state, modules):
    out = _reset_module_dir("pw2")
    w = state['block2.pointwise.weight']  # (96, 64, 1)
    g, b = state['block2_tail.0.weight'], state['block2_tail.0.bias']
    m, v = state['block2_tail.0.running_mean'], state['block2_tail.0.running_var']

    P_OUT = 12
    K = 64  # input channels
    OC_GROUPS = 96 // P_OUT  # 8

    lines = []
    for ocg in range(OC_GROUPS):
        for k in range(K):
            lanes = [q88(w[ocg * P_OUT + lane, k, 0].item()) for lane in range(P_OUT)]
            lines.append(hex_packed_word(lanes))
    write_lines(out / "weight_packed.mem", lines)

    scale, bias = fold_bn(g, b, m, v)
    scale_flat, bias_flat = scale.tolist(), bias.tolist()
    write_lines(out / "bn_scale.mem", [hex16(q88(x)) for x in scale_flat])
    write_lines(out / "bn_bias.mem", [hex16(q88(x)) for x in bias_flat])

    modules["pw2"] = {
        "module": "pw_conv2_array_4x12",
        "files": {
            "weight_packed": "pw2/weight_packed.mem",
            "bn_scale": "pw2/bn_scale.mem",
            "bn_bias": "pw2/bn_bias.mem",
        },
        "specs": {
            "weight_packed": {
                "shape": [OC_GROUPS, K],
                "lanes_per_word": P_OUT,
                "word_width_bits": P_OUT * 16,
                "total_words": OC_GROUPS * K,
                "addressing": "address = oc_group * 64 + k",
                "ranges": "oc_group in [0, 7], k in [0, 63]",
                "lane_mapping": "lane[i] = W_pw2[oc_group*12 + i][k] for i in [0..11]",
                **stats_q88(w.flatten().tolist()),
            },
            "bn_scale": {
                "shape": [96], "element_width_bits": 16, "total_elements": 96,
                "formula": "scale[oc] = bn2_gamma[oc] / sqrt(bn2_var[oc] + 1e-5)",
                **stats_q88(scale_flat),
            },
            "bn_bias": {
                "shape": [96], "element_width_bits": 16, "total_elements": 96,
                "formula": "bias[oc] = bn2_beta[oc] - bn2_mean[oc] * scale[oc]",
                **stats_q88(bias_flat),
            },
        },
        "notes": "PW2 applies folded BN + ReLU and accumulates into GAP register (no tile stream output).",
    }
    print(f"  pw2/: weight_packed.mem ({len(lines)} words x {P_OUT*16}b), bn_scale.mem, bn_bias.mem")


def export_fc0(state, modules):
    """FC0 weight+bias combined file matching fc_classifier_96_5.v layout.

    fc0_weight_mem[out][k] for out in [0..95], k in [0..96]:
      k = 0..95 -> weight W_fc0[out][k]
      k = 96    -> bias    b_fc0[out]

    File is row-major (out outer, k inner), one Q8.8 value per line.
    Loaded via the (fc0_weight_out, fc0_weight_k, fc0_weight_wdata) write port.
    """
    out = _reset_module_dir("fc0")
    w = state['embedding.weight']  # (96, 96)
    b = state['embedding.bias']    # (96,)

    OUT_DIM, IN_DIM = 96, 96
    K_EXT = IN_DIM + 1  # 97 (extra slot for bias)

    lines = []
    for out_idx in range(OUT_DIM):
        for k in range(IN_DIM):
            lines.append(hex16(q88(w[out_idx, k].item())))
        lines.append(hex16(q88(b[out_idx].item())))  # k=96 is bias

    assert len(lines) == OUT_DIM * K_EXT
    write_lines(out / "weight.mem", lines)

    w_flat = w.flatten().tolist()
    b_flat = b.tolist()
    modules["fc0"] = {
        "module": "fc_classifier_96_5 (FC0 portion)",
        "files": {"weight": "fc0/weight.mem"},
        "specs": {
            "weight": {
                "shape": [OUT_DIM, K_EXT],
                "element_width_bits": 16,
                "total_elements": OUT_DIM * K_EXT,
                "layout": "row-major (out outer, k inner); k=0..95 are weights, k=96 is bias",
                "addressing": "line = out_idx * 97 + k",
                "ranges": "out_idx in [0..95], k in [0..96]",
                "load_via": "(fc0_weight_out, fc0_weight_k, fc0_weight_wdata) port; fc0_weight_k=96 writes bias slot",
                "weight_absmax": max((abs(v) for v in w_flat), default=0.0),
                "bias_absmax": max((abs(v) for v in b_flat), default=0.0),
                "overflow_count": sum(
                    1 for v in (w_flat + b_flat)
                    if abs(int(round(v * Q_SCALE))) > INT16_MAX
                ),
            },
        },
        "notes": "FC0 = Linear(96, 96) + ReLU. No BatchNorm. Bias is stored at k=96 inside the same memory.",
    }
    print(f"  fc0/: weight.mem ({len(lines)} entries = 96 out x 97 k, k=96 is bias)")


def export_fc1(state, modules):
    """FC1 weight+bias combined file matching fc_classifier_96_5.v layout.

    fc1_weight_mem[out][k] for out in [0..4], k in [0..96]:
      k = 0..95 -> weight W_fc1[out][k]
      k = 96    -> bias    b_fc1[out]

    File is row-major (out outer, k inner), one Q8.8 value per line.
    Loaded via the (fc1_weight_out, fc1_weight_k, fc1_weight_wdata) write port.
    """
    out = _reset_module_dir("fc1")
    w = state['classifier.weight']  # (5, 96)
    b = state['classifier.bias']    # (5,)

    OUT_DIM, IN_DIM = 5, 96
    K_EXT = IN_DIM + 1  # 97

    lines = []
    for out_idx in range(OUT_DIM):
        for k in range(IN_DIM):
            lines.append(hex16(q88(w[out_idx, k].item())))
        lines.append(hex16(q88(b[out_idx].item())))  # k=96 is bias

    assert len(lines) == OUT_DIM * K_EXT
    write_lines(out / "weight.mem", lines)

    w_flat = w.flatten().tolist()
    b_flat = b.tolist()
    modules["fc1"] = {
        "module": "fc_classifier_96_5 (FC1 portion)",
        "files": {"weight": "fc1/weight.mem"},
        "specs": {
            "weight": {
                "shape": [OUT_DIM, K_EXT],
                "element_width_bits": 16,
                "total_elements": OUT_DIM * K_EXT,
                "layout": "row-major (out outer, k inner); k=0..95 are weights, k=96 is bias",
                "addressing": "line = out_idx * 97 + k",
                "ranges": "out_idx in [0..4], k in [0..96]",
                "load_via": "(fc1_weight_out, fc1_weight_k, fc1_weight_wdata) port; fc1_weight_k=96 writes bias slot",
                "weight_absmax": max((abs(v) for v in w_flat), default=0.0),
                "bias_absmax": max((abs(v) for v in b_flat), default=0.0),
                "overflow_count": sum(
                    1 for v in (w_flat + b_flat)
                    if abs(int(round(v * Q_SCALE))) > INT16_MAX
                ),
            },
        },
        "notes": "FC1 = Linear(96, 5), output is logits (argmax in module). Bias is stored at k=96.",
    }
    print(f"  fc1/: weight.mem ({len(lines)} entries = 5 out x 97 k, k=96 is bias)")


# ---------- main ----------

def main():
    print(f"Loading checkpoint: {CHECKPOINT_PATH}")
    ckpt = torch.load(CHECKPOINT_PATH, map_location="cpu", weights_only=False)
    state = ckpt["model_state_dict"]
    print(f"Exporting to: {OUTPUT_DIR}\n")

    manifest = {
        "checkpoint": {
            "path": CHECKPOINT_PATH,
            "epoch": ckpt.get("epoch"),
            "best_val_macro_f1": ckpt.get("best_val_macro_f1"),
            "class_labels": ckpt.get("class_labels"),
        },
        "quant_format": {
            "weight": "Q8.8 signed int16, two's complement",
            "folded_bn_scale": "Q8.8 signed int16",
            "folded_bn_bias": "Q8.8 signed int16",
            "frac_bits": FRAC_BITS,
            "scale": Q_SCALE,
            "int16_min": INT16_MIN,
            "int16_max": INT16_MAX,
            "lsb_value": 1.0 / Q_SCALE,
        },
        "bn_fold": {
            "eps": BN_EPS,
            "scale_formula": "scale[oc] = gamma[oc] / sqrt(var[oc] + eps)",
            "bias_formula": "bias[oc]  = beta[oc]  - mean[oc] * scale[oc]",
        },
        "packed_word_layout": "word[lane*16 +: 16] = lane_value (lane 0 at LSB, rightmost in hex string)",
        "raw_dir": "raw/",
        "modules": {},
    }

    print("[1/3] raw per-tensor hex files")
    export_raw(state)
    print(f"  raw/: {len(RAW_TENSOR_MAP)} hex files + metadata.json\n")

    print("[2/3] per-module packed files")
    export_stem(state, manifest["modules"])
    export_dw1(state, manifest["modules"])
    export_pw1(state, manifest["modules"])
    export_dw2(state, manifest["modules"])
    export_pw2(state, manifest["modules"])
    export_fc0(state, manifest["modules"])
    export_fc1(state, manifest["modules"])

    print("\n[3/3] manifest.json")
    with (OUTPUT_DIR / "manifest.json").open("w") as fp:
        json.dump(manifest, fp, indent=2)

    print(f"\nDone. All files under {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
