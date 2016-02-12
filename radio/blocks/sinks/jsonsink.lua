local block = require('radio.core.block')

local JSONSinkBlock = block.factory("JSONSinkBlock")

function JSONSinkBlock:instantiate()
    -- Accept all input types that implement to_json()
    self:add_type_signature({block.Input("in", function (type) return type.to_json ~= nil end)}, {})
end

function JSONSinkBlock:process(x)
    for i = 0, x.length-1 do
        io.stdout:write(x.data[i]:to_json() .. "\n")
    end
end

return {JSONSinkBlock = JSONSinkBlock}
