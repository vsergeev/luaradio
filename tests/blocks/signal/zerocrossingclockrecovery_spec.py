import numpy
from generate import *


def generate():
    x = numpy.array([-1, -1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1], dtype=numpy.float32)
    clock = numpy.array([-1, -1, -1, 1, -1, -1, -1, 1, -1, -1, -1, 1, -1, -1, -1, -1, 1, -1, -1, -1, 1, -1, -1, -1, -1, 1, -1, -1, -1, 1, -1], dtype=numpy.float32)

    # Baudrate of 0.4444 with sample rate of 2.0 means we have 4.5 samples per bit
    vectors = []
    vectors.append(TestVector([0.4444, 0.0], [x], [clock], "0.4444 baudrate, 0.0 threshold"))
    vectors.append(TestVector([0.4444, 1.0], [x + 1.0], [clock], "0.4444 baudrate, 1.0 threshold"))

    return BlockSpec("ZeroCrossingClockRecoveryBlock", vectors, 1e-6)
