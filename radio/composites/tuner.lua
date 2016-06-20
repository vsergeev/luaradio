---
-- Frequency translate, low-pass filter, and decimate a complex-valued signal.
-- This block reduces the sample rate for downstream blocks in the flow graph
-- by a factor of M.
--
-- $$ y[n] = (\text{FrequencyTranslate}(x[n], f_{offset}) * h_{lpf})[nM] $$
--
-- This block is convenient for translating signals to baseband and decimating
-- them.
--
-- @category Spectrum Manipulation
-- @block TunerBlock
-- @tparam number offset Translation offset in Hz
-- @tparam number bandwidth Signal bandwidth in Hz
-- @tparam int decimation Downsampling factor M
-- @tparam[opt={}] table options Additional options, specifying:
--                               * `num_taps` (int, default 128)
--                               * `window` (string, default "hamming")
--
-- @signature in:ComplexFloat32 > out:ComplexFloat32
--
-- @usage
-- -- Translate -100 kHz, filter 12 kHz, and decimate by 5
-- local tuner = radio.TunerBlock(-100e3, 12e3, 5)

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local TunerBlock = block.factory("TunerBlock", blocks.CompositeBlock)

function TunerBlock:instantiate(offset, bandwidth, decimation, options)
    blocks.CompositeBlock.instantiate(self)

    assert(offset, "Missing argument #1 (offset)")
    assert(bandwidth, "Missing argument #2 (bandwidth)")
    assert(decimation, "Missing argument #3 (decimation)")
    options = options or {}

    local translator = blocks.FrequencyTranslatorBlock(offset)
    local filter = blocks.LowpassFilterBlock(options.num_taps or 128, bandwidth/2, nil, options.window)
    local downsampler = blocks.DownsamplerBlock(decimation)
    self:connect(translator, filter, downsampler)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:connect(self, "in", translator, "in")
    self:connect(self, "out", downsampler, "out")
end

return TunerBlock
