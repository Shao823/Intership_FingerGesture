from __future__ import annotations

import json
from pathlib import Path

import numpy as np


SRC_ROOT = Path(__file__).resolve().parent
PROJECT_ROOT = SRC_ROOT.parents[1]
PKG_ROOT = PROJECT_ROOT / "lightcnn1d_int8_s001_internal"
ENCODER_ROOT = PKG_ROOT / "deployment" / "encoder"
GOLDEN_ROOT = PKG_ROOT / "deployment" / "golden_vectors"
PARAM_PATH = ENCODER_ROOT / "integer_parameters.npz"
MANIFEST_PATH = ENCODER_ROOT / "model_manifest.json"
WEIGHT_ROOT = PROJECT_ROOT / "weight_data"

DATA_W = 8
# Packed weight ROM words keep the lane count/order unchanged, only each lane
# is stored as the physical INT8 payload.
PACKED_WEIGHT_LANE_W = 8
INPUT_LEN = 348
POOL_LEN = 174
STEM_IC = 5
STEM_OC = 32
PW1_OC = 64
PW2_OC = 96
FC_CLASSES = 5
STEM_K_FLAT = 35
DW_K = 5


def signed_hex(value: int, bits: int) -> str:
    width = (bits + 3) // 4
    return f"{int(value) & ((1 << bits) - 1):0{width}X}"


def write_mem(path: Path, values, bits: int = 16) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    flat = np.asarray(values).reshape(-1)
    text = "\n".join(signed_hex(int(v), bits) for v in flat) + "\n"
    path.write_text(text, encoding="ascii")


def pack_lanes(values) -> str:
    lanes = [signed_hex(int(v), PACKED_WEIGHT_LANE_W) for v in values]
    return "".join(reversed(lanes))


def write_packed_mem(path: Path, words: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(words) + "\n", encoding="ascii")


def write_coe(path: Path, words: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    body = ",\n".join(words)
    path.write_text(
        "memory_initialization_radix=16;\n"
        "memory_initialization_vector=\n"
        f"{body};\n",
        encoding="ascii",
    )


def quantize_multiplier(real_multiplier: float) -> tuple[int, int]:
    significand, exponent = np.frexp(np.asarray([real_multiplier], dtype=np.float64))
    multiplier = np.rint(significand * (1 << 15)).astype(np.int64)
    if multiplier[0] == (1 << 15):
        multiplier[0] //= 2
        exponent[0] += 1
    shift = 15 - exponent.astype(np.int32)
    return int(multiplier[0]), int(shift[0])


def write_layer_params(out_dir: Path, params, prefix: str) -> None:
    write_mem(out_dir / "bias_int32.mem", params[f"{prefix}_bias_int32"], bits=32)
    write_mem(out_dir / "multiplier_q15.mem", params[f"{prefix}_multiplier_q15"], bits=16)
    write_mem(out_dir / "right_shift.mem", params[f"{prefix}_right_shift"], bits=16)


def export_weights_and_quant_params(params, manifest: dict) -> None:
    stem = params["stem_conv_weight_int8"]
    stem_words: list[str] = []
    for oc_base in range(0, STEM_OC, 4):
        for k_flat in range(STEM_K_FLAT):
            in_ch = k_flat // 7
            tap = k_flat % 7
            stem_words.append(pack_lanes(stem[oc_base:oc_base + 4, in_ch, tap]))
    write_packed_mem(WEIGHT_ROOT / "stem" / "weight_packed.mem", stem_words)
    write_coe(WEIGHT_ROOT / "stem" / "weight_packed.coe", stem_words)
    write_layer_params(WEIGHT_ROOT / "stem", params, "stem_conv")
    write_mem(WEIGHT_ROOT / "stem" / "bn_scale.mem", params["stem_conv_multiplier_q15"], bits=16)
    write_mem(WEIGHT_ROOT / "stem" / "bn_bias.mem", params["stem_conv_bias_int32"], bits=32)

    dw1 = params["block1_depthwise_weight_int8"][:, 0, :]
    write_mem(WEIGHT_ROOT / "dw1" / "weight.mem", dw1, bits=PACKED_WEIGHT_LANE_W)
    write_layer_params(WEIGHT_ROOT / "dw1", params, "block1_depthwise")

    pw1 = params["block1_pointwise_weight_int8"][:, :, 0]
    pw1_words: list[str] = []
    for oc_base in range(0, PW1_OC, 8):
        for k in range(STEM_OC):
            pw1_words.append(pack_lanes(pw1[oc_base:oc_base + 8, k]))
    write_packed_mem(WEIGHT_ROOT / "pw1" / "weight_packed.mem", pw1_words)
    write_coe(WEIGHT_ROOT / "pw1" / "weight_packed.coe", pw1_words)
    write_mem(WEIGHT_ROOT / "pw1" / "weight.mem", pw1, bits=DATA_W)
    write_layer_params(WEIGHT_ROOT / "pw1", params, "block1_pointwise")
    write_mem(WEIGHT_ROOT / "pw1" / "bn_scale.mem", params["block1_pointwise_multiplier_q15"], bits=16)
    write_mem(WEIGHT_ROOT / "pw1" / "bn_bias.mem", params["block1_pointwise_bias_int32"], bits=32)

    dw2 = params["block2_depthwise_weight_int8"][:, 0, :]
    write_mem(WEIGHT_ROOT / "dw2" / "weight.mem", dw2, bits=PACKED_WEIGHT_LANE_W)
    write_layer_params(WEIGHT_ROOT / "dw2", params, "block2_depthwise")

    pw2 = params["block2_pointwise_weight_int8"][:, :, 0]
    pw2_words: list[str] = []
    for oc_base in range(0, PW2_OC, 12):
        for k in range(PW1_OC):
            pw2_words.append(pack_lanes(pw2[oc_base:oc_base + 12, k]))
    write_packed_mem(WEIGHT_ROOT / "pw2" / "weight_packed.mem", pw2_words)
    write_coe(WEIGHT_ROOT / "pw2" / "weight_packed.coe", pw2_words)
    write_mem(WEIGHT_ROOT / "pw2" / "weight.mem", pw2, bits=DATA_W)
    write_layer_params(WEIGHT_ROOT / "pw2", params, "block2_pointwise")
    write_mem(WEIGHT_ROOT / "pw2" / "bn_scale.mem", params["block2_pointwise_multiplier_q15"], bits=16)
    write_mem(WEIGHT_ROOT / "pw2" / "bn_bias.mem", params["block2_pointwise_bias_int32"], bits=32)

    embedding = params["embedding_weight_int8"]
    classifier = params["classifier_weight_int8"]
    fc0_aug = []
    for oc in range(PW2_OC):
        fc0_aug.extend(int(v) for v in embedding[oc])
        fc0_aug.append(0)
    fc1_aug = []
    for cls in range(FC_CLASSES):
        fc1_aug.extend(int(v) for v in classifier[cls])
        fc1_aug.append(0)
    write_mem(WEIGHT_ROOT / "fc0" / "weight.mem", fc0_aug, bits=DATA_W)
    write_mem(WEIGHT_ROOT / "fc1" / "weight.mem", fc1_aug, bits=DATA_W)
    write_layer_params(WEIGHT_ROOT / "fc0", params, "embedding")
    write_layer_params(WEIGHT_ROOT / "fc1", params, "classifier")

    fc_words: list[str] = []
    for oc_base in range(0, PW2_OC, 16):
        for k in range(PW2_OC + 1):
            lanes = []
            for lane in range(16):
                oc = oc_base + lane
                lanes.append(int(embedding[oc, k]) if oc < PW2_OC and k < PW2_OC else 0)
            fc_words.append(pack_lanes(lanes))
    for k in range(PW2_OC + 1):
        lanes = []
        for lane in range(16):
            lanes.append(int(classifier[lane, k]) if lane < FC_CLASSES and k < PW2_OC else 0)
        fc_words.append(pack_lanes(lanes))
    write_packed_mem(WEIGHT_ROOT / "fc" / "weight_packed_256.mem", fc_words)
    write_coe(WEIGHT_ROOT / "fc" / "weight_packed_256.coe", fc_words)

    block2_scale = manifest["layers"]["block2_pointwise"]["output_scale"]
    gap_scale = manifest["layers"]["embedding"]["input_scale"]
    gap_mult, gap_shift = quantize_multiplier(block2_scale / (POOL_LEN * gap_scale))
    write_mem(WEIGHT_ROOT / "gap" / "multiplier_q15.mem", [gap_mult], bits=16)
    write_mem(WEIGHT_ROOT / "gap" / "right_shift.mem", [gap_shift], bits=16)


def flatten_nct_time_major(arr: np.ndarray) -> list[int]:
    x = np.asarray(arr)
    if x.ndim == 3:
        x = x[0]
    channels, length = x.shape
    return [int(x[ch, t]) for t in range(length) for ch in range(channels)]


def trace_dirs() -> list[Path]:
    return sorted(p for p in GOLDEN_ROOT.iterdir() if (p / "integer_trace.npz").exists())


def load_traces() -> list[tuple[Path, dict, np.lib.npyio.NpzFile]]:
    out = []
    for path in trace_dirs():
        manifest = json.loads((path / "manifest.json").read_text(encoding="utf-8"))
        out.append((path, manifest, np.load(path / "integer_trace.npz")))
    return out


def write_top_testdata(samples) -> None:
    out = SRC_ROOT / "top" / "accelerator" / "testdata"
    raw = []
    stem = []
    dw1 = []
    pw1 = []
    dw2 = []
    pw2_post = []
    gap_sum = []
    logits = []
    classes = []
    for _path, manifest, trace in samples:
        raw.extend(flatten_nct_time_major(trace["input"]))
        stem.extend(flatten_nct_time_major(trace["stem_relu"]))
        dw1.extend(flatten_nct_time_major(trace["block1_depthwise"]))
        pw1.extend(flatten_nct_time_major(trace["block1_pool"]))
        dw2.extend(flatten_nct_time_major(trace["block2_depthwise"]))
        pw2_post.extend(flatten_nct_time_major(trace["block2_relu"]))
        gap_sum.extend(int(v) for v in trace["block2_relu"][0].sum(axis=1))
        logits.extend(int(v) for v in trace["classifier"][0])
        classes.append(int(manifest["prediction_class_index"]))
    write_mem(out / "raw_input.mem", raw, bits=DATA_W)
    write_mem(out / "stem_expected_full.mem", stem, bits=DATA_W)
    write_mem(out / "dw1_expected_full.mem", dw1, bits=DATA_W)
    write_mem(out / "pw1_expected_pool.mem", pw1, bits=DATA_W)
    write_mem(out / "dw2_expected_full.mem", dw2, bits=DATA_W)
    write_mem(out / "pw2_expected_post.mem", pw2_post, bits=DATA_W)
    write_mem(out / "pw2_gap_sum.mem", gap_sum, bits=48)
    write_mem(out / "fc_expected_logits.mem", logits, bits=DATA_W)
    write_mem(out / "fc_expected_class.mem", classes, bits=8)
    write_mem(out / "case_count.mem", [len(samples)], bits=8)

    stem_dw1 = SRC_ROOT / "top" / "stem_dw1_pipeline" / "testdata"
    write_mem(stem_dw1 / "raw_input.mem", raw, bits=DATA_W)
    write_mem(stem_dw1 / "stem_expected_full.mem", stem, bits=DATA_W)
    write_mem(stem_dw1 / "dw1_expected_full.mem", dw1, bits=DATA_W)
    write_mem(stem_dw1 / "case_count.mem", [len(samples)], bits=8)

    stem_dw1_pw1 = SRC_ROOT / "top" / "stem_dw1_pw1_pipeline" / "testdata"
    write_mem(stem_dw1_pw1 / "raw_input.mem", raw, bits=DATA_W)
    write_mem(stem_dw1_pw1 / "stem_expected_full.mem", stem, bits=DATA_W)
    write_mem(stem_dw1_pw1 / "dw1_expected_full.mem", dw1, bits=DATA_W)
    write_mem(stem_dw1_pw1 / "pw1_expected_pool.mem", pw1, bits=DATA_W)
    write_mem(stem_dw1_pw1 / "case_count.mem", [len(samples)], bits=8)


def write_module_testdata(sample, params) -> None:
    _path, _manifest, trace = sample

    stem_dir = SRC_ROOT / "stem_conv_array_4x4" / "testdata"
    write_mem(stem_dir / "raw_input.mem", flatten_nct_time_major(trace["input"]), bits=DATA_W)
    stem_w = params["stem_conv_weight_int8"].reshape(STEM_OC, STEM_K_FLAT)
    write_mem(stem_dir / "weight.mem", stem_w, bits=DATA_W)
    write_mem(stem_dir / "bn_scale.mem", params["stem_conv_multiplier_q15"], bits=16)
    write_mem(stem_dir / "bn_bias.mem", params["stem_conv_bias_int32"], bits=32)
    stem_cases = [(0, 0), (4, 44), (16, 172), (28, 344)]
    stem_expected = []
    stem_relu = trace["stem_relu"][0]
    for oc_base, t_base in stem_cases:
        for row in range(4):
            for lane in range(4):
                stem_expected.append(int(stem_relu[oc_base + lane, t_base + row]))
    write_mem(stem_dir / "case_oc_base.mem", [c[0] for c in stem_cases], bits=8)
    write_mem(stem_dir / "case_t_base.mem", [c[1] for c in stem_cases], bits=16)
    write_mem(stem_dir / "expected.mem", stem_expected, bits=DATA_W)
    write_mem(stem_dir / "expected_top_checkpoint.mem", flatten_nct_time_major(trace["stem_relu"]), bits=DATA_W)

    dw1_dir = SRC_ROOT / "dw_conv1_4ch_5tap" / "testdata"
    write_mem(dw1_dir / "input.mem", flatten_nct_time_major(trace["stem_relu"]), bits=DATA_W)
    write_mem(dw1_dir / "weight.mem", params["block1_depthwise_weight_int8"][:, 0, :], bits=PACKED_WEIGHT_LANE_W)
    write_mem(dw1_dir / "expected_full.mem", flatten_nct_time_major(trace["block1_depthwise"]), bits=DATA_W)
    dw1_cases = [(0, 0, 4, 0), (4, 4, 4, 0), (16, 172, 4, 0), (28, 344, 4, 1)]
    write_mem(dw1_dir / "case_ch_base.mem", [c[0] for c in dw1_cases], bits=8)
    write_mem(dw1_dir / "case_input_t_base.mem", [c[1] for c in dw1_cases], bits=16)
    write_mem(dw1_dir / "case_input_rows.mem", [c[2] for c in dw1_cases], bits=8)
    write_mem(dw1_dir / "case_final_chunk.mem", [c[3] for c in dw1_cases], bits=8)

    pw1_dir = SRC_ROOT / "pw_conv1_array_4x8" / "testdata"
    write_mem(pw1_dir / "input.mem", flatten_nct_time_major(trace["block1_depthwise"]), bits=DATA_W)
    write_mem(pw1_dir / "weight.mem", params["block1_pointwise_weight_int8"][:, :, 0], bits=DATA_W)
    write_mem(pw1_dir / "bn_scale.mem", params["block1_pointwise_multiplier_q15"], bits=16)
    write_mem(pw1_dir / "bn_bias.mem", params["block1_pointwise_bias_int32"], bits=32)
    write_mem(pw1_dir / "expected_pool.mem", flatten_nct_time_major(trace["block1_pool"]), bits=DATA_W)
    pw1_cases = [0, 4, 172, 344]
    write_mem(pw1_dir / "case_t_base.mem", pw1_cases, bits=16)
    write_mem(pw1_dir / "top_case_t_base.mem", pw1_cases, bits=16)
    write_mem(pw1_dir / "expected_top_checkpoint.mem", flatten_nct_time_major(trace["block1_pool"]), bits=DATA_W)

    dw2_dir = SRC_ROOT / "dw_conv2_4ch_5tap" / "testdata"
    write_mem(dw2_dir / "input.mem", flatten_nct_time_major(trace["block1_pool"]), bits=DATA_W)
    write_mem(dw2_dir / "weight.mem", params["block2_depthwise_weight_int8"][:, 0, :], bits=PACKED_WEIGHT_LANE_W)
    write_mem(dw2_dir / "expected_full.mem", flatten_nct_time_major(trace["block2_depthwise"]), bits=DATA_W)
    dw2_cases = [(0, 2, 2, 0), (8, 4, 2, 0), (32, 88, 2, 0), (56, 172, 2, 1)]
    write_mem(dw2_dir / "case_ch_base.mem", [c[0] for c in dw2_cases], bits=8)
    write_mem(dw2_dir / "case_input_t_base.mem", [c[1] for c in dw2_cases], bits=16)
    write_mem(dw2_dir / "case_input_rows.mem", [c[2] for c in dw2_cases], bits=8)
    write_mem(dw2_dir / "case_final_chunk.mem", [c[3] for c in dw2_cases], bits=8)

    pw2_dir = SRC_ROOT / "pw_conv2_array_4x12" / "testdata"
    write_mem(pw2_dir / "input.mem", flatten_nct_time_major(trace["block2_depthwise"]), bits=DATA_W)
    write_mem(pw2_dir / "weight.mem", params["block2_pointwise_weight_int8"][:, :, 0], bits=DATA_W)
    write_mem(pw2_dir / "bn_scale.mem", params["block2_pointwise_multiplier_q15"], bits=16)
    write_mem(pw2_dir / "bn_bias.mem", params["block2_pointwise_bias_int32"], bits=32)
    pw2_cases = [(0, 0b1111), (4, 0b1111), (88, 0b1111), (172, 0b0011)]
    tile_sums = []
    block2_relu = trace["block2_relu"][0]
    for t_base, mask in pw2_cases:
        for oc in range(PW2_OC):
            total = 0
            for row in range(4):
                if (mask >> row) & 1:
                    total += int(block2_relu[oc, t_base + row])
            tile_sums.append(total)
    write_mem(pw2_dir / "case_t_base.mem", [c[0] for c in pw2_cases], bits=16)
    write_mem(pw2_dir / "case_row_valid_mask.mem", [c[1] for c in pw2_cases], bits=8)
    write_mem(pw2_dir / "expected_tile_sum.mem", tile_sums, bits=48)

    fc_dir = SRC_ROOT / "fc_classifier_96_5" / "testdata"
    samples = load_traces()
    gap_sums = []
    logits = []
    classes = []
    for _p, manifest, tr in samples:
        gap_sums.extend(int(v) for v in tr["block2_relu"][0].sum(axis=1))
        logits.extend(int(v) for v in tr["classifier"][0])
        classes.append(int(manifest["prediction_class_index"]))
    fc0_aug = (WEIGHT_ROOT / "fc0" / "weight.mem").read_text(encoding="ascii")
    fc1_aug = (WEIGHT_ROOT / "fc1" / "weight.mem").read_text(encoding="ascii")
    (fc_dir / "fc0_weight.mem").write_text(fc0_aug, encoding="ascii")
    (fc_dir / "fc1_weight.mem").write_text(fc1_aug, encoding="ascii")
    write_mem(fc_dir / "gap_sum.mem", gap_sums, bits=48)
    write_mem(fc_dir / "expected_logits.mem", logits, bits=DATA_W)
    write_mem(fc_dir / "expected_class.mem", classes, bits=8)
    write_mem(fc_dir / "case_count.mem", [len(samples)], bits=8)


def main() -> None:
    params = np.load(PARAM_PATH)
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    samples = load_traces()
    export_weights_and_quant_params(params, manifest)
    write_top_testdata(samples)
    write_module_testdata(samples[0], params)
    print(f"generated INT8 assets for {len(samples)} golden cases")


if __name__ == "__main__":
    main()
