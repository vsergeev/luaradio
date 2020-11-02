import math
import numpy
from generate import *


def generate():
    def process(symbol_rate, sample_rate, points, constellation, msb_first, x):
        symbol_period = int(sample_rate / symbol_rate)
        symbol_bits = int(math.log2(points))

        if constellation is None:
            scaling = math.sqrt(2 * (points - 1) / 3)
            i_bits = math.ceil(symbol_bits / 2)
            q_bits = symbol_bits - i_bits
            i_levels, q_levels = 2 ** i_bits, 2 ** q_bits

            constellation = {}

            for point in range(points):
                i_value = point >> q_bits
                q_value = point & (q_levels - 1)

                gray_point = ((i_value ^ (i_value >> 1)) << q_bits) | (q_value ^ (q_value >> 1))

                constellation[gray_point] = ((2 * i_value - i_levels + 1) + (2 * q_value - q_levels + 1) * 1j) / scaling

        out = []
        for i in range(0, (len(x) // symbol_bits) * symbol_bits, symbol_bits):
            bits = x[i:i + symbol_bits][::1 if msb_first else -1]
            value = sum([bits[j] << (symbol_bits - j - 1) for j in range(symbol_bits)])
            out += [constellation[value]] * symbol_period

        return [numpy.array(out).astype(numpy.complex64)]

    vectors = []

    # Symbol rate of 0.4 with sample rate of 2.0 means we have a symbol period of 5
    x = random_bit(256)
    vectors.append(TestVector([0.4, 2.0, 2], [x], process(0.4, 2.0, 2, None, True, x), "0.4 symbol rate, 2.0 sample rate, 256 Bit input, 2 points, 1280 ComplexFloat32 output"))
    vectors.append(TestVector([0.4, 2.0, 4], [x], process(0.4, 2.0, 4, None, True, x), "0.4 symbol rate, 2.0 sample rate, 256 Bit input, 4 points, 640 ComplexFloat32 output"))
    vectors.append(TestVector([0.4, 2.0, 8], [x], process(0.4, 2.0, 8, None, True, x), "0.4 symbol rate, 2.0 sample rate, 256 Bit input, 8 points, 425 ComplexFloat32 output"))
    vectors.append(TestVector([0.4, 2.0, 16], [x], process(0.4, 2.0, 16, None, True, x), "0.4 symbol rate, 2.0 sample rate, 256 Bit input, 8 points, 320 ComplexFloat32 output"))
    vectors.append(TestVector([0.4, 2.0, 4, "{constellation  = {[0] = radio.types.ComplexFloat32(-1, -1), [1] = radio.types.ComplexFloat32(-1, 1), [3] = radio.types.ComplexFloat32(1, -1), [2] = radio.types.ComplexFloat32(1, 1)}}"], [x], process(0.4, 2.0, 4, {0: -1 - 1j, 1: -1 + 1j, 3: 1 - 1j, 2: 1 + 1j}, True, x), "0.4 symbol rate, 2.0 sample rate, custom 4 points, 256 Bit input, 640 ComplexFloat32 output"))
    vectors.append(TestVector([0.4, 2.0, 8, "{msb_first = false}"], [x], process(0.4, 2.0, 8, None, False, x), "0.4 symbol rate, 2.0 sample rate, 8 points, lsb first, 256 Bit input, 425 ComplexFloat32 output"))

    return BlockSpec("QuadratureAmplitudeModulatorBlock", vectors, 1e-6)
