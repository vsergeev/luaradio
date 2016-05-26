local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local InterpolatorBlock = block.factory("InterpolatorBlock", blocks.CompositeBlock)

function InterpolatorBlock:instantiate(interpolation, options)
    blocks.CompositeBlock.instantiate(self)

    options = options or {}

    local scaler = blocks.MultiplyConstantBlock(interpolation)
    local upsampler = blocks.UpsamplerBlock(interpolation)
    local filter = blocks.LowpassFilterBlock(options.num_taps or 128, 1/interpolation, 1.0, options.window)
    self:connect(scaler, upsampler, filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", scaler, "in")
    self:connect(self, "out", filter, "out")
end

return InterpolatorBlock
