import numpy
import scipy.signal
from generate import *


def generate():
    def process(factor, x):
        x_interp = numpy.array([type(x[0])()] * (len(x) * factor))
        for i in range(0, len(x)):
            x_interp[i * factor] = factor * x[i]
        b = scipy.signal.firwin(128, 1 / factor)
        return [scipy.signal.lfilter(b, 1, x_interp).astype(type(x[0]))]

    vectors = []

    x = random_complex64(32)
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 32 ComplexFloat32 input, 64 ComplexFloat32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 32 ComplexFloat32 input, 96 ComplexFloat32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 32 ComplexFloat32 input, 128 ComplexFloat32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 32 ComplexFloat32 input, 224 ComplexFloat32 output"))

    x = random_float32(32)
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 32 Float32 input, 64 Float32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 32 Float32 input, 96 Float32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 32 Float32 input, 128 Float32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 32 Float32 input, 224 Float32 output"))

    return BlockSpec("InterpolatorBlock", vectors, 1e-6)
