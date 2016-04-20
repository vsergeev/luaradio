local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local DownsamplerBlock = block.factory("DownsamplerBlock")

function DownsamplerBlock:instantiate(factor)
    self.factor = factor
    self.index = 0

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)})
    self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)})
    self:add_type_signature({block.Input("in", types.Integer32Type)}, {block.Output("out", types.Integer32Type)})
end

function DownsamplerBlock:get_rate()
    return block.Block.get_rate(self)/self.factor
end

function DownsamplerBlock:initialize()
    self.data_type = self:get_input_types()[1]
end

function DownsamplerBlock:process(x)
    local out_len = math.ceil((x.length - self.index)/self.factor)
    local out = self.data_type.vector(out_len)

    for i = 0, out.length-1 do
        out.data[i] = x.data[self.index]
        self.index = self.index + self.factor
    end

    self.index = self.index - x.length
    return out
end

return DownsamplerBlock
