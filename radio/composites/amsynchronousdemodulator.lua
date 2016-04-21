local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local AMSynchronousDemodulator = block.factory("AMSynchronousDemodulator", blocks.CompositeBlock)

function AMSynchronousDemodulator:instantiate(ifreq, bandwidth, gain)
    blocks.CompositeBlock.instantiate(self)

    bandwidth = bandwidth or 5e3
    gain = gain or 1.0

    local rf_filter = blocks.ComplexBandpassFilterBlock(257, {ifreq - bandwidth, ifreq + bandwidth})
    local pll = blocks.PLLBlock(1000, ifreq - 100, ifreq + 100)
    local mixer = blocks.MultiplyConjugateBlock()
    local am_demod = blocks.ComplexToRealBlock()
    local af_gain = blocks.MultiplyConstantBlock(gain)
    local af_filter = blocks.LowpassFilterBlock(256, bandwidth)
    self:connect(rf_filter, pll)
    self:connect(rf_filter, 'out', mixer, 'in1')
    self:connect(pll, 'out', mixer, 'in2')
    self:connect(mixer, am_demod, af_gain, af_filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", rf_filter, "in")
    self:connect(self, "out", af_filter, "out")
end

return AMSynchronousDemodulator
