---
-- Filter a complex or real valued signal with a single-pole high-pass IIR
-- filter.
--
-- $$ H(s) = \frac{\tau s}{\tau s + 1} $$
--
-- $$ H(z) = \frac{2\tau f_s}{1 + 2\tau f_s} \frac{1 - z^{-1}}{1 + (\frac{1 - 2\tau f_s}{1 + 2\tau f_s}) z^{-1}} $$
--
-- $$ y[n] = \frac{2\tau f_s}{1 + 2\tau f_s} \; x[n] + \frac{2\tau f_s}{1 + 2\tau f_s} \; x[n-1] - \frac{1 - 2\tau f_s}{1 + 2\tau f_s} \; y[n-1] $$
--
-- @category Filtering
-- @block SinglepoleHighpassFilterBlock
-- @tparam number cutoff Cutoff frequency in Hz
--
-- @signature in:Float32 > out:Float32
-- @signature in:ComplexFloat32 > out:ComplexFloat32
--
-- @usage
-- -- Single-pole highpass filter with 100 Hz cutoff
-- local hpf = radio.SinglepoleHighpassFilterBlock(100)

local block = require('radio.core.block')
local types = require('radio.types')

local IIRFilterBlock = require('radio.blocks.signal.iirfilter')

local SinglepoleHighpassFilterBlock = block.factory("SinglepoleHighpassFilterBlock", IIRFilterBlock)

function SinglepoleHighpassFilterBlock:instantiate(cutoff)
    self.cutoff = assert(cutoff, "Missing argument #1 (cutoff)")

    IIRFilterBlock.instantiate(self, types.Float32.vector(2), types.Float32.vector(2))
end

--
-- Single-pole high-pass filter transfer function:
--     H(s) = (tau*s)/(tau*s + 1)
--
-- Bilinear transformed transfer function:
--     H(z) = (2*tau/T)/(1 + 2*tau/T) * (1 - z^-1) / (1 + ((1 - 2*tau/T)/(1 + 2*tau/T))*z^-1)
--
-- Difference equation:
--     y[n] + (1 - 2*tau/T)/(1 + 2*tau/T) y[n-1] = (2*tau/T)/(1 + 2*tau/T) x[n] - (2*tau/T)/(1 + 2*tau/T) x[n-1]
--     y[n] = (2*tau/T)/(1 + 2*tau/T) x[n] - (2*tau/T)/(1 + 2*tau/T) x[n-1] - (1 - 2*tau/T)/(1 + 2*tau/T) y[n-1]
--
-- Frequency warping:
--     omega = 1/tau
--     omega_warped = (2/T) tan(omega * (T/2))
--     tau_warped = 1/omega_warped
--     tau_warped = 1/(2/T * tan(T/(2*tau)))
--
-- b_taps = { (2*tau/T)/(1 + 2*tau/T), -(2*tau/T)/(1 + 2*tau/T) }
-- a_taps = { 1, ((1 - 2*tau/T)/(1 + 2*tau/T)) }
--
function SinglepoleHighpassFilterBlock:initialize()
    -- Warp tau
    local tau = 1/(2*math.pi*self.cutoff)
    tau = 1/(2*self:get_rate()*math.tan(1/(2*self:get_rate()*tau)))

    -- Populate taps
    self.b_taps.data[0].value = (2*tau*self:get_rate())/(1 + 2*tau*self:get_rate())
    self.b_taps.data[1].value = -(2*tau*self:get_rate())/(1 + 2*tau*self:get_rate())
    self.a_taps.data[0].value = 1
    self.a_taps.data[1].value = (1 - 2*tau*self:get_rate())/(1 + 2*tau*self:get_rate())

    IIRFilterBlock.initialize(self)
end

return SinglepoleHighpassFilterBlock
