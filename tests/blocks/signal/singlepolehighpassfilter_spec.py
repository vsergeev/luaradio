import numpy
import scipy.signal
from generate import *


def generate():
    def process(fc, x):
        tau = 1/(2*numpy.pi*fc)
        tau = 1/(2*2*numpy.tan(1/(2*2*tau)))
        b_taps = [(2*2*tau) / (1 + 2*2*tau), -(2*2*tau) / (1 + 2*2*tau)]
        a_taps = [1, (1 - 2*2*tau) / (1 + 2*2*tau)]
        return [scipy.signal.lfilter(b_taps, a_taps, x).astype(type(x[0]))]

    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([1e-2], [x], process(1e-2, x), "1e-2 cutoff, 256 Float32 input, 256 Float32 output"))

    x = random_complex64(256)
    vectors.append(TestVector([1e-2], [x], process(1e-2, x), "1e-2 cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    return BlockSpec("SinglepoleHighpassFilterBlock", vectors, 1e-6)
