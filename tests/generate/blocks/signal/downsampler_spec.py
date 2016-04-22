import numpy
from generate import *


def generate():
    def process(factor, x):
        out = []
        for i in range(0, len(x), factor):
            out.append(x[i])
        return [numpy.array(out)]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Factor, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 ComplexFloat32 input, 128 ComplexFloat32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 ComplexFloat32 input, 85 ComplexFloat32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 ComplexFloat32 input, 64 ComplexFloat32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 ComplexFloat32 input, 36 ComplexFloat32 output"))
    vectors.append(TestVector([16], [x], process(16, x), "16 Factor, 256 ComplexFloat32 input, 16 ComplexFloat32 output"))
    vectors.append(TestVector([128], [x], process(128, x), "128 Factor, 256 ComplexFloat32 input, 2 ComplexFloat32 output"))
    vectors.append(TestVector([200], [x], process(200, x), "200 Factor, 256 ComplexFloat32 input, 1 ComplexFloat32 output"))
    vectors.append(TestVector([256], [x], process(256, x), "256 Factor, 256 ComplexFloat32 input, 1 ComplexFloat32 output"))
    vectors.append(TestVector([257], [x], process(257, x), "256 Factor, 256 ComplexFloat32 input, 0 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Factor, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 Float32 input, 128 Float32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 Float32 input, 85 Float32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 Float32 input, 64 Float32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 Float32 input, 36 Float32 output"))
    vectors.append(TestVector([16], [x], process(16, x), "16 Factor, 256 Float32 input, 16 Float32 output"))
    vectors.append(TestVector([128], [x], process(128, x), "128 Factor, 256 Float32 input, 2 Float32 output"))
    vectors.append(TestVector([200], [x], process(200, x), "200 Factor, 256 Float32 input, 1 Float32 output"))
    vectors.append(TestVector([256], [x], process(256, x), "256 Factor, 256 Float32 input, 1 Float32 output"))
    vectors.append(TestVector([257], [x], process(257, x), "256 Factor, 256 Float32 input, 0 Float32 output"))

    return BlockSpec("DownsamplerBlock", "tests/blocks/signal/downsampler_spec.lua", vectors, 1e-6)
