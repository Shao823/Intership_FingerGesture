from __future__ import annotations

import sys
from pathlib import Path
from random import Random

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from golden_utils import conv_bn_relu, rand_q88, write_mem

OUT = Path(__file__).resolve().parent / "testdata"
# These deterministic fixtures are for tb_stem_conv_array_4x4_compute. The
# top-level wrapper test intentionally uses weight_data/stem to match the
# generated blk_mem_gen_stem_weight ROM IP.
SEED = 2026070701
INPUT_LEN = 348
IN_CH = 5
OUT_CH = 32
K = 7
K_FLAT = IN_CH * K
PAD = 3
ROWS = 4
OC_LANES = 4

WEIGHT_ROOT = Path(__file__).resolve().parents[3] / "weight_data" / "stem"


def parse_signed_hex(text: str, bits: int = 16) -> int:
    value = int(text.strip(), 16)
    sign = 1 << (bits - 1)
    return value - (1 << bits) if value & sign else value


def read_mem_signed(path: Path, bits: int = 16) -> list[int]:
    return [parse_signed_hex(line, bits) for line in path.read_text().splitlines() if line.strip()]


def read_packed_stem_weight(path: Path) -> list[list[int]]:
    words = [line.strip() for line in path.read_text().splitlines() if line.strip()]
    weight = [[0 for _ in range(K_FLAT)] for _ in range(OUT_CH)]
    for addr, word in enumerate(words):
        oc_group = addr // K_FLAT
        k_flat = addr % K_FLAT
        packed = int(word, 16)
        for lane in range(OC_LANES):
            raw = (packed >> (lane * 16)) & 0xFFFF
            weight[oc_group * OC_LANES + lane][k_flat] = (
                raw - 0x10000 if raw & 0x8000 else raw
            )
    return weight


def make_expected(
    raw: list[list[int]],
    weight: list[list[int]],
    bn_scale: list[int],
    bn_bias: list[int],
    cases: list[tuple[int, int]],
) -> list[int]:
    expected: list[int] = []
    for oc_base, t_base in cases:
        for row in range(ROWS):
            out_t = t_base + row
            for lane in range(OC_LANES):
                oc = oc_base + lane
                acc = 0
                for k_flat in range(K_FLAT):
                    in_ch = k_flat // K
                    tap = k_flat % K
                    in_t = out_t + tap - PAD
                    x = 0 if in_t < 0 or in_t >= INPUT_LEN else raw[in_t][in_ch]
                    acc += x * weight[oc][k_flat]
                expected.append(conv_bn_relu(acc, bn_scale[oc], bn_bias[oc]))
    return expected


def main() -> None:
    rng = Random(SEED)
    raw = [[rand_q88(rng, -512, 512) for _ in range(IN_CH)] for _ in range(INPUT_LEN)]
    weight = [[rand_q88(rng, -96, 96) for _ in range(K_FLAT)] for _ in range(OUT_CH)]
    bn_scale = [rand_q88(rng, 96, 448) for _ in range(OUT_CH)]
    bn_bias = [rand_q88(rng, -160, 160) for _ in range(OUT_CH)]
    cases = [(0, 0), (4, 37), (12, 168), (28, 344)]

    expected = make_expected(raw, weight, bn_scale, bn_bias, cases)

    top_cases = [
        *cases,
        (4, 37),
        (8, 48),
        (0, 0),
        (28, 340),
        (12, 128),
    ]
    checkpoint_weight = read_packed_stem_weight(WEIGHT_ROOT / "weight_packed.mem")
    checkpoint_bn_scale = read_mem_signed(WEIGHT_ROOT / "bn_scale.mem")
    checkpoint_bn_bias = read_mem_signed(WEIGHT_ROOT / "bn_bias.mem")
    expected_top_checkpoint = make_expected(
        raw,
        checkpoint_weight,
        checkpoint_bn_scale,
        checkpoint_bn_bias,
        top_cases,
    )

    write_mem(OUT / "raw_input.mem", [v for row in raw for v in row])
    write_mem(OUT / "weight.mem", [v for row in weight for v in row])
    write_mem(OUT / "bn_scale.mem", bn_scale)
    write_mem(OUT / "bn_bias.mem", bn_bias)
    write_mem(OUT / "case_oc_base.mem", [c[0] for c in cases], bits=8)
    write_mem(OUT / "case_t_base.mem", [c[1] for c in cases], bits=16)
    write_mem(OUT / "expected.mem", expected)
    write_mem(OUT / "expected_top_checkpoint.mem", expected_top_checkpoint)


if __name__ == "__main__":
    main()
