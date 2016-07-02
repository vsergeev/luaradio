---
-- Decimate a complex or real valued signal. This block band-limits and
-- downsamples the input signal. It reduces the sample rate for downstream
-- blocks in the flow graph by a factor of M.
--
-- $$ y[n] = (x * h_{lpf})[nM] $$
--
-- @category Sample Rate Manipulation
-- @block DecimatorBlock
-- @tparam int decimation Downsampling factor M
-- @tparam[opt={}] table options Additional options, specifying:
--                               * `num_taps` (int, default 128)
--                               * `window` (string, default "hamming")
--
-- @signature in:ComplexFloat32 > out:ComplexFloat32
-- @signature in:Float32 > out:Float32
--
-- @usage
-- -- Decimate by 5
-- local decimator = radio.DecimatorBlock(5)

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local DecimatorBlock = block.factory("DecimatorBlock", blocks.CompositeBlock)

function DecimatorBlock:instantiate(decimation, options)
    blocks.CompositeBlock.instantiate(self)

    assert(decimation, "Missing argument #1 (decimation)")
    options = options or {}

    local filter = blocks.LowpassFilterBlock(options.num_taps or 128, 1/decimation, 1.0, options.window)
    local downsampler = blocks.DownsamplerBlock(decimation)
    self:connect(filter, downsampler)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", filter, "in")
    self:connect(self, "out", downsampler, "out")
end

return DecimatorBlock
