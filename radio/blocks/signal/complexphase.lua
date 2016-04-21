local block = require('radio.core.block')
local types = require('radio.types')

local ComplexPhaseBlock = block.factory("ComplexPhaseBlock")

function ComplexPhaseBlock:instantiate()
    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
end

function ComplexPhaseBlock:process(x)
    local out = types.Float32.vector(x.length)

    for i = 0, x.length-1 do
        out.data[i].value = x.data[i]:arg()
    end

    return out
end

return ComplexPhaseBlock
