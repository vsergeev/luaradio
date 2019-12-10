import numpy
import scipy.signal
from generate import *


def generate():
    def dft(samples):
        # Compute DFT
        return numpy.fft.fft(samples).astype(numpy.complex64)

    def psd(samples, window_type, sample_rate, logarithmic):
        # Compute PSD
        _, psd_samples = scipy.signal.periodogram(samples, fs=sample_rate, window=window_type, return_onesided=False)
        psd_samples = psd_samples.astype(numpy.float32)

        # Fix the averaged out DC component
        win = scipy.signal.get_window(window_type, len(samples))
        psd_samples[0] = numpy.abs(numpy.sum(samples * win))**2 / (sample_rate * numpy.sum(win * win))

        if logarithmic:
            # Calculate 10*log10() of PSD
            psd_samples = 10.0 * numpy.log10(psd_samples)

        return psd_samples

    def fftshift(samples):
        return numpy.fft.fftshift(samples)

    lines = []

    # Header
    lines.append("local radio = require('radio')")
    lines.append("")
    lines.append("local M = {}")

    # Input test vectors
    x = random_complex64(128)
    y = random_float32(128)

    # Test vectors
    lines.append("M.complex_test_vector = " + serialize(x))
    lines.append("M.real_test_vector = " + serialize(y))
    lines.append("")

    # DFT functions
    lines.append("M.complex_test_vector_dft = " + serialize(dft(x)))
    lines.append("M.real_test_vector_dft = " + serialize(dft(y)))
    lines.append("")

    # PSD functions
    lines.append("M.complex_test_vector_rectangular_psd = " + serialize(psd(x, 'rectangular', 44100, False)))
    lines.append("M.complex_test_vector_rectangular_psd_log = " + serialize(psd(x, 'rectangular', 44100, True)))
    lines.append("M.complex_test_vector_hamming_psd = " + serialize(psd(x, 'hamming', 44100, False)))
    lines.append("M.complex_test_vector_hamming_psd_log = " + serialize(psd(x, 'hamming', 44100, True)))
    lines.append("M.real_test_vector_rectangular_psd = " + serialize(psd(y, 'rectangular', 44100, False)))
    lines.append("M.real_test_vector_rectangular_psd_log = " + serialize(psd(y, 'rectangular', 44100, True)))
    lines.append("M.real_test_vector_hamming_psd = " + serialize(psd(y, 'hamming', 44100, False)))
    lines.append("M.real_test_vector_hamming_psd_log = " + serialize(psd(y, 'hamming', 44100, True)))
    lines.append("")

    # fftshift function
    lines.append("M.complex_test_vector_fftshift = " + serialize(fftshift(x)))
    lines.append("M.real_test_vector_fftshift = " + serialize(fftshift(y)))

    lines.append("return M")

    return RawSpec("\n".join(lines))
