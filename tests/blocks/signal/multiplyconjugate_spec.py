import numpy
from generate import *


def generate():
    vectors = []

    x, y = random_complex64(256), random_complex64(256)
    vectors.append(TestVector([], [x, y], [x * numpy.conj(y)], "2 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))

    return BlockSpec("MultiplyConjugateBlock", vectors, 1e-6)
