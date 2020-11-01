import math
import numpy
from generate import *


def generate():
    def process(symbol_rate, sample_rate, levels, amplitudes, msb_first, x):
        symbol_period = int(sample_rate / symbol_rate)
        symbol_bits = int(math.log2(levels))

        if amplitudes is None:
            scaling = math.sqrt((levels ** 2 - 1) / 3)
            amplitudes = {}
            for level in range(levels):
                gray_level = level ^ (level >> 1)
                amplitudes[gray_level] = (2 * level - levels + 1) / scaling

        out = []
        for i in range(0, (len(x) // symbol_bits) * symbol_bits, symbol_bits):
            bits = x[i:i + symbol_bits][::1 if msb_first else -1]
            value = sum([bits[j] << (symbol_bits - j - 1) for j in range(symbol_bits)])
            out += [amplitudes[value]] * symbol_period

        return [numpy.array(out).astype(numpy.float32)]

    vectors = []

    # Symbol rate of 0.4 with sample rate of 2.0 means we have a symbol period of 5
    x = random_bit(256)
    vectors.append(TestVector([0.4, 2.0, 2], [x], process(0.4, 2.0, 2, None, True, x), "0.4 symbol rate, 2.0 sample rate, 256 Bit input, 2 levels, 1280 Float32 output"))
    vectors.append(TestVector([0.4, 2.0, 4], [x], process(0.4, 2.0, 4, None, True, x), "0.4 symbol rate, 2.0 sample rate, 256 Bit input, 4 levels, 640 Float32 output"))
    vectors.append(TestVector([0.4, 2.0, 8], [x], process(0.4, 2.0, 8, None, True, x), "0.4 symbol rate, 2.0 sample rate, 256 Bit input, 8 levels, 425 Float32 output"))
    vectors.append(TestVector([0.4, 2.0, 4, "{amplitudes = {[0] = -2, [1] = -1, [3] = 1, [2] = 2}}"], [x], process(0.4, 2.0, 4, {0: -2, 1: -1, 3: 1, 2: 2}, True, x), "0.4 symbol rate, 2.0 sample rate, custom 4 level amplitudes, 256 Bit input, 640 Float32 output"))
    vectors.append(TestVector([0.4, 2.0, 8, "{msb_first = false}"], [x], process(0.4, 2.0, 8, None, False, x), "0.4 symbol rate, 2.0 sample rate, 8 levels, lsb first, 256 Bit input, 425 Float32 output"))

    return BlockSpec("PulseAmplitudeModulatorBlock", vectors, 1e-6)
