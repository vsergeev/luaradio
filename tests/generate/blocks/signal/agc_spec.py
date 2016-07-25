import numpy
import scipy.signal
from generate import *


def generate():
    def agc(target, gain_tau, power_tau, x):
        # Compute average power
        power_alpha = 1/(1 + power_tau*2)
        average_power = scipy.signal.lfilter([power_alpha], [1, -1+power_alpha], numpy.abs(x)**2).astype(x.dtype)
        # Compute filtered gain
        gain_alpha = 1/(1 + gain_tau*2)
        filtered_gain = scipy.signal.lfilter([gain_alpha], [1, -1+gain_alpha], 10**(target/10)/average_power).astype(x.dtype)
        # Apply sqrt gain
        out = numpy.sqrt(filtered_gain)*x

        return [out]

    vectors = []

    # Cosine with 100 Hz frequency, 1000 Hz sample rate, 0.001 amplitude
    # Average power in dBFS = 10*log10(0.001^2 * 0.5) = -63 dBFS
    x = 0.001*numpy.cos(2*numpy.pi*(100/1000)*numpy.arange(256)).astype(numpy.float32)
    vectors.append(TestVector(['"fast"', -35, -50], [x], [x], "-63 dBFS cosine input, -50 dBFS threshold"))
    vectors.append(TestVector(['"fast"', -35, -75], [x], agc(-35, 0.1, 1.0, x), "-63 dBFS cosine input, -35 dbFS target, fast agc"))
    vectors.append(TestVector(['"slow"', -35, -75], [x], agc(-35, 3.0, 1.0, x), "-63 dBFS cosine input, -35 dbFS target, slow agc"))

    # Complex exponential with 100 Hz frequency, 1000 Hz sample rate, 0.001 amplitude
    # Average power in dBFS = 10*log10(0.001^2 * 1.0) = -60 dBFS
    x = 0.001*numpy.exp(2*numpy.pi*1j*(100/1000)*numpy.arange(256)).astype(numpy.complex64)
    vectors.append(TestVector(['"fast"', -35, -50], [x], [x], "-60 dBFS complex exponential input, -50 dBFS threshold"))
    vectors.append(TestVector(['"fast"', -35, -75], [x], agc(-35, 0.1, 1.0, x), "-60 dBFS complex exponential input, -35 dBFS target, fast agc"))
    vectors.append(TestVector(['"slow"', -35, -75], [x], agc(-35, 3.0, 1.0, x), "-60 dBFS complex exponential input, -35 dBFS target, slow agc"))

    return BlockSpec("AGCBlock", "tests/blocks/signal/agc_spec.lua", vectors, 1e-6)
