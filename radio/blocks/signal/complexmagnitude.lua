local block = require('radio.core.block')
local types = require('radio.types')

local ComplexMagnitudeBlock = block.factory("ComplexMagnitudeBlock")

function ComplexMagnitudeBlock:instantiate()
    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.Float32Type)})
end

function ComplexMagnitudeBlock:process(x)
    local out = types.Float32Type.vector(x.length)

    for i = 0, x.length-1 do
        out.data[i].value = x.data[i]:abs()
    end

    return out
end

return ComplexMagnitudeBlock
