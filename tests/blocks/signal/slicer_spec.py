import numpy
from generate import *


def generate():
    def process(threshold, x):
        return [x > threshold]

    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([0.00], [x], process(0.00, x), "Default threshold, 256 Float32 input, 256 Bit output"))
    vectors.append(TestVector([0.25], [x], process(0.25, x), "0.25 threshold, 256 Float32 input, 256 Bit output"))
    vectors.append(TestVector([-0.25], [x], process(-0.25, x), "-0.25 threshold, 256 Float32 input, 256 Bit output"))

    return BlockSpec("SlicerBlock", vectors, 1e-6)
