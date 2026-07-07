from __future__ import annotations

import sys
from pathlib import Path
from random import Random

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from golden_utils import conv_bn_relu, rand_q88, write_mem

OUT = Path(__file__).resolve().parent / "testdata"
SEED = 2026070703
INPUT_LEN = 348
POOL_LEN = 174
IN_CH = 32
OUT_CH = 64


def main() -> None:
    rng = Random(SEED)
    act = [[rand_q88(rng, -384, 384) for _ in range(IN_CH)] for _ in range(INPUT_LEN)]
    weight = [[rand_q88(rng, -96, 96) for _ in range(IN_CH)] for _ in range(OUT_CH)]
    bn_scale = [rand_q88(rng, 96, 448) for _ in range(OUT_CH)]
    bn_bias = [rand_q88(rng, -160, 160) for _ in range(OUT_CH)]
    cases = [0, 4, 172, 344]

    relu_rows = [[0 for _ in range(OUT_CH)] for _ in range(INPUT_LEN)]
    for t in range(INPUT_LEN):
        for oc in range(OUT_CH):
            acc = sum(act[t][k] * weight[oc][k] for k in range(IN_CH))
            relu_rows[t][oc] = conv_bn_relu(acc, bn_scale[oc], bn_bias[oc])

    pooled = []
    for pool_t in range(POOL_LEN):
        t0 = pool_t * 2
        t1 = t0 + 1
        for oc in range(OUT_CH):
            pooled.append(max(relu_rows[t0][oc], relu_rows[t1][oc]))

    write_mem(OUT / "input.mem", [v for row in act for v in row])
    write_mem(OUT / "weight.mem", [v for row in weight for v in row])
    write_mem(OUT / "bn_scale.mem", bn_scale)
    write_mem(OUT / "bn_bias.mem", bn_bias)
    write_mem(OUT / "expected_pool.mem", pooled)
    write_mem(OUT / "case_t_base.mem", cases, bits=16)


if __name__ == "__main__":
    main()
