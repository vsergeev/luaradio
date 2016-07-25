---
-- Apply automatic gain to a real or complex valued signal to maintain an
-- average target power.
--
-- $$ y[n] = \text{AGC}(x[n], \text{mode}, \text{target}, \text{threshold}) $$
--
-- Implementation note: this is a feedforward AGC. The `power_tau` time
-- constant controls the moving average of the power estimator. The `gain_tau`
-- time constant controls the speed of the gain adjustment. The gain has
-- symmetric attack and decay dynamics.
--
-- @category Level Control
-- @block AGCBlock
-- @tparam string mode Mode, choice of "fast", "slow", "custom"
-- @tparam[opt=-35] number target Target power in dBFS
-- @tparam[opt=-75] number threshold Threshold power in dBFS
-- @tparam[opt={}] table options Additional options, specifying:
--                               * `gain_tau` (number, default 0.1 seconds for
--                                  fast, 3.0 seconds for slow)
--                               * `power_tau` (number, default 1.0 seconds)
-- @signature in:Float32 > out:Float32
-- @signature in:ComplexFloat32 > out:ComplexFloat32
--
-- @usage
-- -- Automatic gain control with fast gain
-- local agc = radio.AGCBlock('fast')
--
-- -- Automatic gain control with slow gain, -20 dbFS target
-- local agc = radio.AGCBlock('slow', -20)
--
-- -- Automatic gain control with custom time constant, -30 dbFS target, -100 dbFS threshold
-- local agc = radio.AGCBlock('custom', -30, -100, {gain_tau = 0.5})

local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local AGCBlock = block.factory("AGCBlock")

function AGCBlock:instantiate(mode, target, threshold, options)
    self.mode = assert(mode, "Missing argument #1 (mode), can be \"fast\", \"slow\", or \"custom\"")
    self.target = target or -35
    self.threshold = threshold or -75
    self.options = options or {}

    self.gain_tau = ({fast = 0.1, slow = 3.0})[self.mode] or self.options.gain_tau
    self.power_tau = self.options.power_tau or 1.0

    assert(self.mode == "fast" or self.mode == "slow" or self.mode == "custom", string.format("Invalid mode \"%s\"", tostring(mode)))
    assert(self.gain_tau, "Missing gain_tau parameter for \"custom\" mode")

    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)}, self.process_real)
    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)}, self.process_complex)
end

function AGCBlock:initialize()
    -- Compute normalized alpha for power estimator
    self.power_alpha = 1/(1 + self.power_tau*self:get_rate())
    -- Compute normalized alpha for gain filter
    self.gain_alpha = 1/(1 + self.gain_tau*self:get_rate())
    -- Initialize average power and gain state
    self.average_power, self.gain = 0.0, 0.0
    -- Linearize logarithmic power target
    self.target = 10^(self.target/10)
    -- Linearize logarithmic power threshold
    self.threshold = 10^(self.threshold/10)

    self.out = self:get_input_type().vector()
end

function AGCBlock:process_real(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        -- Estimate average power
        self.average_power = (1 - self.power_alpha)*self.average_power + self.power_alpha*(x.data[i].value*x.data[i].value)

        if self.average_power >= self.threshold then
            -- Compute filtered gain
            self.gain = (1 - self.gain_alpha)*self.gain + self.gain_alpha*(self.target*(1/self.average_power))
            -- Apply sqrt gain
            out.data[i].value = math.sqrt(self.gain)*x.data[i].value
        else
            -- Pass through without gain
            out.data[i].value = x.data[i].value
        end
    end

    return out
end

function AGCBlock:process_complex(x)
    local out = self.out:resize(x.length)

    for i = 0, x.length-1 do
        -- Estimate average power
        self.average_power = (1 - self.power_alpha)*self.average_power + self.power_alpha*x.data[i]:abs_squared()

        if self.average_power >= self.threshold then
            -- Compute filtered gain
            self.gain = (1 - self.gain_alpha)*self.gain + self.gain_alpha*(self.target*(1/self.average_power))
            -- Apply sqrt gain
            local gain = math.sqrt(self.gain)
            out.data[i].real = gain*x.data[i].real
            out.data[i].imag = gain*x.data[i].imag
        else
            -- Pass through without gain
            out.data[i].real = x.data[i].real
            out.data[i].imag = x.data[i].imag
        end
    end

    return out
end

return AGCBlock
