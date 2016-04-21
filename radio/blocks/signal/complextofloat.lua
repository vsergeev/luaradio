local block = require('radio.core.block')
local types = require('radio.types')

local ComplexToFloatBlock = block.factory("ComplexToFloatBlock")

function ComplexToFloatBlock:instantiate()
    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("real", types.Float32), block.Output("imag", types.Float32)})
end

function ComplexToFloatBlock:process(x)
    local real = types.Float32.vector(x.length)
    local imag = types.Float32.vector(x.length)

    for i = 0, x.length-1 do
        real.data[i].value = x.data[i].real
        imag.data[i].value = x.data[i].imag
    end

    return real, imag
end

return ComplexToFloatBlock
