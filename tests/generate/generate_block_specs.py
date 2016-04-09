#!/usr/bin/env python3

import scipy.signal
import scipy.io.wavfile
import random
import numpy
import io
import collections

# Floating point precision to round and serialize to
PRECISION = 8

################################################################################
# Helper functions for generating random types
################################################################################

def random_complex64(n):
    return numpy.around(numpy.array([complex(2*random.random()-1.0, 2*random.random()-1.0) for _ in range(n)]).astype(numpy.complex64), PRECISION)

def random_float32(n):
    return numpy.around(numpy.array([2*random.random()-1.0 for _ in range(n)]).astype(numpy.float32), PRECISION)

def random_integer32(n):
    return numpy.array([random.randint(-2147483648, 2147483647) for _ in range(n)]).astype(numpy.int32)

def random_bit(n):
    return numpy.array([random.randint(0, 1) for _ in range(n)]).astype(numpy.bool_)

################################################################################
# Test Vector serialization
################################################################################

NUMPY_SERIALIZE_TYPE = {
    numpy.complex64: lambda x: "{%.*f, %.*f}" % (PRECISION, x.real, PRECISION, x.imag),
    numpy.float32: lambda x: "%.*f" % (PRECISION, x),
    numpy.int32: lambda x: "%d" % x,
    numpy.bool_: lambda x: "%d" % x,
}

NUMPY_VECTOR_TYPE = {
    numpy.complex64: "radio.ComplexFloat32Type.vector_from_array({%s})",
    numpy.float32: "radio.Float32Type.vector_from_array({%s})",
    numpy.int32: "radio.Integer32Type.vector_from_array({%s})",
    numpy.bool_: "radio.BitType.vector_from_array({%s})",
}

def serialize(x):
    if isinstance(x, list):
        t = [serialize(e) for e in x]
        return "{" + ", ".join(t) + "}"
    elif isinstance(x, numpy.ndarray):
        t = [NUMPY_SERIALIZE_TYPE[type(x[0])](e) for e in x]
        return NUMPY_VECTOR_TYPE[type(x[0])] % ", ".join(t)
    elif isinstance(x , dict):
        t = []
        for k in sorted(x.keys()):
            t.append(serialize(k) + " = " + serialize(x[k]))
        return "{" + ", ".join(t) + "}"
    elif isinstance(x, numpy.complex64):
        return "radio.ComplexFloat32Type(%.*f, %.*f)" % (PRECISION, x.real, PRECISION, x.imag)
    elif isinstance(x, numpy.float32):
        return "radio.Float32Type(%.*f)" % (PRECISION, x)
    elif isinstance(x, bool):
        return "true" if x else "false"
    else:
        return str(x)

################################################################################

TestVector = collections.namedtuple('TestVector', ['args', 'inputs', 'outputs', 'desc'])
BlockSpec = collections.namedtuple('BlockSpec', ['name', 'filename', 'vectors', 'epsilon'])
SourceSpec = collections.namedtuple('SourceSpec', ['name', 'filename', 'vectors', 'epsilon'])
CompositeSpec = collections.namedtuple('CompositeSpec', ['name', 'filename', 'vectors', 'epsilon'])
RawSpec = collections.namedtuple('RawSpec', ['filename', 'content'])

spec_templates = {
    BlockSpec:
        "local radio = require('radio')\n"
        "local jigs = require('tests.jigs')\n"
        "\n"
        "jigs.TestBlock(radio.%s, {\n"
        "%s"
        "}, {epsilon = %.1e})\n",
    SourceSpec:
        "local radio = require('radio')\n"
        "local jigs = require('tests.jigs')\n"
        "local buffer = require('tests.buffer')\n"
        "\n"
        "jigs.TestSourceBlock(radio.%s, {\n"
        "%s"
        "}, {epsilon = %.1e})\n",
    CompositeSpec:
        "local radio = require('radio')\n"
        "local jigs = require('tests.jigs')\n"
        "\n"
        "jigs.TestCompositeBlock(radio.%s, {\n"
        "%s"
        "}, {epsilon = %.1e})\n",
    TestVector:
        "    {\n"
        "        desc = \"%s\",\n"
        "        args = {%s},\n"
        "        inputs = {%s},\n"
        "        outputs = {%s}\n"
        "    },\n"
}

def generate_spec(spec):
    if isinstance(spec, RawSpec):
        s = spec.content
    else:
        serialized_vectors = []
        for vector in spec.vectors:
            serialized_args = ", ".join([serialize(e) for e in vector.args])
            serialized_inputs = ", ".join([serialize(e) for e in vector.inputs])
            serialized_outputs = ", ".join([serialize(e) for e in vector.outputs])
            serialized_vectors.append(spec_templates[TestVector] % (vector.desc, serialized_args, serialized_inputs, serialized_outputs))
        s = spec_templates[type(spec)] % (spec.name, "".join(serialized_vectors), spec.epsilon)

    with open(spec.filename, "w") as f:
        f.write(s)

################################################################################
# Filter generation helper functions not available in numpy/scipy
################################################################################

def firwin_complex_bandpass(num_taps, cutoffs, window='hamming'):
    width, center = max(cutoffs) - min(cutoffs), (cutoffs[0] + cutoffs[1])/2
    b = scipy.signal.firwin(num_taps, width/2, window='rectangular', scale=False)
    b = b * numpy.exp(1j*numpy.pi*center*numpy.arange(len(b)))
    b = b * scipy.signal.get_window(window, num_taps, False)
    b = b / numpy.sum(b * numpy.exp(-1j*numpy.pi*center*(numpy.arange(num_taps) - (num_taps-1)/2)))
    return b.astype(numpy.complex64)

def firwin_complex_bandstop(num_taps, cutoffs, window='hamming'):
    width, center = max(cutoffs) - min(cutoffs), (cutoffs[0] + cutoffs[1])/2
    scale_freq = 1.0 if (0.0 > cutoffs[0] and 0.0 < cutoffs[1]) else 0.0
    b = scipy.signal.firwin(num_taps, width/2, pass_zero=False, window='rectangular', scale=False)
    b = b * numpy.exp(1j*numpy.pi*center*numpy.arange(len(b)))
    b = b * scipy.signal.get_window(window, num_taps, False)
    b = b / numpy.sum(b * numpy.exp(-1j*numpy.pi*scale_freq*(numpy.arange(num_taps) - (num_taps-1)/2)))
    return b.astype(numpy.complex64)

def fir_root_raised_cosine(num_taps, sample_rate, beta, symbol_period):
    h = []

    assert (num_taps % 2) == 1, "Number of taps must be odd."

    for i in range(num_taps):
        t = (i - (num_taps-1)/2)/sample_rate

        if t == 0:
            h.append((1/(numpy.sqrt(symbol_period))) * (1-beta+4*beta/numpy.pi))
        elif numpy.isclose(t, -symbol_period/(4*beta)) or numpy.isclose(t, symbol_period/(4*beta)):
            h.append((beta/numpy.sqrt(2*symbol_period))*((1+2/numpy.pi)*numpy.sin(numpy.pi/(4*beta))+(1-2/numpy.pi)*numpy.cos(numpy.pi/(4*beta))))
        else:
            num = numpy.cos((1 + beta)*numpy.pi*t/symbol_period) + numpy.sin((1 - beta)*numpy.pi*t/symbol_period)/(4*beta*t/symbol_period)
            denom = (1 - (4*beta*t/symbol_period)*(4*beta*t/symbol_period))
            h.append(((4*beta)/(numpy.pi*numpy.sqrt(symbol_period)))*num/denom)

    h = numpy.array(h)/numpy.sum(h)

    return h.astype(numpy.float32)

def fir_hilbert_transform(num_taps, window_func):
    h = []

    assert (num_taps % 2) == 1, "Number of taps must be odd."

    for i in range(num_taps):
        i_shifted = (i - (num_taps-1)/2)
        h.append(0 if (i_shifted % 2) == 0 else 2/(i_shifted*numpy.pi))

    h = h * window_func(num_taps)

    return h.astype(numpy.float32)

################################################################################
# Signal block test vectors
################################################################################

def generate_firfilter_spec():
    def process(taps, x):
        data_type = numpy.complex64 if isinstance(taps[0], numpy.complex64) or isinstance(x[0], numpy.complex64) else numpy.float32
        return [scipy.signal.lfilter(taps, 1, x).astype(data_type)]

    normalize = lambda v: v / numpy.sum(numpy.abs(v))

    vectors = []

    x = random_complex64(256)
    taps = normalize(random_float32(1))
    vectors.append(TestVector([taps], [x], process(taps, x), "1 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_float32(8))
    vectors.append(TestVector([taps], [x], process(taps, x), "8 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_float32(15))
    vectors.append(TestVector([taps], [x], process(taps, x), "15 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_float32(128))
    vectors.append(TestVector([taps], [x], process(taps, x), "128 Float32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    taps = normalize(random_float32(1))
    vectors.append(TestVector([taps], [x], process(taps, x), "1 Float32 tap, 256 Float32 input, 256 Float32 output"))
    taps = normalize(random_float32(8))
    vectors.append(TestVector([taps], [x], process(taps, x), "8 Float32 tap, 256 Float32 input, 256 Float32 output"))
    taps = normalize(random_float32(15))
    vectors.append(TestVector([taps], [x], process(taps, x), "15 Float32 tap, 256 Float32 input, 256 Float32 output"))
    taps = normalize(random_float32(128))
    vectors.append(TestVector([taps], [x], process(taps, x), "128 Float32 tap, 256 Float32 input, 256 Float32 output"))

    x = random_complex64(256)
    taps = normalize(random_complex64(1))
    vectors.append(TestVector([taps], [x], process(taps, x), "1 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_complex64(8))
    vectors.append(TestVector([taps], [x], process(taps, x), "8 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_complex64(15))
    vectors.append(TestVector([taps], [x], process(taps, x), "15 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_complex64(128))
    vectors.append(TestVector([taps], [x], process(taps, x), "128 ComplexFloat32 tap, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    taps = normalize(random_complex64(1))
    vectors.append(TestVector([taps], [x], process(taps, x), "1 ComplexFloat32 tap, 256 Float32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_complex64(8))
    vectors.append(TestVector([taps], [x], process(taps, x), "8 ComplexFloat32 tap, 256 Float32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_complex64(15))
    vectors.append(TestVector([taps], [x], process(taps, x), "15 ComplexFloat32 tap, 256 Float32 input, 256 ComplexFloat32 output"))
    taps = normalize(random_complex64(128))
    vectors.append(TestVector([taps], [x], process(taps, x), "128 ComplexFloat32 tap, 256 Float32 input, 256 ComplexFloat32 output"))

    return BlockSpec("FIRFilterBlock", "tests/blocks/signal/firfilter_spec.lua", vectors, 1e-6)

def generate_iirfilter_spec():
    def gentaps(n):
        b, a = scipy.signal.butter(n-1, 0.5)
        return b.astype(numpy.float32), a.astype(numpy.float32)

    def process(b_taps, a_taps, x):
        return [scipy.signal.lfilter(b_taps, a_taps, x).astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    b_taps, a_taps = gentaps(3)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "3 Float32 b taps, 3 Float32 a taps, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    b_taps, a_taps = gentaps(5)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "5 Float32 b taps, 5 Float32 a taps, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    b_taps, a_taps = gentaps(10)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "10 Float32 b taps, 10 Float32 a taps, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    b_taps, a_taps = gentaps(3)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "3 Float32 b taps, 3 Float32 a taps, 256 Float32 input, 256 Float32 output"))
    b_taps, a_taps = gentaps(5)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "5 Float32 b taps, 5 Float32 a taps, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    b_taps, a_taps = gentaps(10)
    vectors.append(TestVector([b_taps, a_taps], [x], process(b_taps, a_taps, x), "10 Float32 b taps, 10 Float32 a taps, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    return BlockSpec("IIRFilterBlock", "tests/blocks/signal/iirfilter_spec.lua", vectors, 1e-6)

def generate_lowpassfilter_spec():
    def process(num_taps, cutoff, window, nyquist, x):
        b = scipy.signal.firwin(num_taps, cutoff, window=window, nyq=nyquist)
        return [scipy.signal.lfilter(b, 1, x).astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([128, 0.2], [x], process(128, 0.2, "hamming", 1.0, x), "128 taps, 0.2 cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([128, 0.5], [x], process(128, 0.5, "hamming", 1.0, x), "128 taps, 0.5 cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([128, 0.7], [x], process(128, 0.7, "hamming", 1.0, x), "128 taps, 0.7 cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([128, 0.2, '"bartlett"', 3.0], [x], process(128, 0.2, "bartlett", 3.0, x), "128 taps, 0.2 cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([128, 0.5, '"bartlett"', 3.0], [x], process(128, 0.5, "bartlett", 3.0, x), "128 taps, 0.5 cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([128, 0.7, '"bartlett"', 3.0], [x], process(128, 0.7, "bartlett", 3.0, x), "128 taps, 0.7 cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([128, 0.2], [x], process(128, 0.2, "hamming", 1.0, x), "128 taps, 0.2 cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([128, 0.5], [x], process(128, 0.5, "hamming", 1.0, x), "128 taps, 0.5 cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([128, 0.7], [x], process(128, 0.7, "hamming", 1.0, x), "128 taps, 0.7 cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([128, 0.2, '"bartlett"', 3.0], [x], process(128, 0.2, "bartlett", 3.0, x), "128 taps, 0.2 cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([128, 0.5, '"bartlett"', 3.0], [x], process(128, 0.5, "bartlett", 3.0, x), "128 taps, 0.5 cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([128, 0.7, '"bartlett"', 3.0], [x], process(128, 0.7, "bartlett", 3.0, x), "128 taps, 0.7 cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 Float32 output"))

    return BlockSpec("LowpassFilterBlock", "tests/blocks/signal/lowpassfilter_spec.lua", vectors, 1e-6)

def generate_highpassfilter_spec():
    def process(num_taps, cutoff, window, nyquist, x):
        b = scipy.signal.firwin(num_taps, cutoff, pass_zero=False, window=window, nyq=nyquist)
        return [scipy.signal.lfilter(b, 1, x).astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([129, 0.2], [x], process(129, 0.2, "hamming", 1.0, x), "129 taps, 0.2 cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, 0.5], [x], process(129, 0.5, "hamming", 1.0, x), "129 taps, 0.5 cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, 0.7], [x], process(129, 0.7, "hamming", 1.0, x), "129 taps, 0.7 cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, 0.2, '"bartlett"', 3.0], [x], process(129, 0.2, "bartlett", 3.0, x), "128 taps, 0.2 cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, 0.5, '"bartlett"', 3.0], [x], process(129, 0.5, "bartlett", 3.0, x), "128 taps, 0.5 cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, 0.7, '"bartlett"', 3.0], [x], process(129, 0.7, "bartlett", 3.0, x), "128 taps, 0.7 cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([129, 0.2], [x], process(129, 0.2, "hamming", 1.0, x), "129 taps, 0.2 cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([129, 0.5], [x], process(129, 0.5, "hamming", 1.0, x), "129 taps, 0.5 cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([129, 0.7], [x], process(129, 0.7, "hamming", 1.0, x), "129 taps, 0.7 cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([129, 0.2, '"bartlett"', 3.0], [x], process(129, 0.2, "bartlett", 3.0, x), "128 taps, 0.2 cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([129, 0.5, '"bartlett"', 3.0], [x], process(129, 0.5, "bartlett", 3.0, x), "128 taps, 0.5 cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([129, 0.7, '"bartlett"', 3.0], [x], process(129, 0.7, "bartlett", 3.0, x), "128 taps, 0.7 cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 Float32 output"))

    return BlockSpec("HighpassFilterBlock", "tests/blocks/signal/highpassfilter_spec.lua", vectors, 1e-6)

def generate_bandpassfilter_spec():
    def process(num_taps, cutoffs, window, nyquist, x):
        b = scipy.signal.firwin(num_taps, cutoffs, pass_zero=False, window=window, nyq=nyquist)
        return [scipy.signal.lfilter(b, 1, x).astype(type(x[0]))]

    vectors = []
    x = random_complex64(256)
    vectors.append(TestVector([129, [0.1, 0.3]], [x], process(129, [0.1, 0.3], "hamming", 1.0, x), "129 taps, {0.1, 0.3} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.4, 0.6]], [x], process(129, [0.4, 0.6], "hamming", 1.0, x), "129 taps, {0.4, 0.6} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.1, 0.3], '"bartlett"', 3.0], [x], process(129, [0.1, 0.3], "bartlett", 3.0, x), "129 taps, {0.1, 0.3} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.4, 0.6], '"bartlett"', 3.0], [x], process(129, [0.4, 0.6], "bartlett", 3.0, x), "129 taps, {0.4, 0.6} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([129, [0.1, 0.3]], [x], process(129, [0.1, 0.3], "hamming", 1.0, x), "129 taps, {0.1, 0.3} cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([129, [0.4, 0.6]], [x], process(129, [0.4, 0.6], "hamming", 1.0, x), "129 taps, {0.4, 0.6} cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([129, [0.1, 0.3], '"bartlett"', 3.0], [x], process(129, [0.1, 0.3], "bartlett", 3.0, x), "129 taps, {0.1, 0.3} cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.4, 0.6], '"bartlett"', 3.0], [x], process(129, [0.4, 0.6], "bartlett", 3.0, x), "129 taps, {0.4, 0.6} cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 ComplexFloat32 output"))

    return BlockSpec("BandpassFilterBlock", "tests/blocks/signal/bandpassfilter_spec.lua", vectors, 1e-6)

def generate_bandstopfilter_spec():
    def process(num_taps, cutoffs, window, nyquist, x):
        b = scipy.signal.firwin(num_taps, cutoffs, pass_zero=True, window=window, nyq=nyquist)
        return [scipy.signal.lfilter(b, 1, x).astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([129, [0.1, 0.3]], [x], process(129, [0.1, 0.3], "hamming", 1.0, x), "129 taps, {0.1, 0.3} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.4, 0.6]], [x], process(129, [0.4, 0.6], "hamming", 1.0, x), "129 taps, {0.4, 0.6} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.1, 0.3], '"bartlett"', 3.0], [x], process(129, [0.1, 0.3], "bartlett", 3.0, x), "129 taps, {0.1, 0.3} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.4, 0.6], '"bartlett"', 3.0], [x], process(129, [0.4, 0.6], "bartlett", 3.0, x), "129 taps, {0.4, 0.6} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([129, [0.1, 0.3]], [x], process(129, [0.1, 0.3], "hamming", 1.0, x), "129 taps, {0.1, 0.3} cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([129, [0.4, 0.6]], [x], process(129, [0.4, 0.6], "hamming", 1.0, x), "129 taps, {0.4, 0.6} cutoff, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([129, [0.1, 0.3], '"bartlett"', 3.0], [x], process(129, [0.1, 0.3], "bartlett", 3.0, x), "129 taps, {0.1, 0.3} cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.4, 0.6], '"bartlett"', 3.0], [x], process(129, [0.4, 0.6], "bartlett", 3.0, x), "129 taps, {0.4, 0.6} cutoff, bartlett window, 3.0 nyquist, 256 Float32 input, 256 ComplexFloat32 output"))

    return BlockSpec("BandstopFilterBlock", "tests/blocks/signal/bandstopfilter_spec.lua", vectors, 1e-6)

def generate_complexbandpassfilter_spec():
    def process(num_taps, cutoffs, window, nyquist, x):
        b = firwin_complex_bandpass(num_taps, [cutoffs[0]/nyquist, cutoffs[1]/nyquist], window)
        return [scipy.signal.lfilter(b, 1, x).astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([129, [0.1, 0.3]], [x], process(129, [0.1, 0.3], "hamming", 1.0, x), "129 taps, {0.1, 0.3} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [-0.1, -0.3]], [x], process(129, [-0.1, -0.3], "hamming", 1.0, x), "129 taps, {-0.1, -0.3} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [-0.2, 0.2]], [x], process(129, [-0.2, 0.2], "hamming", 1.0, x), "129 taps, {-0.2, 0.2} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.1, 0.3], '"bartlett"', 3.0], [x], process(129, [0.1, 0.3], "bartlett", 3.0, x), "129 taps, {0.1, 0.3} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [-0.1, -0.3], '"bartlett"', 3.0], [x], process(129, [-0.1, -0.3], "bartlett", 3.0, x), "129 taps, {-0.1, -0.3} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [-0.2, 0.2], '"bartlett"', 3.0], [x], process(129, [-0.2, 0.2], "bartlett", 3.0, x), "129 taps, {-0.2, 0.2} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    return BlockSpec("ComplexBandpassFilterBlock", "tests/blocks/signal/complexbandpassfilter_spec.lua", vectors, 1e-6)

def generate_complexbandstopfilter_spec():
    def process(num_taps, cutoffs, window, nyquist, x):
        b = firwin_complex_bandstop(num_taps, [cutoffs[0]/nyquist, cutoffs[1]/nyquist], window)
        return [scipy.signal.lfilter(b, 1, x).astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([129, [0.1, 0.3]], [x], process(129, [0.1, 0.3], "hamming", 1.0, x), "129 taps, {0.1, 0.3} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [-0.1, -0.3]], [x], process(129, [-0.1, -0.3], "hamming", 1.0, x), "129 taps, {-0.1, -0.3} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [-0.2, 0.2]], [x], process(129, [-0.2, 0.2], "hamming", 1.0, x), "129 taps, {-0.2, 0.2} cutoff, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [0.1, 0.3], '"bartlett"', 3.0], [x], process(129, [0.1, 0.3], "bartlett", 3.0, x), "129 taps, {0.1, 0.3} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [-0.1, -0.3], '"bartlett"', 3.0], [x], process(129, [-0.1, -0.3], "bartlett", 3.0, x), "129 taps, {-0.1, -0.3} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129, [-0.2, 0.2], '"bartlett"', 3.0], [x], process(129, [-0.2, 0.2], "bartlett", 3.0, x), "129 taps, {-0.2, 0.2} cutoff, bartlett window, 3.0 nyquist, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    return BlockSpec("ComplexBandstopFilterBlock", "tests/blocks/signal/complexbandstopfilter_spec.lua", vectors, 1e-6)

def generate_rootraisedcosinefilter_spec():
    def process(num_taps, beta, symbol_rate, x):
        b = fir_root_raised_cosine(num_taps, 2.0, beta, 1/symbol_rate)
        return [scipy.signal.lfilter(b, 1, x).astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([101, 0.5, 1e-3], [x], process(101, 0.5, 1e-3, x), "101 taps, 0.5 beta, 1e-3 symbol rate, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([101, 0.7, 1e-3], [x], process(101, 0.7, 1e-3, x), "101 taps, 0.7 beta, 1e-3 symbol rate, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([101, 1.0, 5e-3], [x], process(101, 1.0, 5e-3, x), "101 taps, 1.0 beta, 5e-3 symbol rate, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([101, 0.5, 1e-3], [x], process(101, 0.5, 1e-3, x), "101 taps, 0.5 beta, 1e-3 symbol rate, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([101, 0.7, 1e-3], [x], process(101, 0.7, 1e-3, x), "101 taps, 0.7 beta, 1e-3 symbol rate, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([101, 1.0, 5e-3], [x], process(101, 1.0, 5e-3, x), "101 taps, 1.0 beta, 5e-3 symbol rate, 256 Float32 input, 256 Float32 output"))

    return BlockSpec("RootRaisedCosineFilterBlock", "tests/blocks/signal/rootraisedcosinefilter_spec.lua", vectors, 1e-6)

def generate_fmdeemphasisfilter_spec():
    def process(tau, x):
        b_taps = [1/(1 + 4*tau), 1/(1 + 4*tau)]
        a_taps = [1, (1 - 4*tau)/(1 + 4*tau)]
        return [scipy.signal.lfilter(b_taps, a_taps, x).astype(numpy.float32)]

    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([75e-6], [x], process(75e-6, x), "75e-6 tau, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([50e-6], [x], process(50e-6, x), "50e-6 tau, 256 Float32 input, 256 Float32 output"))

    return BlockSpec("FMDeemphasisFilterBlock",  "tests/blocks/signal/fmdeemphasisfilter_spec.lua", vectors, 1e-6)

def generate_downsampler_spec():
    def process(factor, x):
        out = []
        for i in range(0, len(x), factor):
            out.append(x[i])
        return [numpy.array(out)]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Factor, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 ComplexFloat32 input, 128 ComplexFloat32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 ComplexFloat32 input, 85 ComplexFloat32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 ComplexFloat32 input, 64 ComplexFloat32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 ComplexFloat32 input, 36 ComplexFloat32 output"))
    vectors.append(TestVector([16], [x], process(16, x), "16 Factor, 256 ComplexFloat32 input, 16 ComplexFloat32 output"))
    vectors.append(TestVector([128], [x], process(128, x), "128 Factor, 256 ComplexFloat32 input, 2 ComplexFloat32 output"))
    vectors.append(TestVector([200], [x], process(200, x), "200 Factor, 256 ComplexFloat32 input, 1 ComplexFloat32 output"))
    vectors.append(TestVector([256], [x], process(256, x), "256 Factor, 256 ComplexFloat32 input, 1 ComplexFloat32 output"))
    vectors.append(TestVector([257], [x], process(257, x), "256 Factor, 256 ComplexFloat32 input, 0 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Factor, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 Float32 input, 128 Float32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 Float32 input, 85 Float32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 Float32 input, 64 Float32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 Float32 input, 36 Float32 output"))
    vectors.append(TestVector([16], [x], process(16, x), "16 Factor, 256 Float32 input, 16 Float32 output"))
    vectors.append(TestVector([128], [x], process(128, x), "128 Factor, 256 Float32 input, 2 Float32 output"))
    vectors.append(TestVector([200], [x], process(200, x), "200 Factor, 256 Float32 input, 1 Float32 output"))
    vectors.append(TestVector([256], [x], process(256, x), "256 Factor, 256 Float32 input, 1 Float32 output"))
    vectors.append(TestVector([257], [x], process(257, x), "256 Factor, 256 Float32 input, 0 Float32 output"))

    x = random_integer32(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Factor, 256 Integer32 input, 256 Integer32 output"))
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 Integer32 input, 128 Integer32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 Integer32 input, 85 Integer32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 Integer32 input, 64 Integer32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 Integer32 input, 36 Integer32 output"))
    vectors.append(TestVector([16], [x], process(16, x), "16 Factor, 256 Integer32 input, 16 Integer32 output"))
    vectors.append(TestVector([128], [x], process(128, x), "128 Factor, 256 Integer32 input, 2 Integer32 output"))
    vectors.append(TestVector([200], [x], process(200, x), "200 Factor, 256 Integer32 input, 1 Integer32 output"))
    vectors.append(TestVector([256], [x], process(256, x), "256 Factor, 256 Integer32 input, 1 Integer32 output"))
    vectors.append(TestVector([257], [x], process(257, x), "256 Factor, 256 Integer32 input, 0 Integer32 output"))

    return BlockSpec("DownsamplerBlock", "tests/blocks/signal/downsampler_spec.lua", vectors, 1e-6)

def generate_upsampler_spec():
    def process(factor, x):
        out = [type(x[0])()]*(len(x)*factor)
        for i in range(0, len(x)):
            out[i*factor] = x[i]
        return [numpy.array(out)]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Factor, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 ComplexFloat32 input, 512 ComplexFloat32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 ComplexFloat32 input, 768 ComplexFloat32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 ComplexFloat32 input, 1024 ComplexFloat32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 ComplexFloat32 input, 1792 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Factor, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 Float32 input, 512 Float32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 Float32 input, 768 Float32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 Float32 input, 1024 Float32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 Float32 input, 1792 Float32 output"))

    x = random_integer32(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Factor, 256 Integer32 input, 256 Integer32 output"))
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 Integer32 input, 512 Integer32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 Integer32 input, 768 Integer32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 Integer32 input, 1024 Integer32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 Integer32 input, 1792 Integer32 output"))

    return BlockSpec("UpsamplerBlock", "tests/blocks/signal/upsampler_spec.lua", vectors, 1e-6)

def generate_decimator_spec():
    def process(factor, x):
        out = scipy.signal.decimate(x, factor, n=128-1, ftype='fir')
        return [out.astype(type(x[0]))]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 ComplexFloat32 input, 128 ComplexFloat32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 ComplexFloat32 input, 85 ComplexFloat32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 ComplexFloat32 input, 64 ComplexFloat32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 ComplexFloat32 input, 36 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 256 Float32 input, 128 Float32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 256 Float32 input, 85 Float32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 256 Float32 input, 64 Float32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 256 Float32 input, 36 Float32 output"))

    return CompositeSpec("DecimatorBlock", "tests/composites/decimator_spec.lua", vectors, 1e-6)

def generate_interpolator_spec():
    def process(factor, x):
        x_interp = numpy.array([type(x[0])()]*(len(x)*factor))
        for i in range(0, len(x)):
            x_interp[i*factor] = factor*x[i]
        b = scipy.signal.firwin(128, 1/factor)
        return [scipy.signal.lfilter(b, 1, x_interp).astype(type(x[0]))]

    vectors = []

    x = random_complex64(32)
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 32 ComplexFloat32 input, 64 ComplexFloat32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 32 ComplexFloat32 input, 96 ComplexFloat32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 32 ComplexFloat32 input, 128 ComplexFloat32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 32 ComplexFloat32 input, 224 ComplexFloat32 output"))

    x = random_float32(32)
    vectors.append(TestVector([2], [x], process(2, x), "2 Factor, 32 Float32 input, 64 Float32 output"))
    vectors.append(TestVector([3], [x], process(3, x), "3 Factor, 32 Float32 input, 96 Float32 output"))
    vectors.append(TestVector([4], [x], process(4, x), "4 Factor, 32 Float32 input, 128 Float32 output"))
    vectors.append(TestVector([7], [x], process(7, x), "7 Factor, 32 Float32 input, 224 Float32 output"))

    return CompositeSpec("InterpolatorBlock", "tests/composites/interpolator_spec.lua", vectors, 1e-6)

def generate_rationalresampler_spec():
    def process(up_factor, down_factor, x):
        x_interp = numpy.array([type(x[0])()]*(len(x)*up_factor))
        for i in range(0, len(x)):
            x_interp[i*up_factor] = up_factor*x[i]
        b = scipy.signal.firwin(128, 1/up_factor if (1/up_factor < 1/down_factor) else 1/down_factor)
        x_interp = scipy.signal.lfilter(b, 1, x_interp).astype(type(x[0]))
        x_decim = numpy.array([x_interp[i] for i in range(0, len(x_interp), down_factor)])
        return [x_decim.astype(type(x[0]))]

    vectors = []

    x = random_complex64(32)
    vectors.append(TestVector([2, 3], [x], process(2, 3, x), "2 up, 3 down, 32 ComplexFloat32 input, 21 ComplexFloat32 output"))
    vectors.append(TestVector([7, 5], [x], process(7, 5, x), "7 up, 5 down, 32 ComplexFloat32 input, 44 ComplexFloat32 output"))

    x = random_float32(32)
    vectors.append(TestVector([2, 3], [x], process(2, 3, x), "2 up, 3 down, 32 Float32 input, 21 Float32 output"))
    vectors.append(TestVector([7, 5], [x], process(7, 5, x), "7 up, 5 down, 32 Float32 input, 44 Float32 output"))

    return CompositeSpec("RationalResamplerBlock", "tests/composites/rationalresampler_spec.lua", vectors, 1e-6)

def generate_frequencytranslator_spec():
    # FIXME why does this need 1e-5 epsilon?
    def process(offset, x):
        rotator = numpy.exp(1j*2*numpy.pi*(offset/2.0)*numpy.arange(len(x))).astype(numpy.complex64)
        return [x * rotator]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([0.2], [x], process(0.2, x), "0.2 offset, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([0.5], [x], process(0.5, x), "0.5 offset, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([0.7], [x], process(0.7, x), "0.7 offset, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    return BlockSpec("FrequencyTranslatorBlock", "tests/blocks/signal/frequencytranslator_spec.lua", vectors, 1e-5)

def generate_tuner_spec():
    def process(offset, bandwidth, decimation, x):
        # Rotate
        x = x * numpy.exp(1j*2*numpy.pi*(offset/2.0)*numpy.arange(len(x))).astype(numpy.complex64)
        # Filter
        x = scipy.signal.lfilter(scipy.signal.firwin(128, bandwidth/2), 1, x).astype(x[0])
        # Downsample
        x = numpy.array([x[i] for i in range(0, len(x), decimation)])
        return [x]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([0.2, 0.1, 5], [x], process(0.2, 0.1, 5, x), "0.2 offset, 0.1 bandwidth, 5 decimation, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([-0.2, 0.1, 5], [x], process(-0.2, 0.1, 5, x), "-0.2 offset, 0.1 bandwidth, 5 decimation, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    return CompositeSpec("TunerBlock", "tests/composites/tuner_spec.lua", vectors, 1e-5)

def generate_hilberttransform_spec():
    def process(num_taps, x):
        delay = int((num_taps-1)/2)
        h = fir_hilbert_transform(num_taps, scipy.signal.hamming)

        imag = scipy.signal.lfilter(h, 1, x).astype(numpy.float32)
        real = numpy.insert(x, 0, [numpy.float32()]*delay)[:len(x)]
        return [numpy.array([complex(*e) for e in zip(real, imag)]).astype(numpy.complex64)]

    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([9], [x], process(9, x), "9 taps, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([65], [x], process(65, x), "65 taps, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([129], [x], process(129, x), "129 taps, 256 Float32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([257], [x], process(257, x), "257 taps, 256 Float32 input, 256 ComplexFloat32 output"))

    return BlockSpec("HilbertTransformBlock", "tests/blocks/signal/hilberttransform_spec.lua", vectors, 1e-6)

def generate_frequencydiscriminator_spec():
    def process(gain, x):
        x_shifted = numpy.insert(x, 0, numpy.complex64())[:len(x)]
        tmp = x*numpy.conj(x_shifted)
        return [(numpy.arctan2(numpy.imag(tmp), numpy.real(tmp))/gain).astype(numpy.float32)]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([1.0], [x], process(1.0, x), "1.0 Gain, 256 ComplexFloat32 input, 256 Float32 output"))
    vectors.append(TestVector([5.0], [x], process(5.0, x), "5.0 Gain, 256 ComplexFloat32 input, 256 Float32 output"))
    vectors.append(TestVector([10.0], [x], process(10.0, x), "10.0 Gain, 256 ComplexFloat32 input, 256 Float32 output"))

    return BlockSpec("FrequencyDiscriminatorBlock", "tests/blocks/signal/frequencydiscriminator_spec.lua", vectors, 1e-6)

def generate_zerocrossingclockrecovery_spec():
    x = numpy.array([-1, -1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1], dtype=numpy.float32)
    clock = numpy.array([-1, -1, -1, 1, -1, -1, -1, 1, -1, -1, -1, 1, -1, -1, -1, -1, 1, -1, -1, -1, 1, -1, -1, -1, -1, 1, -1, -1, -1, 1, -1], dtype=numpy.float32)

    # Baudrate of 0.4444 with sample rate of 2.0 means we have 4.5 samples per bit
    vectors = []
    vectors.append(TestVector([0.4444, 0.0], [x], [clock], "0.4444 baudrate, 0.0 threshold"))
    vectors.append(TestVector([0.4444, 1.0], [x + 1.0], [clock], "0.4444 baudrate, 1.0 threshold"))

    return BlockSpec("ZeroCrossingClockRecoveryBlock", "tests/blocks/signal/zerocrossingclockrecovery_spec.lua", vectors, 1e-6)

def generate_sum_spec():
    vectors = []

    x, y = random_complex64(256), random_complex64(256)
    vectors.append(TestVector([], [x, y], [x+y], "2 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))

    x, y = random_float32(256), random_float32(256)
    vectors.append(TestVector([], [x, y], [x+y], "2 256 Float32 inputs, 256 Float32 output"))

    x, y = random_integer32(256), random_integer32(256)
    vectors.append(TestVector([], [x, y], [x+y], "2 256 Integer32 inputs, 256 Integer32 output"))

    return BlockSpec("SumBlock", "tests/blocks/signal/sum_spec.lua", vectors, 1e-6)

def generate_subtract_spec():
    vectors = []

    x, y = random_complex64(256), random_complex64(256)
    vectors.append(TestVector([], [x, y], [x-y], "2 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))

    x, y = random_float32(256), random_float32(256)
    vectors.append(TestVector([], [x, y], [x-y], "2 256 Float32 inputs, 256 Float32 output"))

    x, y = random_integer32(256), random_integer32(256)
    vectors.append(TestVector([], [x, y], [x-y], "2 256 Integer32 inputs, 256 Integer32 output"))

    return BlockSpec("SubtractBlock", "tests/blocks/signal/subtract_spec.lua", vectors, 1e-6)

def generate_multiply_spec():
    vectors = []

    x, y = random_complex64(256), random_complex64(256)
    vectors.append(TestVector([], [x, y], [x*y], "2 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))

    x, y = random_float32(256), random_float32(256)
    vectors.append(TestVector([], [x, y], [x*y], "2 256 Float32 inputs, 256 Float32 output"))

    return BlockSpec("MultiplyBlock", "tests/blocks/signal/multiply_spec.lua", vectors, 1e-6)

def generate_multiplyconstant_spec():
    def process(constant, x):
        return [x * constant]

    vectors = []

    x = random_complex64(256)
    # ComplexFloat32 vector times number constant
    vectors.append(TestVector([2.5], [x], process(2.5, x), "Number constant, 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))
    # ComplexFloat32 vector times float32 constant
    vectors.append(TestVector([numpy.float32(3.5)], [x], process(numpy.float32(3.5), x), "Float32 constant, 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))
    # ComplexFloat32 vector times ComplexFloat32 constant
    vectors.append(TestVector([numpy.complex64(complex(1,2))], [x], process(numpy.complex64(complex(1,2)), x), "ComplexFloat32 constant, 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))

    x = random_float32(256)
    # Float32 vector times number constant
    vectors.append(TestVector([2.5], [x], process(2.5, x), "Number constant, 256 Float32 inputs, 256 Float32 output"))
    # Float32 vector times Float32 constant
    vectors.append(TestVector([numpy.float32(3.5)], [x], process(numpy.float32(3.5), x), "Float32 constant, 256 Float32 inputs, 256 Float32 output"))

    return BlockSpec("MultiplyConstantBlock", "tests/blocks/signal/multiplyconstant_spec.lua", vectors, 1e-6)

def generate_multiplyconjugate_spec():
    vectors = []

    x, y = random_complex64(256), random_complex64(256)
    vectors.append(TestVector([], [x, y], [x * numpy.conj(y)], "2 256 ComplexFloat32 inputs, 256 ComplexFloat32 output"))

    return BlockSpec("MultiplyConjugateBlock", "tests/blocks/signal/multiplyconjugate_spec.lua", vectors, 1e-6)

def generate_absolutevalue_spec():
    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([], [x], [numpy.abs(x)], "256 Float32 input, 256 Float32 output"))

    return BlockSpec("AbsoluteValueBlock", "tests/blocks/signal/absolutevalue_spec.lua", vectors, 1e-6)

def generate_complexconjugate_spec():
    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([], [x], [numpy.conj(x)], "256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    return BlockSpec("ComplexConjugateBlock", "tests/blocks/signal/complexconjugate_spec.lua", vectors, 1e-6)

def generate_complexmagnitude_spec():
    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([], [x], [numpy.abs(x).astype(numpy.float32)], "256 ComplexFloat32 input, 256 Float32 output"))

    return BlockSpec("ComplexMagnitudeBlock", "tests/blocks/signal/complexmagnitude_spec.lua", vectors, 1e-6)

def generate_complexphase_spec():
    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([], [x], [numpy.angle(x).astype(numpy.float32)], "256 ComplexFloat32 input, 256 Float32 output"))

    return BlockSpec("ComplexPhaseBlock", "tests/blocks/signal/complexphase_spec.lua", vectors, 1e-6)

def generate_binaryphasecorrector_spec():
    def process(num_samples, x):
        phi_state = [0.0]*num_samples
        out = []

        for e in x:
            phi = numpy.arctan2(e.imag, e.real)
            phi = (phi + numpy.pi) if phi < -numpy.pi/2 else phi
            phi = (phi - numpy.pi) if phi > numpy.pi/2 else phi
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

def generate_delay_spec():
    def process(n, x):
        elem_type = type(x[0])
        return [numpy.insert(x, 0, [elem_type()]*n)[:len(x)]]

    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Sample Delay, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([15], [x], process(15, x), "1 Sample Delay, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))
    vectors.append(TestVector([100], [x], process(100, x), "1 Sample Delay, 256 ComplexFloat32 input, 256 ComplexFloat32 output"))

    x = random_float32(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Sample Delay, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([15], [x], process(15, x), "1 Sample Delay, 256 Float32 input, 256 Float32 output"))
    vectors.append(TestVector([100], [x], process(100, x), "1 Sample Delay, 256 Float32 input, 256 Float32 output"))

    x = random_integer32(256)
    vectors.append(TestVector([1], [x], process(1, x), "1 Sample Delay, 256 Integer32 input, 256 Integer32 output"))
    vectors.append(TestVector([15], [x], process(15, x), "1 Sample Delay, 256 Integer32 input, 256 Integer32 output"))
    vectors.append(TestVector([100], [x], process(100, x), "1 Sample Delay, 256 Integer32 input, 256 Integer32 output"))

    return BlockSpec("DelayBlock", "tests/blocks/signal/delay_spec.lua", vectors, 1e-6)

def generate_sampler_spec():
    def process(data, clock):
        sampled_data = []
        hysteresis = False

        for i in range(len(clock)):
            if hysteresis == False and clock[i] > 0:
                sampled_data.append(data[i])
                hysteresis = True
            elif hysteresis == True and clock[i] < 0:
                hysteresis = False

        return [numpy.array(sampled_data)]

    vectors = []

    data, clock = random_complex64(256), random_float32(256)
    vectors.append(TestVector([], [data, clock], process(data, clock), "256 ComplexFloat32 data, 256 Float32 clock, 256 Float32 output"))

    data, clock = random_float32(256), random_float32(256)
    vectors.append(TestVector([], [data, clock], process(data, clock), "256 Float32 data, 256 Float32 clock, 256 Float32 output"))

    return BlockSpec("SamplerBlock", "tests/blocks/signal/sampler_spec.lua", vectors, 1e-6)

def generate_slicer_spec():
    def process(threshold, x):
        return [x > threshold]

    vectors = []

    x = random_float32(256)
    vectors.append(TestVector([0.00], [x], process(0.00, x), "Default threshold, 256 Float32 input, 256 Bit output"))
    vectors.append(TestVector([0.25], [x], process(0.25, x), "0.25 threshold, 256 Float32 input, 256 Bit output"))
    vectors.append(TestVector([-0.25], [x], process(-0.25, x), "-0.25 threshold, 256 Float32 input, 256 Bit output"))

    return BlockSpec("SlicerBlock", "tests/blocks/signal/slicer_spec.lua", vectors, 1e-6)

def generate_differentialdecoder_spec():
    def process(invert, x):
        return [numpy.logical_xor(numpy.logical_xor(numpy.insert(x, 0, False)[:-1], x), invert)]

    vectors = []

    x = random_bit(256)
    vectors.append(TestVector([False], [x], process(False, x), "Non-inverted output, 256 Bit input, 256 Bit output"))
    vectors.append(TestVector([True], [x], process(True, x), "Inverted output, 256 Bit input, 256 Bit output"))

    return BlockSpec("DifferentialDecoderBlock", "tests/blocks/signal/differentialdecoder_spec.lua", vectors, 1e-6)

def generate_complextoreal_spec():
    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([], [x], [numpy.real(x)], "256 ComplexFloat32 input, 256 Float32 output"))

    return BlockSpec("ComplexToRealBlock", "tests/blocks/signal/complextoreal_spec.lua", vectors, 1e-6)

def generate_complextoimag_spec():
    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([], [x], [numpy.imag(x)], "256 ComplexFloat32 input, 256 Float32 output"))

    return BlockSpec("ComplexToImagBlock", "tests/blocks/signal/complextoimag_spec.lua", vectors, 1e-6)

def generate_complextofloat_spec():
    vectors = []

    x = random_complex64(256)
    vectors.append(TestVector([], [x], [numpy.real(x), numpy.imag(x)], "256 ComplexFloat32 input, 2 256 Float32 outputs"))

    return BlockSpec("ComplexToFloatBlock", "tests/blocks/signal/complextofloat_spec.lua", vectors, 1e-6)

def generate_floattocomplex_spec():
    def process(real, imag):
        return [numpy.array([complex(*e) for e in zip(real, imag)]).astype(numpy.complex64)]

    vectors = []

    real, imag = random_float32(256), random_float32(256)
    vectors.append(TestVector([], [real, imag], process(real, imag), "2 256 Float32 inputs, 256 ComplexFloat32 output"))

    return BlockSpec("FloatToComplexBlock", "tests/blocks/signal/floattocomplex_spec.lua", vectors, 1e-6)

def generate_window_utils_spec():
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

    return RawSpec("tests/blocks/signal/window_utils_vectors.lua", "\n".join(lines))

def generate_filter_utils_spec():
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

def generate_spectrum_utils_spec():
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
        psd_samples[len(samples)/2] = numpy.abs(numpy.sum(samples*win))**2 / (sample_rate * numpy.sum(win * win))

        if logarithmic:
            # Calculate 10*log10() of PSD
            psd_samples = 10.0*numpy.log10(psd_samples)

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

def generate_top_spec():
    # Generate random source vectors
    src1 = random_complex64(512)
    src2 = random_complex64(512)

    # Multiply Conjugate
    out = src1 * numpy.conj(src2)

    # Low pass filter 16 taps, 100e3 cutoff at 1e6 sample rate
    b = scipy.signal.firwin(16, 100e3, nyq=1e6/2)
    out = scipy.signal.lfilter(b, 1, out).astype(type(out[0]))

    # Frequency discriminator with gain 5
    out_shifted = numpy.insert(out, 0, numpy.complex64())[:len(out)]
    tmp = out*numpy.conj(out_shifted)
    out = (numpy.arctan2(numpy.imag(tmp), numpy.real(tmp))/5.0).astype(numpy.float32)

    # Decimate by 25
    out = scipy.signal.decimate(out, 25, n=16-1, ftype='fir').astype(numpy.float32)

    lines= []

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

    return RawSpec("tests/top_vectors.lua", "\n".join(lines))

################################################################################
# Protocol block test vectors
################################################################################

def generate_ax25frame_spec():
    def test_vector_wrapper(frames):
        template = "require('radio.blocks.protocol.ax25frame').AX25FrameType.vector_from_array({%s})"
        return [template % (','.join(frames))]

    def bytes_to_stuffed_bits(data):
        bits = numpy.array([not not (b & (1<<i)) for b in data for i in range(8)], dtype=numpy.bool_)

        stuffed_bits = []
        ones_count = 0
        for i in range(8, len(bits)-8):
            ones_count = (ones_count + 1) if bits[i] == True and ones_count < 5 else 0
            stuffed_bits.append(bits[i])
            if ones_count == 5:
                stuffed_bits.append(False)

        return numpy.hstack([bits[0:8], stuffed_bits, bits[-8:]])

    frame1_data = [0x7E, 0x96, 0x70, 0x9A, 0x9A, 0x9E, 0x40, 0xE0, 0xAE, 0x84, 0x68, 0x94, 0x8C, 0x92, 0x60, 0xAE, 0x84, 0x68, 0x94, 0x8C, 0x92, 0xE3, 0x3E, 0xF0, 0xF4, 0x79, 0x7E]
    frame1_object = "{{{callsign = \"K8MMO \", ssid = 112}, {callsign = \"WB4JFI\", ssid = 48}, {callsign = \"WB4JFI\", ssid = 113}}, 0x3e, 0xf0, \"\"}"

    frame2_data = [0x7E, 0x96, 0x70, 0x9A, 0x9A, 0x9E, 0x40, 0xE0, 0xAE, 0x84, 0x68, 0x94, 0x8C, 0x92, 0x61, 0x3E, 0xF0, 0x74, 0x65, 0x73, 0x74, 0xa0, 0x99, 0x7E]
    frame2_object = "{{{callsign = \"K8MMO \", ssid = 112}, {callsign = \"WB4JFI\", ssid = 48}}, 0x3e, 0xf0, \"test\"}"

    vectors = []

    x = numpy.hstack([random_bit(20), bytes_to_stuffed_bits(frame1_data), random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object]), "Valid frame 1"))

    x = numpy.hstack([random_bit(20), bytes_to_stuffed_bits(frame1_data), random_bit(20)])
    x[40] = not x[40]
    vectors.append(TestVector([], [x], test_vector_wrapper([]), "Invalid frame 1 (bit error)"))

    x = numpy.hstack([random_bit(20), bytes_to_stuffed_bits(frame1_data), random_bit(20), bytes_to_stuffed_bits(frame2_data), random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object, frame2_object]), "Two valid frames"))

    x = numpy.hstack([random_bit(20), bytes_to_stuffed_bits(frame1_data), [False, True, True, True, True, True, True, False]*11, bytes_to_stuffed_bits(frame2_data), random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object, frame2_object]), "Two valid frames with many flag fields in between"))

    x = numpy.hstack([random_bit(20), bytes_to_stuffed_bits(frame2_data), bytes_to_stuffed_bits(frame1_data), bytes_to_stuffed_bits(frame2_data), random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame2_object, frame1_object, frame2_object]), "Three back to back valid frames"))

    return BlockSpec("AX25FrameBlock", "tests/blocks/protocol/ax25frame_spec.lua", vectors, 1e-6)

def generate_pocsagframe_spec():
    def test_vector_wrapper(frames):
        template = "require('radio.blocks.protocol.pocsagframe').POCSAGFrameType.vector_from_array({%s})"
        return [template % (','.join(frames))]

    def words_to_bits(words):
        bits = []
        for w in words:
            for i in range(32):
                bits.append(True if w & (1 << (31-i)) else False)
        return bits

    #     0  1  2  3    4  5  6  7
    # F | II II AD DI | AD DD DD DD |
    # F | DI AD AD AI | II II AD DD |
    frame1_words = [0xaaaaaaaa]*18 + [0x7cd215d8, 0x7a89c197,0x7a89c197, 0x7a89c197,0x7a89c197, 0x7e4b8585,0xd43f30a9, 0xbd782239,0x7a89c197, 0x486c4e00,0xebceb7a1, 0xd9a474c5,0xfde4633d, 0x95ecc6ce,0xc7a66d1e, 0xd614e7c2,0xac426ee5] + [0x7cd215d8, 0xa11078cc,0x7a89c197, 0x3f3ab55e,0xd3ffcef5, 0x57887b02,0xf8cfc87b, 0x375a21cd,0x7a89c197, 0x7a89c197,0x7a89c197, 0x7a89c197,0x7a89c197, 0x2de2fb1a,0xa30da919, 0xf572a509,0xf1e9fea1]
    frame1_objects = ["{0x1f92e2, 0, {0xa87e6, 0x7af04}}", "{0x121b14, 1, {0xd79d6, 0xb348e, 0xfbc8c, 0x2bd98, 0x8f4cd, 0xac29c, 0x5884d, 0x4220f}}", "{0xfcea9, 2, {0xa7ff9}}", "{0x15e21a, 3, {0xf19f9}}", "{0xdd68b, 0, {}}", "{0xb78be, 3, {0x461b5, 0xeae54, 0xe3d3f}}"]
    frame1_bits = words_to_bits(frame1_words)

    vectors = []

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(600)])
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects), "Valid frame"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(32), frame1_bits, random_bit(600)])
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects + frame1_objects), "Two valid frames"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(600)])
    x[20+100] = not x[20+100]
    x[20+201] = not x[20+201]
    x[20+300] = not x[20+300]
    x[20+401] = not x[20+301]
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects), "Frame with preamble bit errors"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(600)])
    x[20+576+32*6+7] = not x[20+576+32*6+7]
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects), "Frame with message bit error"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(600)])
    x[20+576+32*9+25] = not x[20+576+32*9+25]
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects), "Frame with crc bit error"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(600)])
    x[20+576+32*14+10] = not x[20+576+32*14+10]
    x[20+576+32*14+11] = not x[20+576+32*14+11]
    x[20+576+32*14+12] = not x[20+576+32*14+12]
    frame1_objects_cutoff = ["{0x1f92e2, 0, {0xa87e6, 0x7af04}}", "{0x121b14, 1, {0xd79d6, 0xb348e, 0xfbc8c, 0x2bd98}}", "{0xfcea9, 2, {0xa7ff9}}", "{0x15e21a, 3, {0xf19f9}}", "{0xdd68b, 0, {}}", "{0xb78be, 3, {0x461b5, 0xeae54, 0xe3d3f}}"]
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects_cutoff), "Frame with an uncorrectable bit error"))

    return BlockSpec("POCSAGFrameBlock", "tests/blocks/protocol/pocsagframe_spec.lua", vectors, 1e-6)

def generate_pocsagdecode_spec():
    def test_vector_wrapper(messages):
        template = "require('radio.blocks.protocol.pocsagdecode').POCSAGMessageType.vector_from_array({%s})"
        return [template % (','.join(messages))]

    frame1 = "require('radio.blocks.protocol.pocsagframe').POCSAGFrameType.vector_from_array({{12345, 2, {0x2f4f3, 0x9796e, 0xf9f40}}})"
    message1 = "{12345, 2, 'testing', nil}"
    message1_both = "{12345, 2, 'testing', '2)4)39796()9)40'}"

    frame2 = "require('radio.blocks.protocol.pocsagframe').POCSAGFrameType.vector_from_array({{45678, 0, {0x86753, 0x09ccc}}})"
    message2 = "{45678, 0, nil, '8675309   '}"

    vectors = []

    vectors.append(TestVector(['"alphanumeric"'], [frame1], test_vector_wrapper([message1]), "Alphanumeric Message"))
    vectors.append(TestVector(['"both"'], [frame1], test_vector_wrapper([message1_both]), "Alphanumeric Message"))
    vectors.append(TestVector(['"numeric"'], [frame2], test_vector_wrapper([message2]), "Numeric Message"))

    return BlockSpec("POCSAGDecodeBlock", "tests/blocks/protocol/pocsagdecode_spec.lua", vectors, 1e-6)

def generate_rdsframe_spec():
    def test_vector_wrapper(frames):
        template = "require('radio.blocks.protocol.rdsframe').RDSFrameType.vector_from_array({%s})"
        return [template % (','.join(frames))]

    frame1_bits = numpy.array([0,0,1,1,1,0,1,0,1,0,1,0,1,0,1,1,0,1,1,1,0,1,1,0,0,0,0,0,0,0,0,0,1,0,1,1,0,0,1,0,0,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,0,0,1,1,0,1,1,0,0,1,0,0,0,1,1,0,1,0,0,1,1,1,1,1,0,0,0,1,1,0], dtype=numpy.bool_)
    frame1_object = "{{{0x3aab, 0x02c9, 0x0608, 0x6469}}}"

    frame2_bits = numpy.array([0,0,1,1,1,0,1,0,1,0,1,0,1,0,1,1,0,1,1,1,0,1,1,0,0,0,1,0,0,0,0,0,1,0,1,1,0,0,1,0,0,0,1,1,0,0,0,0,1,1,0,1,0,1,0,0,1,0,0,0,0,1,0,0,1,0,0,1,1,0,0,1,0,1,1,0,1,1,0,0,1,0,1,0,0,1,0,0,0,1,1,0,0,0,0,1,0,0,1,0,0,0,1,0], dtype=numpy.bool_)
    frame2_object = "{{{0x3aab, 0x82c8, 0x4849, 0x2918}}}"

    frame3_bits = numpy.array([0,0,1,1,1,0,1,0,1,0,1,0,1,0,1,1,0,1,1,1,0,1,1,0,0,0,0,0,0,0,0,0,1,0,1,1,0,0,1,0,1,0,0,0,0,0,0,0,1,0,0,0,1,1,1,0,0,0,1,1,0,0,0,0,1,0,1,0,0,1,0,1,0,0,0,0,1,0,0,1,1,0,1,1,1,1,0,0,1,0,0,0,0,0,1,1,0,1,1,1,0,1,1,0], dtype=numpy.bool_)
    frame3_object = "{{{0x3aab, 0x02ca, 0xe30a, 0x6f20}}}"

    vectors = []

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object]), "Valid frame 1"))

    x = numpy.hstack([random_bit(20), frame2_bits, random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame2_object]), "Valid frame 2"))

    x = numpy.hstack([random_bit(20), frame3_bits, random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame3_object]), "Valid frame 3"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(20)])
    x[27] = not x[27]
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object]), "Frame 1 with message bit error"))

    x = numpy.hstack([random_bit(20), frame2_bits, random_bit(20)])
    x[39] = not x[39]
    vectors.append(TestVector([], [x], test_vector_wrapper([frame2_object]), "Frame 2 with crc bit error"))

    x = numpy.hstack([frame1_bits, frame2_bits, frame3_bits])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object, frame2_object, frame3_object]), "Three contiguous frames"))

    return BlockSpec("RDSFrameBlock", "tests/blocks/protocol/rdsframe_spec.lua", vectors, 1e-6)

def generate_rdsdecode_spec():
    def test_vector_wrapper(packets):
        template = "require('radio.blocks.protocol.rdsdecode').RDSPacketType.vector_from_array({%s})"
        return [template % (','.join(packets))]

    frame1 = "require('radio.blocks.protocol.rdsframe').RDSFrameType.vector_from_array({{{{0x3aab, 0x02ca, 0xe30a, 0x6963}}}})"
    packet1 = "{{pi_code = 15019, tp_code = 0, group_code = 0, group_version = 0, pty_code = 22}, {text_data = 'ic', di_position = 1, text_address = 2, ms_code = 1, di_value = 0, af_code = {227, 10}, type = 'basictuning', ta_code = 0}}"
    frame2 = "require('radio.blocks.protocol.rdsframe').RDSFrameType.vector_from_array({{{{0x3aab, 0x22c8, 0x2043, 0x616c}}}})"
    packet2 = "{{pi_code = 15019, tp_code = 0, group_code = 2, group_version = 0, pty_code = 22}, {type = 'radiotext', text_data = ' Cal', text_address = 8, ab_flag = 0}}"
    frame3 = "require('radio.blocks.protocol.rdsframe').RDSFrameType.vector_from_array({{{{0x3aab, 0x42dd, 0xc11a, 0xd0ae}}}})"
    packet3 = "{{pi_code = 15019, tp_code = 0, group_code = 4, group_version = 0, pty_code = 22}, {type = 'datetime', time = {offset = -7, hour = 13, minute = 2}, date = {day = 7, year = 2016, month = 4}}}"
    frame4 = "require('radio.blocks.protocol.rdsframe').RDSFrameType.vector_from_array({{{{0x3aab, 0x82c0, 0x18ed, 0x14fa}}}})"
    packet4 = "{{pi_code = 15019, tp_code = 0, group_code = 8, group_version = 0, pty_code = 22}, {type = 'raw', frame = {15019,33472,6381,5370}}}"

    vectors = []

    vectors.append(TestVector([], [frame1], test_vector_wrapper([packet1]), "Basic Tuning Frame"))
    vectors.append(TestVector([], [frame2], test_vector_wrapper([packet2]), "Radio Text Frame"))
    vectors.append(TestVector([], [frame3], test_vector_wrapper([packet3]), "Datetime Frame"))
    vectors.append(TestVector([], [frame4], test_vector_wrapper([packet4]), "Other Frame"))

    return BlockSpec("RDSDecodeBlock", "tests/blocks/protocol/rdsdecode_spec.lua", vectors, 1e-6)

################################################################################
# Source block test vectors
################################################################################

def generate_null_spec():
    vectors = []

    vectors.append(TestVector(["radio.ComplexFloat32Type", 1], [], [numpy.array([complex(0, 0) for _ in range(256)]).astype(numpy.complex64)], "Data type ComplexFloat32, rate 1"))
    vectors.append(TestVector(["radio.Float32Type", 1], [], [numpy.array([0 for _ in range(256)]).astype(numpy.float32)], "Data type Float32, rate 1"))
    vectors.append(TestVector(["radio.Integer32Type", 1], [], [numpy.array([0 for _ in range(256)]).astype(numpy.int32)], "Data type Integer32, rate 1"))

    return SourceSpec("NullSource", "tests/blocks/sources/null_spec.lua", vectors, 1e-6)

def generate_iqfile_spec():
    numpy_vectors = [
        # Format, numpy array, byteswap
        ( "u8", numpy.array([random.randint(0, 255) for _ in range(256*2)], dtype=numpy.uint8), False ),
        ( "s8", numpy.array([random.randint(-128, 127) for _ in range(256*2)], dtype=numpy.int8), False ),
        ( "u16le", numpy.array([random.randint(0, 65535) for _ in range(256*2)], dtype=numpy.uint16), False ),
        ( "u16be", numpy.array([random.randint(0, 65535) for _ in range(256*2)], dtype=numpy.uint16), True ),
        ( "s16le", numpy.array([random.randint(-32768, 32767) for _ in range(256*2)], dtype=numpy.int16), False ),
        ( "s16be", numpy.array([random.randint(-32768, 32767) for _ in range(256*2)], dtype=numpy.int16), True ),
        ( "u32le", numpy.array([random.randint(0, 4294967295) for _ in range(256*2)], dtype=numpy.uint32), False ),
        ( "u32be", numpy.array([random.randint(0, 4294967295) for _ in range(256*2)], dtype=numpy.uint32), True ),
        ( "s32le", numpy.array([random.randint(-2147483648, 2147483647) for _ in range(256*2)], dtype=numpy.int32), False ),
        ( "s32be", numpy.array([random.randint(-2147483648, 2147483647) for _ in range(256*2)], dtype=numpy.int32), True ),
        ( "f32le", numpy.array(random_float32(256*2), dtype=numpy.float32), False ),
        ( "f32be", numpy.array(random_float32(256*2), dtype=numpy.float32), True ),
        ( "f64le", numpy.array(random_float32(256*2), dtype=numpy.float64), False ),
        ( "f64be", numpy.array(random_float32(256*2), dtype=numpy.float64), True),
    ]

    def process(x):
        if type(x[0]) == numpy.uint8:
            y = ((x - 127.5) / 127.5).astype(numpy.float32)
        elif type(x[0]) == numpy.int8:
            y = ((x - 0) / 127.5).astype(numpy.float32)
        elif type(x[0]) == numpy.uint16:
            y = ((x - 32767.5) / 32767.5).astype(numpy.float32)
        elif type(x[0]) == numpy.int16:
            y = ((x - 0) / 32767.5).astype(numpy.float32)
        elif type(x[0]) == numpy.uint32:
            y = ((x - 2147483647.5) / 2147483647.5).astype(numpy.float32)
        elif type(x[0]) == numpy.int32:
            y = ((x - 0) / 2147483647.5).astype(numpy.float32)
        elif type(x[0]) == numpy.float32:
            y = x
        elif type(x[0]) == numpy.float64:
            y = x.astype(numpy.float32)
        return [numpy.array([numpy.complex64(complex(y[i], y[i+1])) for i in range(0, len(y), 2)])]

    vectors = []

    for (fmt, vector, byteswap) in numpy_vectors:
        # Build byte array with raw test vector
        buf = vector.tobytes() if not byteswap else vector.byteswap().tobytes()
        buf = ''.join(["\\x%02x" % b for b in buf])

        # Build test vector
        vectors.append(TestVector(["buffer.open(\"%s\")" % buf, "\"%s\"" % fmt, 1], [], process(vector), "Data type %s, rate 1" % fmt))

    return SourceSpec("IQFileSource", "tests/blocks/sources/iqfile_spec.lua", vectors, 1e-6)

def generate_realfile_spec():
    numpy_vectors = [
        # Format, numpy array, byteswap
        ( "u8", numpy.array([random.randint(0, 255) for _ in range(256)], dtype=numpy.uint8), False ),
        ( "s8", numpy.array([random.randint(-128, 127) for _ in range(256)], dtype=numpy.int8), False ),
        ( "u16le", numpy.array([random.randint(0, 65535) for _ in range(256)], dtype=numpy.uint16), False ),
        ( "u16be", numpy.array([random.randint(0, 65535) for _ in range(256)], dtype=numpy.uint16), True ),
        ( "s16le", numpy.array([random.randint(-32768, 32767) for _ in range(256)], dtype=numpy.int16), False ),
        ( "s16be", numpy.array([random.randint(-32768, 32767) for _ in range(256)], dtype=numpy.int16), True ),
        ( "u32le", numpy.array([random.randint(0, 4294967295) for _ in range(256)], dtype=numpy.uint32), False ),
        ( "u32be", numpy.array([random.randint(0, 4294967295) for _ in range(256)], dtype=numpy.uint32), True ),
        ( "s32le", numpy.array([random.randint(-2147483648, 2147483647) for _ in range(256)], dtype=numpy.int32), False ),
        ( "s32be", numpy.array([random.randint(-2147483648, 2147483647) for _ in range(256)], dtype=numpy.int32), True ),
        ( "f32le", numpy.array(random_float32(256), dtype=numpy.float32), False ),
        ( "f32be", numpy.array(random_float32(256), dtype=numpy.float32), True ),
        ( "f64le", numpy.array(random_float32(256), dtype=numpy.float64), False ),
        ( "f64be", numpy.array(random_float32(256), dtype=numpy.float64), True),
    ]

    def process(x):
        if type(x[0]) == numpy.uint8:
            y = ((x - 127.5) / 127.5).astype(numpy.float32)
        elif type(x[0]) == numpy.int8:
            y = ((x - 0) / 127.5).astype(numpy.float32)
        elif type(x[0]) == numpy.uint16:
            y = ((x - 32767.5) / 32767.5).astype(numpy.float32)
        elif type(x[0]) == numpy.int16:
            y = ((x - 0) / 32767.5).astype(numpy.float32)
        elif type(x[0]) == numpy.uint32:
            y = ((x - 2147483647.5) / 2147483647.5).astype(numpy.float32)
        elif type(x[0]) == numpy.int32:
            y = ((x - 0) / 2147483647.5).astype(numpy.float32)
        elif type(x[0]) == numpy.float32:
            y = x
        elif type(x[0]) == numpy.float64:
            y = x.astype(numpy.float32)
        return [y]

    vectors = []

    for (fmt, vector, byteswap) in numpy_vectors:
        # Build byte array with raw test vector
        buf = vector.tobytes() if not byteswap else vector.byteswap().tobytes()
        buf = ''.join(["\\x%02x" % b for b in buf])

        # Build test vector
        vectors.append(TestVector(["buffer.open(\"%s\")" % buf, "\"%s\"" % fmt, 1], [], process(vector), "Data type %s, rate 1" % fmt))

    return SourceSpec("RealFileSource", "tests/blocks/sources/realfile_spec.lua", vectors, 1e-6)

def generate_wavfile_spec():
    def float32_to_u8(x):
        return ((x * 127.5) + 127.5).astype(numpy.uint8)
    def u8_to_float32(x):
        return ((x - 127.5) / 127.5).astype(numpy.float32)

    def float32_to_s16(x):
        return ((x * 32767.5) + 0.0).astype(numpy.int16)
    def s16_to_float32(x):
        return ((x - 0.0) / 32767.5).astype(numpy.float32)

    def float32_to_s32(x):
        return ((x * 2147483647.5) + 0.0).astype(numpy.int32)
    def s32_to_float32(x):
        return ((x - 0.0) / 2147483647.5).astype(numpy.float32)

    vectors = []

    test_vector = random_float32(256)
    for bits_per_sample in (8, 16, 32):
        for num_channels in (1, 2):
            # Prepare wav and float vectors
            if bits_per_sample == 8:
                wav_vector = float32_to_u8(test_vector)
                expected_vector = u8_to_float32(wav_vector)
            elif bits_per_sample == 16:
                wav_vector = float32_to_s16(test_vector)
                expected_vector = s16_to_float32(wav_vector)
            elif bits_per_sample == 32:
                wav_vector = float32_to_s32(test_vector)
                expected_vector = s32_to_float32(wav_vector)

            # Reshape vectors with num channels
            wav_vector.shape = (len(wav_vector)/num_channels, num_channels)
            expected_vector.shape = (len(expected_vector)/num_channels, num_channels)

            # Write WAV file to bytes array
            f_buf = io.BytesIO()
            scipy.io.wavfile.write(f_buf, 44100, wav_vector)
            buf = ''.join(["\\x%02x" % b for b in f_buf.getvalue()])

            # Build test vector
            vectors.append(TestVector(["buffer.open(\"%s\")" % buf, num_channels, 44100], [], [expected_vector[:,i] for i in range(num_channels)], "bits per sample %d, num channels %d" % (bits_per_sample, num_channels)))

    return SourceSpec("WAVFileSource", "tests/blocks/sources/wavfile_spec.lua", vectors, 1e-6)

def generate_signal_spec():
    # FIXME why does exponential, cosine, sine need 1e-5 epsilon?
    def process(signal, frequency, rate, amplitude, phase, offset):
        if signal == "exponential":
            vec = amplitude*numpy.exp(1j*2*numpy.pi*(frequency/rate)*numpy.arange(256) + 1j*phase)
            return [vec.astype(numpy.complex64)]
        elif signal == "cosine":
            vec = amplitude*numpy.cos(2*numpy.pi*(frequency/rate)*numpy.arange(256) + phase) + offset
            return [vec.astype(numpy.float32)]
        elif signal == "sine":
            vec = amplitude*numpy.sin(2*numpy.pi*(frequency/rate)*numpy.arange(256) + phase) + offset
            return [vec.astype(numpy.float32)]
        elif signal == "constant":
            vec = numpy.ones(256)*amplitude
            return [vec.astype(numpy.float32)]

        def generate_domain(n, phase_offset=0.0):
            # Generate the 2*pi modulo domain with addition, as the signal
            # source block does it, instead of multiplication, which has small
            # discrepancies compared to addition in the neighborhood of 1e-13
            # and can cause different slicing on the x axis for square,
            # triangle, and sawtooth signals.
            omega, phi, phis = 2*numpy.pi*(frequency/rate), phase_offset, []
            for i in range(n):
                phis.append(phi)
                phi += omega
                phi = (phi - 2*numpy.pi) if phi >= 2*numpy.pi else phi
            return numpy.array(phis)

        if signal == "square":
            def f(phi):
                return 1.0 if phi < numpy.pi else -1.0
        elif signal == "triangle":
            def f(phi):
                if phi < numpy.pi:
                    return 1 - (2/numpy.pi)*phi
                else:
                    return -1 + (2/numpy.pi)*(phi - numpy.pi)
        elif signal == "sawtooth":
            def f(phi):
                return -1.0 + (1 / numpy.pi) * phi

        vec = amplitude*numpy.vectorize(f)(generate_domain(256, phase)) + offset
        return [vec.astype(numpy.float32)]

    vectors = []

    for signal in ("exponential", "cosine", "sine", "square", "triangle", "sawtooth", "constant"):
        for (frequency, amplitude, phase, offset) in ((50, 1.0, 0.0, 0.0), (100, 2.5, numpy.pi/4, -0.5)):
            vectors.append(TestVector(["\"%s\"" % signal, frequency, 1e3, {'amplitude': amplitude, 'phase': phase, 'offset': offset}], [], process(signal, frequency, 1e3, amplitude, phase, offset), "%s frequency %d, sample rate 1000, ampltiude %.2f, phase %.4f, offset %.2f" % (signal, frequency, amplitude, phase, offset)))

    return SourceSpec("SignalSource", "tests/blocks/sources/signal_spec.lua", vectors, 1e-5)

################################################################################

funcs = [
    generate_firfilter_spec,
    generate_iirfilter_spec,
    generate_lowpassfilter_spec,
    generate_highpassfilter_spec,
    generate_bandpassfilter_spec,
    generate_bandstopfilter_spec,
    generate_complexbandpassfilter_spec,
    generate_complexbandstopfilter_spec,
    generate_rootraisedcosinefilter_spec,
    generate_fmdeemphasisfilter_spec,
    generate_downsampler_spec,
    generate_upsampler_spec,
    generate_decimator_spec,
    generate_interpolator_spec,
    generate_rationalresampler_spec,
    generate_frequencytranslator_spec,
    generate_tuner_spec,
    generate_hilberttransform_spec,
    generate_frequencydiscriminator_spec,
    generate_zerocrossingclockrecovery_spec,
    generate_sum_spec,
    generate_subtract_spec,
    generate_multiply_spec,
    generate_multiplyconstant_spec,
    generate_multiplyconjugate_spec,
    generate_absolutevalue_spec,
    generate_complexconjugate_spec,
    generate_complexmagnitude_spec,
    generate_complexphase_spec,
    generate_binaryphasecorrector_spec,
    generate_delay_spec,
    generate_sampler_spec,
    generate_slicer_spec,
    generate_differentialdecoder_spec,
    generate_complextoreal_spec,
    generate_complextoimag_spec,
    generate_complextofloat_spec,
    generate_floattocomplex_spec,
    generate_window_utils_spec,
    generate_filter_utils_spec,
    generate_spectrum_utils_spec,
    generate_top_spec,
    generate_ax25frame_spec,
    generate_pocsagframe_spec,
    generate_pocsagdecode_spec,
    generate_rdsframe_spec,
    generate_rdsdecode_spec,
    generate_null_spec,
    generate_iqfile_spec,
    generate_realfile_spec,
    generate_wavfile_spec,
    generate_signal_spec,
]

if __name__ == "__main__":
    for f in funcs:
        # Reset random seed before each spec file for deterministic generation
        random.seed(1)
        generate_spec(f())

