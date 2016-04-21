local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local NBFMDemodulator = block.factory("NBFMDemodulator", blocks.CompositeBlock)

function NBFMDemodulator:instantiate(deviation, bandwidth)
    blocks.CompositeBlock.instantiate(self)

    deviation = deviation or 5e3
    bandwidth = bandwidth or 4e3

    local rf_filter = blocks.LowpassFilterBlock(128, 2*(deviation + bandwidth)/2)
    local fm_demod = blocks.FrequencyDiscriminatorBlock(5.0)
    local af_filter = blocks.LowpassFilterBlock(128, bandwidth)
    self:connect(rf_filter, fm_demod, af_filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", rf_filter, "in")
    self:connect(self, "out", af_filter, "out")
end

return NBFMDemodulator
