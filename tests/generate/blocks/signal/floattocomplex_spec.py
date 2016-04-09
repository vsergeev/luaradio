import numpy
from generate import *


def generate():
    def process(real, imag):
        return [numpy.array([complex(*e) for e in zip(real, imag)]).astype(numpy.complex64)]

    vectors = []

    real, imag = random_float32(256), random_float32(256)
    vectors.append(TestVector([], [real, imag], process(real, imag), "2 256 Float32 inputs, 256 ComplexFloat32 output"))

    return BlockSpec("FloatToComplexBlock", "tests/blocks/signal/floattocomplex_spec.lua", vectors, 1e-6)
