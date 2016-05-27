local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local AMSynchronousDemodulator = block.factory("AMSynchronousDemodulator", blocks.CompositeBlock)

function AMSynchronousDemodulator:instantiate(ifreq, bandwidth)
    blocks.CompositeBlock.instantiate(self)

    assert(ifreq, "Missing argument #1 (ifreq)")
    bandwidth = bandwidth or 5e3

    local rf_filter = blocks.ComplexBandpassFilterBlock(129, {ifreq - bandwidth, ifreq + bandwidth})
    local pll = blocks.PLLBlock(1000, ifreq - 100, ifreq + 100)
    local mixer = blocks.MultiplyConjugateBlock()
    local am_demod = blocks.ComplexToRealBlock()
    local dcr_filter = blocks.SinglepoleHighpassFilterBlock(100)
    local af_filter = blocks.LowpassFilterBlock(128, bandwidth)
    self:connect(rf_filter, pll)
    self:connect(rf_filter, 'out', mixer, 'in1')
    self:connect(pll, 'out', mixer, 'in2')
    self:connect(mixer, am_demod, dcr_filter, af_filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", rf_filter, "in")
    self:connect(self, "out", af_filter, "out")
end

return AMSynchronousDemodulator
