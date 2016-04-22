---
-- Compose a complex-valued signal from a real-valued signal and a zero-valued
-- imaginary part.
--
-- $$ y[n] = x[n] + 0 \, j $$
--
-- @category Miscellaneous
-- @block RealToComplexBlock
--
-- @signature in:Float32 > out:ComplexFloat32
--
-- @usage
-- local realtocomplex = radio.RealToComplexBlock()

local block = require('radio.core.block')
local types = require('radio.types')

local RealToComplexBlock = block.factory("RealToComplexBlock")

function RealToComplexBlock:instantiate()
    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.ComplexFloat32)})
end

function RealToComplexBlock:initialize()
    self.out = types.ComplexFloat32.vector()
end

function RealToComplexBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        out.data[i].real = x.data[i].value
    end

    return out
end

return RealToComplexBlock
