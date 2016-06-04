local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')
local filter_utils = require('radio.blocks.signal.filter_utils')

local FIRFilterBlock = require('radio.blocks.signal.firfilter')

local BandstopFilterBlock = block.factory("BandstopFilterBlock", FIRFilterBlock)

function BandstopFilterBlock:instantiate(num_taps, cutoffs, nyquist, window_type)
    FIRFilterBlock.instantiate(self, types.Float32.vector(num_taps))

    self.cutoffs = cutoffs
    self.window_type = (window_type == nil) and "hamming" or window_type
    self.nyquist = nyquist
end

function BandstopFilterBlock:initialize()
    -- Compute Nyquist frequency
    local nyquist = self.nyquist or (self:get_rate()/2)

    -- Generate and populate taps
    local cutoffs = {self.cutoffs[1]/nyquist, self.cutoffs[2]/nyquist}
    local real_taps = filter_utils.firwin_bandstop(self.taps.length, cutoffs, self.window_type)
    for i=0, self.taps.length-1 do
        self.taps.data[i].value = real_taps[i+1]
    end

    FIRFilterBlock.initialize(self)
end

return BandstopFilterBlock
