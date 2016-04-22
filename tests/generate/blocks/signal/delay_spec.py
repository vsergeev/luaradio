import numpy
from generate import *


def generate():
    def process(n, x):
        return [numpy.insert(x, 0, [type(x[0])()] * n)[:len(x)]]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Sample Delay, 256 ComplexFloat32 input, 257 ComplexFloat32 output"))
    vectors.append(TestVector([15], [x], process(15, x), "15 Sample Delay, 256 ComplexFloat32 input, 271 ComplexFloat32 output"))
    vectors.append(TestVector([100], [x], process(100, x), "100 Sample Delay, 256 ComplexFloat32 input, 356 ComplexFloat32 output"))
    vectors.append(TestVector([307], [x], process(307, x), "307 Sample Delay, 256 ComplexFloat32 input, 563 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Sample Delay, 256 Float32 input, 257 Float32 output"))
    vectors.append(TestVector([15], [x], process(15, x), "15 Sample Delay, 256 Float32 input, 271 Float32 output"))
    vectors.append(TestVector([100], [x], process(100, x), "100 Sample Delay, 256 Float32 input, 356 Float32 output"))
    vectors.append(TestVector([307], [x], process(307, x), "307 Sample Delay, 256 Float32 input, 563 Float32 output"))

    return BlockSpec("DelayBlock", "tests/blocks/signal/delay_spec.lua", vectors, 1e-6)
