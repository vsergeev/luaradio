---
-- Modulate a real-valued signal into a baseband, single-sideband amplitude
-- modulated complex-valued signal.
--
-- $$ y[n] = \text{SSBModulate}(x[n], \text{sideband}, \text{bandwidth}) $$
--
-- @category Modulation
-- @block SSBModulator
-- @tparam string sideband Sideband, choice of "lsb" or "usb".
-- @tparam[opt=3e3] number bandwidth Bandwidth in Hz
--
-- @signature in:Float32 > out:ComplexFloat32
--
-- @usage
-- -- SSB LSB modulator with 3 kHz bandwidth
-- local mod = radio.SSBModulator("lsb", 3e3)

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local SSBModulator = block.factory("SSBModulator", blocks.CompositeBlock)

function SSBModulator:instantiate(sideband, bandwidth)
    blocks.CompositeBlock.instantiate(self)

    assert(sideband, "Missing argument #1 (sideband)")
    assert(sideband == "lsb" or sideband == "usb", "Sideband should be 'lsb' or 'usb'")
    bandwidth = bandwidth or 3e3

    local af_filter = blocks.LowpassFilterBlock(128, bandwidth)
    local hilbert = blocks.HilbertTransformBlock(129)
    local sb_filter = blocks.ComplexBandpassFilterBlock(129, (sideband == "lsb") and {-bandwidth, 0} or {0, bandwidth})

    if sideband == "lsb" then
        local conjugate = blocks.ComplexConjugateBlock()
        self:connect(af_filter, hilbert, conjugate, sb_filter)
    else
        self:connect(af_filter, hilbert, sb_filter)
    end

    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.ComplexFloat32)})
    self:connect(self, "in", af_filter, "in")
    self:connect(self, "out", sb_filter, "out")
end

return SSBModulator
