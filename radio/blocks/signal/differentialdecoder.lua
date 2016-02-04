local block = require('radio.core.block')
local BitType = require('radio.types.bit').BitType

local DifferentialDecoderBlock = block.factory("DifferentialDecoderBlock")

function DifferentialDecoderBlock:instantiate(threshold)
    self.prev_bit = BitType(0)
    self:add_type_signature({block.Input("in", BitType)}, {block.Output("out", BitType)})
end

function DifferentialDecoderBlock:process(x)
    local out = BitType.vector(x.length)

    for i = 0, x.length-1 do
        out.data[i] = self.prev_bit:bxor(x.data[i])
        self.prev_bit = BitType(x.data[i].value)
    end

    return out
end

return {DifferentialDecoderBlock = DifferentialDecoderBlock}
