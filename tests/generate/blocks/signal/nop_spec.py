import numpy
from generate import *


def generate():
    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([], [x], [x], "256 Float32 input, 256 Float32 output"))
    y = random_bit(256)
    vectors.append(TestVector([], [y], [y], "256 Bit input, 256 Bit output"))

    return BlockSpec("NopBlock", vectors, 1e-6)
