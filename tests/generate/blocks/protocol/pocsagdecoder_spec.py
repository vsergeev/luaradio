import numpy
from generate import *


def generate():
    def test_vector_wrapper(messages):
        template = "require('radio.blocks.protocol.pocsagdecoder').POCSAGMessageType.vector_from_array({%s})"
        return [template % (','.join(messages))]

    frame1 = "require('radio.blocks.protocol.pocsagframer').POCSAGFrameType.vector_from_array({{12345, 2, {0x2f4f3, 0x9796e, 0xf9f40}}})"
    message1 = "{12345, 2, 'testing', nil}"
    message1_both = "{12345, 2, 'testing', '2)4)39796()9)40'}"

    frame2 = "require('radio.blocks.protocol.pocsagframer').POCSAGFrameType.vector_from_array({{45678, 0, {0x86753, 0x09ccc}}})"
    message2 = "{45678, 0, nil, '8675309   '}"

    vectors = []

    vectors.append(TestVector(['"alphanumeric"'], [frame1], test_vector_wrapper([message1]), "Alphanumeric Message"))
    vectors.append(TestVector(['"both"'], [frame1], test_vector_wrapper([message1_both]), "Alphanumeric Message"))
    vectors.append(TestVector(['"numeric"'], [frame2], test_vector_wrapper([message2]), "Numeric Message"))

    return BlockSpec("POCSAGDecoderBlock", vectors, 1e-6)
