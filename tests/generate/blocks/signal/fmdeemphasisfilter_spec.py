import numpy
import scipy.signal
from generate import *


def generate():
    def process(tau, x):
        b_taps = [1 / (1 + 4 * tau), 1 / (1 + 4 * tau)]
        a_taps = [1, (1 - 4 * tau) / (1 + 4 * tau)]
        return [scipy.signal.lfilter(b_taps, a_taps, x).astype(numpy.float32)]

    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([75e-6], [x], process(75e-6, x), "75e-6 tau, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([50e-6], [x], process(50e-6, x), "50e-6 tau, 256 Float32 input, 256 Float32 output"))

    return BlockSpec("FMDeemphasisFilterBlock", "tests/blocks/signal/fmdeemphasisfilter_spec.lua", vectors, 1e-6)
