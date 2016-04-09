import numpy
from generate import *


def generate():
    def process(num_samples, x):
        phi_state = [0.0] * num_samples
        out = []

        for e in x:
            phi = numpy.arctan2(e.imag, e.real)
            phi = (phi + numpy.pi) if phi < -numpy.pi / 2 else phi
            phi = (phi - numpy.pi) if phi > numpy.pi / 2 else phi
            phi_state = phi_state[1:] + [phi]
            phi_avg = numpy.mean(phi_state)

            out.append(e * numpy.complex64(complex(numpy.cos(-phi_avg), numpy.sin(-phi_avg))))

        return [numpy.array(out)]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([4], [x], process(4, x), "4 sample average, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([17], [x], process(17, x), "17 sample average, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([64], [x], process(64, x), "64 sample average, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([100], [x], process(100, x), "100 sample average, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    return BlockSpec("BinaryPhaseCorrectorBlock", "tests/blocks/signal/binaryphasecorrector_spec.lua", vectors, 1e-6)
