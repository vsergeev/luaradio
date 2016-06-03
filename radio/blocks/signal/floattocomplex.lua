local block = require('radio.core.block')
local types = require('radio.types')

local FloatToComplexBlock = block.factory("FloatToComplexBlock")

function FloatToComplexBlock:instantiate()
    self:add_type_signature({block.Input("real", types.Float32), block.Input("imag", types.Float32)}, {block.Output("out", types.ComplexFloat32)})
end

function FloatToComplexBlock:initialize()
    self.out = types.ComplexFloat32.vector()
end

function FloatToComplexBlock:process(real, imag)
    local out = self.out:resize(real.length)

    for i = 0, real.length-1 do
        out.data[i].real = real.data[i].value
        out.data[i].imag = imag.data[i].value
    end

    return out
end

return FloatToComplexBlock
