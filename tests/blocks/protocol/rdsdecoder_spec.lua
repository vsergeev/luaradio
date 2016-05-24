local radio = require('radio')
local jigs = require('tests.jigs')

jigs.TestBlock(radio.RDSDecoderBlock, {
    {
        desc = "Basic Tuning Frame",
        args = {},
        inputs = {require('radio.blocks.protocol.rdsframer').RDSFrameType.vector_from_array({{{{0x3aab, 0x02ca, 0xe30a, 0x6963}}}})},
        outputs = {require('radio.blocks.protocol.rdsdecoder').RDSPacketType.vector_from_array({{{pi_code = 15019, tp_code = 0, group_code = 0, group_version = 0, pty_code = 22}, {text_data = 'ic', di_position = 1, text_address = 2, ms_code = 1, di_value = 0, af_code = {227, 10}, type = 'basictuning', ta_code = 0}}})}
    },
    {
        desc = "Radio Text Frame",
        args = {},
        inputs = {require('radio.blocks.protocol.rdsframer').RDSFrameType.vector_from_array({{{{0x3aab, 0x22c8, 0x2043, 0x616c}}}})},
        outputs = {require('radio.blocks.protocol.rdsdecoder').RDSPacketType.vector_from_array({{{pi_code = 15019, tp_code = 0, group_code = 2, group_version = 0, pty_code = 22}, {type = 'radiotext', text_data = ' Cal', text_address = 8, ab_flag = 0}}})}
    },
    {
        desc = "Datetime Frame",
        args = {},
        inputs = {require('radio.blocks.protocol.rdsframer').RDSFrameType.vector_from_array({{{{0x3aab, 0x42dd, 0xc11a, 0xd0ae}}}})},
        outputs = {require('radio.blocks.protocol.rdsdecoder').RDSPacketType.vector_from_array({{{pi_code = 15019, tp_code = 0, group_code = 4, group_version = 0, pty_code = 22}, {type = 'datetime', time = {offset = -7, hour = 13, minute = 2}, date = {day = 7, year = 2016, month = 4}}}})}
    },
    {
        desc = "Other Frame",
        args = {},
        inputs = {require('radio.blocks.protocol.rdsframer').RDSFrameType.vector_from_array({{{{0x3aab, 0x82c0, 0x18ed, 0x14fa}}}})},
        outputs = {require('radio.blocks.protocol.rdsdecoder').RDSPacketType.vector_from_array({{{pi_code = 15019, tp_code = 0, group_code = 8, group_version = 0, pty_code = 22}, {type = 'raw', frame = {15019,33472,6381,5370}}}})}
    },
}, {epsilon = 1.0e-06})
