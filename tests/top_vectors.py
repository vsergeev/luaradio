import numpy
import scipy.signal
from generate import *


def generate():
    # Generate random source vectors
    src1 = random_complex64(512)
    src2 = random_complex64(512)

    # Multiply Conjugate
    out = src1 * numpy.conj(src2)

    # Low pass filter 16 taps, 100e3 cutoff at 1e6 sample rate
    b = scipy.signal.firwin(16, 100e3, nyq=1e6 / 2)
    out = scipy.signal.lfilter(b, 1, out).astype(type(out[0]))

    # Frequency discriminator with modulation index of 5
    out_shifted = numpy.insert(out, 0, numpy.complex64())[:len(out)]
    tmp = out * numpy.conj(out_shifted)
    out = (numpy.arctan2(numpy.imag(tmp), numpy.real(tmp)) / (2*numpy.pi*5.0)).astype(numpy.float32)

    # Decimate by 25
    out = scipy.signal.decimate(out, 25, n=16 - 1, ftype='fir', zero_phase=False).astype(numpy.float32)

    lines = []

    # Header
    lines.append("local M = {}")

    # Source vectors
    lines.append("M.SRC1_TEST_VECTOR = \"%s\"" % ''.join(["\\x%02x" % b for b in src1.tobytes()]))
    lines.append("M.SRC2_TEST_VECTOR = \"%s\"" % ''.join(["\\x%02x" % b for b in src2.tobytes()]))
    lines.append("")

    # Output vector
    lines.append("M.SNK_TEST_VECTOR = \"%s\"" % ''.join(["\\x%02x" % b for b in out.tobytes()]))
    lines.append("")

    lines.append("return M")

    return RawSpec("\n".join(lines))
