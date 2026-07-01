#!/usr/bin/env python3
"""Row-buffer sizing model for the LightCNN1D streaming pipeline.

This script focuses on the extra storage introduced by row packers:

- DW1 can produce rows before PW1 has accumulated four rows.
- DW2 can produce rows before PW2 has accumulated four low-resolution rows.

The model uses the recommended parameters in the design note:

- stem P_T x P_OC, configured by command-line arguments
- DW P_CH/P_TAP, configured by command-line arguments
- PW1 4xP_OC, configured by command-line arguments
- PW2 4xP_OC, configured by command-line arguments
"""

from __future__ import annotations

import argparse
from collections import defaultdict, deque
from dataclasses import dataclass
from math import ceil


DATA_W = 16
INPUT_LEN = 348
POOL_LEN = 174

STEM_CIN = 5
STEM_CH = 32
STEM_K = 7
DW1_OUT_CH = 32
POOL_CH = 64
DW2_OUT_CH = 64
PW2_OUT_CH = 96

STEM_BATCH_ROWS = 4
DW_K = 5
PW1_GROUP_ROWS = 4
PW1_CIN = 32
PW1_COUT = 64
PW1_POST_LATENCY = 6
PW2_GROUP_ROWS = 4
PW2_CIN = 64
PW2_COUT = 96


def ceildiv(a: int, b: int) -> int:
    return (a + b - 1) // b


def row_bytes(channels: int) -> int:
    return channels * DATA_W // 8


def stem_batch_cycles(stem_pt: int, stem_poc: int) -> int:
    return ceildiv(STEM_BATCH_ROWS, stem_pt) * ceildiv(STEM_CH, stem_poc) * STEM_CIN * STEM_K


def depthwise_row_cycles(channels: int, p_ch: int, p_tap: int) -> int:
    return ceildiv(channels, p_ch) * ceildiv(DW_K, p_tap)


def pw_group_cycles(group_rows: int, cin: int, cout: int, p_t: int, p_oc: int) -> int:
    return ceildiv(group_rows, p_t) * ceildiv(cout, p_oc) * cin


@dataclass
class GroupInfo:
    start_time: int
    rows: list[int]
    waits: list[int]


@dataclass
class ConsumerResult:
    name: str
    max_occupancy: int
    max_wait_cycles: int
    group_count: int
    final_partial_rows: int
    done_time: int
    output_events: list[tuple[int, int]]
    groups: list[GroupInfo]


def generate_dw1_events(stem_cycles_per_batch: int, dw1_row_cycles: int) -> list[tuple[int, int]]:
    """Return (time, highres_row_index) events for DW1 output rows."""
    events: list[tuple[int, int]] = []
    dw1_free = 0
    next_row = 0
    microtiles = INPUT_LEN // STEM_BATCH_ROWS

    for mt in range(microtiles):
        stem_done = (mt + 1) * stem_cycles_per_batch
        if mt == 0:
            new_rows = 2
        elif mt == microtiles - 1:
            new_rows = 6
        else:
            new_rows = 4

        dw1_free = max(dw1_free, stem_done)
        for _ in range(new_rows):
            dw1_free += dw1_row_cycles
            events.append((dw1_free, next_row))
            next_row += 1

    assert next_row == INPUT_LEN
    return events


def simulate_group_consumer(
    name: str,
    arrivals: list[tuple[int, int]],
    group_rows: int,
    service_cycles: int,
    output_rows_per_group: int = 0,
    output_latency: int = 0,
    final_flush: bool = False,
) -> ConsumerResult:
    """Consume row arrivals in fixed-size groups and track FIFO occupancy."""
    arrivals_by_time: dict[int, list[int]] = defaultdict(list)
    for time, row in arrivals:
        arrivals_by_time[time].append(row)

    total_rows = len(arrivals)
    last_arrival = max(time for time, _ in arrivals) if arrivals else 0
    max_time = last_arrival + service_cycles * ceildiv(total_rows, group_rows) + 1000

    queue: deque[tuple[int, int]] = deque()
    busy_until = 0
    arrived = 0
    consumed = 0
    max_occupancy = 0
    max_wait = 0
    group_count = 0
    final_partial_rows = 0
    next_output_row = 0
    output_events: list[tuple[int, int]] = []
    groups: list[GroupInfo] = []

    for time in range(max_time + 1):
        for row in arrivals_by_time.get(time, []):
            queue.append((row, time))
            arrived += 1

        max_occupancy = max(max_occupancy, len(queue))

        all_arrived = arrived == total_rows
        can_full = len(queue) >= group_rows
        can_final = final_flush and all_arrived and len(queue) > 0

        if time >= busy_until and (can_full or can_final):
            take = group_rows if can_full else len(queue)
            if take < group_rows:
                final_partial_rows = take

            taken_rows: list[int] = []
            waits: list[int] = []
            for _ in range(take):
                row, arrival_time = queue.popleft()
                wait = time - arrival_time
                taken_rows.append(row)
                waits.append(wait)
                max_wait = max(max_wait, wait)
            consumed += take
            group_count += 1
            groups.append(GroupInfo(start_time=time, rows=taken_rows, waits=waits))
            busy_until = time + service_cycles

            for _ in range(output_rows_per_group):
                output_events.append((busy_until + output_latency, next_output_row))
                next_output_row += 1

        if consumed == total_rows and not queue and time >= busy_until:
            break
    else:
        raise RuntimeError(f"{name} simulation did not finish")

    return ConsumerResult(
        name=name,
        max_occupancy=max_occupancy,
        max_wait_cycles=max_wait,
        group_count=group_count,
        final_partial_rows=final_partial_rows,
        done_time=busy_until,
        output_events=output_events,
        groups=groups,
    )


def generate_dw2_events(pool_events: list[tuple[int, int]], dw2_row_cycles: int) -> list[tuple[int, int]]:
    """Return (time, lowres_row_index) events for DW2 output rows."""
    events: list[tuple[int, int]] = []
    events_by_time: dict[int, list[int]] = defaultdict(list)
    for time, row in pool_events:
        events_by_time[time].append(row)

    dw2_free = 0
    pool_right = -1
    next_dw2_row = 0

    for time in sorted(events_by_time):
        for row in sorted(events_by_time[time]):
            pool_right = max(pool_right, row)

        final = pool_right == POOL_LEN - 1
        ready = POOL_LEN - 1 if final else pool_right - 2
        if ready < next_dw2_row:
            continue

        dw2_free = max(dw2_free, time)
        while next_dw2_row <= ready:
            dw2_free += dw2_row_cycles
            events.append((dw2_free, next_dw2_row))
            next_dw2_row += 1

    assert next_dw2_row == POOL_LEN
    return events


def bits_for(depth_rows: int, channels: int) -> int:
    return depth_rows * channels * DATA_W


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
    stem_cycles = stem_batch_cycles(args.stem_pt, args.stem_poc)
    dw1_row_cycles = depthwise_row_cycles(STEM_CH, args.dw_pch, args.dw_ptap)
    dw2_row_cycles = depthwise_row_cycles(POOL_CH, args.dw_pch, args.dw_ptap)
    pw1_cycles = pw_group_cycles(PW1_GROUP_ROWS, PW1_CIN, PW1_COUT, 4, args.pw1_poc)
    pw2_cycles = pw_group_cycles(PW2_GROUP_ROWS, PW2_CIN, PW2_COUT, 4, args.pw2_poc)

    dw1_events = generate_dw1_events(stem_cycles, dw1_row_cycles)

    pw1 = simulate_group_consumer(
        "DW1_to_PW1",
        dw1_events,
        group_rows=PW1_GROUP_ROWS,
        service_cycles=pw1_cycles,
        output_rows_per_group=2,
        output_latency=PW1_POST_LATENCY,
        final_flush=False,
    )

    dw2_events = generate_dw2_events(pw1.output_events, dw2_row_cycles)

    pw2 = simulate_group_consumer(
        "DW2_to_PW2",
        dw2_events,
        group_rows=PW2_GROUP_ROWS,
        service_cycles=pw2_cycles,
        output_rows_per_group=0,
        final_flush=True,
    )

    rows = [
        (
            "buffer",
            "row width",
            "model max rows",
            "recommended rows",
            "recommended bits",
            "recommended bytes",
            "reason",
        ),
        (
            "stem_to_dw1_window",
            f"{STEM_CH} ch",
            "5-row window, 4-row burst",
            8,
            bits_for(8, STEM_CH),
            bits_for(8, STEM_CH) // 8,
            "k=5 plus 4-row stem burst and boundary padding",
        ),
        (
            "dw1_to_pw1_row_fifo",
            f"{DW1_OUT_CH} ch",
            pw1.max_occupancy,
            8,
            bits_for(8, DW1_OUT_CH),
            bits_for(8, DW1_OUT_CH) // 8,
            f"FIFO max occupancy is 4 rows; max row wait is {pw1.max_wait_cycles} cycles",
        ),
        (
            "pw1_input_tile_regs",
            f"{DW1_OUT_CH} ch",
            "4 rows locked during PW1 tile",
            4,
            bits_for(4, DW1_OUT_CH),
            bits_for(4, DW1_OUT_CH) // 8,
            "local packer/activation tile, separate from row FIFO if FIFO is not multi-read",
        ),
        (
            "pool_to_dw2_window",
            f"{POOL_CH} ch",
            "5-row window, 2-row pool burst",
            8,
            bits_for(8, POOL_CH),
            bits_for(8, POOL_CH) // 8,
            "k=5 DW2 lookahead plus pool pair output",
        ),
        (
            "dw2_to_pw2_row_fifo",
            f"{DW2_OUT_CH} ch",
            pw2.max_occupancy,
            8,
            bits_for(8, DW2_OUT_CH),
            bits_for(8, DW2_OUT_CH) // 8,
            f"FIFO max occupancy is 4 rows; max row wait is {pw2.max_wait_cycles} cycles",
        ),
        (
            "pw2_input_tile_regs",
            f"{DW2_OUT_CH} ch",
            "4 rows locked during PW2 tile",
            4,
            bits_for(4, DW2_OUT_CH),
            bits_for(4, DW2_OUT_CH) // 8,
            "local packer/activation tile, separate from row FIFO if FIFO is not multi-read",
        ),
        (
            "pw2_to_gap_optional_fifo",
            f"{PW2_OUT_CH} ch",
            "streaming accumulation",
            4,
            bits_for(4, PW2_OUT_CH),
            bits_for(4, PW2_OUT_CH) // 8,
            "optional debug/backpressure FIFO; GAP normally accumulates directly",
        ),
    ]

    print("# LightCNN1D Row Buffer Sizing")
    print()
    print(
        f"Assumption: stem `{args.stem_pt}x{args.stem_poc}` emits "
        f"{STEM_BATCH_ROWS} full-channel high-resolution rows every {stem_cycles} cycles."
    )
    print(
        f"Assumption: DW P_CH={args.dw_pch}, P_TAP={args.dw_ptap}; "
        f"DW1 row={dw1_row_cycles} cycles, DW2 row={dw2_row_cycles} cycles."
    )
    print(f"Assumption: PW1 4x{args.pw1_poc} group={pw1_cycles} cycles, PW2 4x{args.pw2_poc} group={pw2_cycles} cycles.")
    print()
    print("| " + " | ".join(rows[0]) + " |")
    print("| " + " | ".join(["---"] * len(rows[0])) + " |")
    for row in rows[1:]:
        print("| " + " | ".join(str(x) for x in row) + " |")

    print()
    print("## Simulated packer details")
    print()
    print(f"- DW1->PW1 groups: {pw1.group_count}, max FIFO rows: {pw1.max_occupancy}, max wait: {pw1.max_wait_cycles} cycles")
    print(f"- DW2->PW2 groups: {pw2.group_count}, max FIFO rows: {pw2.max_occupancy}, max wait: {pw2.max_wait_cycles} cycles, final partial rows: {pw2.final_partial_rows}")
    print(f"- PW1 pool rows produced: {len(pw1.output_events)}")
    print(f"- DW2 rows produced: {len(dw2_events)}")

    print()
    print("## First and worst group timing")
    print()
    pw1_worst = max(pw1.groups, key=lambda g: max(g.waits))
    pw2_worst = max(pw2.groups, key=lambda g: max(g.waits))
    print(f"- PW1 first group starts at {pw1.groups[0].start_time}, rows={pw1.groups[0].rows}, waits={pw1.groups[0].waits}")
    print(f"- PW1 worst group starts at {pw1_worst.start_time}, rows={pw1_worst.rows}, waits={pw1_worst.waits}")
    print(f"- PW2 first group starts at {pw2.groups[0].start_time}, rows={pw2.groups[0].rows}, waits={pw2.groups[0].waits}")
    print(f"- PW2 worst group starts at {pw2_worst.start_time}, rows={pw2_worst.rows}, waits={pw2_worst.waits}")

    print()
    print("## End-to-GAP/AveragePool timing")
    print()
    stem_done = ceildiv(INPUT_LEN, STEM_BATCH_ROWS) * stem_cycles
    dw1_done = dw1_events[-1][0]
    pool_done = pw1.output_events[-1][0]
    dw2_done = dw2_events[-1][0]
    final_pw2_group = pw2.groups[-1]
    print(f"- Stem last 4-row micro-tile done: {stem_done} cycles")
    print(f"- DW1 last row produced: {dw1_done} cycles")
    print(f"- PW1/Pool all low-resolution rows produced: {pool_done} cycles")
    print(f"- DW2 last row produced: {dw2_done} cycles")
    print(f"- PW2 final group starts: {final_pw2_group.start_time} cycles, rows={final_pw2_group.rows}, waits={final_pw2_group.waits}")
    print(f"- PW2/GAP receives all rows: {pw2.done_time} cycles")
    print(f"- Drain after final stem micro-tile: {pw2.done_time - stem_done} cycles")


if __name__ == "__main__":
    main()
