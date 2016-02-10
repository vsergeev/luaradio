local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local CompositeBlock = require('radio.core.composite').CompositeBlock
local LowpassFilterBlock = require('radio.blocks.signal.lowpassfilter').LowpassFilterBlock
local DownsamplerBlock = require('radio.blocks.signal.downsampler').DownsamplerBlock

local DecimatorBlock = block.factory("DecimatorBlock", CompositeBlock)

function DecimatorBlock:instantiate(bandwidth, decimation, options)
    CompositeBlock.instantiate(self)

    options = options or {}

    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {block.Output("out", ComplexFloat32Type)})

    local filter = LowpassFilterBlock(options.num_taps or 128, bandwidth)
    local downsampler = DownsamplerBlock(decimation)

    self:connect(self, "in", filter, "in")
    self:connect(filter, downsampler)
    self:connect(downsampler, "out", self, "out")
end

return {DecimatorBlock = DecimatorBlock}
