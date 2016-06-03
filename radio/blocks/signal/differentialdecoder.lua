local block = require('radio.core.block')
local types = require('radio.types')

local DifferentialDecoderBlock = block.factory("DifferentialDecoderBlock")

function DifferentialDecoderBlock:instantiate(invert)
    self.invert = invert or false

    self:add_type_signature({block.Input("in", types.Bit)}, {block.Output("out", types.Bit)})
end

function DifferentialDecoderBlock:initialize()
    self.prev_bit = types.Bit(0)
    self.out = types.Bit.vector()
end

function DifferentialDecoderBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        if self.invert then
            out.data[i].value = (bit.bxor(self.prev_bit.value, x.data[i].value) + 1) % 2
        else
            out.data[i].value = bit.bxor(self.prev_bit.value, x.data[i].value)
        end

        self.prev_bit.value = x.data[i].value
    end

    return out
end

return DifferentialDecoderBlock
