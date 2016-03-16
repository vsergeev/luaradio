local block = require('radio.core.block')
local types = require('radio.types')

local ComplexConjugateBlock = block.factory("ComplexConjugateBlock")

function ComplexConjugateBlock:instantiate()
    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)})
end

function ComplexConjugateBlock:process(x)
    local out = types.ComplexFloat32Type.vector(x.length)

    for i = 0, x.length-1 do
        out.data[i] = x.data[i]:conj()
    end

    return out
end

return {ComplexConjugateBlock = ComplexConjugateBlock}
