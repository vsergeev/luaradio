import numpy
import scipy.signal
from generate import *


def generate():
    def dft(samples, window_type):
        # Apply window
        win = scipy.signal.get_window(window_type, len(samples)).astype(numpy.float32)
        windowed_samples = samples * win

        # Compute DFT
        dft_samples = numpy.fft.fftshift(numpy.fft.fft(windowed_samples)).astype(numpy.complex64)

        return dft_samples

    def psd(samples, window_type, sample_rate, logarithmic):
        # Compute PSD
        _, psd_samples = scipy.signal.periodogram(samples, fs=sample_rate, window=window_type, return_onesided=False)
        psd_samples = numpy.fft.fftshift(psd_samples).astype(numpy.float32)

        # Fix the averaged out DC component
        win = scipy.signal.get_window(window_type, len(samples))
        psd_samples[len(samples) / 2] = numpy.abs(numpy.sum(samples * win))**2 / (sample_rate * numpy.sum(win * win))

        if logarithmic:
            # Calculate 10*log10() of PSD
            psd_samples = 10.0 * numpy.log10(psd_samples)

        return psd_samples

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
    lines.append("M.dft_complex_rectangular = " + serialize(dft(x, 'rectangular')))
    lines.append("M.dft_complex_hamming = " + serialize(dft(x, 'hamming')))
    lines.append("M.dft_real_rectangular = " + serialize(dft(y, 'rectangular')))
    lines.append("M.dft_real_hamming = " + serialize(dft(y, 'hamming')))
    lines.append("")

    # PSD functions
    lines.append("M.psd_complex_rectangular = " + serialize(psd(x, 'rectangular', 44100, False)))
    lines.append("M.psd_complex_rectangular_log = " + serialize(psd(x, 'rectangular', 44100, True)))
    lines.append("M.psd_complex_hamming = " + serialize(psd(x, 'hamming', 44100, False)))
    lines.append("M.psd_complex_hamming_log = " + serialize(psd(x, 'hamming', 44100, True)))
    lines.append("M.psd_real_rectangular = " + serialize(psd(y, 'rectangular', 44100, False)))
    lines.append("M.psd_real_rectangular_log = " + serialize(psd(y, 'rectangular', 44100, True)))
    lines.append("M.psd_real_hamming = " + serialize(psd(y, 'hamming', 44100, False)))
    lines.append("M.psd_real_hamming_log = " + serialize(psd(y, 'hamming', 44100, True)))
    lines.append("")

    lines.append("return M")

    return RawSpec("tests/blocks/signal/spectrum_utils_vectors.lua", "\n".join(lines))
