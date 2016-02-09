local ffi = require('ffi')

local block = require('radio.core.block')
local filter_utils = require('radio.blocks.signal.filter_utils')
local Float32Type = require('radio.types.float32').Float32Type
local FIRFilterBlock = require('radio.blocks.signal.firfilter').FIRFilterBlock

local LowpassFilterBlock = block.factory("LowpassFilterBlock", FIRFilterBlock)

function LowpassFilterBlock:instantiate(num_taps, cutoff_frequency, window_type)
    FIRFilterBlock.instantiate(self, Float32Type.vector(num_taps))

    self.cutoff_frequency = cutoff_frequency
    self.window_type = (window_type == nil) and "hamming" or window_type
end

function LowpassFilterBlock:initialize()
    FIRFilterBlock.initialize(self)

    -- Generate and populate taps
    local real_taps = filter_utils.firwin_lowpass(self.taps.length, (2*self.cutoff_frequency)/self:get_rate(), self.window_type)
    for i=0, self.taps.length-1 do
        self.taps.data[i].value = real_taps[i+1]
    end
end

return {LowpassFilterBlock = LowpassFilterBlock}
