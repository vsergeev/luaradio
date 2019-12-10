import numpy
from generate import *


def generate():
    def test_vector_wrapper(frames):
        template = "require('radio.blocks.protocol.ax25framer').AX25FrameType.vector_from_array({%s})"
        return [template % (','.join(frames))]

    def bytes_to_stuffed_bits(data):
        bits = numpy.array([not not (b & (1 << i)) for b in data for i in range(8)], dtype=numpy.bool_)

        stuffed_bits = []
        ones_count = 0
        for i in range(8, len(bits) - 8):
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

    x = numpy.hstack([random_bit(20), bytes_to_stuffed_bits(frame1_data), [False, True, True, True, True, True, True, False] * 11, bytes_to_stuffed_bits(frame2_data), random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame1_object, frame2_object]), "Two valid frames with many flag fields in between"))

    x = numpy.hstack([random_bit(20), bytes_to_stuffed_bits(frame2_data), bytes_to_stuffed_bits(frame1_data), bytes_to_stuffed_bits(frame2_data), random_bit(20)])
    vectors.append(TestVector([], [x], test_vector_wrapper([frame2_object, frame1_object, frame2_object]), "Three back to back valid frames"))

    return BlockSpec("AX25FramerBlock", vectors, 1e-6)
