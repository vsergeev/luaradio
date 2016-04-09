import numpy
import scipy.signal
from generate import *


def generate():
    def process(offset, bandwidth, decimation, x):
        # Rotate
        x = x * numpy.exp(1j * 2 * numpy.pi * (offset / 2.0) * numpy.arange(len(x))).astype(numpy.complex64)
        # Filter
        x = scipy.signal.lfilter(scipy.signal.firwin(128, bandwidth / 2), 1, x).astype(x[0])
        # Downsample
        x = numpy.array([x[i] for i in range(0, len(x), decimation)])
        return [x]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([0.2, 0.1, 5], [x], process(0.2, 0.1, 5, x), "0.2 offset, 0.1 bandwidth, 5 decimation, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([-0.2, 0.1, 5], [x], process(-0.2, 0.1, 5, x), "-0.2 offset, 0.1 bandwidth, 5 decimation, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    # FIXME why does this need 1e-5 epsilon?
    return CompositeSpec("TunerBlock", "tests/composites/tuner_spec.lua", vectors, 1e-5)
