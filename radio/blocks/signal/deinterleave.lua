---
-- Deinterleave a complex or real valued signal.
--
-- $$ y_1[n],\, y_2[n],\, ... = x[Nn+0],\, x[Nn+1],\, ... $$
--
-- @category Miscellaneous
-- @block DeinterleaveBlock
-- @tparam[opt=2] int num_channels Number of channels
--
-- @signature in:Float32 > out1:Float32, out2:Float32, ...
-- @signature in:ComplexFloat32 > out1:ComplexFloat32, out2:ComplexFloat32, ...
--
-- @usage
-- -- Deinterleave two channels
-- local deinterleaver = radio.DeinterleaveBlock()
--
-- -- Deinterleave four channels
-- local deinterleaver = radio.DeinterleaveBlock(4)

local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local DeinterleaveBlock = block.factory("DeinterleaveBlock")

function DeinterleaveBlock:instantiate(num_channels)
    self.num_channels = num_channels or 2
    assert(self.num_channels > 1, "Number of channels must be greater than 1")

    for _, input_type in ipairs({types.Float32, types.ComplexFloat32}) do
        local block_outputs = {}
        for i = 1, self.num_channels do
            block_outputs[i] = block.Output("out" .. i, input_type)
        end
        self:add_type_signature({block.Input("in", input_type)}, block_outputs)
    end
end

function DeinterleaveBlock:initialize()
    self.index = 0

    self.out_vectors = {}
    for i = 1, self.num_channels do
        self.out_vectors[i] = self:get_input_type().vector()
    end
end

function DeinterleaveBlock:process(x)
    local out_vectors = self.out_vectors

    for i = 1, self.num_channels do
        local offset = ((i-1) - self.index) % self.num_channels
        out_vectors[i]:resize(math.ceil((x.length - offset)/self.num_channels))

        for j = 0, out_vectors[i].length-1 do
            out_vectors[i].data[j] = x.data[self.num_channels*j + offset]
        end
    end

    self.index = (self.index + x.length) % self.num_channels

    return unpack(out_vectors)
end

return DeinterleaveBlock
