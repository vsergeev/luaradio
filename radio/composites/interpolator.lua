local block = require('radio.core.block')
local types = require('radio.types')

local CompositeBlock = require('radio.core.composite').CompositeBlock
local MultiplyConstantBlock = require('radio.blocks.signal.multiplyconstant').MultiplyConstantBlock
local UpsamplerBlock = require('radio.blocks.signal.upsampler').UpsamplerBlock
local LowpassFilterBlock = require('radio.blocks.signal.lowpassfilter').LowpassFilterBlock

local InterpolatorBlock = block.factory("InterpolatorBlock", CompositeBlock)

function InterpolatorBlock:instantiate(interpolation, options)
    CompositeBlock.instantiate(self)

    options = options or {}

    local scaler = MultiplyConstantBlock(interpolation)
    local upsampler = UpsamplerBlock(interpolation)
    local filter = LowpassFilterBlock(options.num_taps or 128, 1/interpolation, options.window, 1.0)
    self:connect(scaler, upsampler, filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)})
    self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)})
    self:connect(self, "in", scaler, "in")
    self:connect(self, "out", filter, "out")
end

return {InterpolatorBlock = InterpolatorBlock}
