---
-- Decode a Manchester encoded bit stream.
--
-- $$ y[n] = \begin{cases} 0 & \text{for }\{0, 1\} \\ 1 & \text{for }\{1, 0\} \\ \text{slip input} & \text{otherwise} \end{cases} $$
--
-- @category Digital
-- @block ManchesterDecoderBlock
-- @tparam[opt=false] bool invert Invert the output.
--
-- @signature in:Bit > out:Bit
--
-- @usage
-- local manchester_decoder = radio.ManchesterDecoderBlock()

local block = require('radio.core.block')
local types = require('radio.types')

local ManchesterDecoderBlock = block.factory("ManchesterDecoderBlock")

function ManchesterDecoderBlock:instantiate(invert)
    self.invert = invert or false

    self:add_type_signature({block.Input("in", types.Bit)}, {block.Output("out", types.Bit)})
end

function ManchesterDecoderBlock:initialize()
    self.prev_bit = false
    self.out = types.Bit.vector()
end

function ManchesterDecoderBlock:process(x)
    local out = self.out:resize(0)

    local prev_bit = self.prev_bit

    for i = 0, x.length-1 do
        local cur_bit = x.data[i]

        if not prev_bit then
            prev_bit = cur_bit
        else
            if prev_bit.value == 0 and cur_bit.value == 1 then
                -- 0 to 1 transition
                out:append(types.Bit(self.invert and 1 or 0))
                prev_bit = false
            elseif prev_bit.value == 1 and cur_bit.value == 0 then
                -- 1 to 0 transition
                out:append(types.Bit(self.invert and 0 or 1))
                prev_bit = false
            else
                -- Clock slip
                prev_bit = cur_bit
            end
        end
    end

    -- Save a copy the left-over bit if there is one
    self.prev_bit = prev_bit and types.Bit(prev_bit.value)

    return out
end

return ManchesterDecoderBlock
