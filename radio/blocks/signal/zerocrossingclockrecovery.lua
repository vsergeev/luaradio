local block = require('radio.core.block')
local types = require('radio.types')

local ZeroCrossingClockRecoveryBlock = block.factory("ZeroCrossingClockRecoveryBlock")

function ZeroCrossingClockRecoveryBlock:instantiate(baudrate, threshold)
    self.baudrate = assert(baudrate, "Missing argument #1 (baudrate)")
    self.threshold = threshold or 0.0

    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
end

function ZeroCrossingClockRecoveryBlock:initialize()
    self.hysteresis = false
    self.symbol_period = self:get_rate() / self.baudrate
    self.sample_offset = self.symbol_period

    self.out = types.Float32.vector()
end

function ZeroCrossingClockRecoveryBlock:process(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        -- If we detect a zero crossing, adjust our sample offset to half of a
        -- symbol period
        if self.hysteresis == false and x.data[i].value > self.threshold then
            self.hysteresis = true
            self.sample_offset = self.symbol_period/2
        elseif self.hysteresis == true and x.data[i].value < self.threshold then
            self.hysteresis = false
            self.sample_offset = self.symbol_period/2
        end

        -- Count down to our sample offset
        self.sample_offset = self.sample_offset - 1

        -- If we've reached our sample point, generate a +1 pulse
        if self.sample_offset < 1 then
            out.data[i].value = 1

            -- Increase our sample offset by a symbol period
            self.sample_offset = self.sample_offset + self.symbol_period
        else
            -- Revert to -1 pulse
            out.data[i].value = -1
        end
    end

    return out
end

return ZeroCrossingClockRecoveryBlock
