#!/usr/bin/env python3
"""Cycle model for the proposed LightCNN1D streaming pipeline.

The model follows the chunking idea discussed on 2026-07-01:

- Stem produces high-resolution time chunks: 43 chunks of 8 samples and one
  tail chunk of 4 samples.
- DW1 can emit 6 samples after the first stem chunk, 8 samples for each middle
  chunk, and 6 samples at the tail because of k=5, pad=2.
- MaxPool converts the high-resolution PW1 stream to 174 low-resolution points.
- DW2 then emits 1 point after the first chunk, 4 points per middle chunk, and
  5 points at the tail.

The script compares several PE-array parameter choices and prints a Markdown
summary. It does not depend on the old RTL baseline.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from math import ceil
from typing import Iterable


INPUT_LEN = 348
POOL_LEN = 174

STEM_CIN = 5
STEM_COUT = 32
STEM_K = 7
DW_K = 5
DW_PAD = 2
PW1_CIN = 32
PW1_COUT = 64
PW2_CIN = 64
PW2_COUT = 96

STAGE_ORDER = ("stem", "dw1", "pw1", "pool", "dw2", "pw2")


def ceildiv(a: int, b: int) -> int:
    return (a + b - 1) // b


@dataclass(frozen=True)
class GemmArray:
    pt: int
    poc: int

    @property
    def macs(self) -> int:
        return self.pt * self.poc

    def label(self) -> str:
        return f"{self.pt}x{self.poc}"


@dataclass(frozen=True)
class Config:
    name: str
    stem: GemmArray
    pw1: GemmArray
    pw2: GemmArray
    dw1_pch: int = 8
    dw2_pch: int = 8
    dw1_ptap: int = DW_K
    dw2_ptap: int = DW_K
    pool_pch: int = 64

    def resource_label(self) -> str:
        dw1_mul = self.dw1_pch * self.dw1_ptap
        dw2_mul = self.dw2_pch * self.dw2_ptap
        return (
            f"stem {self.stem.macs} MAC, "
            f"PW1 {self.pw1.macs} MAC, "
            f"PW2 {self.pw2.macs} MAC, "
            f"DW1 {dw1_mul} mul, DW2 {dw2_mul} mul"
        )


@dataclass(frozen=True)
class Chunk:
    index: int
    final: bool
    stem_new: int
    dw1_new: int
    pool_new: int
    dw2_new: int

    @property
    def pw1_new(self) -> int:
        return self.dw1_new

    @property
    def pw2_new(self) -> int:
        return self.dw2_new


def gemm_cycles(length: int, n_out: int, k_red: int, array: GemmArray) -> int:
    if length <= 0:
        return 0
    return ceildiv(length, array.pt) * ceildiv(n_out, array.poc) * k_red


def depthwise_cycles(length: int, channels: int, p_ch: int, p_tap: int = DW_K) -> int:
    if length <= 0:
        return 0
    return length * ceildiv(channels, p_ch) * ceildiv(DW_K, p_tap)


def pool_cycles(length: int, channels: int, p_ch: int) -> int:
    if length <= 0:
        return 0
    return length * ceildiv(channels, p_ch)


def build_chunks(chunk_t: int = 8) -> list[Chunk]:
    sizes = [chunk_t] * (INPUT_LEN // chunk_t)
    if INPUT_LEN % chunk_t:
        sizes.append(INPUT_LEN % chunk_t)

    chunks: list[Chunk] = []
    stem_right = -1
    last_dw1 = -1
    last_pool = -1
    last_dw2 = -1

    for index, size in enumerate(sizes):
        final = index == len(sizes) - 1
        stem_right += size

        if final:
            dw1_ready = INPUT_LEN - 1
        else:
            dw1_ready = min(INPUT_LEN - 1, stem_right - DW_PAD)
        dw1_new = max(0, dw1_ready - last_dw1)
        if dw1_new:
            last_dw1 = dw1_ready

        if final:
            pool_ready = POOL_LEN - 1
        elif last_dw1 >= 1:
            pool_ready = min(POOL_LEN - 1, (last_dw1 - 1) // 2)
        else:
            pool_ready = -1
        pool_new = max(0, pool_ready - last_pool)
        if pool_new:
            last_pool = pool_ready

        if final:
            dw2_ready = POOL_LEN - 1
        else:
            dw2_ready = min(POOL_LEN - 1, pool_ready - DW_PAD)
        dw2_new = max(0, dw2_ready - last_dw2)
        if dw2_new:
            last_dw2 = dw2_ready

        chunks.append(
            Chunk(
                index=index,
                final=final,
                stem_new=size,
                dw1_new=dw1_new,
                pool_new=pool_new,
                dw2_new=dw2_new,
            )
        )

    assert sum(c.dw1_new for c in chunks) == INPUT_LEN
    assert sum(c.pool_new for c in chunks) == POOL_LEN
    assert sum(c.dw2_new for c in chunks) == POOL_LEN
    return chunks


def chunk_cycles(chunk: Chunk, cfg: Config) -> dict[str, int]:
    return {
        "stem": gemm_cycles(chunk.stem_new, STEM_COUT, STEM_CIN * STEM_K, cfg.stem),
        "dw1": depthwise_cycles(chunk.dw1_new, STEM_COUT, cfg.dw1_pch, cfg.dw1_ptap),
        "pw1": gemm_cycles(chunk.pw1_new, PW1_COUT, PW1_CIN, cfg.pw1),
        "pool": pool_cycles(chunk.pool_new, PW1_COUT, cfg.pool_pch),
        "dw2": depthwise_cycles(chunk.dw2_new, PW1_COUT, cfg.dw2_pch, cfg.dw2_ptap),
        "pw2": gemm_cycles(chunk.pw2_new, PW2_COUT, PW2_CIN, cfg.pw2),
    }


def pipeline_makespan(chunks: list[Chunk], cfg: Config) -> tuple[int, dict[str, int]]:
    """Schedule chunks through fixed stages, one chunk at a time per stage."""
    finish_by_stage: dict[str, list[int]] = {stage: [] for stage in STAGE_ORDER}
    stage_work = {stage: 0 for stage in STAGE_ORDER}

    for chunk in chunks:
        durations = chunk_cycles(chunk, cfg)
        for stage_index, stage in enumerate(STAGE_ORDER):
            prev_stage_done = 0
            if stage_index > 0:
                prev_stage_done = finish_by_stage[STAGE_ORDER[stage_index - 1]][chunk.index]
            prev_chunk_done = finish_by_stage[stage][-1] if finish_by_stage[stage] else 0
            done = max(prev_stage_done, prev_chunk_done) + durations[stage]
            finish_by_stage[stage].append(done)
            stage_work[stage] += durations[stage]

    return finish_by_stage[STAGE_ORDER[-1]][-1], stage_work


def format_cycles(cycles: int) -> str:
    return f"{cycles:,}"


def format_us(cycles: int, mhz: int = 100) -> str:
    return f"{cycles / mhz:.2f}"


def markdown_table(rows: Iterable[Iterable[object]]) -> str:
    rows = [list(row) for row in rows]
    header = rows[0]
    aligns = ["---"] * len(header)
    lines = [
        "| " + " | ".join(str(x) for x in header) + " |",
        "| " + " | ".join(aligns) + " |",
    ]
    for row in rows[1:]:
        lines.append("| " + " | ".join(str(x) for x in row) + " |")
    return "\n".join(lines)


def describe_config(cfg: Config, chunks: list[Chunk]) -> str:
    first = chunks[0]
    middle = chunks[1]
    tail = chunks[-1]
    first_cycles = chunk_cycles(first, cfg)
    middle_cycles = chunk_cycles(middle, cfg)
    tail_cycles = chunk_cycles(tail, cfg)
    steady_ii = max(middle_cycles.values())
    makespan, work = pipeline_makespan(chunks, cfg)

    rows = [
        ("stage", "first chunk", "middle chunk", "tail chunk", "steady util"),
    ]
    for stage in STAGE_ORDER:
        rows.append(
            (
                stage,
                format_cycles(first_cycles[stage]),
                format_cycles(middle_cycles[stage]),
                format_cycles(tail_cycles[stage]),
                f"{middle_cycles[stage] / steady_ii * 100:.1f}%",
            )
        )

    bottleneck = max(middle_cycles, key=middle_cycles.get)
    total_macs = cfg.stem.macs + cfg.pw1.macs + cfg.pw2.macs
    total_dw_mul = cfg.dw1_pch * cfg.dw1_ptap + cfg.dw2_pch * cfg.dw2_ptap
    summary = [
        f"### {cfg.name}",
        "",
        f"- Arrays: stem `{cfg.stem.label()}`, PW1 `{cfg.pw1.label()}`, PW2 `{cfg.pw2.label()}`.",
        f"- Resource count: {cfg.resource_label()} ({total_macs} GEMM MAC lanes + {total_dw_mul} DW multipliers).",
        f"- Middle-chunk initiation interval: `{format_cycles(steady_ii)}` cycles, bottleneck `{bottleneck}`.",
        f"- Scheduled 44-chunk PW2 completion: `{format_cycles(makespan)}` cycles = `{format_us(makespan)}` us @100 MHz.",
        "",
        markdown_table(rows),
        "",
    ]
    return "\n".join(summary)


def microtile_handoff_summary(cfg: Config) -> str:
    """Analyze the 4-time stem micro-tile handoff cadence."""

    stem_4 = gemm_cycles(4, STEM_COUT, STEM_CIN * STEM_K, cfg.stem)
    stem_8 = gemm_cycles(8, STEM_COUT, STEM_CIN * STEM_K, cfg.stem)

    rows = [
        (
            "handoff",
            "produced points",
            "DW cycles",
            "PW cycles",
            "producer interval",
            "PW slack",
            "note",
        ),
    ]

    dw1_mid = depthwise_cycles(4, STEM_COUT, cfg.dw1_pch, cfg.dw1_ptap)
    pw1_mid = gemm_cycles(4, PW1_COUT, PW1_CIN, cfg.pw1)
    rows.append(
        (
            "DW1 -> PW1 steady",
            "4 high-res",
            dw1_mid,
            pw1_mid,
            stem_4,
            stem_4 - pw1_mid,
            "fits if PW1 consumes 4 rows per beat",
        )
    )

    dw1_first = depthwise_cycles(2, STEM_COUT, cfg.dw1_pch, cfg.dw1_ptap)
    pw1_first = gemm_cycles(2, PW1_COUT, PW1_CIN, cfg.pw1)
    rows.append(
        (
            "DW1 -> PW1 first boundary",
            "2 high-res",
            dw1_first,
            pw1_first,
            stem_4,
            stem_4 - pw1_first,
            "valid_count=2 or wait to merge",
        )
    )

    dw1_tail = depthwise_cycles(6, STEM_COUT, cfg.dw1_pch, cfg.dw1_ptap)
    pw1_tail = gemm_cycles(6, PW1_COUT, PW1_CIN, cfg.pw1)
    rows.append(
        (
            "DW1 -> PW1 tail boundary",
            "6 high-res",
            dw1_tail,
            pw1_tail,
            stem_4,
            stem_4 - pw1_tail,
            "tail needs two PW1 time tiles",
        )
    )

    dw2_mid_2 = depthwise_cycles(2, PW1_COUT, cfg.dw2_pch, cfg.dw2_ptap)
    pw2_mid_2 = gemm_cycles(2, PW2_COUT, PW2_CIN, cfg.pw2)
    rows.append(
        (
            "DW2 -> PW2 every 4 high-res",
            "2 low-res",
            dw2_mid_2,
            pw2_mid_2,
            stem_4,
            stem_4 - pw2_mid_2,
            "fits but underuses P_T=4" if stem_4 >= pw2_mid_2 else "does not fit unless PW2 is underused/stalls",
        )
    )

    dw2_mid_4 = depthwise_cycles(4, PW1_COUT, cfg.dw2_pch, cfg.dw2_ptap)
    pw2_mid_4 = gemm_cycles(4, PW2_COUT, PW2_CIN, cfg.pw2)
    rows.append(
        (
            "DW2 -> PW2 every 8 high-res",
            "4 low-res",
            dw2_mid_4,
            pw2_mid_4,
            stem_8,
            stem_8 - pw2_mid_4,
            "full PW2 time tile cadence",
        )
    )

    return "\n".join(
        [
            "## 4-Time Stem Micro-Tile Handoff",
            "",
            f"Stem `{cfg.stem.label()}` emits 4 full-channel stem time points in `{stem_4}` cycles.",
            f"Two such beats, i.e. 8 stem time points, take `{stem_8}` cycles.",
            "",
            markdown_table(rows),
            "",
            "The slack column compares only PW compute time with the producer interval. "
            "DW runs as a short producer in front of PW and writes a small FIFO/ping-pong buffer.",
            "",
        ]
    )


def boundary_strategy_summary(cfg: Config, chunks: list[Chunk]) -> str:
    """Compare eager masked boundary tiles with row-packer grouping."""

    pw1_eager = sum(chunk_cycles(chunk, cfg)["pw1"] for chunk in chunks)
    pw2_eager = sum(chunk_cycles(chunk, cfg)["pw2"] for chunk in chunks)

    pw1_tile = ceildiv(PW1_COUT, cfg.pw1.poc) * PW1_CIN
    pw2_tile = ceildiv(PW2_COUT, cfg.pw2.poc) * PW2_CIN
    pw1_packed = ceildiv(INPUT_LEN, cfg.pw1.pt) * pw1_tile
    pw2_packed = ceildiv(POOL_LEN, cfg.pw2.pt) * pw2_tile

    rows = [
        ("layer", "eager chunk tiles", "row-packer tiles", "saved cycles", "boundary note"),
        (
            "PW1",
            pw1_eager,
            pw1_packed,
            pw1_eager - pw1_packed,
            "348 high-res points is exactly 87 groups of 4",
        ),
        (
            "PW2",
            pw2_eager,
            pw2_packed,
            pw2_eager - pw2_packed,
            "174 low-res points is 43 full groups plus final 2-point flush",
        ),
    ]

    return "\n".join(
        [
            "## Boundary Strategy: Eager Mask vs Row Packer",
            "",
            "Eager chunk scheduling fires PW on every boundary-valid group, even when fewer than "
            f"`P_T={cfg.pw1.pt}` rows are valid. A row packer stores DW/PW-ready time rows in FIFO order "
            "and only fires PW when four rows are available, except for final flush.",
            "",
            markdown_table(rows),
            "",
        ]
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stem-pt", type=int, default=4, help="stem PE rows/time lanes")
    parser.add_argument("--stem-poc", type=int, default=8, help="stem PE output-channel lanes")
    parser.add_argument("--pw1-poc", type=int, default=16, help="PW1 PE output-channel lanes for recommended config")
    parser.add_argument("--pw2-poc", type=int, default=24, help="PW2 PE output-channel lanes for recommended config")
    parser.add_argument("--dw-pch", type=int, default=8, help="DW channel lanes for recommended config")
    parser.add_argument("--dw-ptap", type=int, default=DW_K, help="DW tap lanes per channel for recommended config")
    parser.add_argument("--recommended-only", action="store_true", help="print only the time-tile recommended config")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    chunks = build_chunks(8)
    count_rows = [
        ("chunk", "stem new", "DW1/PW1 new", "pool new", "DW2/PW2 new"),
        ("first", chunks[0].stem_new, chunks[0].dw1_new, chunks[0].pool_new, chunks[0].dw2_new),
        ("middle x42", chunks[1].stem_new, chunks[1].dw1_new, chunks[1].pool_new, chunks[1].dw2_new),
        ("tail", chunks[-1].stem_new, chunks[-1].dw1_new, chunks[-1].pool_new, chunks[-1].dw2_new),
        (
            "total",
            sum(c.stem_new for c in chunks),
            sum(c.dw1_new for c in chunks),
            sum(c.pool_new for c in chunks),
            sum(c.dw2_new for c in chunks),
        ),
    ]

    stem = GemmArray(args.stem_pt, args.stem_poc)
    configs = [
        Config(
            name="User proposal: PW1/PW2 single-time 1x16",
            stem=stem,
            pw1=GemmArray(1, 16),
            pw2=GemmArray(1, 16),
            dw1_pch=args.dw_pch,
            dw2_pch=args.dw_pch,
            dw1_ptap=args.dw_ptap,
            dw2_ptap=args.dw_ptap,
        ),
        Config(
            name="Balanced single-time flow: PW1 1x32, PW2 1x48",
            stem=stem,
            pw1=GemmArray(1, 32),
            pw2=GemmArray(1, 48),
            dw1_pch=args.dw_pch,
            dw2_pch=args.dw_pch,
            dw1_ptap=args.dw_ptap,
            dw2_ptap=args.dw_ptap,
        ),
        Config(
            name=f"Recommended time-tile flow: PW1 4x{args.pw1_poc}, PW2 4x{args.pw2_poc}",
            stem=stem,
            pw1=GemmArray(4, args.pw1_poc),
            pw2=GemmArray(4, args.pw2_poc),
            dw1_pch=args.dw_pch,
            dw2_pch=args.dw_pch,
            dw1_ptap=args.dw_ptap,
            dw2_ptap=args.dw_ptap,
        ),
        Config(
            name="Aggressive single-time match: PW1 1x64, PW2 1x96",
            stem=stem,
            pw1=GemmArray(1, 64),
            pw2=GemmArray(1, 96),
            dw1_pch=args.dw_pch,
            dw2_pch=args.dw_pch,
            dw1_ptap=args.dw_ptap,
            dw2_ptap=args.dw_ptap,
        ),
    ]
    if args.recommended_only:
        configs = [configs[2]]

    print("# LightCNN1D Streaming Pipeline Cycle Model")
    print()
    print("## Chunk Production Counts")
    print()
    print(markdown_table(count_rows))
    print()
    print("## Parameter Comparisons")
    print()
    for cfg in configs:
        print(describe_config(cfg, chunks))

    recommended = configs[0] if args.recommended_only else configs[2]
    print(microtile_handoff_summary(recommended))
    print(boundary_strategy_summary(recommended, chunks))


if __name__ == "__main__":
    main()
