import numpy
import scipy.signal
from generate import *


def generate():
    lines = []

    # Header
    lines.append("local radio = require('radio')")
    lines.append("")
    lines.append("local M = {}")

    # Window functions
    lines.append("M.window_rectangular = " + serialize(scipy.signal.boxcar(128).astype(numpy.float32)))
    lines.append("M.window_rectangular_periodic = " + serialize(scipy.signal.boxcar(128, False).astype(numpy.float32)))
    lines.append("M.window_hamming = " + serialize(scipy.signal.hamming(128).astype(numpy.float32)))
    lines.append("M.window_hamming_periodic = " + serialize(scipy.signal.hamming(128, False).astype(numpy.float32)))
    lines.append("M.window_hanning = " + serialize(scipy.signal.hanning(128).astype(numpy.float32)))
    lines.append("M.window_hanning_periodic = " + serialize(scipy.signal.hanning(128, False).astype(numpy.float32)))
    lines.append("M.window_bartlett = " + serialize(scipy.signal.bartlett(128).astype(numpy.float32)))
    lines.append("M.window_bartlett_periodic = " + serialize(scipy.signal.bartlett(128, False).astype(numpy.float32)))
    lines.append("M.window_blackman = " + serialize(scipy.signal.blackman(128).astype(numpy.float32)))
    lines.append("M.window_blackman_periodic = " + serialize(scipy.signal.blackman(128, False).astype(numpy.float32)))
    lines.append("")

    lines.append("return M")

    return RawSpec("tests/utilities/window_utils_vectors.lua", "\n".join(lines))
