local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local AbsoluteValueBlock = block.factory("AbsoluteValueBlock")

function AbsoluteValueBlock:instantiate()
    self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)})
end

function AbsoluteValueBlock:process(x)
    local out = types.Float32Type.vector(x.length)

    for i = 0, x.length-1 do
        out.data[i].value = math.abs(x.data[i].value)
    end

    return out
end

return {AbsoluteValueBlock = AbsoluteValueBlock}
