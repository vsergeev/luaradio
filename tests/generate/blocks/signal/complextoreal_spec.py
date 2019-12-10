import numpy
from generate import *


def generate():
    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([], [x], [numpy.real(x)], "256 ComplexFloat32 input, 256 Float32 output"))

    return BlockSpec("ComplexToRealBlock", vectors, 1e-6)
