import numpy
from generate import *


def generate():
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
