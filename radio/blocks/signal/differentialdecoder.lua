local block = require('radio.core.block')
local types = require('radio.types')

local DifferentialDecoderBlock = block.factory("DifferentialDecoderBlock")

function DifferentialDecoderBlock:instantiate(invert)
    self.invert = (invert == nil) and false or invert

    self.prev_bit = types.BitType(0)
    self:add_type_signature({block.Input("in", types.BitType)}, {block.Output("out", types.BitType)})
end

function DifferentialDecoderBlock:process(x)
    local out = types.BitType.vector(x.length)

    for i = 0, x.length-1 do
        if self.invert then
            out.data[i] = self.prev_bit:bxor(x.data[i]):bnot()
        else
            out.data[i] = self.prev_bit:bxor(x.data[i])
        end

        self.prev_bit = types.BitType(x.data[i].value)
    end

    return out
end

return {DifferentialDecoderBlock = DifferentialDecoderBlock}
