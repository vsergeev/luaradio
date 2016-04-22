---
-- Generate a phase-locked complex-valued sinusoid to a complex-valued
-- reference signal.
--
-- $$ y[n] = \text{PLL}(x[n], f_{BW}, f_{min}, f_{max}, M) $$
--
-- @category Carrier and Clock Recovery
-- @block PLLBlock
-- @tparam number loop_bandwidth Loop bandwidth in Hz
-- @tparam number frequency_min Minimum frequency in Hz
-- @tparam number frequency_max Maximum frequency in Hz
-- @tparam[opt=1.0] number multiplier Multiplier, can be fractional
--
-- @signature in:ComplexFloat32 > out:ComplexFloat32, error:Float32
--
-- @usage
-- -- PLL with 1 KHz loop bandwidth, 18 KHz - 21 KHz capture range, 3 multiplier
-- local pll = radio.PLLBlock(1e3, 18e3, 21e3, 3)
--
-- -- PLL with 1 KHz loop bandwidth, 18 KHz - 21 KHz capture range, 1/16 multiplier
-- local pll = radio.PLLBlock(1e3, 18e3, 21e3, 1/16)

local block = require('radio.core.block')
local types = require('radio.types')

local PLLBlock = block.factory("PLLBlock")

function PLLBlock:instantiate(loop_bandwidth, frequency_min, frequency_max, multiplier)
    self.loop_bw = assert(loop_bandwidth, "Missing argument #1 (loop_bandwidth)")
    self.freq_min = assert(frequency_min, "Missing argument #2 (frequency_min)")
    self.freq_max = assert(frequency_max, "Missing argument #3 (frequency_max)")
    self.multiplier = multiplier or 1.0

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32), block.Output("error", types.Float32)})
end

--
-- PLL Block Diagram
--
--              e[n]          phi[n]
-- x[n] ---[PD]------[Filter]--------[D]--[Osc]--- y[n]
--          |                                   |
--          \-----------------------------------/
--                         y[n]
--
-- See figure A.11 of [1].
--
--      x[n] is input signal, y[n] is output signal
--
--      PD = Phase Detector = atan2(x * conj(y))
--      Filter = Loop Filter
--      D = Delay
--      Osc = Complex Oscillator = cos(phi) + j*sin(phi)
--
-- Linearized Block Diagram
--
--            e[n]          p[n]
-- x[n] --(-)------[Filter]------[D]--- y[n]
--         |                         |
--         \-------------------------/
--
-- See figure A.13 of [1].
--
--      x[n] is input phase, y[n] is output phase
--
--      e[n] = x[n] - y[n]
--
--      Loop Filter
--           f[n] = f[n-1] + b*e[n]
--           p[n] = p[n-1] + f[n] + a*e[n]
--           y[n] = p[n-1]
--
-- Closed Loop Transfer Function
--
--      Y(z)     z^-1              b
--      ---- = -------- * ( a + -------- )
--      E(z)   1 - z^-1         1 - z^-1
--
--      Y(z)        -a*z^-2 + (a + b)*z^-1
--      ---- = ---------------------------------
--      X(z)    (1-a)z^-2 + (a + b - 2)*z^-1 + 1
--
-- This matches A.51 of [1] with Kp=1, K0=1, K1=a, K2=b.
--
-- Blinear Transform of CT Second Order PLL
--
--      Y(z)            .......................
--      ---- = -----------------------------------------
--      X(z)          2w^2 - 2          1-2dw+w^2
--              1 + ----------- z^-1 + ----------- z^-2
--                  (1+2dw+w^2)        (1+2dw+w^2)
--
--      where d = damping ratio zeta, w = (w_n*T)/2

-- See A.52 of [1].
--
-- Matching Coefficients
--
--      (a + b - 2) = (-2w^2 + 2)/(1 + 2dw + w^2)
--      (1 - a) = (1 - 2dw + w^2)/(1 + 2dw + w^2)
--
--      a = (4dw) / (1 + 2dw + w^2)
--      b = (4w^2) / (1 + 2 dw + w^2)
--
--      w expressed in terms of loop bandwidth (see A.56 of [1])
--          w = Bn*T / (d + 1/(4*d))
--      w expressed in terms of loop bandwidth frequency
--          w = (2*pi*B/Fs) / (d + 1/(4*d))
--
-- [1] http://ece485web.groups.et.byu.net/ee485.fall.03/lectures/pll_notes.pdf
--

function PLLBlock:initialize()
    local rate = self:get_rate()

    -- Translate our bandwidths and frequencies into radians
    self.loop_bw = 2*math.pi*(self.loop_bw/rate)
    self.freq_min = 2*math.pi*(self.freq_min/rate)
    self.freq_max = 2*math.pi*(self.freq_max/rate)

    -- Calculate loop filter constants
    local damping = math.sqrt(2)/2
    self.loop_bw = self.loop_bw / (damping + 1/(4*damping))
    local denom = (1 + 2*damping*self.loop_bw + self.loop_bw*self.loop_bw)
    self.alpha = (4*damping*self.loop_bw)/denom
    self.beta = (4*self.loop_bw*self.loop_bw)/denom

    -- Initial state
    self.phi_locked = 0.0
    self.phi_multiplied = 0.0
    self.freq_locked = (self.freq_min + self.freq_max)/2.0

    -- Create output vectors
    self.out = types.ComplexFloat32.vector()
    self.err = types.Float32.vector()
end

function PLLBlock:process(x)
    local out = self.out:resize(x.length)
    local err = self.err:resize(x.length)

    for i = 0, x.length-1 do
        -- VCO
        local vco_output = types.ComplexFloat32(math.cos(self.phi_locked), math.sin(self.phi_locked))
        out.data[i] = types.ComplexFloat32(math.cos(self.phi_multiplied), math.sin(self.phi_multiplied))

        -- Phase Detector
        err.data[i].value = (x.data[i] * vco_output:conj()):arg()

        -- Loop filter
        self.freq_locked = self.freq_locked + self.beta * err.data[i].value
        self.phi_locked = self.phi_locked + self.freq_locked + self.alpha * err.data[i].value
        self.phi_multiplied = self.phi_multiplied + self.freq_locked*self.multiplier + self.alpha * err.data[i].value

        -- Clamp frequency
        self.freq_locked = (self.freq_locked > self.freq_max) and self.freq_max or self.freq_locked
        self.freq_locked = (self.freq_locked < self.freq_min) and self.freq_min or self.freq_locked

        -- Wrap phi's
        self.phi_locked = (self.phi_locked > 2*math.pi) and (self.phi_locked - 2*math.pi) or self.phi_locked
        self.phi_locked = (self.phi_locked < -2*math.pi) and (self.phi_locked + 2*math.pi) or self.phi_locked
        self.phi_multiplied = (self.phi_multiplied > 2*math.pi) and (self.phi_multiplied - 2*math.pi) or self.phi_multiplied
        self.phi_multiplied = (self.phi_multiplied < -2*math.pi) and (self.phi_multiplied + 2*math.pi) or self.phi_multiplied
    end

    return out, err
end

return PLLBlock
