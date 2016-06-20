---
-- Demodulate a baseband, double-sideband amplitude modulated complex-valued
-- signal with an envelope detector.
--
-- $$ y[n] = \text{AMDemodulate}(x[n], \text{bandwidth}) $$
--
-- @category Demodulation
-- @block AMEnvelopeDemodulator
-- @tparam[opt=5e3] number bandwidth Bandwidth in Hz
--
-- @signature in:ComplexFloat32 > out:Float32
--
-- @usage
-- -- AM demodulator with 5 kHz bandwidth
-- local demod = radio.AMEnvelopeDemodulator(5e3)

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local AMEnvelopeDemodulator = block.factory("AMEnvelopeDemodulator", blocks.CompositeBlock)

function AMEnvelopeDemodulator:instantiate(bandwidth)
    blocks.CompositeBlock.instantiate(self)

    bandwidth = bandwidth or 5e3

    local am_demod = blocks.ComplexMagnitudeBlock()
    local dcr_filter = blocks.SinglepoleHighpassFilterBlock(100)
    local af_filter = blocks.LowpassFilterBlock(128, bandwidth)
    self:connect(am_demod, dcr_filter, af_filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", am_demod, "in")
    self:connect(self, "out", af_filter, "out")
end

return AMEnvelopeDemodulator
