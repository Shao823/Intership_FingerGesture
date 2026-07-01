#!/usr/bin/env python3
"""Parameter comparison for the stem-4x4 LightCNN1D pipeline."""

from __future__ import annotations

from dataclasses import dataclass

from cycle_model import Config, GemmArray, build_chunks, chunk_cycles, pipeline_makespan


@dataclass(frozen=True)
class Candidate:
    name: str
    pw1_poc: int
    pw2_poc: int
    dw_pch: int
    dw_ptap: int
    note: str


def frontend_multipliers(cfg: Config) -> int:
    return (
        cfg.stem.macs
        + cfg.pw1.macs
        + cfg.pw2.macs
        + cfg.dw1_pch * cfg.dw1_ptap
        + cfg.dw2_pch * cfg.dw2_ptap
    )


def make_config(candidate: Candidate) -> Config:
    return Config(
        name=candidate.name,
        stem=GemmArray(4, 4),
        pw1=GemmArray(4, candidate.pw1_poc),
        pw2=GemmArray(4, candidate.pw2_poc),
        dw1_pch=candidate.dw_pch,
        dw2_pch=candidate.dw_pch,
        dw1_ptap=candidate.dw_ptap,
        dw2_ptap=candidate.dw_ptap,
    )


def main() -> None:
    chunks = build_chunks(8)
    middle = chunks[1]
    candidates = [
        Candidate("keep 4x8 PW/DW-full", 16, 24, 8, 5, "low PW utilization, high resource"),
        Candidate("resize PW only", 8, 12, 8, 5, "PW matches stem, DW still over-parallel"),
        Candidate("balanced full-tap", 8, 12, 4, 5, "recommended first RTL, keeps 5-tap parallel"),
        Candidate("tap-serial squeeze", 8, 12, 4, 1, "optional lower-DSP DW, changes DW micro-architecture"),
        Candidate("balanced odd-DW", 8, 12, 3, 1, "higher DW utilization, awkward banking"),
        Candidate("tiny DW bottleneck", 8, 12, 2, 1, "DW becomes bottleneck"),
        Candidate("smaller PW2", 8, 10, 4, 1, "saves PW2 lanes, lower throughput"),
    ]

    print("# Stem 4x4 Parallel Parameter Sweep")
    print()
    print(
        "| candidate | PW1 | PW2 | DW | frontend mult | II | stem | DW1 | PW1 | DW2 | PW2 | min heavy util | note |"
    )
    print("| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |")
    for candidate in candidates:
        cfg = make_config(candidate)
        cycles = chunk_cycles(middle, cfg)
        ii = max(cycles.values())
        makespan, _ = pipeline_makespan(chunks, cfg)
        heavy_utils = [
            cycles["stem"] / ii,
            cycles["dw1"] / ii,
            cycles["pw1"] / ii,
            cycles["dw2"] / ii,
            cycles["pw2"] / ii,
        ]
        print(
            "| "
            + " | ".join(
                [
                    candidate.name,
                    f"4x{candidate.pw1_poc}",
                    f"4x{candidate.pw2_poc}",
                    f"P_CH={candidate.dw_pch}, P_TAP={candidate.dw_ptap}",
                    str(frontend_multipliers(cfg)),
                    str(ii),
                    str(cycles["stem"]),
                    str(cycles["dw1"]),
                    str(cycles["pw1"]),
                    str(cycles["dw2"]),
                    str(cycles["pw2"]),
                    f"{min(heavy_utils) * 100:.1f}%",
                    f"{candidate.note}; done={makespan}",
                ]
            )
            + " |"
        )


if __name__ == "__main__":
    main()
