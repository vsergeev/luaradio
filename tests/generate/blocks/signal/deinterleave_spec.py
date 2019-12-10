import numpy
from generate import *


def generate():
    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([2], [x], [x[0::2], x[1::2]], "Deinterleave 2 channels, Float32 input"))
    vectors.append(TestVector([3], [x], [x[0::3], x[1::3], x[2::3]], "Deinterleave 3 channels, Float32 input"))

    x = random_complex64(256)
    vectors.append(TestVector([2], [x], [x[0::2], x[1::2]], "Deinterleave 2 channels, ComplexFloat32 input"))
    vectors.append(TestVector([3], [x], [x[0::3], x[1::3], x[2::3]], "Deinterleave 3 channels, ComplexFloat32 input"))

    return BlockSpec("DeinterleaveBlock", vectors, 1e-6)
