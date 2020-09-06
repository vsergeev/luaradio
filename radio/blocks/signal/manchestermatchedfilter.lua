---
-- Correlate a real valued signal with a matched filter of a 1 to 0 pulse
-- transition. The resulting signal will have positive peaks at 1 to 0
-- transitions and negative peaks at 0 to 1 transitions, representing
-- Manchester coded one and zero data bits, respectively.
--
-- $$ y[n] = (x * h_{mf})[n] $$
--
-- $$ h_{-mf}[n] = \begin{cases} +1 & 0 \le n \lt T \\ -1 & T \le n \lt 2T \end{cases} $$
--
-- @category Filtering
-- @block ManchesterMatchedFilterBlock
-- @tparam number baudrate Baudrate of coded symbols in Hz
-- @tparam[opt=false] bool invert Invert matched filter
--
-- @signature in:Float32 > out:Float32
--
-- @usage
-- -- Manchester coded matched filter with 32768 baudrate
-- local matched_filter = radio.ManchesterMatchedFilterBlock(32768)

local block = require('radio.core.block')
local types = require('radio.types')

local FIRFilterBlock = require('radio.blocks.signal.firfilter')

local ManchesterMatchedFilterBlock = block.factory("ManchesterMatchedFilterBlock", FIRFilterBlock)

function ManchesterMatchedFilterBlock:instantiate(baudrate, invert)
    self.baudrate = assert(baudrate, "Missing argument #1 (baudrate)")
    self.invert = invert or false

    -- Instantiate FIRFilterBlock with a dummy vector
    FIRFilterBlock.instantiate(self, types.Float32.vector(32))
end

function ManchesterMatchedFilterBlock:initialize()
    -- Generate taps
    local symbol_period = self:get_rate() / self.baudrate
    local taps = {}
    for i=1, symbol_period do
        taps[#taps + 1] = self.invert and 1 or -1
    end
    for i=1, symbol_period do
        taps[#taps + 1] = self.invert and -1 or 1
    end

    self.taps = types.Float32.vector_from_array(taps)

    FIRFilterBlock.initialize(self)
end

return ManchesterMatchedFilterBlock
