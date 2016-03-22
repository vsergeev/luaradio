local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local WBFMMonoDemodulator = block.factory("WBFMMonoDemodulator", blocks.CompositeBlock)

function WBFMMonoDemodulator:instantiate(tau)
    blocks.CompositeBlock.instantiate(self)

    local tau = tau or 75e-6
    local bandwidth = 15e3

    local fm_demod = blocks.FrequencyDiscriminatorBlock(6.0)
    local af_filter = blocks.LowpassFilterBlock(128, bandwidth)
    local af_deemphasis = blocks.FMDeemphasisFilterBlock(tau)
    self:connect(fm_demod, af_filter, af_deemphasis)

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.Float32Type)})
    self:connect(self, "in", fm_demod, "in")
    self:connect(self, "out", af_deemphasis, "out")
end

return {WBFMMonoDemodulator = WBFMMonoDemodulator}
