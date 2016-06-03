local block = require('radio.core.block')
local types = require('radio.types')

local ComplexToImagBlock = block.factory("ComplexToImagBlock")

function ComplexToImagBlock:instantiate()
    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
end

function ComplexToImagBlock:initialize()
    self.out = types.Float32.vector()
end

function ComplexToImagBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        out.data[i].value = x.data[i].imag
    end

    return out
end

return ComplexToImagBlock
