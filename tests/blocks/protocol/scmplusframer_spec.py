import numpy
from generate import *


def generate():
    def test_vector_wrapper(frames):
        template = "require('radio.blocks.protocol.scmplusframer').SCMPlusFrameType.vector_from_array({%s})"
        return [template % (','.join(frames))]

    frame1_bits = numpy.array([0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 1], dtype=numpy.bool_)
    frame1_object = "{0x1e, 0xbc, 100169616, 169294, 0x0908, 0xcef1}"

    frame2_bits = numpy.array([0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0], dtype=numpy.bool_)
    frame2_object = "{0x1e, 0x9c, 91309068, 8438900, 0x1310, 0x419c}"

    frame3_bits = numpy.array([0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1], dtype=numpy.bool_)
    frame3_object = "{0x1e, 0x9c, 91307242, 3322100, 0x1510, 0x2549}"

    vectors = []

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object]), "Valid frame 1"))

    x = numpy.hstack([random_bit(20), frame2_bits, random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame2_object]), "Valid frame 2"))

    x = numpy.hstack([random_bit(20), frame3_bits, random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame3_object]), "Valid frame 3"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(20)])
    x[70] = not x[70]
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object]), "Frame 1 with message bit error"))

    x = numpy.hstack([random_bit(20), frame2_bits, random_bit(20)])
    x[140] = not x[140]
    vectors.append(TestVector([], [x], test_vector_wrapper([frame2_object]), "Frame 2 with crc bit error"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(20), frame2_bits, random_bit(20), frame3_bits, random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object, frame2_object, frame3_object]), "Three frames"))

    return BlockSpec("SCMPlusFramerBlock", vectors, 1e-6)
