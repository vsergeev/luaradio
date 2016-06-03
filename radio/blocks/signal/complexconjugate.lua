local block = require('radio.core.block')
local types = require('radio.types')

local ComplexConjugateBlock = block.factory("ComplexConjugateBlock")

function ComplexConjugateBlock:instantiate()
    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
end

function ComplexConjugateBlock:initialize()
    self.out = types.ComplexFloat32.vector()
end

function ComplexConjugateBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        out.data[i] = x.data[i]:conj()
    end

    return out
end

return ComplexConjugateBlock
