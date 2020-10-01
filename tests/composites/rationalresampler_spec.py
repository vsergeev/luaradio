import numpy
import scipy.signal
from generate import *


def generate():
    def process(up_factor, down_factor, x):
        x_interp = numpy.array([type(x[0])()] * (len(x) * up_factor))
        for i in range(0, len(x)):
            x_interp[i * up_factor] = up_factor * x[i]
        b = scipy.signal.firwin(128, 1 / up_factor if (1 / up_factor < 1 / down_factor) else 1 / down_factor)
        x_interp = scipy.signal.lfilter(b, 1, x_interp).astype(type(x[0]))
        x_decim = numpy.array([x_interp[i] for i in range(0, len(x_interp), down_factor)])
        return [x_decim.astype(type(x[0]))]

    vectors = []

    x = random_complex64(32)
    vectors.append(TestVector([2, 3], [x], process(2, 3, x), "2 up, 3 down, 32 ComplexFloat32 input, 21 ComplexFloat32 output"))
    vectors.append(TestVector([7, 5], [x], process(7, 5, x), "7 up, 5 down, 32 ComplexFloat32 input, 44 ComplexFloat32 output"))

    x = random_float32(32)
    vectors.append(TestVector([2, 3], [x], process(2, 3, x), "2 up, 3 down, 32 Float32 input, 21 Float32 output"))
    vectors.append(TestVector([7, 5], [x], process(7, 5, x), "7 up, 5 down, 32 Float32 input, 44 Float32 output"))

    return BlockSpec("RationalResamplerBlock", vectors, 1e-6)
