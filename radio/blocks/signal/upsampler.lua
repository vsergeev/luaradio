local block = require('radio.core.block')
local types = require('radio.types')

local UpsamplerBlock = block.factory("UpsamplerBlock")

function UpsamplerBlock:instantiate(factor)
    self.factor = factor

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
    self:add_type_signature({block.Input("in", types.Integer32)}, {block.Output("out", types.Integer32)})
end

function UpsamplerBlock:get_rate()
    return block.Block.get_rate(self)*self.factor
end

function UpsamplerBlock:initialize()
    self.data_type = self:get_input_types()[1]
end

function UpsamplerBlock:process(x)
    local out = self.data_type.vector(x.length*self.factor)

    for i = 0, x.length-1 do
        out.data[i*self.factor] = x.data[i]
    end

    return out
end

return UpsamplerBlock
