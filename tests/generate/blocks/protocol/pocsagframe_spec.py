import numpy
from generate import *


def generate():
    def test_vector_wrapper(frames):
        template = "require('radio.blocks.protocol.pocsagframe').POCSAGFrameType.vector_from_array({%s})"
        return [template % (','.join(frames))]

    def words_to_bits(words):
        bits = []
        for w in words:
            for i in range(32):
                bits.append(True if w & (1 << (31 - i)) else False)
        return bits

    #     0  1  2  3    4  5  6  7
    # F | II II AD DI | AD DD DD DD |
    # F | DI AD AD AI | II II AD DD |
    frame1_words = [0xaaaaaaaa] * 18 + [0x7cd215d8, 0x7a89c197, 0x7a89c197, 0x7a89c197, 0x7a89c197, 0x7e4b8585, 0xd43f30a9, 0xbd782239, 0x7a89c197, 0x486c4e00, 0xebceb7a1, 0xd9a474c5, 0xfde4633d, 0x95ecc6ce, 0xc7a66d1e, 0xd614e7c2, 0xac426ee5] + [0x7cd215d8, 0xa11078cc, 0x7a89c197, 0x3f3ab55e, 0xd3ffcef5, 0x57887b02, 0xf8cfc87b, 0x375a21cd, 0x7a89c197, 0x7a89c197, 0x7a89c197, 0x7a89c197, 0x7a89c197, 0x2de2fb1a, 0xa30da919, 0xf572a509, 0xf1e9fea1]
    frame1_objects = ["{0x1f92e2, 0, {0xa87e6, 0x7af04}}", "{0x121b14, 1, {0xd79d6, 0xb348e, 0xfbc8c, 0x2bd98, 0x8f4cd, 0xac29c, 0x5884d, 0x4220f}}", "{0xfcea9, 2, {0xa7ff9}}", "{0x15e21a, 3, {0xf19f9}}", "{0xdd68b, 0, {}}", "{0xb78be, 3, {0x461b5, 0xeae54, 0xe3d3f}}"]
    frame1_bits = words_to_bits(frame1_words)

    vectors = []

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(600)])
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects), "Valid frame"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(32), frame1_bits, random_bit(600)])
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects + frame1_objects), "Two valid frames"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(600)])
    x[20 + 100] = not x[20 + 100]
    x[20 + 201] = not x[20 + 201]
    x[20 + 300] = not x[20 + 300]
    x[20 + 401] = not x[20 + 301]
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects), "Frame with preamble bit errors"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(600)])
    x[20 + 576 + 32 * 6 + 7] = not x[20 + 576 + 32 * 6 + 7]
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects), "Frame with message bit error"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(600)])
    x[20 + 576 + 32 * 9 + 25] = not x[20 + 576 + 32 * 9 + 25]
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects), "Frame with crc bit error"))

    x = numpy.hstack([random_bit(20), frame1_bits, random_bit(600)])
    x[20 + 576 + 32 * 14 + 10] = not x[20 + 576 + 32 * 14 + 10]
    x[20 + 576 + 32 * 14 + 11] = not x[20 + 576 + 32 * 14 + 11]
    x[20 + 576 + 32 * 14 + 12] = not x[20 + 576 + 32 * 14 + 12]
    frame1_objects_cutoff = ["{0x1f92e2, 0, {0xa87e6, 0x7af04}}", "{0x121b14, 1, {0xd79d6, 0xb348e, 0xfbc8c, 0x2bd98}}", "{0xfcea9, 2, {0xa7ff9}}", "{0x15e21a, 3, {0xf19f9}}", "{0xdd68b, 0, {}}", "{0xb78be, 3, {0x461b5, 0xeae54, 0xe3d3f}}"]
    vectors.append(TestVector([], [x], test_vector_wrapper(frame1_objects_cutoff), "Frame with an uncorrectable bit error"))

    return BlockSpec("POCSAGFrameBlock", "tests/blocks/protocol/pocsagframe_spec.lua", vectors, 1e-6)
