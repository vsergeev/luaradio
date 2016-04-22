---
-- Sample a complex or real valued data signal on positive zero-crossing
-- transitions of a real-valued clock signal.
--
-- $$ y[n] = x_{data}[m] \text{ when } \begin{align}&x_{clk}[m] > 0 \\ &x_{clk}[m-1] < 0\end{align} $$
--
-- @category Digital
-- @block SamplerBlock
--
-- @signature data:ComplexFloat32, clock:Float32 > out:ComplexFloat32
-- @signature data:Float32, clock:Float32 > out:Float32
--
-- @usage
-- local sampler = radio.SamplerBlock()
-- top:connect(data_src, 'out', sampler, 'data')
-- top:connect(clock_src, 'out', sampler, 'clock')
-- top:connect(sampler, snk)

local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local SamplerBlock = block.factory("SamplerBlock")

local ClockState = {LOW = 1, HIGH = 2}

function SamplerBlock:instantiate()
    self:add_type_signature({block.Input("data", types.ComplexFloat32), block.Input("clock", types.Float32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("data", types.Float32), block.Input("clock", types.Float32)}, {block.Output("out", types.Float32)})
end

function SamplerBlock:initialize()
    self.clock_hysteresis = ClockState.LOW

    self.out = self:get_output_type().vector()
end

function SamplerBlock:process(data, clock)
    local out = self.out:resize(0)

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
