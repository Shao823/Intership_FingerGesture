from __future__ import annotations

from pathlib import Path
from random import Random

DATA_W = 16
ACC_W = 48
FRAC_BITS = 8

INT16_MIN = -(1 << 15)
INT16_MAX = (1 << 15) - 1


def sat16(value: int) -> int:
    if value > INT16_MAX:
        return INT16_MAX
    if value < INT16_MIN:
        return INT16_MIN
    return int(value)


def relu16(value: int) -> int:
    return 0 if value < 0 else value


def conv_bn_relu(acc: int, scale: int, bias: int) -> int:
    conv_q = sat16(acc >> FRAC_BITS)
    post = (conv_q * scale) >> FRAC_BITS
    return relu16(sat16(post + bias))


def mac_sat_q88(xs: list[int], ws: list[int]) -> int:
    acc = 0
    for x, w in zip(xs, ws):
        acc += int(x) * int(w)
    return sat16(acc >> FRAC_BITS)


def fc_out_from_acc(acc: int) -> int:
    return sat16(acc >> FRAC_BITS)


def fc_bias_to_acc(bias: int) -> int:
    return int(bias) << FRAC_BITS


def hex_twos(value: int, bits: int = 16) -> str:
    mask = (1 << bits) - 1
    width = (bits + 3) // 4
    return f"{value & mask:0{width}X}"


def write_mem(path: Path, values: list[int], bits: int = 16) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii") as fp:
        for value in values:
            fp.write(hex_twos(int(value), bits) + "\n")


def rand_q88(rng: Random, low: int = -384, high: int = 384) -> int:
    return rng.randint(low, high)


def rand_nonzero_q88(rng: Random, low: int = -384, high: int = 384) -> int:
    value = 0
    while value == 0:
        value = rand_q88(rng, low, high)
    return value
