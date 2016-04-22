---
-- Slice a real-valued signal on a threshold into a bit stream.
--
-- $$ y[n] = \begin{cases} 1 & \text{if } x[n] > \text{threshold} \\ 0 & \text{if } x[n] < \text{threshold} \end{cases} $$
--
-- @category Digital
-- @block SlicerBlock
-- @tparam[opt=0.0] number threshold Threshold
--
-- @signature in:Float32 > out:Bit
--
-- @usage
-- -- Slice at default threshold 0.0
-- local slicer = radio.SlicerBlock()
--
-- -- Slice at threshold 0.5
-- local slicer = radio.SlicerBlock(0.5)

local block = require('radio.core.block')
local types = require('radio.types')

local SlicerBlock = block.factory("SlicerBlock")

function SlicerBlock:instantiate(threshold)
    self.threshold = threshold or 0.0

    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Bit)})
end

function SlicerBlock:initialize()
    self.out = types.Bit.vector()
end

function SlicerBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        out.data[i].value = (x.data[i].value > self.threshold) and 1 or 0
    end

    return out
end

return SlicerBlock
