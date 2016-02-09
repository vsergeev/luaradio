local ffi = require('ffi')

local block = require('radio.core.block')
local filter_utils = require('radio.blocks.signal.filter_utils')
local Float32Type = require('radio.types.float32').Float32Type
local FIRFilterBlock = require('radio.blocks.signal.firfilter').FIRFilterBlock

local RootRaisedCosineFilterBlock = block.factory("RootRaisedCosineFilterBlock", FIRFilterBlock)

function RootRaisedCosineFilterBlock:instantiate(num_taps, beta, symbol_rate)
    FIRFilterBlock.instantiate(self, Float32Type.vector(num_taps))

    self.beta = beta
    self.symbol_rate = symbol_rate
end

function RootRaisedCosineFilterBlock:initialize()
    FIRFilterBlock.initialize(self)

    -- Generate and populate taps
    local real_taps = filter_utils.fir_root_raised_cosine(self.taps.length, self:get_rate(), self.beta, 1/self.symbol_rate)
    for i=0, self.taps.length-1 do
        self.taps.data[i].value = real_taps[i+1]
    end
end

return {RootRaisedCosineFilterBlock = RootRaisedCosineFilterBlock}
