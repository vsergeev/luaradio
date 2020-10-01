import numpy
from generate import *


def generate():
    vectors = []

    vectors.append(TestVector(["radio.types.ComplexFloat32", 1], [], [numpy.array([complex(0, 0) for _ in range(256)]).astype(numpy.complex64)], "Data type ComplexFloat32, rate 1"))
    vectors.append(TestVector(["radio.types.Float32", 1], [], [numpy.array([0 for _ in range(256)]).astype(numpy.float32)], "Data type Float32, rate 1"))

    return BlockSpec("ZeroSource", vectors, 1e-6)
