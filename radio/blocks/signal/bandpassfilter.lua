local ffi = require('ffi')

local block = require('radio.core.block')
local filter_utils = require('radio.blocks.signal.filter_utils')
local Float32Type = require('radio.types.float32').Float32Type
local FIRFilterBlock = require('radio.blocks.signal.firfilter').FIRFilterBlock

local BandpassFilterBlock = block.factory("BandpassFilterBlock", FIRFilterBlock)

function BandpassFilterBlock:instantiate(num_taps, cutoff_frequencies, window_type)
    FIRFilterBlock.instantiate(self, Float32Type.vector(num_taps))

    self.cutoff_frequencies = cutoff_frequencies
    self.window_type = (window_type == nil) and "hamming" or window_type
end

function BandpassFilterBlock:initialize()
    FIRFilterBlock.initialize(self)

    -- Generate and populate taps
    self.cutoff_frequencies = {(2*self.cutoff_frequencies[1])/self:get_rate(), (2*self.cutoff_frequencies[2])/self:get_rate()}
    local real_taps = filter_utils.firwin_bandpass(self.taps.length, self.cutoff_frequencies, self.window_type)
    for i=0, self.taps.length-1 do
        self.taps.data[i].value = real_taps[i+1]
    end
end

return {BandpassFilterBlock = BandpassFilterBlock}
