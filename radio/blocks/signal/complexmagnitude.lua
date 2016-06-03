local block = require('radio.core.block')
local types = require('radio.types')

local ComplexMagnitudeBlock = block.factory("ComplexMagnitudeBlock")

function ComplexMagnitudeBlock:instantiate()
    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
end

function ComplexMagnitudeBlock:initialize()
    self.out = types.Float32.vector()
end

function ComplexMagnitudeBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        out.data[i].value = x.data[i]:abs()
    end

    return out
end

return ComplexMagnitudeBlock
