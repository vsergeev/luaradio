import numpy
import scipy.signal
from generate import *


def generate():
    def process(num_taps, cutoff, window, nyquist, x):
        b = scipy.signal.firwin(num_taps, cutoff, window=window, nyq=nyquist)
        return [scipy.signal.lfilter(b, 1, x).astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([128, 0.2], [x], process(128, 0.2, "hamming", 1.0, x), "128 taps, 0.2 cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([128, 0.5], [x], process(128, 0.5, "hamming", 1.0, x), "128 taps, 0.5 cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([128, 0.7], [x], process(128, 0.7, "hamming", 1.0, x), "128 taps, 0.7 cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([128, 0.2, '"bartlett"', 3.0], [x], process(128, 0.2, "bartlett", 3.0, x), "128 taps, 0.2 cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([128, 0.5, '"bartlett"', 3.0], [x], process(128, 0.5, "bartlett", 3.0, x), "128 taps, 0.5 cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([128, 0.7, '"bartlett"', 3.0], [x], process(128, 0.7, "bartlett", 3.0, x), "128 taps, 0.7 cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([128, 0.2], [x], process(128, 0.2, "hamming", 1.0, x), "128 taps, 0.2 cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([128, 0.5], [x], process(128, 0.5, "hamming", 1.0, x), "128 taps, 0.5 cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([128, 0.7], [x], process(128, 0.7, "hamming", 1.0, x), "128 taps, 0.7 cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([128, 0.2, '"bartlett"', 3.0], [x], process(128, 0.2, "bartlett", 3.0, x), "128 taps, 0.2 cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([128, 0.5, '"bartlett"', 3.0], [x], process(128, 0.5, "bartlett", 3.0, x), "128 taps, 0.5 cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([128, 0.7, '"bartlett"', 3.0], [x], process(128, 0.7, "bartlett", 3.0, x), "128 taps, 0.7 cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 Float32 output"))

    return BlockSpec("LowpassFilterBlock", "tests/blocks/signal/lowpassfilter_spec.lua", vectors, 1e-6)
