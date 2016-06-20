---
-- Demodulate a baseband, narrowband FM modulated complex-valued signal.
--
-- $$ y[n] = \text{NBFMDemodulate}(x[n], \text{deviation}, \text{bandwidth}) $$
--
-- The input signal will be band-limited by the specified deviation and
-- bandwidth with a cutoff frequency calculated by Carson's rule.
--
-- @category Demodulation
-- @block NBFMDemodulator
-- @tparam[opt=5e3] number deviation Deviation in Hz
-- @tparam[opt=4e3] number bandwidth Bandwidth in Hz
--
-- @signature in:ComplexFloat32 > out:Float32
--
-- @usage
-- -- NBFM demodulator with 5 kHz deviation and 4 kHz bandwidth
-- local demod = radio.NBFMDemodulator(5e3, 4e3)

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local NBFMDemodulator = block.factory("NBFMDemodulator", blocks.CompositeBlock)

function NBFMDemodulator:instantiate(deviation, bandwidth)
    blocks.CompositeBlock.instantiate(self)

    deviation = deviation or 5e3
    bandwidth = bandwidth or 4e3

    local rf_filter = blocks.LowpassFilterBlock(128, 2*(deviation + bandwidth)/2)
    local fm_demod = blocks.FrequencyDiscriminatorBlock(deviation/bandwidth)
    local af_filter = blocks.LowpassFilterBlock(128, bandwidth)
    self:connect(rf_filter, fm_demod, af_filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", rf_filter, "in")
    self:connect(self, "out", af_filter, "out")
end

return NBFMDemodulator
