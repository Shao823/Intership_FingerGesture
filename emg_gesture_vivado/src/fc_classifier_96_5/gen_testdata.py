from __future__ import annotations

import sys
from pathlib import Path
from random import Random

ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from golden_utils import fc_bias_to_acc, fc_out_from_acc, relu16, sat16, write_mem

OUT = Path(__file__).resolve().parent / "testdata"
WEIGHT_ROOT = PROJECT_ROOT / "weight_data"

SEED = 2026071002
GAP_LEN = 174
IN_CH = 96
HIDDEN = 96
CLASSES = 5
CASES = 20


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


def make_gap_from_avg(avg: list[int], remainders: bool = True) -> list[int]:
    gap: list[int] = []
    for idx, value in enumerate(avg):
        rem = ((idx * 17) % GAP_LEN) - (GAP_LEN // 2) if remainders else 0
        gap.append(value * GAP_LEN + rem)
    return gap


def make_cases(rng: Random) -> list[list[int]]:
    cases: list[list[int]] = []

    cases.append(make_gap_from_avg([rng.randint(-256, 512) for _ in range(IN_CH)]))
    cases.append(make_gap_from_avg([rng.randint(-768, 768) for _ in range(IN_CH)]))
    cases.append(make_gap_from_avg([rng.randint(-64, 64) for _ in range(IN_CH)]))
    cases.append(make_gap_from_avg([0 for _ in range(IN_CH)], False))
    cases.append(make_gap_from_avg([256 if (idx & 1) == 0 else -256 for idx in range(IN_CH)]))
    cases.append(make_gap_from_avg([idx * 4 - 192 for idx in range(IN_CH)]))
    cases.append(make_gap_from_avg([192 - idx * 3 for idx in range(IN_CH)]))
    cases.append(make_gap_from_avg([1024 if (idx % 8) == 0 else 0 for idx in range(IN_CH)]))
    cases.append(make_gap_from_avg([-1024 if (idx % 7) == 0 else 64 for idx in range(IN_CH)]))
    cases.append(make_gap_from_avg([32767 if (idx % 11) == 0 else -32768 for idx in range(IN_CH)]))
    cases.append(make_gap_from_avg([rng.randint(-1536, 1536) for _ in range(IN_CH)]))
    cases.append(make_gap_from_avg([rng.randint(-2048, 2048) for _ in range(IN_CH)]))

    sparse = [0 for _ in range(IN_CH)]
    for _ in range(12):
        sparse[rng.randrange(IN_CH)] = rng.choice([-768, 768, -512, 512])
    cases.append(make_gap_from_avg(sparse))

    cases.append(make_gap_from_avg([128, -128, 256, -256] * (IN_CH // 4)))
    cases.append(make_gap_from_avg([512 if idx < IN_CH // 2 else -512 for idx in range(IN_CH)]))
    cases.append(make_gap_from_avg([-512 if idx < IN_CH // 2 else 512 for idx in range(IN_CH)]))
    cases.append(make_gap_from_avg([((idx // 3) % 5 - 2) * 160 for idx in range(IN_CH)]))
    cases.append(make_gap_from_avg([rng.randint(-384, 384) for _ in range(IN_CH)]))
    cases.append(make_gap_from_avg([rng.randint(-4096, 4096) for _ in range(IN_CH)]))
    cases.append(make_gap_from_avg([256 if ((idx // 5) & 1) else -128 for idx in range(IN_CH)]))

    assert len(cases) == CASES
    return cases


def main() -> None:
    rng = Random(SEED)

    fc0_aug = read_mem_signed(WEIGHT_ROOT / "fc0" / "weight.mem")
    fc1_aug = read_mem_signed(WEIGHT_ROOT / "fc1" / "weight.mem")
    assert len(fc0_aug) == HIDDEN * (IN_CH + 1)
    assert len(fc1_aug) == CLASSES * (HIDDEN + 1)

    fc0_weight = [
        fc0_aug[out * (IN_CH + 1) : out * (IN_CH + 1) + IN_CH]
        for out in range(HIDDEN)
    ]
    fc0_bias = [fc0_aug[out * (IN_CH + 1) + IN_CH] for out in range(HIDDEN)]
    fc1_weight = [
        fc1_aug[out * (HIDDEN + 1) : out * (HIDDEN + 1) + HIDDEN]
        for out in range(CLASSES)
    ]
    fc1_bias = [fc1_aug[out * (HIDDEN + 1) + HIDDEN] for out in range(CLASSES)]

    gap_sum = make_cases(rng)
    logits: list[int] = []
    class_idx: list[int] = []

    for case in range(CASES):
        avg = [sat16(trunc_div(gap_sum[case][k], GAP_LEN)) for k in range(IN_CH)]

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

    write_mem(OUT / "gap_sum.mem", [v for row in gap_sum for v in row], bits=48)
    write_mem(OUT / "fc0_weight.mem", fc0_aug)
    write_mem(OUT / "fc1_weight.mem", fc1_aug)
    write_mem(OUT / "expected_logits.mem", logits)
    write_mem(OUT / "expected_class.mem", class_idx, bits=8)
    write_mem(OUT / "case_count.mem", [CASES], bits=8)


if __name__ == "__main__":
    main()
