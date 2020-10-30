import numpy
import scipy.signal
from generate import *


def fir_pulse_matched_filter(baudrate, sample_rate, invert):
    symbol_period = int(sample_rate / baudrate)

    h = numpy.array([-1 if invert else 1] * symbol_period)

    return h.astype(numpy.float32)


def generate():
    def process(baudrate, invert, x):
        b = fir_pulse_matched_filter(baudrate, 2.0, invert)
        return [scipy.signal.lfilter(b, 1, x).astype(type(x[0]))]

    vectors = []

    # Baudrate of 0.2 with sample rate of 2.0 means we have a symbol period of 10
    x = random_float32(256)
    vectors.append(TestVector([0.2, False], [x], process(0.2, False, x), "0.1 baudrate, invert false, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([0.2, True], [x], process(0.2, True, x), "0.1 baudrate, invert true, 256 Float32 input, 256 Float32 output"))

    return BlockSpec("PulseMatchedFilterBlock", vectors, 1e-6)
