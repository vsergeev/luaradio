import numpy
import scipy.signal
from generate import *


def generate():
    def process(tau, x):
        tau = 1/(2*2*numpy.tan(1/(2*2*tau)))
        b_taps = [(2*2*tau) / (1 + 2*2*tau), -(2*2*tau) / (1 + 2*2*tau)]
        a_taps = [1, (1 - 2*2*tau) / (1 + 2*2*tau)]
        return [scipy.signal.lfilter(b_taps, a_taps, x).astype(numpy.float32)]

    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([5e-6], [x], process(5e-6, x), "5e-6 tau, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([1e-6], [x], process(1e-6, x), "1e-6 tau, 256 Float32 input, 256 Float32 output"))

    return BlockSpec("FMPreemphasisFilterBlock", "tests/blocks/signal/fmpreemphasisfilter_spec.lua", vectors, 1e-6)
