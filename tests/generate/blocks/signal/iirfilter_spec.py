import numpy
import scipy.signal
from generate import *


def generate():
    def gentaps(n):
        b, a = scipy.signal.butter(n - 1, 0.5)
        return b.astype(numpy.float32), a.astype(numpy.float32)

    def process(b_taps, a_taps, x):
        return [scipy.signal.lfilter(b_taps, a_taps, x).astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    b_taps, a_taps = gentaps(3)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "3 Float32 b taps, 3 Float32 a taps, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    b_taps, a_taps = gentaps(5)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "5 Float32 b taps, 5 Float32 a taps, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    b_taps, a_taps = gentaps(10)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "10 Float32 b taps, 10 Float32 a taps, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    b_taps, a_taps = gentaps(3)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "3 Float32 b taps, 3 Float32 a taps, 256 Float32 input, 256 Float32 output"))
    b_taps, a_taps = gentaps(5)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "5 Float32 b taps, 5 Float32 a taps, 256 Float32 input, 256 Float32 output"))
    b_taps, a_taps = gentaps(10)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "10 Float32 b taps, 10 Float32 a taps, 256 Float32 input, 256 Float32 output"))

    return BlockSpec("IIRFilterBlock", "tests/blocks/signal/iirfilter_spec.lua", vectors, 1e-6)
