import numpy
from generate import *


def generate():
    def process(k, x):
        return [numpy.exp(1j * 2 * numpy.pi * k * numpy.cumsum(x)).astype(numpy.complex64)]

    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([0.10], [x], process(0.10, x), "0.15 Modulation Index, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([0.25], [x], process(0.25, x), "0.25 Modulation Index, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([0.50], [x], process(0.50, x), "0.50 Modulation Index, 256 Float32 input, 256 ComplexFloat32 output"))

    # FIXME liquid-dsp implementation has less precision (5e-3)
    # FIXME why does this need 5e-5 epsilon?
    return BlockSpec("FrequencyModulatorBlock", vectors, "radio.platform.features.liquid and 5e-3 or 5e-5")
