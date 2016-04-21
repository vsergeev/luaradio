local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')
local filter_utils = require('radio.blocks.signal.filter_utils')

local FIRFilterBlock = require('radio.blocks.signal.firfilter')

local RootRaisedCosineFilterBlock = block.factory("RootRaisedCosineFilterBlock", FIRFilterBlock)

function RootRaisedCosineFilterBlock:instantiate(num_taps, beta, symbol_rate)
    FIRFilterBlock.instantiate(self, types.Float32.vector(num_taps))

    self.beta = beta
    self.symbol_rate = symbol_rate
end

function RootRaisedCosineFilterBlock:initialize()
    -- Generate and populate taps
    local real_taps = filter_utils.fir_root_raised_cosine(self.taps.length, self:get_rate(), self.beta, 1/self.symbol_rate)
    for i=0, self.taps.length-1 do
        self.taps.data[i].value = real_taps[i+1]
    end

    FIRFilterBlock.initialize(self)
end

return RootRaisedCosineFilterBlock
