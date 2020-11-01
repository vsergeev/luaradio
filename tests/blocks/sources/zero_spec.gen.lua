-- Do not edit! This file was generated by blocks/sources/zero_spec.py

local radio = require('radio')
local jigs = require('tests.jigs')

jigs.TestBlock(radio.ZeroSource, {
    {
        desc = "Data type ComplexFloat32, rate 1",
        args = {radio.types.ComplexFloat32, 1},
        inputs = {},
        outputs = {radio.types.ComplexFloat32.vector_from_array({{0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}, {0.00000000, 0.00000000}})}
    },
    {
        desc = "Data type Float32, rate 1",
        args = {radio.types.Float32, 1},
        inputs = {},
        outputs = {radio.types.Float32.vector_from_array({0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000, 0.00000000})}
    },
}, {epsilon = 1.0e-06})