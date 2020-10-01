import numpy
import scipy.signal
from generate import *


def generate():
    def process(factor, x):
        out = scipy.signal.decimate(x, factor, n=128 - 1, ftype='fir', zero_phase=False)
        return [out.astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 ComplexFloat32 input, 128 ComplexFloat32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 ComplexFloat32 input, 85 ComplexFloat32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 ComplexFloat32 input, 64 ComplexFloat32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 ComplexFloat32 input, 36 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 Float32 input, 128 Float32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 Float32 input, 85 Float32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 Float32 input, 64 Float32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 Float32 input, 36 Float32 output"))

    return BlockSpec("DecimatorBlock", vectors, 1e-6)
