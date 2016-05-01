import numpy
import scipy.signal
from generate import *


def generate():
    def process(taps, x):
        data_type = numpy.complex64 if isinstance(taps[0], numpy.complex64) or isinstance(x[0], numpy.complex64) else numpy.float32
        return [scipy.signal.lfilter(taps, 1, x).astype(data_type)]

    def normalize(v):
        return v / numpy.sum(numpy.abs(v))

    vectors = []

    x = random_complex64(256)
    taps = normalize(random_float32(1))
    vectors.append(TestVector([taps], [x], process(taps, x), "1 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_float32(8))
    vectors.append(TestVector([taps], [x], process(taps, x), "8 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_float32(15))
    vectors.append(TestVector([taps], [x], process(taps, x), "15 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_float32(128))
    vectors.append(TestVector([taps], [x], process(taps, x), "128 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    taps = normalize(random_float32(1))
    vectors.append(TestVector([taps], [x], process(taps, x), "1 Float32 tap, 256 Float32 input, 256 Float32 output"))
    taps = normalize(random_float32(8))
    vectors.append(TestVector([taps], [x], process(taps, x), "8 Float32 tap, 256 Float32 input, 256 Float32 output"))
    taps = normalize(random_float32(15))
    vectors.append(TestVector([taps], [x], process(taps, x), "15 Float32 tap, 256 Float32 input, 256 Float32 output"))
    taps = normalize(random_float32(128))
    vectors.append(TestVector([taps], [x], process(taps, x), "128 Float32 tap, 256 Float32 input, 256 Float32 output"))

    x = random_complex64(256)
    taps = normalize(random_complex64(1))
    vectors.append(TestVector([taps], [x], process(taps, x), "1 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_complex64(8))
    vectors.append(TestVector([taps], [x], process(taps, x), "8 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_complex64(15))
    vectors.append(TestVector([taps], [x], process(taps, x), "15 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_complex64(128))
    vectors.append(TestVector([taps], [x], process(taps, x), "128 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    return BlockSpec("FIRFilterBlock", "tests/blocks/signal/firfilter_spec.lua", vectors, 1e-6)
