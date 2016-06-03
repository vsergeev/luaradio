local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local SamplerBlock = block.factory("SamplerBlock")

local ClockState = {LOW = 1, HIGH = 2}

function SamplerBlock:instantiate()
    self.clock_hysteresis = ClockState.LOW

    self:add_type_signature({block.Input("data", types.ComplexFloat32), block.Input("clock", types.Float32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("data", types.Float32), block.Input("clock", types.Float32)}, {block.Output("out", types.Float32)})
end

function SamplerBlock:initialize()
    self.data_type = self:get_input_type()
end

function SamplerBlock:process(data, clock)
    local out = self.data_type.vector()

    for i = 0, data.length-1 do
        if self.clock_hysteresis == ClockState.LOW and clock.data[i].value > 0 then
            -- Sample data into out on clock transition from low to high
            out:append(data.data[i])
            self.clock_hysteresis = ClockState.HIGH
        elseif self.clock_hysteresis == ClockState.HIGH and clock.data[i].value < 0 then
            self.clock_hysteresis = ClockState.LOW
        end
    end

    return out
end

return SamplerBlock
