from __future__ import annotations

import sys
from pathlib import Path
from random import Random

SRC_ROOT = Path(__file__).resolve().parents[2]
PROJECT_ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(SRC_ROOT))

from golden_utils import conv_bn_relu, mac_sat_q88, rand_q88, write_mem

OUT = Path(__file__).resolve().parent / "testdata"
WEIGHT_ROOT = PROJECT_ROOT / "weight_data"

SEED = 2026070901
N_CASES = 6
INPUT_LEN = 348
POOL_LEN = INPUT_LEN // 2
STEM_IC = 5
STEM_OC = 32
STEM_K = 7
STEM_PAD = 3
DW_K = 5
DW_PAD = 2
PW1_OC = 64
STEM_K_FLAT = STEM_IC * STEM_K
STEM_OC_LANES = 4
PW1_OC_LANES = 8


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


def compute_dw1_case(stem: list[list[int]], weight: list[list[int]]) -> list[list[int]]:
    out = [[0 for _ in range(STEM_OC)] for _ in range(INPUT_LEN)]
    for out_t in range(INPUT_LEN):
        for ch in range(STEM_OC):
            xs = []
            for tap in range(DW_K):
                in_t = out_t + tap - DW_PAD
                xs.append(0 if in_t < 0 or in_t >= INPUT_LEN else stem[in_t][ch])
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


def flatten_time_major(cases: list[list[list[int]]]) -> list[int]:
    flat: list[int] = []
    for case in cases:
        for row in case:
            flat.extend(row)
    return flat


def make_random_case(rng: Random) -> list[list[int]]:
    return [
        [rand_q88(rng, -256, 256) for _ch in range(STEM_IC)]
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


def main() -> None:
    rng = Random(SEED)
    stem_weight = read_packed_stem_weight(
        WEIGHT_ROOT / "stem" / "weight_packed.mem"
    )
    stem_bn_scale = read_mem_signed(WEIGHT_ROOT / "stem" / "bn_scale.mem")
    stem_bn_bias = read_mem_signed(WEIGHT_ROOT / "stem" / "bn_bias.mem")
    dw_weight_flat = read_mem_signed(WEIGHT_ROOT / "dw1" / "weight.mem")
    dw_weight = [
        dw_weight_flat[ch * DW_K : (ch + 1) * DW_K]
        for ch in range(STEM_OC)
    ]
    pw1_weight = read_packed_pw1_weight(
        WEIGHT_ROOT / "pw1" / "weight_packed.mem"
    )
    pw1_bn_scale = read_mem_signed(WEIGHT_ROOT / "pw1" / "bn_scale.mem")
    pw1_bn_bias = read_mem_signed(WEIGHT_ROOT / "pw1" / "bn_bias.mem")

    input_cases = [
        make_random_case(rng),
        make_random_case(rng),
        make_random_case(rng),
        make_alternating_case(),
        make_zero_case(),
        make_edge_impulse_case(),
    ]
    assert len(input_cases) == N_CASES

    raw_cases: list[list[list[int]]] = []
    stem_cases: list[list[list[int]]] = []
    dw_cases: list[list[list[int]]] = []
    pw1_cases: list[list[list[int]]] = []

    for raw in input_cases:
        stem = compute_stem_case(raw, stem_weight, stem_bn_scale, stem_bn_bias)
        dw = compute_dw1_case(stem, dw_weight)
        pw1 = compute_pw1_pool_case(dw, pw1_weight, pw1_bn_scale, pw1_bn_bias)
        raw_cases.append(raw)
        stem_cases.append(stem)
        dw_cases.append(dw)
        pw1_cases.append(pw1)

    write_mem(OUT / "raw_input.mem", flatten_time_major(raw_cases))
    write_mem(OUT / "stem_expected_full.mem", flatten_time_major(stem_cases))
    write_mem(OUT / "dw1_expected_full.mem", flatten_time_major(dw_cases))
    write_mem(OUT / "pw1_expected_pool.mem", flatten_time_major(pw1_cases))
    write_mem(OUT / "case_count.mem", [N_CASES], bits=8)


if __name__ == "__main__":
    main()
