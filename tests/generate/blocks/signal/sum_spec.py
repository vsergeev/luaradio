import numpy
from generate import *


def generate():
    vectors = []

    x, y = random_complex64(256), random_complex64(256)
    vectors.append(TestVector([], [x, y], [x + y], "2 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))

    x, y = random_float32(256), random_float32(256)
    vectors.append(TestVector([], [x, y], [x + y], "2 256 Float32 inputs, 256 Float32 output"))

    return BlockSpec("SumBlock", "tests/blocks/signal/sum_spec.lua", vectors, 1e-6)
