import numpy
from generate import *


def generate():
    def process(invert, x):
        return [numpy.logical_xor(numpy.logical_xor(numpy.insert(x, 0, False)[:-1], x), invert)]

    vectors = []

    x = random_bit(256)
    vectors.append(TestVector([False], [x], process(False, x), "Non-inverted output, 256 Bit input, 256 Bit output"))
    vectors.append(TestVector([True], [x], process(True, x), "Inverted output, 256 Bit input, 256 Bit output"))

    return BlockSpec("DifferentialDecoderBlock", vectors, 1e-6)
