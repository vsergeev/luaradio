import numpy
from generate import *


def generate():
    numpy_vectors = [
        # Format, numpy array, byteswap
        ("u8", numpy.array([random.randint(0, 255) for _ in range(256)], dtype=numpy.uint8), False),
        ("s8", numpy.array([random.randint(-128, 127) for _ in range(256)], dtype=numpy.int8), False),
        ("u16le", numpy.array([random.randint(0, 65535) for _ in range(256)], dtype=numpy.uint16), False),
        ("u16be", numpy.array([random.randint(0, 65535) for _ in range(256)], dtype=numpy.uint16), True),
        ("s16le", numpy.array([random.randint(-32768, 32767) for _ in range(256)], dtype=numpy.int16), False),
        ("s16be", numpy.array([random.randint(-32768, 32767) for _ in range(256)], dtype=numpy.int16), True),
        ("u32le", numpy.array([random.randint(0, 4294967295) for _ in range(256)], dtype=numpy.uint32), False),
        ("u32be", numpy.array([random.randint(0, 4294967295) for _ in range(256)], dtype=numpy.uint32), True),
        ("s32le", numpy.array([random.randint(-2147483648, 2147483647) for _ in range(256)], dtype=numpy.int32), False),
        ("s32be", numpy.array([random.randint(-2147483648, 2147483647) for _ in range(256)], dtype=numpy.int32), True),
        ("f32le", numpy.array(random_float32(256), dtype=numpy.float32), False),
        ("f32be", numpy.array(random_float32(256), dtype=numpy.float32), True),
        ("f64le", numpy.array(random_float32(256), dtype=numpy.float64), False),
        ("f64be", numpy.array(random_float32(256), dtype=numpy.float64), True),
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
        vectors.append(TestVector(["require('tests.buffer').open(\"%s\")" % buf, "\"%s\"" % fmt, 1], [], process(vector), "Data type %s, rate 1" % fmt))

    return BlockSpec("RealFileSource", vectors, 1e-6)
