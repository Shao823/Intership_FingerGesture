from __future__ import annotations

import sys
from pathlib import Path
from random import Random

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from golden_utils import conv_bn_relu, rand_q88, write_mem

OUT = Path(__file__).resolve().parent / "testdata"
# Synthetic fixtures are for tb_pw_conv1_array_4x8_compute. The wrapper test
# uses weight_data/pw1 so it can validate the generated ROM contents.
SEED = 2026070703
INPUT_LEN = 348
POOL_LEN = 174
IN_CH = 32
OUT_CH = 64
OC_LANES = 8

WEIGHT_ROOT = Path(__file__).resolve().parents[3] / "weight_data" / "pw1"


def parse_signed_hex(text: str, bits: int = 16) -> int:
    value = int(text.strip(), 16)
    sign = 1 << (bits - 1)
    return value - (1 << bits) if value & sign else value


def read_mem_signed(path: Path, bits: int = 16) -> list[int]:
    return [parse_signed_hex(line, bits) for line in path.read_text().splitlines() if line.strip()]


def read_packed_pw1_weight(path: Path) -> list[list[int]]:
    words = [line.strip() for line in path.read_text().splitlines() if line.strip()]
    weight = [[0 for _ in range(IN_CH)] for _ in range(OUT_CH)]
    for addr, word in enumerate(words):
        oc_group = addr // IN_CH
        k = addr % IN_CH
        packed = int(word, 16)
        for lane in range(OC_LANES):
            raw = (packed >> (lane * 16)) & 0xFFFF
            weight[oc_group * OC_LANES + lane][k] = (
                raw - 0x10000 if raw & 0x8000 else raw
            )
    return weight


def make_pooled_expected(
    act: list[list[int]],
    weight: list[list[int]],
    bn_scale: list[int],
    bn_bias: list[int],
) -> list[int]:
    relu_rows = [[0 for _ in range(OUT_CH)] for _ in range(INPUT_LEN)]
    for t in range(INPUT_LEN):
        for oc in range(OUT_CH):
            acc = sum(act[t][k] * weight[oc][k] for k in range(IN_CH))
            relu_rows[t][oc] = conv_bn_relu(acc, bn_scale[oc], bn_bias[oc])

    pooled: list[int] = []
    for pool_t in range(POOL_LEN):
        t0 = pool_t * 2
        t1 = t0 + 1
        for oc in range(OUT_CH):
            pooled.append(max(relu_rows[t0][oc], relu_rows[t1][oc]))
    return pooled


def gather_top_cases(pooled: list[int], cases: list[int]) -> list[int]:
    values: list[int] = []
    for high_t_base in cases:
        pool_t_base = high_t_base >> 1
        for pool_row in range(2):
            for oc in range(OUT_CH):
                values.append(pooled[(pool_t_base + pool_row) * OUT_CH + oc])
    return values


def main() -> None:
    rng = Random(SEED)
    act = [[rand_q88(rng, -384, 384) for _ in range(IN_CH)] for _ in range(INPUT_LEN)]
    weight = [[rand_q88(rng, -96, 96) for _ in range(IN_CH)] for _ in range(OUT_CH)]
    bn_scale = [rand_q88(rng, 96, 448) for _ in range(OUT_CH)]
    bn_bias = [rand_q88(rng, -160, 160) for _ in range(OUT_CH)]
    cases = [0, 4, 172, 344]
    top_cases = [0, 4, 20, 24, 28, 128, 172, 340, 344]

    pooled = make_pooled_expected(act, weight, bn_scale, bn_bias)
    checkpoint_weight = read_packed_pw1_weight(WEIGHT_ROOT / "weight_packed.mem")
    checkpoint_bn_scale = read_mem_signed(WEIGHT_ROOT / "bn_scale.mem")
    checkpoint_bn_bias = read_mem_signed(WEIGHT_ROOT / "bn_bias.mem")
    checkpoint_pooled = make_pooled_expected(
        act,
        checkpoint_weight,
        checkpoint_bn_scale,
        checkpoint_bn_bias,
    )

    write_mem(OUT / "input.mem", [v for row in act for v in row])
    write_mem(OUT / "weight.mem", [v for row in weight for v in row])
    write_mem(OUT / "bn_scale.mem", bn_scale)
    write_mem(OUT / "bn_bias.mem", bn_bias)
    write_mem(OUT / "expected_pool.mem", pooled)
    write_mem(OUT / "case_t_base.mem", cases, bits=16)
    write_mem(OUT / "top_case_t_base.mem", top_cases, bits=16)
    write_mem(OUT / "expected_top_checkpoint.mem", gather_top_cases(checkpoint_pooled, top_cases))


if __name__ == "__main__":
    main()
