local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')
local filter_utils = require('radio.blocks.signal.filter_utils')

local FIRFilterBlock = require('radio.blocks.signal.firfilter')

local BandpassFilterBlock = block.factory("BandpassFilterBlock", FIRFilterBlock)

function BandpassFilterBlock:instantiate(num_taps, cutoffs, nyquist, window_type)
    assert(num_taps, "Missing argument #1 (num_taps)")
    self.cutoffs = assert(cutoffs, "Missing argument #2 (cutoffs)")
    self.window_type = window_type or "hamming"
    self.nyquist = nyquist

    FIRFilterBlock.instantiate(self, types.Float32.vector(num_taps))
end

function BandpassFilterBlock:initialize()
    -- Compute Nyquist frequency
    local nyquist = self.nyquist or (self:get_rate()/2)

    -- Generate taps
    local cutoffs = {self.cutoffs[1]/nyquist, self.cutoffs[2]/nyquist}
    local taps = filter_utils.firwin_bandpass(self.taps.length, cutoffs, self.window_type)
    self.taps = types.Float32.vector_from_array(taps)

    FIRFilterBlock.initialize(self)
end

return BandpassFilterBlock
