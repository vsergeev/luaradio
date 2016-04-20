local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local RationalResamplerBlock = block.factory("RationalResamplerBlock", blocks.CompositeBlock)

function RationalResamplerBlock:instantiate(interpolation, decimation, options)
    blocks.CompositeBlock.instantiate(self)

    options = options or {}

    local cutoff = (1/interpolation < 1/decimation) and 1/interpolation or 1/decimation

    local scaler = blocks.MultiplyConstantBlock(interpolation)
    local upsampler = blocks.UpsamplerBlock(interpolation)
    local filter = blocks.LowpassFilterBlock(options.num_taps or 128, cutoff, options.window, 1.0)
    local downsampler = blocks.DownsamplerBlock(decimation)
    self:connect(scaler, upsampler, filter, downsampler)

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)})
    self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)})
    self:connect(self, "in", scaler, "in")
    self:connect(self, "out", downsampler, "out")
end

return RationalResamplerBlock
