local radio = require('radio')
local jigs = require('tests.jigs')

jigs.TestBlock(radio.POCSAGDecodeBlock, {
    {
        desc = "Alphanumeric Message",
        args = {"alphanumeric"},
        inputs = {require('radio.blocks.protocol.pocsagframe').POCSAGFrameType.vector_from_array({{12345, 2, {0x2f4f3, 0x9796e, 0xf9f40}}})},
        outputs = {require('radio.blocks.protocol.pocsagdecode').POCSAGMessageType.vector_from_array({{12345, 2, 'testing', nil}})}
    },
    {
        desc = "Alphanumeric Message",
        args = {"both"},
        inputs = {require('radio.blocks.protocol.pocsagframe').POCSAGFrameType.vector_from_array({{12345, 2, {0x2f4f3, 0x9796e, 0xf9f40}}})},
        outputs = {require('radio.blocks.protocol.pocsagdecode').POCSAGMessageType.vector_from_array({{12345, 2, 'testing', '2)4)39796()9)40'}})}
    },
    {
        desc = "Numeric Message",
        args = {"numeric"},
        inputs = {require('radio.blocks.protocol.pocsagframe').POCSAGFrameType.vector_from_array({{45678, 0, {0x86753, 0x09ccc}}})},
        outputs = {require('radio.blocks.protocol.pocsagdecode').POCSAGMessageType.vector_from_array({{45678, 0, nil, '8675309   '}})}
    },
}, {epsilon = 1.0e-06})
