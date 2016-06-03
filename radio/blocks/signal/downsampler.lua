local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local DownsamplerBlock = block.factory("DownsamplerBlock")

function DownsamplerBlock:instantiate(factor)
    self.factor = assert(factor, "Missing argument #1 (factor)")

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
end

function DownsamplerBlock:get_rate()
    return block.Block.get_rate(self)/self.factor
end

function DownsamplerBlock:initialize()
    self.index = 0
    self.out = self:get_input_type().vector()
end

function DownsamplerBlock:process(x)
    local out = self.out:resize(math.ceil((x.length - self.index)/self.factor))

    for i = 0, out.length-1 do
        out.data[i] = x.data[self.index]
        self.index = self.index + self.factor
    end

    self.index = self.index - x.length

    return out
end

return DownsamplerBlock
