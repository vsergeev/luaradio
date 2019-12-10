import numpy
from generate import *


def generate():
    vectors = []

    message1_bits = numpy.array([0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0], dtype=numpy.bool_)
    message1 = numpy.array(bytearray("Hello World".encode()))

    message2_bits = numpy.array([0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0], dtype=numpy.bool_)
    message2 = numpy.array(bytearray("Hello World".encode()))

    message3_bits = numpy.array([0]*40, dtype=numpy.bool_)
    message3 = numpy.array([], dtype=numpy.uint8)

    vectors.append(TestVector([], [message1_bits], [message1], "Valid message"))
    vectors.append(TestVector([], [message2_bits], [message2], "Valid message with extra leading 0 bit"))
    vectors.append(TestVector([], [message3_bits], [message3], "Empty message"))

    return BlockSpec("VaricodeDecoderBlock", vectors, 1e-6)
