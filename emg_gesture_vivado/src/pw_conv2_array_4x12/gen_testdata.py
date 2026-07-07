from __future__ import annotations

import sys
from pathlib import Path
from random import Random

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from golden_utils import conv_bn_relu, rand_q88, write_mem

OUT = Path(__file__).resolve().parent / "testdata"
SEED = 2026070705
INPUT_LEN = 174
IN_CH = 64
OUT_CH = 96
ROWS = 4


def main() -> None:
    rng = Random(SEED)
    act = [[rand_q88(rng, -320, 320) for _ in range(IN_CH)] for _ in range(INPUT_LEN)]
    weight = [[rand_q88(rng, -80, 80) for _ in range(IN_CH)] for _ in range(OUT_CH)]
    bn_scale = [rand_q88(rng, 96, 448) for _ in range(OUT_CH)]
    bn_bias = [rand_q88(rng, -160, 160) for _ in range(OUT_CH)]
    cases = [(0, 0b1111), (68, 0b1111), (168, 0b1111), (172, 0b0011)]

    post = [[0 for _ in range(OUT_CH)] for _ in range(INPUT_LEN)]
    for t in range(INPUT_LEN):
        for oc in range(OUT_CH):
            acc = sum(act[t][k] * weight[oc][k] for k in range(IN_CH))
            post[t][oc] = conv_bn_relu(acc, bn_scale[oc], bn_bias[oc])

    tile_sums: list[int] = []
    for t_base, mask in cases:
        for oc in range(OUT_CH):
            total = 0
            for row in range(ROWS):
                if (mask >> row) & 1:
                    total += post[t_base + row][oc]
            tile_sums.append(total)

    write_mem(OUT / "input.mem", [v for row in act for v in row])
    write_mem(OUT / "weight.mem", [v for row in weight for v in row])
    write_mem(OUT / "bn_scale.mem", bn_scale)
    write_mem(OUT / "bn_bias.mem", bn_bias)
    write_mem(OUT / "case_t_base.mem", [c[0] for c in cases], bits=16)
    write_mem(OUT / "case_row_valid_mask.mem", [c[1] for c in cases], bits=8)
    write_mem(OUT / "expected_tile_sum.mem", tile_sums, bits=48)


if __name__ == "__main__":
    main()
