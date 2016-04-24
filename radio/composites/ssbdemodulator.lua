---
-- Demodulate a baseband, single-sideband amplitude modulated complex-valued
-- signal.
--
-- $$ y[n] = \text{SSBDemodulate}(x[n], \text{sideband}, \text{bandwidth}) $$
--
-- @category Demodulation
-- @block SSBDemodulator
-- @tparam string sideband Sideband, choice of "lsb" or "usb".
-- @tparam[opt=3e3] number bandwidth Bandwidth in Hz
--
-- @signature in:ComplexFloat32 > out:Float32
--
-- @usage
-- -- SSB LSB demodulator with 3 KHz bandwidth
-- local demod = radio.SSBDemodulator("lsb", 3e3)

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local SSBDemodulator = block.factory("SSBDemodulator", blocks.CompositeBlock)

function SSBDemodulator:instantiate(sideband, bandwidth)
    blocks.CompositeBlock.instantiate(self)

    assert(sideband, "Missing argument #1 (sideband)")
    assert(sideband == "lsb" or sideband == "usb", "Sideband should be 'lsb' or 'usb'")
    bandwidth = bandwidth or 3e3

    local sb_filter = blocks.ComplexBandpassFilterBlock(129, (sideband == "lsb") and {0, -bandwidth} or {0, bandwidth})
    local am_demod = blocks.ComplexToRealBlock()
    local af_filter = blocks.LowpassFilterBlock(128, bandwidth)
    self:connect(sb_filter, am_demod, af_filter)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
    self:connect(self, "in", sb_filter, "in")
    self:connect(self, "out", af_filter, "out")
end

return SSBDemodulator
