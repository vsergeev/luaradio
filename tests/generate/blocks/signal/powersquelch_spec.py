import numpy
from generate import *


def generate():
    vectors = []

    # Cosine with 100 Hz frequency, 1000 Hz sample rate, 0.01 amplitude
    # Average power in dBFS = 10*log10(0.01^2 * 0.5) = -43 dBFS
    x = 0.01*numpy.cos(2*numpy.pi*(100/1000)*numpy.arange(256)).astype(numpy.float32)
    vectors.append(TestVector([-30], [x], [numpy.array([0.0]*len(x), dtype=numpy.float32)], "-43 dBFS cosine input, -30 dBFS squelch"))
    vectors.append(TestVector([-55], [x], [x], "-43 dBFS cosine input, -55 dBFS squelch"))

    # Complex exponential with 100 Hz frequency, 1000 Hz sample rate, 0.01 amplitude
    # Average power in dBFS = 10*log10(0.01^2 * 1.0) = -40 dBFS
    x = 0.01*numpy.exp(2*numpy.pi*1j*(100/1000)*numpy.arange(256)).astype(numpy.complex64)
    vectors.append(TestVector([-30], [x], [numpy.array([0.0]*len(x), dtype=numpy.complex64)], "-40 dBFS complex exponential input, -30 dBFS squelch"))
    vectors.append(TestVector([-50], [x], [x], "-40 dBFS complex exponential input, -50 dBFS squelch"))

    return BlockSpec("PowerSquelchBlock", "tests/blocks/signal/powersquelch_spec.lua", vectors, 1e-6)
