local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local DecimatorBlock = block.factory("DecimatorBlock", blocks.CompositeBlock)

function DecimatorBlock:instantiate(decimation, options)
    blocks.CompositeBlock.instantiate(self)

    options = options or {}

    local filter = blocks.LowpassFilterBlock(options.num_taps or 128, 1/decimation, options.window, 1.0)
    local downsampler = blocks.DownsamplerBlock(decimation)
    self:connect(filter, downsampler)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", filter, "in")
    self:connect(self, "out", downsampler, "out")
end

return DecimatorBlock
