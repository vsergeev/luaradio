---
-- Resample a complex or real valued signal by a rational factor. This block
-- band-limits and resamples the input signal. It changes the sample rate for
-- downstream blocks in the flow graph by a factor of L/M.
--
-- $$ y[n] = \text{Decimate}(\text{Interpolate}(x[n], L), M) $$
--
-- @category Sample Rate Manipulation
-- @block RationalResamplerBlock
-- @tparam int interpolation Upsampling factor L
-- @tparam int decimation Downsampling factor M
-- @tparam[opt={}] table options Additional options, specifying:
--                               * `num_taps` (int, default 128)
--                               * `window` (string, default "hamming")
--
-- @signature in:ComplexFloat32 > out:ComplexFloat32
-- @signature in:Float32 > out:Float32
--
-- @usage
-- -- Resample by 5/3
-- local resampler = radio.RationalResamplerBlock(5, 3)

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local RationalResamplerBlock = block.factory("RationalResamplerBlock", blocks.CompositeBlock)

function RationalResamplerBlock:instantiate(interpolation, decimation, options)
    blocks.CompositeBlock.instantiate(self)

    assert(interpolation, "Missing argument #1 (interpolation)")
    assert(decimation, "Missing argument #2 (decimation)")
    options = options or {}

    local cutoff = (1/interpolation < 1/decimation) and 1/interpolation or 1/decimation

    local scaler = blocks.MultiplyConstantBlock(interpolation)
    local upsampler = blocks.UpsamplerBlock(interpolation)
    local filter = blocks.LowpassFilterBlock(options.num_taps or 128, cutoff, 1.0, options.window)
    local downsampler = blocks.DownsamplerBlock(decimation)
    self:connect(scaler, upsampler, filter, downsampler)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", scaler, "in")
    self:connect(self, "out", downsampler, "out")
end

return RationalResamplerBlock
