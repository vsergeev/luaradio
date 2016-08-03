---
-- Interleave a complex or real valued signal.
--
-- $$ y[n] = \left\{x_1[0],\, x_2[0],\, ...,\, x_N[0],\, x_1[1],\, x_2[1],\, ...,\, x_N[1],\, ...\right\} $$
--
-- @category Miscellaneous
-- @block InterleaveBlock
-- @tparam[opt=2] int num_channels Number of channels
--
-- @signature in1:Float32, in2:Float32, ... > out:Float32
-- @signature in1:ComplexFloat32, in2:ComplexFloat32, ... > out:ComplexFloat32
--
-- @usage
-- -- Interleave two channels
-- local interleaver = radio.InterleaveBlock()
--
-- -- Interleave four channels
-- local interleaver = radio.InterleaveBlock(4)

local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local InterleaveBlock = block.factory("InterleaveBlock")

function InterleaveBlock:instantiate(num_channels)
    self.num_channels = num_channels or 2
    assert(self.num_channels > 1, "Number of channels must be greater than 1")

    for _, input_type in ipairs({types.Float32, types.ComplexFloat32}) do
        local block_inputs = {}
        for i = 1, self.num_channels do
            block_inputs[i] = block.Input("in" .. i, input_type)
        end
        self:add_type_signature(block_inputs, {block.Output("out", input_type)})
    end
end

function InterleaveBlock:initialize()
    self.out = self:get_input_type().vector()
end

function InterleaveBlock:process(...)
    local inputs = {...}
    local out = self.out:resize(inputs[1].length*self.num_channels)

    for i = 0, inputs[1].length-1 do
        for j = 0, self.num_channels-1 do
            out.data[self.num_channels*i + j] = inputs[j+1].data[i]
        end
    end

    return out
end

return InterleaveBlock
