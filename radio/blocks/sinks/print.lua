local block = require('radio.core.block')

local PrintSink = block.factory("PrintSink")

function PrintSink:instantiate()
    -- Accept all input types that implement __tostring()
    self:add_type_signature({block.Input("in", function (type) return type.__tostring ~= nil end)}, {})
end

function PrintSink:process(x)
    for i = 0, x.length-1 do
        print(x.data[i])
    end
end

return {PrintSink = PrintSink}
