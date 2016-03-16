local block = require('radio.core.block')
local types = require('radio.types')

local CompositeBlock = require('radio.core.composite').CompositeBlock
local MultiplyConstantBlock = require('radio.blocks.signal.multiplyconstant').MultiplyConstantBlock
local UpsamplerBlock = require('radio.blocks.signal.upsampler').UpsamplerBlock
local LowpassFilterBlock = require('radio.blocks.signal.lowpassfilter').LowpassFilterBlock
local DownsamplerBlock = require('radio.blocks.signal.downsampler').DownsamplerBlock

local RationalResamplerBlock = block.factory("RationalResamplerBlock", CompositeBlock)

function RationalResamplerBlock:instantiate(interpolation, decimation, options)
    CompositeBlock.instantiate(self)
    options = options or {}

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)})
    self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)})

    local cutoff = (1/interpolation < 1/decimation) and 1/interpolation or 1/decimation

    local scaler = MultiplyConstantBlock(interpolation)
    local upsampler = UpsamplerBlock(interpolation)
    local filter = LowpassFilterBlock(options.num_taps or 128, cutoff, options.window, 1.0)
    local downsampler = DownsamplerBlock(decimation)

    self:connect(self, "in", scaler, "in")
    self:connect(scaler, upsampler, filter, downsampler)
    self:connect(downsampler, "out", self, "out")
end

return {RationalResamplerBlock = RationalResamplerBlock}
