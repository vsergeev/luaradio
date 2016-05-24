local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local AMEnvelopeDemodulator = block.factory("AMEnvelopeDemodulator", blocks.CompositeBlock)

function AMEnvelopeDemodulator:instantiate(bandwidth)
    blocks.CompositeBlock.instantiate(self)

    bandwidth = bandwidth or 5e3

    local am_demod = blocks.ComplexMagnitudeBlock()
    local af_filter = blocks.LowpassFilterBlock(128, bandwidth)
    self:connect(am_demod, af_filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", am_demod, "in")
    self:connect(self, "out", af_filter, "out")
end

return AMEnvelopeDemodulator
