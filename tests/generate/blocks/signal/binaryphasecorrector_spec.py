import numpy
from generate import *


def generate():
    def process(num_samples, sample_interval, x):
        phi_state = [0.0] * num_samples
        out = []

        for i, e in enumerate(x):
            if (i % sample_interval) == 0:
                phi = numpy.arctan2(e.imag, e.real)
                phi = (phi + numpy.pi) if phi < -numpy.pi / 2 else phi
                phi = (phi - numpy.pi) if phi > numpy.pi / 2 else phi
                phi_state = phi_state[1:] + [phi]
                phi_avg = numpy.mean(phi_state)

            out.append(e * numpy.complex64(complex(numpy.cos(-phi_avg), numpy.sin(-phi_avg))))

        return [numpy.array(out)]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([4, 1], [x], process(4, 1, x), "4 sample average, 1 sample interval, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([17, 15], [x], process(17, 15, x), "17 sample average, 15 sample interval, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([64, 7], [x], process(64, 7, x), "64 sample average, 7 sample interval, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([100, 32], [x], process(100, 32, x), "100 sample average, 32 sample interval, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    return BlockSpec("BinaryPhaseCorrectorBlock", "tests/blocks/signal/binaryphasecorrector_spec.lua", vectors, 1e-6)
