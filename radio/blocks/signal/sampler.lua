local ffi = require('ffi')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type

local SamplerBlock = block.factory("SamplerBlock")

local ClockState = {LOW = 1, HIGH = 2}

function SamplerBlock:instantiate()
    self.clock_hysteresis = ClockState.LOW

    self:add_type_signature({block.Input("data", ComplexFloat32Type), block.Input("clock", Float32Type)}, {block.Output("out", ComplexFloat32Type)})
    self:add_type_signature({block.Input("data", Float32Type), block.Input("clock", Float32Type)}, {block.Output("out", Float32Type)})
end

function SamplerBlock:initialize()
    self.data_type = self.signature.inputs[1].data_type
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

return {SamplerBlock = SamplerBlock}
