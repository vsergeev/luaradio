---
-- Correlate a real valued signal with a matched filter of a pulse width of the
-- specified symbol rate. The resulting signal will have positive peaks at
-- positive pulses and negative peaks at negative pulses.
--
-- $$ y[n] = (x * h_{mf})[n] $$
--
-- $$ h_{-mf}[n] = \begin{cases} 1 & 0 \le n \lt T \\ 0 & \text{otherwise} \end{cases} $$
--
-- @category Filtering
-- @block PulseMatchedFilterBlock
-- @tparam number baudrate Symbol baudrate in Hz
-- @tparam[opt=false] bool invert Invert matched filter
--
-- @signature in:Float32 > out:Float32
--
-- @usage
-- -- Pulse matched filter with 32768 baudrate
-- local matched_filter = radio.PulseMatchedFilterBlock(32768)

local block = require('radio.core.block')
local types = require('radio.types')

local FIRFilterBlock = require('radio.blocks.signal.firfilter')

local PulseMatchedFilterBlock = block.factory("PulseMatchedFilterBlock", FIRFilterBlock)

function PulseMatchedFilterBlock:instantiate(baudrate, invert)
    self.baudrate = assert(baudrate, "Missing argument #1 (baudrate)")
    self.invert = invert or false

    -- Instantiate FIRFilterBlock with a dummy vector
    FIRFilterBlock.instantiate(self, types.Float32.vector(32))
end

function PulseMatchedFilterBlock:initialize()
    -- Generate taps
    local symbol_period = self:get_rate() / self.baudrate
    local taps = {}
    for i=1, symbol_period do
        taps[#taps + 1] = self.invert and -1 or 1
    end

    self.taps = types.Float32.vector_from_array(taps)

    FIRFilterBlock.initialize(self)
end

return PulseMatchedFilterBlock
