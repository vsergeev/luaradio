import numpy
from generate import *


def generate():
    def process(factor, x):
        out = [type(x[0])()] * (len(x) * factor)
        for i in range(0, len(x)):
            out[i * factor] = x[i]
        return [numpy.array(out)]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Factor, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 ComplexFloat32 input, 512 ComplexFloat32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 ComplexFloat32 input, 768 ComplexFloat32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 ComplexFloat32 input, 1024 ComplexFloat32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 ComplexFloat32 input, 1792 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Factor, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 Float32 input, 512 Float32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 Float32 input, 768 Float32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 Float32 input, 1024 Float32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 Float32 input, 1792 Float32 output"))

    return BlockSpec("UpsamplerBlock", vectors, 1e-6)
