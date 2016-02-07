local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type
local Integer32Type = require('radio.types.integer32').Integer32Type

local SummerBlock = block.factory("SummerBlock")

function SummerBlock:instantiate()
    self:add_type_signature({block.Input("in1", ComplexFloat32Type), block.Input("in2", ComplexFloat32Type)}, {block.Output("out", ComplexFloat32Type)})
    self:add_type_signature({block.Input("in1", Float32Type), block.Input("in2", Float32Type)}, {block.Output("out", Float32Type)})
    self:add_type_signature({block.Input("in1", Integer32Type), block.Input("in2", Integer32Type)}, {block.Output("out", Integer32Type)})
end

function SummerBlock:initialize()
    self.data_type = self.signature.inputs[1].data_type
end

function SummerBlock:process(x, y)
    local out = self.data_type.vector(x.length)
    for i = 0, x.length-1 do
        out.data[i] = x.data[i] + y.data[i]
    end
    return out
end

return {SummerBlock = SummerBlock}
