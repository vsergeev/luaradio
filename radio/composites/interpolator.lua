local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local InterpolatorBlock = block.factory("InterpolatorBlock", blocks.CompositeBlock)

function InterpolatorBlock:instantiate(interpolation, options)
    blocks.CompositeBlock.instantiate(self)

    options = options or {}

    local scaler = blocks.MultiplyConstantBlock(interpolation)
    local upsampler = blocks.UpsamplerBlock(interpolation)
    local filter = blocks.LowpassFilterBlock(options.num_taps or 128, 1/interpolation, options.window, 1.0)
    self:connect(scaler, upsampler, filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)})
    self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)})
    self:connect(self, "in", scaler, "in")
    self:connect(self, "out", filter, "out")
end

return {InterpolatorBlock = InterpolatorBlock}
