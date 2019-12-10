import numpy
from generate import *


def generate():
    def manchester_encode(x):
        out = numpy.array([], dtype=numpy.bool_)

        for b in x:
            if b:
                out = numpy.append(out, [True, False])
            else:
                out = numpy.append(out, [False, True])

        return out

    vectors = []

    x = random_bit(256)
    encoded_x = manchester_encode(x)
    vectors.append(TestVector([False], [encoded_x], [x], "Non-inverted output, 512 Bit input, 256 Bit output"))
    vectors.append(TestVector([True], [encoded_x], [numpy.invert(x)], "Inverted output, 512 Bit input, 256 Bit output"))

    slipped_x = numpy.append([encoded_x[0]], encoded_x)
    vectors.append(TestVector([False], [slipped_x], [x], "Non-inverted output with invalid first bit, 513 Bit input, 256 Bit output"))
    vectors.append(TestVector([True], [slipped_x], [numpy.invert(x)], "Inverted output with invalid first bit, 513 Bit input, 256 Bit output"))

    return BlockSpec("ManchesterDecoderBlock", vectors, 1e-6)
