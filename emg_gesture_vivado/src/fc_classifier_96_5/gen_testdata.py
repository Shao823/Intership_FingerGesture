from __future__ import annotations

import sys
from pathlib import Path
from random import Random

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from golden_utils import fc_bias_to_acc, fc_out_from_acc, rand_q88, relu16, write_mem

OUT = Path(__file__).resolve().parent / "testdata"
SEED = 2026070706
GAP_LEN = 174
IN_CH = 96
HIDDEN = 96
CLASSES = 5
CASES = 4


def main() -> None:
    rng = Random(SEED)
    gap_sum = [
        [rand_q88(rng, -256, 768) * GAP_LEN for _ in range(IN_CH)]
        for _ in range(CASES)
    ]
    fc0_weight = [[rand_q88(rng, -72, 72) for _ in range(IN_CH)] for _ in range(HIDDEN)]
    fc0_bias = [rand_q88(rng, -96, 96) for _ in range(HIDDEN)]
    fc1_weight = [[rand_q88(rng, -96, 96) for _ in range(HIDDEN)] for _ in range(CLASSES)]
    fc1_bias = [rand_q88(rng, -96, 96) for _ in range(CLASSES)]

    logits: list[int] = []
    class_idx: list[int] = []
    for case in range(CASES):
        avg = [int(gap_sum[case][k] / GAP_LEN) for k in range(IN_CH)]
        hidden = []
        for out in range(HIDDEN):
            acc = fc_bias_to_acc(fc0_bias[out])
            for k in range(IN_CH):
                acc += avg[k] * fc0_weight[out][k]
            hidden.append(relu16(fc_out_from_acc(acc)))

        case_logits = []
        for cls in range(CLASSES):
            acc = fc_bias_to_acc(fc1_bias[cls])
            for k in range(HIDDEN):
                acc += hidden[k] * fc1_weight[cls][k]
            case_logits.append(fc_out_from_acc(acc))
        logits.extend(case_logits)
        best = 0
        for cls in range(1, CLASSES):
            if case_logits[cls] > case_logits[best]:
                best = cls
        class_idx.append(best)

    fc0_aug = []
    for out in range(HIDDEN):
        fc0_aug.extend(fc0_weight[out])
        fc0_aug.append(fc0_bias[out])
    fc1_aug = []
    for out in range(CLASSES):
        fc1_aug.extend(fc1_weight[out])
        fc1_aug.append(fc1_bias[out])

    write_mem(OUT / "gap_sum.mem", [v for row in gap_sum for v in row], bits=48)
    write_mem(OUT / "fc0_weight.mem", fc0_aug)
    write_mem(OUT / "fc1_weight.mem", fc1_aug)
    write_mem(OUT / "expected_logits.mem", logits)
    write_mem(OUT / "expected_class.mem", class_idx, bits=8)


if __name__ == "__main__":
    main()
