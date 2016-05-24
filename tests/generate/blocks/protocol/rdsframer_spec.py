import numpy
from generate import *


def generate():
    def test_vector_wrapper(frames):
        template = "require('radio.blocks.protocol.rdsframer').RDSFrameType.vector_from_array({%s})"
        return [template % (','.join(frames))]

    frame1_bits = numpy.array([0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0], dtype=numpy.bool_)
    frame1_object = "{{{0x3aab, 0x02c9, 0x0608, 0x6469}}}"

    frame2_bits = numpy.array([0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0], dtype=numpy.bool_)
    frame2_object = "{{{0x3aab, 0x82c8, 0x4849, 0x2918}}}"

    frame3_bits = numpy.array([0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0], dtype=numpy.bool_)
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

    return BlockSpec("RDSFramerBlock", "tests/blocks/protocol/rdsframer_spec.lua", vectors, 1e-6)
