local block = require('radio.core.block')
local types = require('radio.types')

local CompositeBlock = require('radio.core.composite').CompositeBlock
local UpsamplerBlock = require('radio.blocks.signal.upsampler').UpsamplerBlock
local LowpassFilterBlock = require('radio.blocks.signal.lowpassfilter').LowpassFilterBlock

local InterpolatorBlock = block.factory("InterpolatorBlock", CompositeBlock)

function InterpolatorBlock:instantiate(bandwidth, interpolation, options)
    CompositeBlock.instantiate(self)
    options = options or {}

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)})
    self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)})

    local upsampler = UpsamplerBlock(interpolation)
    local filter = LowpassFilterBlock(options.num_taps or 128, bandwidth)

    self:connect(self, "in", upsampler, "in")
    self:connect(upsampler, filter)
    self:connect(filter, "out", self, "out")
end

return {InterpolatorBlock = InterpolatorBlock}
