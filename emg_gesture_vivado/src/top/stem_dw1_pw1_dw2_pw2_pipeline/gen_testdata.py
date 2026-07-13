from __future__ import annotations

import sys
from pathlib import Path
from random import Random

SRC_ROOT = Path(__file__).resolve().parents[2]
PROJECT_ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(SRC_ROOT))

from golden_utils import (
    conv_bn_relu,
    fc_bias_to_acc,
    fc_out_from_acc,
    mac_sat_q88,
    rand_q88,
    relu16,
    sat16,
    write_mem,
)

OUT = Path(__file__).resolve().parent / "testdata"
WEIGHT_ROOT = PROJECT_ROOT / "weight_data"

SEED = 2026071001
N_CASES = 20
INPUT_LEN = 348
POOL_LEN = INPUT_LEN // 2
STEM_IC = 5
STEM_OC = 32
STEM_K = 7
STEM_PAD = 3
DW_K = 5
DW_PAD = 2
PW1_OC = 64
PW2_OC = 96
FC_CLASSES = 5
STEM_K_FLAT = STEM_IC * STEM_K
STEM_OC_LANES = 4
PW1_OC_LANES = 8
PW2_OC_LANES = 12


def parse_signed_hex(text: str, bits: int = 16) -> int:
    value = int(text.strip(), 16)
    sign = 1 << (bits - 1)
    return value - (1 << bits) if value & sign else value


def read_mem_signed(path: Path, bits: int = 16) -> list[int]:
    return [
        parse_signed_hex(line, bits)
        for line in path.read_text(encoding="ascii").splitlines()
        if line.strip()
    ]


def trunc_div(value: int, divisor: int) -> int:
    if value < 0:
        return -((-value) // divisor)
    return value // divisor


def read_packed_stem_weight(path: Path) -> list[list[int]]:
    words = [
        line.strip()
        for line in path.read_text(encoding="ascii").splitlines()
        if line.strip()
    ]
    weight = [[0 for _ in range(STEM_K_FLAT)] for _ in range(STEM_OC)]
    for addr, word in enumerate(words):
        oc_group = addr // STEM_K_FLAT
        k_flat = addr % STEM_K_FLAT
        packed = int(word, 16)
        for lane in range(STEM_OC_LANES):
            raw = (packed >> (lane * 16)) & 0xFFFF
            weight[oc_group * STEM_OC_LANES + lane][k_flat] = (
                raw - 0x10000 if raw & 0x8000 else raw
            )
    return weight


def read_packed_pw1_weight(path: Path) -> list[list[int]]:
    words = [
        line.strip()
        for line in path.read_text(encoding="ascii").splitlines()
        if line.strip()
    ]
    weight = [[0 for _ in range(STEM_OC)] for _ in range(PW1_OC)]
    for addr, word in enumerate(words):
        oc_group = addr // STEM_OC
        k = addr % STEM_OC
        packed = int(word, 16)
        for lane in range(PW1_OC_LANES):
            raw = (packed >> (lane * 16)) & 0xFFFF
            weight[oc_group * PW1_OC_LANES + lane][k] = (
                raw - 0x10000 if raw & 0x8000 else raw
            )
    return weight


def read_packed_pw2_weight(path: Path) -> list[list[int]]:
    words = [
        line.strip()
        for line in path.read_text(encoding="ascii").splitlines()
        if line.strip()
    ]
    weight = [[0 for _ in range(PW1_OC)] for _ in range(PW2_OC)]
    for addr, word in enumerate(words):
        oc_group = addr // PW1_OC
        k = addr % PW1_OC
        packed = int(word, 16)
        for lane in range(PW2_OC_LANES):
            raw = (packed >> (lane * 16)) & 0xFFFF
            weight[oc_group * PW2_OC_LANES + lane][k] = (
                raw - 0x10000 if raw & 0x8000 else raw
            )
    return weight


def compute_stem_case(
    raw: list[list[int]],
    weight: list[list[int]],
    bn_scale: list[int],
    bn_bias: list[int],
) -> list[list[int]]:
    stem = [[0 for _ in range(STEM_OC)] for _ in range(INPUT_LEN)]
    for out_t in range(INPUT_LEN):
        for oc in range(STEM_OC):
            acc = 0
            for k_flat in range(STEM_K_FLAT):
                in_ch = k_flat // STEM_K
                tap = k_flat % STEM_K
                in_t = out_t + tap - STEM_PAD
                x = 0 if in_t < 0 or in_t >= INPUT_LEN else raw[in_t][in_ch]
                acc += x * weight[oc][k_flat]
            stem[out_t][oc] = conv_bn_relu(acc, bn_scale[oc], bn_bias[oc])
    return stem


def compute_dw_case(
    data: list[list[int]],
    weight: list[list[int]],
    channels: int,
) -> list[list[int]]:
    out = [[0 for _ in range(channels)] for _ in range(len(data))]
    for out_t in range(len(data)):
        for ch in range(channels):
            xs = []
            for tap in range(DW_K):
                in_t = out_t + tap - DW_PAD
                xs.append(0 if in_t < 0 or in_t >= len(data) else data[in_t][ch])
            out[out_t][ch] = mac_sat_q88(xs, weight[ch])
    return out


def compute_pw1_pool_case(
    dw1: list[list[int]],
    weight: list[list[int]],
    bn_scale: list[int],
    bn_bias: list[int],
) -> list[list[int]]:
    relu_rows = [[0 for _ in range(PW1_OC)] for _ in range(INPUT_LEN)]
    for t in range(INPUT_LEN):
        for oc in range(PW1_OC):
            acc = 0
            for k in range(STEM_OC):
                acc += dw1[t][k] * weight[oc][k]
            relu_rows[t][oc] = conv_bn_relu(acc, bn_scale[oc], bn_bias[oc])

    pooled = [[0 for _ in range(PW1_OC)] for _ in range(POOL_LEN)]
    for pool_t in range(POOL_LEN):
        t0 = pool_t * 2
        t1 = t0 + 1
        for oc in range(PW1_OC):
            pooled[pool_t][oc] = max(relu_rows[t0][oc], relu_rows[t1][oc])
    return pooled


def compute_pw2_post_and_gap_case(
    dw2: list[list[int]],
    weight: list[list[int]],
    bn_scale: list[int],
    bn_bias: list[int],
) -> tuple[list[list[int]], list[int]]:
    post = [[0 for _ in range(PW2_OC)] for _ in range(POOL_LEN)]
    gap = [0 for _ in range(PW2_OC)]
    for t in range(POOL_LEN):
        for oc in range(PW2_OC):
            acc = 0
            for k in range(PW1_OC):
                acc += dw2[t][k] * weight[oc][k]
            value = conv_bn_relu(acc, bn_scale[oc], bn_bias[oc])
            post[t][oc] = value
            gap[oc] += value
    return post, gap


def compute_fc_case(
    gap: list[int],
    fc0_weight: list[list[int]],
    fc0_bias: list[int],
    fc1_weight: list[list[int]],
    fc1_bias: list[int],
) -> tuple[list[int], int]:
    avg = [sat16(trunc_div(gap[k], POOL_LEN)) for k in range(PW2_OC)]

    hidden: list[int] = []
    for out in range(PW2_OC):
        acc = fc_bias_to_acc(fc0_bias[out])
        for k in range(PW2_OC):
            acc += avg[k] * fc0_weight[out][k]
        hidden.append(relu16(fc_out_from_acc(acc)))

    logits: list[int] = []
    for cls in range(FC_CLASSES):
        acc = fc_bias_to_acc(fc1_bias[cls])
        for k in range(PW2_OC):
            acc += hidden[k] * fc1_weight[cls][k]
        logits.append(fc_out_from_acc(acc))

    best = 0
    for cls in range(1, FC_CLASSES):
        if logits[cls] > logits[best]:
            best = cls
    return logits, best


def flatten_time_major(cases: list[list[list[int]]]) -> list[int]:
    flat: list[int] = []
    for case in cases:
        for row in case:
            flat.extend(row)
    return flat


def make_random_case(rng: Random, low: int = -256, high: int = 256) -> list[list[int]]:
    return [
        [rand_q88(rng, low, high) for _ch in range(STEM_IC)]
        for _t in range(INPUT_LEN)
    ]


def make_zero_case() -> list[list[int]]:
    return [[0 for _ch in range(STEM_IC)] for _t in range(INPUT_LEN)]


def make_alternating_case() -> list[list[int]]:
    return [
        [256 if ((t + ch) & 1) == 0 else -256 for ch in range(STEM_IC)]
        for t in range(INPUT_LEN)
    ]


def make_edge_impulse_case() -> list[list[int]]:
    raw = make_zero_case()
    for t in (0, 1, INPUT_LEN - 2, INPUT_LEN - 1):
        for ch in range(STEM_IC):
            raw[t][ch] = 512 if ((t + ch) & 1) == 0 else -512
    raw[INPUT_LEN // 2] = [384, -384, 256, -256, 128]
    return raw


def make_ramp_case(scale: int, offset: int = 0) -> list[list[int]]:
    raw = []
    for t in range(INPUT_LEN):
        row = []
        for ch in range(STEM_IC):
            value = ((t * scale) // 16) + offset + (ch - 2) * 32
            value = max(-768, min(768, value))
            row.append(value)
        raw.append(row)
    return raw


def make_step_case(level_low: int, level_high: int) -> list[list[int]]:
    raw = []
    for t in range(INPUT_LEN):
        level = level_low if t < (INPUT_LEN // 2) else level_high
        raw.append([level if (ch & 1) == 0 else -level for ch in range(STEM_IC)])
    return raw


def make_sparse_case(rng: Random, amplitude: int) -> list[list[int]]:
    raw = make_zero_case()
    for _ in range(32):
        t = rng.randrange(INPUT_LEN)
        ch = rng.randrange(STEM_IC)
        raw[t][ch] = amplitude if rng.randrange(2) == 0 else -amplitude
    return raw


def make_channel_constant_case(values: list[int]) -> list[list[int]]:
    return [values[:] for _t in range(INPUT_LEN)]


def make_checker_case() -> list[list[int]]:
    raw = []
    for t in range(INPUT_LEN):
        row = []
        for ch in range(STEM_IC):
            if ((t // 3) + ch) & 1:
                row.append(-320 + ch * 24)
            else:
                row.append(320 - ch * 24)
        raw.append(row)
    return raw


def make_input_cases(rng: Random) -> list[list[list[int]]]:
    cases = [
        make_random_case(rng),
        make_random_case(rng, -384, 384),
        make_random_case(rng, -128, 128),
        make_random_case(rng, -512, 512),
        make_zero_case(),
        make_alternating_case(),
        make_edge_impulse_case(),
        make_ramp_case(9, -192),
        make_ramp_case(-7, 224),
        make_step_case(96, 384),
        make_step_case(-224, 192),
        make_sparse_case(rng, 512),
        make_sparse_case(rng, 768),
        make_channel_constant_case([128, -128, 256, -256, 0]),
        make_channel_constant_case([384, 192, 0, -192, -384]),
        make_checker_case(),
        make_random_case(rng, -64, 64),
        make_random_case(rng, -768, 768),
        make_sparse_case(rng, 1024),
        make_channel_constant_case([0, 256, -256, 512, -512]),
    ]
    assert len(cases) == N_CASES
    return cases


def main() -> None:
    rng = Random(SEED)
    stem_weight = read_packed_stem_weight(
        WEIGHT_ROOT / "stem" / "weight_packed.mem"
    )
    stem_bn_scale = read_mem_signed(WEIGHT_ROOT / "stem" / "bn_scale.mem")
    stem_bn_bias = read_mem_signed(WEIGHT_ROOT / "stem" / "bn_bias.mem")

    dw1_weight_flat = read_mem_signed(WEIGHT_ROOT / "dw1" / "weight.mem")
    dw1_weight = [
        dw1_weight_flat[ch * DW_K : (ch + 1) * DW_K]
        for ch in range(STEM_OC)
    ]

    pw1_weight = read_packed_pw1_weight(
        WEIGHT_ROOT / "pw1" / "weight_packed.mem"
    )
    pw1_bn_scale = read_mem_signed(WEIGHT_ROOT / "pw1" / "bn_scale.mem")
    pw1_bn_bias = read_mem_signed(WEIGHT_ROOT / "pw1" / "bn_bias.mem")

    dw2_weight_flat = read_mem_signed(WEIGHT_ROOT / "dw2" / "weight.mem")
    dw2_weight = [
        dw2_weight_flat[ch * DW_K : (ch + 1) * DW_K]
        for ch in range(PW1_OC)
    ]

    pw2_weight = read_packed_pw2_weight(
        WEIGHT_ROOT / "pw2" / "weight_packed.mem"
    )
    pw2_bn_scale = read_mem_signed(WEIGHT_ROOT / "pw2" / "bn_scale.mem")
    pw2_bn_bias = read_mem_signed(WEIGHT_ROOT / "pw2" / "bn_bias.mem")

    fc0_aug = read_mem_signed(WEIGHT_ROOT / "fc0" / "weight.mem")
    fc1_aug = read_mem_signed(WEIGHT_ROOT / "fc1" / "weight.mem")
    assert len(fc0_aug) == PW2_OC * (PW2_OC + 1)
    assert len(fc1_aug) == FC_CLASSES * (PW2_OC + 1)

    fc0_weight = [
        fc0_aug[out * (PW2_OC + 1) : out * (PW2_OC + 1) + PW2_OC]
        for out in range(PW2_OC)
    ]
    fc0_bias = [
        fc0_aug[out * (PW2_OC + 1) + PW2_OC]
        for out in range(PW2_OC)
    ]
    fc1_weight = [
        fc1_aug[out * (PW2_OC + 1) : out * (PW2_OC + 1) + PW2_OC]
        for out in range(FC_CLASSES)
    ]
    fc1_bias = [
        fc1_aug[out * (PW2_OC + 1) + PW2_OC]
        for out in range(FC_CLASSES)
    ]

    raw_cases: list[list[list[int]]] = []
    stem_cases: list[list[list[int]]] = []
    dw1_cases: list[list[list[int]]] = []
    pw1_cases: list[list[list[int]]] = []
    dw2_cases: list[list[list[int]]] = []
    pw2_post_cases: list[list[list[int]]] = []
    gap_cases: list[list[int]] = []
    fc_logits_cases: list[list[int]] = []
    fc_class_cases: list[int] = []

    for raw in make_input_cases(rng):
        stem = compute_stem_case(raw, stem_weight, stem_bn_scale, stem_bn_bias)
        dw1 = compute_dw_case(stem, dw1_weight, STEM_OC)
        pw1 = compute_pw1_pool_case(dw1, pw1_weight, pw1_bn_scale, pw1_bn_bias)
        dw2 = compute_dw_case(pw1, dw2_weight, PW1_OC)
        pw2_post, gap = compute_pw2_post_and_gap_case(
            dw2,
            pw2_weight,
            pw2_bn_scale,
            pw2_bn_bias,
        )
        fc_logits, fc_class = compute_fc_case(
            gap,
            fc0_weight,
            fc0_bias,
            fc1_weight,
            fc1_bias,
        )

        raw_cases.append(raw)
        stem_cases.append(stem)
        dw1_cases.append(dw1)
        pw1_cases.append(pw1)
        dw2_cases.append(dw2)
        pw2_post_cases.append(pw2_post)
        gap_cases.append(gap)
        fc_logits_cases.append(fc_logits)
        fc_class_cases.append(fc_class)

    write_mem(OUT / "raw_input.mem", flatten_time_major(raw_cases))
    write_mem(OUT / "stem_expected_full.mem", flatten_time_major(stem_cases))
    write_mem(OUT / "dw1_expected_full.mem", flatten_time_major(dw1_cases))
    write_mem(OUT / "pw1_expected_pool.mem", flatten_time_major(pw1_cases))
    write_mem(OUT / "dw2_expected_full.mem", flatten_time_major(dw2_cases))
    write_mem(OUT / "pw2_expected_post.mem", flatten_time_major(pw2_post_cases))
    write_mem(OUT / "pw2_gap_sum.mem", [v for row in gap_cases for v in row], bits=48)
    write_mem(OUT / "fc_expected_logits.mem", [v for row in fc_logits_cases for v in row])
    write_mem(OUT / "fc_expected_class.mem", fc_class_cases, bits=8)
    write_mem(OUT / "case_count.mem", [N_CASES], bits=8)


if __name__ == "__main__":
    main()
