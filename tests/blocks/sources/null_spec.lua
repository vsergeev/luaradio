local radio = require('radio')
local jigs = require('tests.jigs')

jigs.TestSourceBlock(radio.NullSource, {
    {
        args = {},
        outputs = {radio.ComplexFloat32Type.vector(16384)}
    },
}, {epsilon = 1.0e-06})
