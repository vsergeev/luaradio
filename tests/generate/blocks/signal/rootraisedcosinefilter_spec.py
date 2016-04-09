import numpy
import scipy.signal
from generate import *


def fir_root_raised_cosine(num_taps, sample_rate, beta, symbol_period):
    h = []

    assert (num_taps % 2) == 1, "Number of taps must be odd."

    for i in range(num_taps):
        t = (i - (num_taps - 1) / 2) / sample_rate

        if t == 0:
            h.append((1 / (numpy.sqrt(symbol_period))) * (1 - beta + 4 * beta / numpy.pi))
        elif numpy.isclose(t, -symbol_period / (4 * beta)) or numpy.isclose(t, symbol_period / (4 * beta)):
            h.append((beta / numpy.sqrt(2 * symbol_period)) * ((1 + 2 / numpy.pi) * numpy.sin(numpy.pi / (4 * beta)) + (1 - 2 / numpy.pi) * numpy.cos(numpy.pi / (4 * beta))))
        else:
            num = numpy.cos((1 + beta) * numpy.pi * t / symbol_period) + numpy.sin((1 - beta) * numpy.pi * t / symbol_period) / (4 * beta * t / symbol_period)
            denom = (1 - (4 * beta * t / symbol_period) * (4 * beta * t / symbol_period))
            h.append(((4 * beta) / (numpy.pi * numpy.sqrt(symbol_period))) * num / denom)

    h = numpy.array(h) / numpy.sum(h)

    return h.astype(numpy.float32)


def generate():
    def process(num_taps, beta, symbol_rate, x):
        b = fir_root_raised_cosine(num_taps, 2.0, beta, 1 / symbol_rate)
        return [scipy.signal.lfilter(b, 1, x).astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([101, 0.5, 1e-3], [x], process(101, 0.5, 1e-3, x), "101 taps, 0.5 beta, 1e-3 symbol rate, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([101, 0.7, 1e-3], [x], process(101, 0.7, 1e-3, x), "101 taps, 0.7 beta, 1e-3 symbol rate, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([101, 1.0, 5e-3], [x], process(101, 1.0, 5e-3, x), "101 taps, 1.0 beta, 5e-3 symbol rate, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([101, 0.5, 1e-3], [x], process(101, 0.5, 1e-3, x), "101 taps, 0.5 beta, 1e-3 symbol rate, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([101, 0.7, 1e-3], [x], process(101, 0.7, 1e-3, x), "101 taps, 0.7 beta, 1e-3 symbol rate, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([101, 1.0, 5e-3], [x], process(101, 1.0, 5e-3, x), "101 taps, 1.0 beta, 5e-3 symbol rate, 256 Float32 input, 256 Float32 output"))

    return BlockSpec("RootRaisedCosineFilterBlock", "tests/blocks/signal/rootraisedcosinefilter_spec.lua", vectors, 1e-6)
