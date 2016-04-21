local ffi = require('ffi')

local block = require('radio.core.block')
local filter_utils = require('radio.blocks.signal.filter_utils')
local types = require('radio.types')

local FIRFilterBlock = require('radio.blocks.signal.firfilter')

local ComplexBandstopFilterBlock = block.factory("ComplexBandstopFilterBlock", FIRFilterBlock)

function ComplexBandstopFilterBlock:instantiate(num_taps, cutoff_frequencies, window_type, nyquist_frequency)
    FIRFilterBlock.instantiate(self, types.ComplexFloat32.vector(num_taps))

    self.cutoff_frequencies = cutoff_frequencies
    self.window_type = (window_type == nil) and "hamming" or window_type
    self.nyquist_frequency = nyquist_frequency
end

function ComplexBandstopFilterBlock:initialize()
    -- Compute Nyquist frequency
    local nyquist_frequency = self.nyquist_frequency or (self:get_rate()/2)

    -- Generate and populate taps
    local cutoffs = {self.cutoff_frequencies[1]/nyquist_frequency, self.cutoff_frequencies[2]/nyquist_frequency}
    local taps = filter_utils.firwin_complex_bandstop(self.taps.length, cutoffs, self.window_type)
    self.taps = types.ComplexFloat32.vector_from_array(taps)

    FIRFilterBlock.initialize(self)
end

return ComplexBandstopFilterBlock
