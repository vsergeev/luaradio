local math = require('math')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type
local Integer32Type = require('radio.types.integer32').Integer32Type

local DownsamplerBlock = block.factory("DownsamplerBlock")

function DownsamplerBlock:instantiate(factor)
    self.factor = factor
    self._index = 0

    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {block.Output("out", ComplexFloat32Type)})
    self:add_type_signature({block.Input("in", Float32Type)}, {block.Output("out", Float32Type)})
    self:add_type_signature({block.Input("in", Integer32Type)}, {block.Output("out", Integer32Type)})
end

function DownsamplerBlock:get_rate()
    return self.inputs[1].pipe:get_rate()/self.factor
end

function DownsamplerBlock:initialize()
    self.data_type = self.signature.inputs[1].data_type
end

function DownsamplerBlock:process(x)
    local out_len = math.ceil((x.length - self._index)/self.factor)
    local out = self.data_type.vector(out_len)

    for i = 0, out.length-1 do
        out.data[i] = x.data[self._index]
        self._index = self._index + self.factor
    end

    self._index = self._index - x.length
    return out
end

return {DownsamplerBlock = DownsamplerBlock}
