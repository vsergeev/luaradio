import numpy
import scipy.signal
from generate import *


def fir_hilbert_transform(num_taps, window_func):
    h = []

    assert (num_taps % 2) == 1, "Number of taps must be odd."

    for i in range(num_taps):
        i_shifted = (i - (num_taps - 1) / 2)
        h.append(0 if (i_shifted % 2) == 0 else 2 / (i_shifted * numpy.pi))

    h = h * window_func(num_taps)

    return h.astype(numpy.float32)


def generate():
    def process(num_taps, x):
        delay = int((num_taps - 1) / 2)
        h = fir_hilbert_transform(num_taps, scipy.signal.hamming)

        imag = scipy.signal.lfilter(h, 1, x).astype(numpy.float32)
        real = numpy.insert(x, 0, [numpy.float32()] * delay)[:len(x)]
        return [numpy.array([complex(*e) for e in zip(real, imag)]).astype(numpy.complex64)]

    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([9], [x], process(9, x), "9 taps, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([65], [x], process(65, x), "65 taps, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129], [x], process(129, x), "129 taps, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([257], [x], process(257, x), "257 taps, 256 Float32 input, 256 ComplexFloat32 output"))

    return BlockSpec("HilbertTransformBlock", "tests/blocks/signal/hilberttransform_spec.lua", vectors, 1e-6)
