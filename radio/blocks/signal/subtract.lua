---
-- Subtract two complex or real valued signals.
--
-- $$ y[n] = x_{1}[n] - x_{2}[n] $$
--
-- @category Math Operations
-- @block SubtractBlock
--
-- @signature in1:ComplexFloat32, in2:ComplexFloat32 > out:ComplexFloat32
-- @signature in1:Float32, in2:Float32 > out:Float32
--
-- @usage
-- local subtractor = radio.SubtractBlock()
-- top:connect(src1, 'out', subtractor, 'in1')
-- top:connect(src2, 'out', subtractor, 'in2')
-- top:connect(subtractor, snk)

local block = require('radio.core.block')
local types = require('radio.types')

local SubtractBlock = block.factory("SubtractBlock")

function SubtractBlock:instantiate()
    self:add_type_signature({block.Input("in1", types.ComplexFloat32), block.Input("in2", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("in1", types.Float32), block.Input("in2", types.Float32)}, {block.Output("out", types.Float32)})
end

function SubtractBlock:initialize()
    self.out = self:get_output_type().vector()
end

function SubtractBlock:process(x, y)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        out.data[i] = x.data[i] - y.data[i]
    end

    return out
end

return SubtractBlock
