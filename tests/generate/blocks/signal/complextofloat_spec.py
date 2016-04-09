import numpy
from generate import *


def generate():
    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([], [x], [numpy.real(x), numpy.imag(x)], "256 ComplexFloat32 input, 2 256 Float32 outputs"))

    return BlockSpec("ComplexToFloatBlock", "tests/blocks/signal/complextofloat_spec.lua", vectors, 1e-6)
