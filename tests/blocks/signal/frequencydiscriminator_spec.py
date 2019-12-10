import numpy
from generate import *


def generate():
    def process(k, x):
        x_shifted = numpy.insert(x, 0, numpy.complex64())[:len(x)]
        tmp = x * numpy.conj(x_shifted)
        return [(numpy.arctan2(numpy.imag(tmp), numpy.real(tmp)) / (2*numpy.pi*k)).astype(numpy.float32)]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([1.0], [x], process(1.0, x), "1.0 Modulation Index, 256 ComplexFloat32 input, 256 Float32 output"))
    vectors.append(TestVector([5.0], [x], process(5.0, x), "5.0 Modulation Index, 256 ComplexFloat32 input, 256 Float32 output"))
    vectors.append(TestVector([10.0], [x], process(10.0, x), "10.0 Modulation Index, 256 ComplexFloat32 input, 256 Float32 output"))

    return BlockSpec("FrequencyDiscriminatorBlock", vectors, 1e-6)
