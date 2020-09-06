import numpy
from generate import *


def generate():
    def modulate(sample_rate, baudrate, bits):
        symbol_period = int(sample_rate / baudrate)
        assert(symbol_period % 2 == 1)

        samples = []
        for b in bits:
            pulse = numpy.interp(range(symbol_period), [0, symbol_period // 2, symbol_period - 1], [0, 1 if b else -1, 0])
            samples = numpy.hstack((samples, pulse))

        return samples.astype(numpy.float32)

    vectors = []

    # Baudrate of 0.4 with sample rate of 2.0 means we have a symbol period of 5
    preamble, data = random_bit(16), random_bit(32)
    waveform = modulate(2.0, 0.4, numpy.hstack((preamble, data)))

    x = numpy.hstack((random_float32(32), waveform, random_float32(128)))
    y = numpy.sign(numpy.hstack((preamble, data)) - 0.5).astype(numpy.float32)
    vectors.append(TestVector([0.4, preamble, 48], [x], [y], "0.4 baudrate, 16 bits preamble, 32 bits data, 368 Float32 input, 48 Float32 output"))

    return BlockSpec("PreambleSamplerBlock", vectors, 1e-6)
