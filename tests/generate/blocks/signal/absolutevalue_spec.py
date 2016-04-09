import numpy
from generate import *


def generate():
    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([], [x], [numpy.abs(x)], "256 Float32 input, 256 Float32 output"))

    return BlockSpec("AbsoluteValueBlock", "tests/blocks/signal/absolutevalue_spec.lua", vectors, 1e-6)
