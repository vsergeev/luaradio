local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local AMEnvelopeDemodulator = block.factory("AMEnvelopeDemodulator", blocks.CompositeBlock)

function AMEnvelopeDemodulator:instantiate(bandwidth, gain)
    blocks.CompositeBlock.instantiate(self)

    bandwidth = bandwidth or 5e3
    gain = gain or 1.0

    local am_demod = blocks.ComplexMagnitudeBlock()
    local af_gain = blocks.MultiplyConstantBlock(gain)
    local af_filter = blocks.LowpassFilterBlock(128, bandwidth)
    self:connect(am_demod, af_gain, af_filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.Float32Type)})
    self:connect(self, "in", am_demod, "in")
    self:connect(self, "out", af_filter, "out")
end

return AMEnvelopeDemodulator
