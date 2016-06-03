local block = require('radio.core.block')
local types = require('radio.types')

local SubtractBlock = block.factory("SubtractBlock")

function SubtractBlock:instantiate()
    self:add_type_signature({block.Input("in1", types.ComplexFloat32), block.Input("in2", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("in1", types.Float32), block.Input("in2", types.Float32)}, {block.Output("out", types.Float32)})
end

function SubtractBlock:initialize()
    self.data_type = self:get_input_type()
end

function SubtractBlock:process(x, y)
    local out = self.data_type.vector(x.length)
    for i = 0, x.length-1 do
        out.data[i] = x.data[i] - y.data[i]
    end
    return out
end

return SubtractBlock
