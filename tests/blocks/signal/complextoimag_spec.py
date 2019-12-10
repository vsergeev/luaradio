import numpy
from generate import *


def generate():
    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([], [x], [numpy.imag(x)], "256 ComplexFloat32 input, 256 Float32 output"))

    return BlockSpec("ComplexToImagBlock", vectors, 1e-6)
