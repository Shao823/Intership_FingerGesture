#!/usr/bin/env python3

from pathlib import Path


CHANNELS = 5
INPUT_LEN = 348
FRAME_BYTES = CHANNELS * INPUT_LEN
BRAM_BYTES = 64 * 1024
SELECTED_CASES = (6, 8, 0, 2)
EXPECTED_CLASSES = (1, 2, 3, 4)


def load_hex_bytes(path: Path) -> list[int]:
    values = [int(line.strip(), 16) for line in path.read_text().splitlines() if line.strip()]
    expected_count = 10 * FRAME_BYTES
    if len(values) != expected_count:
        raise ValueError(f"expected {expected_count} bytes in {path}, found {len(values)}")
    return values


def to_channel_major(raw: list[int], case_index: int) -> list[int]:
    case_base = case_index * FRAME_BYTES
    frame = []
    for channel_index in range(CHANNELS):
        for time_index in range(INPUT_LEN):
            source_index = case_base + time_index * CHANNELS + channel_index
            frame.append(raw[source_index])
    return frame


def pack_words(memory: list[int]) -> list[int]:
    return [
        memory[index]
        | (memory[index + 1] << 8)
        | (memory[index + 2] << 16)
        | (memory[index + 3] << 24)
        for index in range(0, len(memory), 4)
    ]


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parents[2]
    raw_input_path = project_root / "src/top/accelerator/testdata/raw_input.mem"
    raw = load_hex_bytes(raw_input_path)

    memory = []
    manifest_lines = []
    for packed_index, (source_case, expected_class) in enumerate(
        zip(SELECTED_CASES, EXPECTED_CLASSES)
    ):
        offset = packed_index * FRAME_BYTES
        memory.extend(to_channel_major(raw, source_case))
        manifest_lines.append(
            f"packed_case={packed_index} source_case={source_case} "
            f"offset=0x{offset:04X} bytes={FRAME_BYTES} expected_class={expected_class}"
        )

    if len(memory) > BRAM_BYTES:
        raise ValueError("selected frames do not fit in the configured BRAM")
    memory.extend([0] * (BRAM_BYTES - len(memory)))
    words = pack_words(memory)

    coe_path = script_dir / "emg_representative_4cases.coe"
    mem_path = script_dir / "emg_representative_4cases.mem"
    manifest_path = script_dir / "emg_representative_4cases.txt"

    with coe_path.open("w", newline="\n") as coe_file:
        coe_file.write("memory_initialization_radix=16;\n")
        coe_file.write("memory_initialization_vector=\n")
        for index, word in enumerate(words):
            terminator = ";\n" if index == len(words) - 1 else ",\n"
            coe_file.write(f"{word:08X}{terminator}")

    mem_path.write_text("".join(f"{word:08X}\n" for word in words))
    manifest_path.write_text("\n".join(manifest_lines) + "\n")

    print(f"generated {coe_path}")
    print(f"generated {mem_path}")
    print(f"generated {manifest_path}")
    for line in manifest_lines:
        print(line)


if __name__ == "__main__":
    main()
