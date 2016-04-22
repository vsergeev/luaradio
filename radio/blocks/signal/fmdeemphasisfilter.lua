---
-- Filter a complex or real valued signal with an FM De-emphasis filter, a
-- single-pole low-pass IIR filter.
--
-- $$ y[n] = (x * h_{fmdeemph})[n] $$
--
-- @category Filtering
-- @block FMDeemphasisFilterBlock
-- @tparam number tau Time constant of filter
--
-- @signature in:Float32 > out:Float32
-- @signature in:ComplexFloat32 > out:ComplexFloat32
--
-- @usage
-- -- FM de-emphasis filter with 75uS time constant for the Americas
-- local fmdeemph = radio.FMDeemphasisFilterBlock(75e-6)

local block = require('radio.core.block')

local SinglepoleLowpassFilterBlock = require('radio.blocks.signal.singlepolelowpassfilter')

local FMDeemphasisFilterBlock = block.factory("FMDeemphasisFilterBlock", SinglepoleLowpassFilterBlock)

function FMDeemphasisFilterBlock:instantiate(tau)
    assert(tau, "Missing argument #1 (tau)")
    SinglepoleLowpassFilterBlock.instantiate(self, 1/(2*math.pi*tau))
end

return FMDeemphasisFilterBlock
