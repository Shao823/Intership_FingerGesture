from __future__ import annotations

import sys
from pathlib import Path
from random import Random

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from golden_utils import mac_sat_q88, rand_q88, write_mem

OUT = Path(__file__).resolve().parent / "testdata"
SEED = 2026070704
INPUT_LEN = 174
CHANNELS = 64
K = 5
PAD = 2


def main() -> None:
    rng = Random(SEED)
    act = [[rand_q88(rng, -384, 384) for _ in range(CHANNELS)] for _ in range(INPUT_LEN)]
    weight = [[rand_q88(rng, -112, 112) for _ in range(K)] for _ in range(CHANNELS)]
    cases = [(0, 0, 2, 0), (8, 2, 2, 0), (48, 86, 2, 0), (56, 172, 2, 1)]

    expected = []
    for t in range(INPUT_LEN):
        for ch in range(CHANNELS):
            xs = []
            for tap in range(K):
                in_t = t + tap - PAD
                xs.append(0 if in_t < 0 or in_t >= INPUT_LEN else act[in_t][ch])
            expected.append(mac_sat_q88(xs, weight[ch]))

    write_mem(OUT / "input.mem", [v for row in act for v in row])
    write_mem(OUT / "weight.mem", [v for row in weight for v in row])
    write_mem(OUT / "expected_full.mem", expected)
    write_mem(OUT / "case_ch_base.mem", [c[0] for c in cases], bits=8)
    write_mem(OUT / "case_input_t_base.mem", [c[1] for c in cases], bits=16)
    write_mem(OUT / "case_input_rows.mem", [c[2] for c in cases], bits=8)
    write_mem(OUT / "case_final_chunk.mem", [c[3] for c in cases], bits=8)


if __name__ == "__main__":
    main()
