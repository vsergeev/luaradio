import numpy
from generate import *


def generate():
    def process(signal, frequency, rate, amplitude, phase, offset):
        if signal == "exponential":
            vec = amplitude * numpy.exp(1j * 2 * numpy.pi * (frequency / rate) * numpy.arange(256) + 1j * phase)
            return [vec.astype(numpy.complex64)]
        elif signal == "cosine":
            vec = amplitude * numpy.cos(2 * numpy.pi * (frequency / rate) * numpy.arange(256) + phase) + offset
            return [vec.astype(numpy.float32)]
        elif signal == "sine":
            vec = amplitude * numpy.sin(2 * numpy.pi * (frequency / rate) * numpy.arange(256) + phase) + offset
            return [vec.astype(numpy.float32)]
        elif signal == "constant":
            vec = numpy.ones(256) * amplitude
            return [vec.astype(numpy.float32)]

        def generate_domain(n, phase_offset=0.0):
            # Generate the 2*pi modulo domain with addition, as the signal
            # source block does it, instead of multiplication, which has small
            # discrepancies compared to addition in the neighborhood of 1e-13
            # and can cause different slicing on the x axis for square,
            # triangle, and sawtooth signals.
            omega, phi, phis = 2 * numpy.pi * (frequency / rate), phase_offset, []
            for i in range(n):
                phis.append(phi)
                phi += omega
                phi = (phi - 2 * numpy.pi) if phi >= 2 * numpy.pi else phi
            return numpy.array(phis)

        if signal == "square":
            def f(phi):
                return 1.0 if phi < numpy.pi else -1.0
        elif signal == "triangle":
            def f(phi):
                if phi < numpy.pi:
                    return 1 - (2 / numpy.pi) * phi
                else:
                    return -1 + (2 / numpy.pi) * (phi - numpy.pi)
        elif signal == "sawtooth":
            def f(phi):
                return -1.0 + (1 / numpy.pi) * phi

        vec = amplitude * numpy.vectorize(f)(generate_domain(256, phase)) + offset
        return [vec.astype(numpy.float32)]

    vectors = []

    for signal in ("exponential", "cosine", "sine", "square", "triangle", "sawtooth", "constant"):
        for (frequency, amplitude, phase, offset) in ((50, 1.0, 0.0, 0.0), (100, 2.5, numpy.pi / 4, -0.5)):
            vectors.append(TestVector(["\"%s\"" % signal, frequency, 1e3, {'amplitude': amplitude, 'phase': phase, 'offset': offset}], [], process(signal, frequency, 1e3, amplitude, phase, offset), "%s frequency %d, sample rate 1000, ampltiude %.2f, phase %.4f, offset %.2f" % (signal, frequency, amplitude, phase, offset)))

    # FIXME why does this need 2e-5 epsilon?
    return BlockSpec("SignalSource", vectors, 2e-5)
