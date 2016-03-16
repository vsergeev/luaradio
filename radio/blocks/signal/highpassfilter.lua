local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')
local filter_utils = require('radio.blocks.signal.filter_utils')

local FIRFilterBlock = require('radio.blocks.signal.firfilter').FIRFilterBlock

local HighpassFilterBlock = block.factory("HighpassFilterBlock", FIRFilterBlock)

function HighpassFilterBlock:instantiate(num_taps, cutoff_frequency, window_type, nyquist_frequency)
    FIRFilterBlock.instantiate(self, types.Float32Type.vector(num_taps))

    self.cutoff_frequency = cutoff_frequency
    self.window_type = (window_type == nil) and "hamming" or window_type
    self.nyquist_frequency = nyquist_frequency
end

function HighpassFilterBlock:initialize()
    FIRFilterBlock.initialize(self)

    -- Compute Nyquist frequency
    local nyquist_frequency = self.nyquist_frequency or (self:get_rate()/2)

    -- Generate and populate taps
    local real_taps = filter_utils.firwin_highpass(self.taps.length, self.cutoff_frequency/nyquist_frequency, self.window_type)
    for i=0, self.taps.length-1 do
        self.taps.data[i].value = real_taps[i+1]
    end
end

return {HighpassFilterBlock = HighpassFilterBlock}
