import numpy
from generate import *


def generate():
    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([], [x], [x.astype(numpy.complex64)], "256 Float32 input, 256 ComplexFloat32 output"))

    return BlockSpec("RealToComplexBlock", "tests/blocks/signal/realtocomplex_spec.lua", vectors, 1e-6)
