import numpy
import scipy.signal
from generate import *


def firwin_complex_bandpass(num_taps, cutoffs, window='hamming'):
    width, center = max(cutoffs) - min(cutoffs), (cutoffs[0] + cutoffs[1]) / 2
    b = scipy.signal.firwin(num_taps, width / 2, window='rectangular', scale=False)
    b = b * numpy.exp(1j * numpy.pi * center * numpy.arange(len(b)))
    b = b * scipy.signal.get_window(window, num_taps, False)
    b = b / numpy.sum(b * numpy.exp(-1j * numpy.pi * center * (numpy.arange(num_taps) - (num_taps - 1) / 2)))
    return b.astype(numpy.complex64)


def firwin_complex_bandstop(num_taps, cutoffs, window='hamming'):
    width, center = max(cutoffs) - min(cutoffs), (cutoffs[0] + cutoffs[1]) / 2
    scale_freq = 1.0 if (0.0 > cutoffs[0] and 0.0 < cutoffs[1]) else 0.0
    b = scipy.signal.firwin(num_taps, width / 2, pass_zero=False, window='rectangular', scale=False)
    b = b * numpy.exp(1j * numpy.pi * center * numpy.arange(len(b)))
    b = b * scipy.signal.get_window(window, num_taps, False)
    b = b / numpy.sum(b * numpy.exp(-1j * numpy.pi * scale_freq * (numpy.arange(num_taps) - (num_taps - 1) / 2)))
    return b.astype(numpy.complex64)


def fir_root_raised_cosine(num_taps, sample_rate, beta, symbol_period):
    h = []

    assert (num_taps % 2) == 1, "Number of taps must be odd."

    for i in range(num_taps):
        t = (i - (num_taps - 1) / 2) / sample_rate

        if t == 0:
            h.append((1 / (numpy.sqrt(symbol_period))) * (1 - beta + 4 * beta / numpy.pi))
        elif numpy.isclose(t, -symbol_period / (4 * beta)) or numpy.isclose(t, symbol_period / (4 * beta)):
            h.append((beta / numpy.sqrt(2 * symbol_period)) * ((1 + 2 / numpy.pi) * numpy.sin(numpy.pi / (4 * beta)) + (1 - 2 / numpy.pi) * numpy.cos(numpy.pi / (4 * beta))))
        else:
            num = numpy.cos((1 + beta) * numpy.pi * t / symbol_period) + numpy.sin((1 - beta) * numpy.pi * t / symbol_period) / (4 * beta * t / symbol_period)
            denom = (1 - (4 * beta * t / symbol_period) * (4 * beta * t / symbol_period))
            h.append(((4 * beta) / (numpy.pi * numpy.sqrt(symbol_period))) * num / denom)

    h = numpy.array(h) / numpy.sum(h)

    return h.astype(numpy.float32)


def fir_hilbert_transform(num_taps, window_func):
    h = []

    assert (num_taps % 2) == 1, "Number of taps must be odd."

    for i in range(num_taps):
        i_shifted = (i - (num_taps - 1) / 2)
        h.append(0 if (i_shifted % 2) == 0 else 2 / (i_shifted * numpy.pi))

    h = h * window_func(num_taps)

    return h.astype(numpy.float32)


def generate():
    lines = []

    # Header
    lines.append("local radio = require('radio')")
    lines.append("")
    lines.append("local M = {}")

    # Firwin functions
    lines.append("M.firwin_lowpass = " + serialize(scipy.signal.firwin(128, 0.5).astype(numpy.float32)))
    lines.append("M.firwin_highpass = " + serialize(scipy.signal.firwin(129, 0.5, pass_zero=False).astype(numpy.float32)))
    lines.append("M.firwin_bandpass = " + serialize(scipy.signal.firwin(129, [0.4, 0.6], pass_zero=False).astype(numpy.float32)))
    lines.append("M.firwin_bandstop = " + serialize(scipy.signal.firwin(129, [0.4, 0.6]).astype(numpy.float32)))
    lines.append("")

    # Complex firwin functions
    lines.append("M.firwin_complex_bandpass_positive = " + serialize(firwin_complex_bandpass(129, [0.1, 0.3])))
    lines.append("M.firwin_complex_bandpass_negative = " + serialize(firwin_complex_bandpass(129, [-0.1, -0.3])))
    lines.append("M.firwin_complex_bandpass_zero = " + serialize(firwin_complex_bandpass(129, [-0.2, 0.2])))
    lines.append("M.firwin_complex_bandstop_positive = " + serialize(firwin_complex_bandstop(129, [0.1, 0.3])))
    lines.append("M.firwin_complex_bandstop_negative = " + serialize(firwin_complex_bandstop(129, [-0.1, -0.3])))
    lines.append("M.firwin_complex_bandstop_zero = " + serialize(firwin_complex_bandstop(129, [-0.2, 0.2])))
    lines.append("")

    # FIR Root Raised Cosine function
    lines.append("M.fir_root_raised_cosine = " + serialize(fir_root_raised_cosine(101, 1e6, 0.5, 1e3)))
    lines.append("")

    # FIR Root Raised Cosine function
    lines.append("M.fir_hilbert_transform = " + serialize(fir_hilbert_transform(129, scipy.signal.hamming)))
    lines.append("")

    lines.append("return M")

    return RawSpec("tests/blocks/signal/filter_utils_vectors.lua", "\n".join(lines))
