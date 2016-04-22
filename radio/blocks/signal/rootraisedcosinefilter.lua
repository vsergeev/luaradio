---
-- Filter a complex or real valued signal with an FIR approximation of a root
-- raised cosine filter.
--
-- $$ y[n] = (x * h_{rrc})[n] $$
--
-- @category Filtering
-- @block RootRaisedCosineFilterBlock
-- @tparam int num_taps Number of FIR taps, must be odd
-- @tparam number beta Roll-off factor
-- @tparam number symbol_rate Symbol rate in Hz
--
-- @signature in:ComplexFloat32 > out:ComplexFloat32
-- @signature in:Float32 > out:Float32
--
-- @usage
-- -- Root raised cosine filter with 101 taps, 1.0 beta, 1187.5 symbol rate
-- local rrcfilter = radio.RootRaisedCosineFilterBlock(101, 1.0, 1187.5)

local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')
local filter_utils = require('radio.blocks.signal.filter_utils')

local FIRFilterBlock = require('radio.blocks.signal.firfilter')

local RootRaisedCosineFilterBlock = block.factory("RootRaisedCosineFilterBlock", FIRFilterBlock)

function RootRaisedCosineFilterBlock:instantiate(num_taps, beta, symbol_rate)
    assert(num_taps, "Missing argument #1 (num_taps)")
    self.beta = assert(beta, "Missing argument #2 (beta)")
    self.symbol_rate = assert(symbol_rate, "Missing argument #3 (symbol_rate)")

    FIRFilterBlock.instantiate(self, types.Float32.vector(num_taps))
end

function RootRaisedCosineFilterBlock:initialize()
    -- Generate taps
    local taps = filter_utils.fir_root_raised_cosine(self.taps.length, self:get_rate(), self.beta, 1/self.symbol_rate)
    self.taps = types.Float32.vector_from_array(taps)

    FIRFilterBlock.initialize(self)
end

return RootRaisedCosineFilterBlock
