---
-- Compute the argument (phase) of a complex-valued signal.
--
-- $$ y[n] = \text{arg}(x[n]) $$
-- $$ y[n] = \text{atan2}(\text{Im}(x[n]), \text{Re}(x[n])) $$
--
-- @category Math Operations
-- @block ComplexPhaseBlock
--
-- @signature in:ComplexFloat32 > out:Float32
--
-- @usage
-- local phase = radio.ComplexPhaseBlock()

local block = require('radio.core.block')
local types = require('radio.types')

local ComplexPhaseBlock = block.factory("ComplexPhaseBlock")

function ComplexPhaseBlock:instantiate()
    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
end

function ComplexPhaseBlock:initialize()
    self.out = types.Float32.vector()
end

function ComplexPhaseBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        out.data[i].value = x.data[i]:arg()
    end

    return out
end

return ComplexPhaseBlock
