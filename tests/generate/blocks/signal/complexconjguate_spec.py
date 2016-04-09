import numpy
from generate import *


def generate():
    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([], [x], [numpy.conj(x)], "256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    return BlockSpec("ComplexConjugateBlock", "tests/blocks/signal/complexconjugate_spec.lua", vectors, 1e-6)
