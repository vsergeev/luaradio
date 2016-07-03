#!/usr/bin/env python3

import sys
import os
import os.path
import random
import numpy
import collections
import glob

# Floating point precision to round and serialize to
PRECISION = 8

################################################################################
# Helper functions for generating random types
################################################################################


def random_complex64(n):
    return numpy.around(numpy.array([complex(2 * random.random() - 1.0, 2 * random.random() - 1.0) for _ in range(n)]).astype(numpy.complex64), PRECISION)


def random_float32(n):
    return numpy.around(numpy.array([2 * random.random() - 1.0 for _ in range(n)]).astype(numpy.float32), PRECISION)


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
    numpy.complex64: "radio.types.ComplexFloat32.vector_from_array({%s})",
    numpy.float32: "radio.types.Float32.vector_from_array({%s})",
    numpy.bool_: "radio.types.Bit.vector_from_array({%s})",
}


def serialize(x):
    if isinstance(x, list):
        t = [serialize(e) for e in x]
        return "{" + ", ".join(t) + "}"
    elif isinstance(x, numpy.ndarray):
        t = [NUMPY_SERIALIZE_TYPE[x.dtype.type](e) for e in x]
        return NUMPY_VECTOR_TYPE[x.dtype.type] % ", ".join(t)
    elif isinstance(x, dict):
        t = []
        for k in sorted(x.keys()):
            t.append(serialize(k) + " = " + serialize(x[k]))
        return "{" + ", ".join(t) + "}"
    elif isinstance(x, numpy.complex64):
        return "radio.types.ComplexFloat32(%.*f, %.*f)" % (PRECISION, x.real, PRECISION, x.imag)
    elif isinstance(x, numpy.float32):
        return "radio.types.Float32(%.*f)" % (PRECISION, x)
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
    "BlockSpec":
        "local radio = require('radio')\n"
        "local jigs = require('tests.jigs')\n"
        "\n"
        "jigs.TestBlock(radio.%s, {\n"
        "%s"
        "}, {epsilon = %.1e})\n",
    "SourceSpec":
        "local radio = require('radio')\n"
        "local jigs = require('tests.jigs')\n"
        "local buffer = require('tests.buffer')\n"
        "\n"
        "jigs.TestSourceBlock(radio.%s, {\n"
        "%s"
        "}, {epsilon = %.1e})\n",
    "CompositeSpec":
        "local radio = require('radio')\n"
        "local jigs = require('tests.jigs')\n"
        "\n"
        "jigs.TestCompositeBlock(radio.%s, {\n"
        "%s"
        "}, {epsilon = %.1e})\n",
    "TestVector":
        "    {\n"
        "        desc = \"%s\",\n"
        "        args = {%s},\n"
        "        inputs = {%s},\n"
        "        outputs = {%s}\n"
        "    },\n"
}


def generate_spec(spec):
    # We have to use spec.__class__.__name__ here because the spec namedtuple
    # is an instance of a different class in the unit test generator modules
    # (e.g. <class 'generate.BlockSpec'> instead of <class '__main__.BlockSpec'>)

    if spec.__class__.__name__ == "RawSpec":
        s = spec.content
    else:
        serialized_vectors = []
        for vector in spec.vectors:
            serialized_args = ", ".join([serialize(e) for e in vector.args])
            serialized_inputs = ", ".join([serialize(e) for e in vector.inputs])
            serialized_outputs = ", ".join([serialize(e) for e in vector.outputs])
            serialized_vectors.append(spec_templates[vector.__class__.__name__] % (vector.desc, serialized_args, serialized_inputs, serialized_outputs))
        s = spec_templates[spec.__class__.__name__] % (spec.name, "".join(serialized_vectors), spec.epsilon)

    with open(spec.filename, "w") as f:
        f.write(s)

if __name__ == "__main__":
    # Disable bytecode generation to keep the repository clean
    sys.dont_write_bytecode = True

    # Get list of unit test generator modules
    modules = glob.glob(os.path.dirname(os.path.realpath(__file__)) + "/**/*.py", recursive=True)
    modules = [m[len(os.path.dirname(os.path.realpath(__file__)) + "/"):] for m in modules]
    modules = [m for m in modules if m != os.path.basename(__file__)]
    modules = [m.replace("/", ".").strip(".py") for m in modules]

    # Run each unit test generator
    for module in modules:
        print(module)
        random.seed(1)
        generate_spec(__import__(module, fromlist=['']).generate())
