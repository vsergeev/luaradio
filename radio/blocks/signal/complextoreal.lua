---
-- Decompose the real part of a complex-valued signal.
--
-- $$ y[n] = \text{Re}(x[n]) $$
--
-- @category Miscellaneous
-- @block ComplexToRealBlock
--
-- @signature in:ComplexFloat32 > out:Float32
--
-- @usage
-- local complextoreal = radio.ComplexToRealBlock()

local block = require('radio.core.block')
local types = require('radio.types')

local ComplexToRealBlock = block.factory("ComplexToRealBlock")

function ComplexToRealBlock:instantiate()
    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
end

function ComplexToRealBlock:initialize()
    self.out = types.Float32.vector()
end

function ComplexToRealBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        out.data[i].value = x.data[i].real
    end

    return out
end

return ComplexToRealBlock
