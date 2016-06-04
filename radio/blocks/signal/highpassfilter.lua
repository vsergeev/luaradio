local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')
local filter_utils = require('radio.blocks.signal.filter_utils')

local FIRFilterBlock = require('radio.blocks.signal.firfilter')

local HighpassFilterBlock = block.factory("HighpassFilterBlock", FIRFilterBlock)

function HighpassFilterBlock:instantiate(num_taps, cutoff, nyquist, window_type)
    FIRFilterBlock.instantiate(self, types.Float32.vector(num_taps))

    self.cutoff = cutoff
    self.window_type = (window_type == nil) and "hamming" or window_type
    self.nyquist = nyquist
end

function HighpassFilterBlock:initialize()
    -- Compute Nyquist frequency
    local nyquist = self.nyquist or (self:get_rate()/2)

    -- Generate and populate taps
    local real_taps = filter_utils.firwin_highpass(self.taps.length, self.cutoff/nyquist, self.window_type)
    for i=0, self.taps.length-1 do
        self.taps.data[i].value = real_taps[i+1]
    end

    FIRFilterBlock.initialize(self)
end

return HighpassFilterBlock
