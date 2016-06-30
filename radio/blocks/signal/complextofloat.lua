---
-- Decompose the real and imaginary parts of a complex-valued signal.
--
-- $$ y_{real}[n],\, y_{imag}[n] = \text{Re}(x[n]),\, \text{Im}(x[n]) $$
--
-- @category Type Conversion
-- @block ComplexToFloatBlock
--
-- @signature in:ComplexFloat32 > real:Float32, imag:Float32
--
-- @usage
-- local complextofloat = radio.ComplexToFloatBlock()

local block = require('radio.core.block')
local types = require('radio.types')

local ComplexToFloatBlock = block.factory("ComplexToFloatBlock")

function ComplexToFloatBlock:instantiate()
    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("real", types.Float32), block.Output("imag", types.Float32)})
end

function ComplexToFloatBlock:initialize()
    self.out_real = types.Float32.vector()
    self.out_imag = types.Float32.vector()
end

function ComplexToFloatBlock:process(x)
    local real = self.out_real:resize(x.length)
    local imag = self.out_imag:resize(x.length)

    for i = 0, x.length-1 do
        real.data[i].value = x.data[i].real
        imag.data[i].value = x.data[i].imag
    end

    return real, imag
end

return ComplexToFloatBlock
