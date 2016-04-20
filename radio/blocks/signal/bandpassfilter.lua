local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')
local filter_utils = require('radio.blocks.signal.filter_utils')

local FIRFilterBlock = require('radio.blocks.signal.firfilter')

local BandpassFilterBlock = block.factory("BandpassFilterBlock", FIRFilterBlock)

function BandpassFilterBlock:instantiate(num_taps, cutoff_frequencies, window_type, nyquist_frequency)
    FIRFilterBlock.instantiate(self, types.Float32Type.vector(num_taps))

    self.cutoff_frequencies = cutoff_frequencies
    self.window_type = (window_type == nil) and "hamming" or window_type
    self.nyquist_frequency = nyquist_frequency
end

function BandpassFilterBlock:initialize()
    -- Compute Nyquist frequency
    local nyquist_frequency = self.nyquist_frequency or (self:get_rate()/2)

    -- Generate and populate taps
    local cutoffs = {self.cutoff_frequencies[1]/nyquist_frequency, self.cutoff_frequencies[2]/nyquist_frequency}
    local real_taps = filter_utils.firwin_bandpass(self.taps.length, cutoffs, self.window_type)
    for i=0, self.taps.length-1 do
        self.taps.data[i].value = real_taps[i+1]
    end

    FIRFilterBlock.initialize(self)
end

return BandpassFilterBlock
