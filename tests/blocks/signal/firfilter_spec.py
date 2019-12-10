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
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 1 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([taps, True], [x], process(taps, x), "FFT, 1 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_float32(8))
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 8 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([taps, True], [x], [process(taps, x)[0][0:228]], "FFT, 8 Float32 tap, 256 ComplexFloat32 input, 228 ComplexFloat32 output"))
    taps = normalize(random_float32(15))
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 15 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([taps, True], [x], [process(taps, x)[0][0:250]], "FFT, 15 Float32 tap, 256 ComplexFloat32 input, 250 ComplexFloat32 output"))
    taps = normalize(random_float32(32))
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 32 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([taps, True], [x], [process(taps, x)[0][0:225]], "FFT, 32 Float32 tap, 256 ComplexFloat32 input, 225 ComplexFloat32 output"))

    x = random_float32(256)
    taps = normalize(random_float32(1))
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 1 Float32 tap, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([taps, True], [x], process(taps, x), "FFT, 1 Float32 tap, 256 Float32 input, 256 Float32 output"))
    taps = normalize(random_float32(8))
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 8 Float32 tap, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([taps, True], [x], [process(taps, x)[0][0:228]], "FFT, 8 Float32 tap, 256 Float32 input, 228 Float32 output"))
    taps = normalize(random_float32(15))
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 15 Float32 tap, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([taps, True], [x], [process(taps, x)[0][0:250]], "FFT, 15 Float32 tap, 256 Float32 input, 250 Float32 output"))
    taps = normalize(random_float32(32))
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 32 Float32 tap, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([taps, True], [x], [process(taps, x)[0][0:225]], "FFT, 32 Float32 tap, 256 Float32 input, 225 Float32 output"))

    x = random_complex64(256)
    taps = normalize(random_complex64(1))
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 1 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([taps, True], [x], process(taps, x), "FFT, 1 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_complex64(8))
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 8 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([taps, True], [x], [process(taps, x)[0][0:228]], "FFT, 8 ComplexFloat32 tap, 256 ComplexFloat32 input, 228 ComplexFloat32 output"))
    taps = normalize(random_complex64(15))
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 15 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([taps, True], [x], [process(taps, x)[0][0:250]], "FFT, 15 ComplexFloat32 tap, 256 ComplexFloat32 input, 250 ComplexFloat32 output"))
    taps = normalize(random_complex64(32))
    vectors.append(TestVector([taps, False], [x], process(taps, x), "Dot product, 64 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([taps, True], [x], [process(taps, x)[0][0:225]], "FFT, 64 ComplexFloat32 tap, 256 ComplexFloat32 input, 225 ComplexFloat32 output"))

    return BlockSpec("FIRFilterBlock", vectors, 1e-6)
