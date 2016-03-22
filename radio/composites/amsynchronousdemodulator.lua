local block = require('radio.core.block')
local types = require('radio.types')

local CompositeBlock = require('radio.core.composite').CompositeBlock
local ComplexBandpassFilterBlock = require('radio.blocks.signal.complexbandpassfilter').ComplexBandpassFilterBlock
local PLLBlock = require('radio.blocks.signal.pll').PLLBlock
local MultiplyConjugateBlock = require('radio.blocks.signal.multiplyconjugate').MultiplyConjugateBlock
local ComplexToRealBlock = require('radio.blocks.signal.complextoreal').ComplexToRealBlock
local MultiplyConstantBlock = require('radio.blocks.signal.multiplyconstant').MultiplyConstantBlock
local LowpassFilterBlock = require('radio.blocks.signal.lowpassfilter').LowpassFilterBlock

local AMSynchronousDemodulator = block.factory("AMSynchronousDemodulator", CompositeBlock)

function AMSynchronousDemodulator:instantiate(ifreq, bandwidth, gain)
    CompositeBlock.instantiate(self)

    bandwidth = bandwidth or 5e3
    gain = gain or 1.0

    local rf_filter = ComplexBandpassFilterBlock(257, {ifreq - bandwidth, ifreq + bandwidth})
    local pll = PLLBlock(1000, ifreq - 100, ifreq + 100)
    local mixer = MultiplyConjugateBlock()
    local am_demod = ComplexToRealBlock()
    local af_gain = MultiplyConstantBlock(gain)
    local af_filter = LowpassFilterBlock(256, bandwidth)
    self:connect(rf_filter, pll)
    self:connect(rf_filter, 'out', mixer, 'in1')
    self:connect(pll, 'out', mixer, 'in2')
    self:connect(mixer, am_demod, af_gain, af_filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.Float32Type)})
    self:connect(self, "in", rf_filter, "in")
    self:connect(self, "out", af_filter, "out")
end

return {AMSynchronousDemodulator = AMSynchronousDemodulator}
