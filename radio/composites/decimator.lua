local block = require('radio.core.block')
local types = require('radio.types')

local CompositeBlock = require('radio.core.composite').CompositeBlock
local LowpassFilterBlock = require('radio.blocks.signal.lowpassfilter').LowpassFilterBlock
local DownsamplerBlock = require('radio.blocks.signal.downsampler').DownsamplerBlock

local DecimatorBlock = block.factory("DecimatorBlock", CompositeBlock)

function DecimatorBlock:instantiate(decimation, options)
    CompositeBlock.instantiate(self)

    options = options or {}

    local filter = LowpassFilterBlock(options.num_taps or 128, 1/decimation, options.window, 1.0)
    local downsampler = DownsamplerBlock(decimation)
    self:connect(filter, downsampler)

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)})
    self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)})
    self:connect(self, "in", filter, "in")
    self:connect(self, "out", downsampler, "out")
end

return {DecimatorBlock = DecimatorBlock}
