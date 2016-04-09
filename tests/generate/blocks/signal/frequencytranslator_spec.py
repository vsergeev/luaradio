import numpy
from generate import *


def generate():
    def process(offset, x):
        rotator = numpy.exp(1j * 2 * numpy.pi * (offset / 2.0) * numpy.arange(len(x))).astype(numpy.complex64)
        return [x * rotator]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([0.2], [x], process(0.2, x), "0.2 offset, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([0.5], [x], process(0.5, x), "0.5 offset, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([0.7], [x], process(0.7, x), "0.7 offset, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    # FIXME why does this need 1e-5 epsilon?
    return BlockSpec("FrequencyTranslatorBlock", "tests/blocks/signal/frequencytranslator_spec.lua", vectors, 1e-5)
