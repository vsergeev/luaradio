local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local WBFMStereoDemodulator = block.factory("WBFMStereoDemodulator", blocks.CompositeBlock)

function WBFMStereoDemodulator:instantiate(tau)
    blocks.CompositeBlock.instantiate(self)

    local tau = tau or 75e-6
    local bandwidth = 15e3

    local fm_demod = blocks.FrequencyDiscriminatorBlock(6.0)
    local hilbert = blocks.HilbertTransformBlock(129)
    local delay = blocks.DelayBlock(129)
    local pilot_filter = blocks.ComplexBandpassFilterBlock(129, {18e3, 20e3})
    local pilot_pll = blocks.PLLBlock(100, 19e3-50, 19e3+50, 2)
    local mixer = blocks.MultiplyConjugateBlock()
    -- L+R
    local lpr_filter = blocks.LowpassFilterBlock(128, bandwidth)
    local lpr_am_demod = blocks.ComplexToRealBlock()
    -- L-R
    local lmr_filter = blocks.LowpassFilterBlock(128, bandwidth)
    local lmr_am_demod = blocks.ComplexToRealBlock()
    -- L
    local l_sum = blocks.AddBlock()
    local left_af_deemphasis = blocks.FMDeemphasisFilterBlock(tau)
    -- R
    local r_sub = blocks.SubtractBlock()
    local right_af_deemphasis = blocks.FMDeemphasisFilterBlock(tau)

    self:connect(fm_demod, hilbert)
    self:connect(hilbert, pilot_filter, pilot_pll)
    self:connect(hilbert, delay)
    self:connect(delay, 'out', mixer, 'in1')
    self:connect(pilot_pll, 'out', mixer, 'in2')
    self:connect(delay, lpr_filter, lpr_am_demod)
    self:connect(mixer, lmr_filter, lmr_am_demod)
    self:connect(lpr_am_demod, 'out', l_sum, 'in1')
    self:connect(lmr_am_demod, 'out', l_sum, 'in2')
    self:connect(lpr_am_demod, 'out', r_sub, 'in1')
    self:connect(lmr_am_demod, 'out', r_sub, 'in2')
    self:connect(l_sum, left_af_deemphasis)
    self:connect(r_sub, right_af_deemphasis)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("left", types.Float32), block.Output("right", types.Float32)})
    self:connect(self, "in", fm_demod, "in")
    self:connect(self, "left", left_af_deemphasis, "out")
    self:connect(self, "right", right_af_deemphasis, "out")
end

return WBFMStereoDemodulator
