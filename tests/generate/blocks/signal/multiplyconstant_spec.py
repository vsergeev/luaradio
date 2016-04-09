import numpy
from generate import *


def generate():
    def process(constant, x):
        return [x * constant]

    vectors = []

    x = random_complex64(256)
    # ComplexFloat32 vector times number constant
    vectors.append(TestVector([2.5], [x], process(2.5, x), "Number constant, 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))
    # ComplexFloat32 vector times float32 constant
    vectors.append(TestVector([numpy.float32(3.5)], [x], process(numpy.float32(3.5), x), "Float32 constant, 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))
    # ComplexFloat32 vector times ComplexFloat32 constant
    vectors.append(TestVector([numpy.complex64(complex(1, 2))], [x], process(numpy.complex64(complex(1, 2)), x), "ComplexFloat32 constant, 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))

    x = random_float32(256)
    # Float32 vector times number constant
    vectors.append(TestVector([2.5], [x], process(2.5, x), "Number constant, 256 Float32 inputs, 256 Float32 output"))
    # Float32 vector times Float32 constant
    vectors.append(TestVector([numpy.float32(3.5)], [x], process(numpy.float32(3.5), x), "Float32 constant, 256 Float32 inputs, 256 Float32 output"))

    return BlockSpec("MultiplyConstantBlock", "tests/blocks/signal/multiplyconstant_spec.lua", vectors, 1e-6)
