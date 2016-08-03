import numpy
from generate import *


def generate():
    vectors = []

    x, y, z = random_float32(32), random_float32(32), random_float32(32)
    vectors.append(TestVector([2], [x, y], [numpy.ravel(numpy.column_stack((x, y)))], "Interleave 2 channels, Float32 input"))
    vectors.append(TestVector([3], [x, y, z], [numpy.ravel(numpy.column_stack((x, y, z)))], "Interleave 3 channels, Float32 input"))

    x, y, z = random_complex64(32), random_complex64(32), random_complex64(32)
    vectors.append(TestVector([2], [x, y], [numpy.ravel(numpy.column_stack((x, y)))], "Interleave 2 channels, ComplexFloat32 input"))
    vectors.append(TestVector([3], [x, y, z], [numpy.ravel(numpy.column_stack((x, y, z)))], "Interleave 3 channels, ComplexFloat32 input"))

    return BlockSpec("InterleaveBlock", "tests/blocks/signal/interleave_spec.lua", vectors, 1e-6)
