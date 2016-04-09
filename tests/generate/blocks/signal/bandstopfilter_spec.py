import numpy
import scipy.signal
from generate import *


def generate():
    def process(num_taps, cutoffs, window, nyquist, x):
        b = scipy.signal.firwin(num_taps, cutoffs, pass_zero=True, window=window, nyq=nyquist)
        return [scipy.signal.lfilter(b, 1, x).astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([129, [0.1, 0.3]], [x], process(129, [0.1, 0.3], "hamming", 1.0, x), "129 taps, {0.1, 0.3} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.4, 0.6]], [x], process(129, [0.4, 0.6], "hamming", 1.0, x), "129 taps, {0.4, 0.6} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.1, 0.3], '"bartlett"', 3.0], [x], process(129, [0.1, 0.3], "bartlett", 3.0, x), "129 taps, {0.1, 0.3} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.4, 0.6], '"bartlett"', 3.0], [x], process(129, [0.4, 0.6], "bartlett", 3.0, x), "129 taps, {0.4, 0.6} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([129, [0.1, 0.3]], [x], process(129, [0.1, 0.3], "hamming", 1.0, x), "129 taps, {0.1, 0.3} cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([129, [0.4, 0.6]], [x], process(129, [0.4, 0.6], "hamming", 1.0, x), "129 taps, {0.4, 0.6} cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([129, [0.1, 0.3], '"bartlett"', 3.0], [x], process(129, [0.1, 0.3], "bartlett", 3.0, x), "129 taps, {0.1, 0.3} cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.4, 0.6], '"bartlett"', 3.0], [x], process(129, [0.4, 0.6], "bartlett", 3.0, x), "129 taps, {0.4, 0.6} cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 ComplexFloat32 output"))

    return BlockSpec("BandstopFilterBlock", "tests/blocks/signal/bandstopfilter_spec.lua", vectors, 1e-6)
