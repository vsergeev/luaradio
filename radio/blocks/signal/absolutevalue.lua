---
-- Compute the absolute value of a real-valued signal.
--
-- $$ y[n] = \text{abs}(x[n]) $$
--
-- @category Math Operations
-- @block AbsoluteValueBlock
-- @signature in:Float32 > out:Float32
--
-- @usage
-- local abs = radio.AbsoluteValueBlock()

local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local AbsoluteValueBlock = block.factory("AbsoluteValueBlock")

function AbsoluteValueBlock:instantiate()
    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
end

function AbsoluteValueBlock:initialize()
    self.out = types.Float32.vector()
end

function AbsoluteValueBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        out.data[i].value = math.abs(x.data[i].value)
    end

    return out
end

return AbsoluteValueBlock
