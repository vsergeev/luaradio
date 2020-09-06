import numpy
from generate import *


def generate():
    def test_vector_wrapper(frames):
        template = "require('radio.blocks.protocol.scmframer').SCMFrameType.vector_from_array({%s})"
        return [template % (','.join(frames))]

    frame1_bits = numpy.array([1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1], dtype=numpy.bool_)
    frame1_object = "{12, 42918012, 214050, 2, 0, 0, 0x3fd9}"

    frame2_bits = numpy.array([1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1], dtype=numpy.bool_)
    frame2_object = "{12, 65432515, 2584540, 3, 3, 1, 0x3945}"

    frame3_bits = numpy.array([1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1], dtype=numpy.bool_)
    frame3_object = "{3, 8923843, 10946663, 1, 2, 0, 0x3ed1}"

    vectors = []

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object]), "Valid frame 1"))

    x = numpy.hstack([random_bit(20), frame2_bits, random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame2_object]), "Valid frame 2"))

    x = numpy.hstack([random_bit(20), frame3_bits, random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame3_object]), "Valid frame 3"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(20)])
    x[60] = not x[60]
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object]), "Frame 1 with message bit error"))

    x = numpy.hstack([random_bit(20), frame2_bits, random_bit(20)])
    x[108] = not x[108]
    vectors.append(TestVector([], [x], test_vector_wrapper([frame2_object]), "Frame 2 with crc bit error"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(20), frame2_bits, random_bit(20), frame3_bits, random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object, frame2_object, frame3_object]), "Three frames"))

    return BlockSpec("SCMFramerBlock", vectors, 1e-6)
