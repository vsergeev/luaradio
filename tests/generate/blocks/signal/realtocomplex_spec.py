import numpy
from generate import *


def generate():
    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([], [x], [x.astype(numpy.complex64)], "256 Float32 input, 256 ComplexFloat32 output"))

    return BlockSpec("RealToComplexBlock", vectors, 1e-6)
