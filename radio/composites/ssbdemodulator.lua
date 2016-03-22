local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local SSBDemodulator = block.factory("SSBDemodulator", blocks.CompositeBlock)

function SSBDemodulator:instantiate(sideband, bandwidth, gain)
    blocks.CompositeBlock.instantiate(self)

    assert(sideband == "lsb" or sideband == "usb", "Sideband should be 'lsb' or 'usb'.")
    bandwidth = bandwidth or 5e3
    gain = gain or 1.0

    local sb_filter = blocks.ComplexBandpassFilterBlock(257, (sideband == "lsb") and {0, -bandwidth} or {0, bandwidth})
    local am_demod = blocks.ComplexToRealBlock()
    local af_gain = blocks.MultiplyConstantBlock(gain)
    local af_filter = blocks.LowpassFilterBlock(256, bandwidth)
    self:connect(sb_filter, am_demod, af_gain, af_filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.Float32Type)})
    self:connect(self, "in", sb_filter, "in")
    self:connect(self, "out", af_filter, "out")
end

return {SSBDemodulator = SSBDemodulator}
