import numpy
from generate import *


def generate():
    def process(n, x):
        elem_type = type(x[0])
        return [numpy.insert(x, 0, [elem_type()] * n)[:len(x)]]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Sample Delay, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([15], [x], process(15, x), "1 Sample Delay, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([100], [x], process(100, x), "1 Sample Delay, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Sample Delay, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([15], [x], process(15, x), "1 Sample Delay, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([100], [x], process(100, x), "1 Sample Delay, 256 Float32 input, 256 Float32 output"))

    x = random_integer32(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Sample Delay, 256 Integer32 input, 256 Integer32 output"))
    vectors.append(TestVector([15], [x], process(15, x), "1 Sample Delay, 256 Integer32 input, 256 Integer32 output"))
    vectors.append(TestVector([100], [x], process(100, x), "1 Sample Delay, 256 Integer32 input, 256 Integer32 output"))

    return BlockSpec("DelayBlock", "tests/blocks/signal/delay_spec.lua", vectors, 1e-6)
