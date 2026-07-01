#!/usr/bin/env python3
"""Storage budget for the fused LightCNN1D streaming pipeline.

The budget assumes these fusions are enabled:

- stem Conv + BN + ReLU
- PW1 + BN + ReLU + MaxPool
- PW2 + BN + ReLU + GAP accumulation

Therefore the design does not keep full b1pw or b2pw feature maps.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass


DATA_W = 16
ACC_W = 48
DW_K = 5


def bits_to_bytes(bits: int) -> float:
    return bits / 8.0


def fmt_bits(bits: int) -> str:
    if bits % 8 == 0:
        return f"{bits:,} bit = {bits // 8:,} B"
    return f"{bits:,} bit = {bits_to_bytes(bits):.1f} B"


@dataclass(frozen=True)
class Entry:
    name: str
    rows_or_lanes: str
    channels_or_width: str
    bits: int
    note: str


def markdown_table(entries: list[Entry]) -> str:
    rows = [
        ("name", "rows/lanes", "channels/width", "storage", "note"),
        *[
            (entry.name, entry.rows_or_lanes, entry.channels_or_width, fmt_bits(entry.bits), entry.note)
            for entry in entries
        ],
    ]
    lines = [
        "| " + " | ".join(str(x) for x in rows[0]) + " |",
        "| " + " | ".join(["---"] * len(rows[0])) + " |",
    ]
    for row in rows[1:]:
        lines.append("| " + " | ".join(str(x) for x in row) + " |")
    return "\n".join(lines)


def interstage_entries() -> list[Entry]:
    return [
        Entry(
            "input_to_stem_window_optional",
            "10 rows",
            "5 ch x 16 bit",
            10 * 5 * DATA_W,
            "only needed for fully streaming raw input; full-window input buffer can replace it",
        ),
        Entry(
            "stem_to_dw1_window",
            "8 rows",
            "32 ch x 16 bit",
            8 * 32 * DATA_W,
            "stem Conv+BN+ReLU output window for DW1 k=5",
        ),
        Entry(
            "dw1_to_pw1_row_fifo",
            "8 rows",
            "32 ch x 16 bit",
            8 * 32 * DATA_W,
            "row FIFO before PW1 row packer",
        ),
        Entry(
            "pw1_input_tile_regs",
            "4 rows",
            "32 ch x 16 bit",
            4 * 32 * DATA_W,
            "local PW1 activation tile; can merge with FIFO if multi-read",
        ),
        Entry(
            "pool_to_dw2_window",
            "8 rows",
            "64 ch x 16 bit",
            8 * 64 * DATA_W,
            "PW1+BN+ReLU+MaxPool output window for DW2 k=5",
        ),
        Entry(
            "dw2_to_pw2_row_fifo",
            "8 rows",
            "64 ch x 16 bit",
            8 * 64 * DATA_W,
            "row FIFO before PW2 row packer",
        ),
        Entry(
            "pw2_input_tile_regs",
            "4 rows",
            "64 ch x 16 bit",
            4 * 64 * DATA_W,
            "local PW2 activation tile; can merge with FIFO if multi-read",
        ),
        Entry(
            "pw2_to_gap_optional_fifo",
            "4 rows",
            "96 ch x 16 bit",
            4 * 96 * DATA_W,
            "optional; normally GAP accumulates directly from PW2+BN+ReLU",
        ),
        Entry(
            "gap_sum",
            "96 lanes",
            "48 bit accumulator",
            96 * ACC_W,
            "streaming GAP accumulation before divide-by-174",
        ),
        Entry(
            "gap_vec",
            "96 values",
            "16 bit",
            96 * DATA_W,
            "Q8.8 vector after GAP normalization",
        ),
        Entry(
            "fc0_vec",
            "96 values",
            "16 bit",
            96 * DATA_W,
            "FC0+ReLU output",
        ),
        Entry(
            "logits",
            "5 values",
            "16 bit",
            5 * DATA_W,
            "FC1 output logits",
        ),
    ]


def dw_local_bits(p_ch: int, p_tap: int) -> int:
    return p_ch * DW_K * DATA_W + p_ch * p_tap * DATA_W + p_ch * ACC_W + p_ch * DATA_W


def pw1_local_bits(p_t: int, p_oc: int) -> int:
    return (
        p_t * p_oc * ACC_W
        + p_t * DATA_W
        + p_oc * DATA_W
        + 2 * p_oc * DATA_W
        + p_t * p_oc * DATA_W
        + 2 * p_oc * DATA_W
    )


def pw2_local_bits(p_t: int, p_oc: int) -> int:
    return p_t * p_oc * ACC_W + p_t * DATA_W + p_oc * DATA_W + 2 * p_oc * DATA_W + p_t * p_oc * DATA_W


def compute_local_entries(stem_pt: int, stem_poc: int, pw1_poc: int, pw2_poc: int, dw_pch: int, dw_ptap: int) -> list[Entry]:
    return [
        Entry(
            "stem_array_local",
            f"{stem_pt}x{stem_poc} PE",
            "acc + act + weight + BN + post regs",
            stem_pt * stem_poc * ACC_W
            + stem_pt * DATA_W
            + stem_poc * DATA_W
            + 2 * stem_poc * DATA_W
            + stem_pt * stem_poc * DATA_W,
            "output-stationary stem Conv+BN+ReLU local state",
        ),
        Entry(
            "dw1_pu_local",
            f"{dw_pch} ch x {dw_ptap} tap lanes",
            "5-tap window + active weights + acc + output",
            dw_local_bits(dw_pch, dw_ptap),
            "DW1 lane state; P_TAP<5 reuses multiplier across taps",
        ),
        Entry(
            "pw1_array_local",
            f"4x{pw1_poc} PE",
            "acc + act + weight + BN + post/pool regs",
            pw1_local_bits(4, pw1_poc),
            "PW1+BN+ReLU+MaxPool local state, excluding input tile regs above",
        ),
        Entry(
            "dw2_pu_local",
            f"{dw_pch} ch x {dw_ptap} tap lanes",
            "5-tap window + active weights + acc + output",
            dw_local_bits(dw_pch, dw_ptap),
            "DW2 lane state; P_TAP<5 reuses multiplier across taps",
        ),
        Entry(
            "pw2_array_local",
            f"4x{pw2_poc} PE",
            "acc + act + weight + BN + post regs",
            pw2_local_bits(4, pw2_poc),
            "PW2+BN+ReLU local state, excluding input tile regs above",
        ),
        Entry(
            "fc_dot_local",
            "16 output lanes",
            "acc + act + weight + bias + output",
            16 * ACC_W + DATA_W + 16 * DATA_W + 16 * DATA_W + 16 * DATA_W,
            "P_OUT=16 FC0/FC1 dot-product unit local state",
        ),
        Entry(
            "argmax_local",
            "1 lane",
            "best index + best value",
            3 + DATA_W,
            "serial argmax state",
        ),
    ]


def parameter_entries() -> list[Entry]:
    weight_values = {
        "stem_weight": 32 * 5 * 7,
        "dw1_weight": 32 * 5,
        "pw1_weight": 64 * 32,
        "dw2_weight": 64 * 5,
        "pw2_weight": 96 * 64,
        "fc0_weight": 96 * 96,
        "fc1_weight": 5 * 96,
    }
    entries = [
        Entry(name, f"{count} values", "16 bit", count * DATA_W, "Q8.8 parameter ROM")
        for name, count in weight_values.items()
    ]
    entries.extend(
        [
            Entry(
                "folded_bn_scale_bias",
                "384 values",
                "16 bit",
                (32 + 64 + 96) * 2 * DATA_W,
                "two folded BN params per output channel for stem/PW1/PW2",
            ),
            Entry(
                "fc_bias",
                "101 values",
                "16 bit",
                (96 + 5) * DATA_W,
                "FC0 and FC1 bias",
            ),
        ]
    )
    return entries


def print_section(title: str, entries: list[Entry]) -> int:
    total = sum(entry.bits for entry in entries)
    print(f"## {title}")
    print()
    print(markdown_table(entries))
    print()
    print(f"Subtotal: {fmt_bits(total)}")
    print()
    return total


def subtotal_by_name(entries: list[Entry], names: set[str]) -> int:
    return sum(entry.bits for entry in entries if entry.name in names)


def print_interstage_interpretation(entries: list[Entry]) -> None:
    required_names = {
        "stem_to_dw1_window",
        "dw1_to_pw1_row_fifo",
        "pw1_input_tile_regs",
        "pool_to_dw2_window",
        "dw2_to_pw2_row_fifo",
        "pw2_input_tile_regs",
    }
    optional_names = {
        "input_to_stem_window_optional",
        "pw2_to_gap_optional_fifo",
    }
    state_names = {
        "gap_sum",
        "gap_vec",
        "fc0_vec",
        "logits",
    }

    print("### Inter-stage/state subtotal interpretation")
    print()
    print(f"- Required inter-stage windows/FIFOs/tile regs: {fmt_bits(subtotal_by_name(entries, required_names))}")
    print(f"- Optional input/debug/backpressure buffers: {fmt_bits(subtotal_by_name(entries, optional_names))}")
    print(f"- GAP/FC runtime state vectors: {fmt_bits(subtotal_by_name(entries, state_names))}")
    print()


def print_parameter_interpretation(entries: list[Entry]) -> None:
    weight_names = {
        "stem_weight",
        "dw1_weight",
        "pw1_weight",
        "dw2_weight",
        "pw2_weight",
        "fc0_weight",
        "fc1_weight",
    }
    non_weight_names = {
        "folded_bn_scale_bias",
        "fc_bias",
    }

    print("### Parameter ROM subtotal interpretation")
    print()
    print(f"- Weight ROM only: {fmt_bits(subtotal_by_name(entries, weight_names))}")
    print(f"- Folded BN and FC bias ROM: {fmt_bits(subtotal_by_name(entries, non_weight_names))}")
    print()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stem-pt", type=int, default=4, help="stem PE rows/time lanes")
    parser.add_argument("--stem-poc", type=int, default=8, help="stem PE output-channel lanes")
    parser.add_argument("--pw1-poc", type=int, default=16, help="PW1 PE output-channel lanes")
    parser.add_argument("--pw2-poc", type=int, default=24, help="PW2 PE output-channel lanes")
    parser.add_argument("--dw-pch", type=int, default=8, help="DW channel lanes")
    parser.add_argument("--dw-ptap", type=int, default=DW_K, help="DW tap lanes per channel")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    print("# LightCNN1D Fused Pipeline Storage Budget")
    print()
    inter_entries = interstage_entries()
    param_entries = parameter_entries()

    inter = print_section("Inter-stage and State Storage", inter_entries)
    print_interstage_interpretation(inter_entries)
    local = print_section(
        "Compute Unit Local Storage",
        compute_local_entries(args.stem_pt, args.stem_poc, args.pw1_poc, args.pw2_poc, args.dw_pch, args.dw_ptap),
    )
    params = print_section("Parameter ROM Storage", param_entries)
    print_parameter_interpretation(param_entries)
    print("## Totals")
    print()
    print(f"- Inter-stage/state subtotal: {fmt_bits(inter)}")
    print(f"- Compute-local subtotal: {fmt_bits(local)}")
    print(f"- Parameter ROM subtotal: {fmt_bits(params)}")
    print(f"- Runtime storage without parameter ROM: {fmt_bits(inter + local)}")
    print(f"- Runtime storage with parameter ROM: {fmt_bits(inter + local + params)}")


if __name__ == "__main__":
    main()
