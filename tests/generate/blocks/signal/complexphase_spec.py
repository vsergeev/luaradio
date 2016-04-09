import numpy
from generate import *


def generate():
    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([], [x], [numpy.angle(x).astype(numpy.float32)], "256 ComplexFloat32 input, 256 Float32 output"))

    return BlockSpec("ComplexPhaseBlock", "tests/blocks/signal/complexphase_spec.lua", vectors, 1e-6)
