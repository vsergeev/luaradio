---
-- Demodulate a baseband, wideband FM modulated complex-valued signal into the
-- real-valued mono channel (L+R) signal.
--
-- $$ y[n] = \text{WBFMMonoDemodulate}(x[n], \tau) $$
--
-- @category Demodulation
-- @block WBFMMonoDemodulator
-- @tparam[opt=75e-6] number tau FM de-emphasis time constant
--
-- @signature in:ComplexFloat32 > out:Float32
--
-- @usage
-- local demod = radio.WBFMMonoDemodulator()

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local WBFMMonoDemodulator = block.factory("WBFMMonoDemodulator", blocks.CompositeBlock)

function WBFMMonoDemodulator:instantiate(tau)
    blocks.CompositeBlock.instantiate(self)

    local tau = tau or 75e-6
    local bandwidth = 15e3

    local fm_demod = blocks.FrequencyDiscriminatorBlock(1.25)
    local af_filter = blocks.LowpassFilterBlock(128, bandwidth)
    local af_deemphasis = blocks.FMDeemphasisFilterBlock(tau)
    self:connect(fm_demod, af_filter, af_deemphasis)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", fm_demod, "in")
    self:connect(self, "out", af_deemphasis, "out")
end

return WBFMMonoDemodulator
