---
-- Interpolate a complex or real valued signal. This block scales, band-limits,
-- and upsamples the input signal. It increases the sample rate for downstream
-- blocks in the flow graph by a factor of L.
--
-- $$ y'[n] = \begin{cases} Lx[n/L] & \text{for integer } n/L \\ 0 & \text{otherwise} \end{cases} $$
-- $$ y[n] = (y' * h_{lpf})[n] $$
--
-- @category Sample Rate Manipulation
-- @block InterpolatorBlock
-- @tparam int interpolation Upsampling factor L
-- @tparam[opt={}] table options Additional options, specifying:
--                               * `num_taps` (int, default 128)
--                               * `window` (string, default "hamming")
--
-- @signature in:ComplexFloat32 > out:ComplexFloat32
-- @signature in:Float32 > out:Float32
--
-- @usage
-- -- Interpolate by 5
-- local interpolator = radio.InterpolatorBlock(5)

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local InterpolatorBlock = block.factory("InterpolatorBlock", blocks.CompositeBlock)

function InterpolatorBlock:instantiate(interpolation, options)
    blocks.CompositeBlock.instantiate(self)

    assert(interpolation, "Missing argument #1 (interpolation)")
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
