---
-- Filter a complex or real valued signal with an FM Pre-emphasis filter, a
-- single-pole high-pass IIR filter.
--
-- $$ y[n] = (x * h_{fmpreemph})[n] $$
--
-- @category Filtering
-- @block FMPreemphasisFilterBlock
-- @tparam number tau Time constant of filter
--
-- @signature in:Float32 > out:Float32
-- @signature in:ComplexFloat32 > out:ComplexFloat32
--
-- @usage
-- -- FM pre-emphasis filter with 75uS time constant for the Americas
-- local fmpreemph = radio.FMPreemphasisFilterBlock(75e-6)

local block = require('radio.core.block')

local SinglepoleHighpassFilterBlock = require('radio.blocks.signal.singlepolehighpassfilter')

local FMPreemphasisFilterBlock = block.factory("FMPreemphasisFilterBlock", SinglepoleHighpassFilterBlock)

function FMPreemphasisFilterBlock:instantiate(tau)
    assert(tau, "Missing argument #1 (tau)")
    SinglepoleHighpassFilterBlock.instantiate(self, 1/(2*math.pi*tau))
end

return FMPreemphasisFilterBlock
