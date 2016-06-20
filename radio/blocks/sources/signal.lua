---
-- Source a complex or real valued signal from a signal generator.
--
-- Note: the "exponential" waveform generates a complex-valued signal, all
-- other waveform types generate a real-valued signal.
--
-- @category Sources
-- @block SignalSource
-- @tparam string signal Waveform type, either "exponential", "cosine", "sine",
--                       "square", "triangle", "sawtooth", "constant".
-- @tparam number frequency Frequency in Hz
-- @tparam number|nil rate Sample rate in Hz
-- @tparam[opt={}] table options Additional options, specifying:
--                               * `amplitude` (number, default 1.0)
--                               * `offset` (number, default 0.0)
--                               * `phase` (number, default 0.0)
--
-- @signature > out:ComplexFloat32
-- @signature > out:Float32
--
-- @usage
-- -- Source a 250 kHz complex exponential sampled at 2 MHz
-- local src = radio.SignalSource('exponential', 250e3, 2e6)
--
-- -- Source a 100 kHz cosine sampled at 1 MHz, with amplitude 2.5
-- local src = radio.SignalSource('cosine', 100e3, 1e6, {amplitude = 2.5})
--
-- -- Source a 1 kHz square wave sampled at 2 MHz, with offset 1.0
-- local src = radio.SignalSource('square', 1e3, 2e6, {offset = 1.0})

local ffi = require('ffi')
local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local SignalSource = block.factory("SignalSource")

function SignalSource:instantiate(signal, frequency, rate, options)
    local supported_signals = {
        exponential = {process = SignalSource.process_exponential, initialize = SignalSource.initialize_exponential, type = types.ComplexFloat32},
        cosine = {process = SignalSource.process_cosine, initialize = SignalSource.initialize_cosine_sine, type = types.Float32},
        sine = {process = SignalSource.process_sine, initialize = SignalSource.initialize_cosine_sine, type = types.Float32},
        square = {process = SignalSource.process_square, initialize = SignalSource.initialize_square_triangle_sawtooth, type = types.Float32},
        triangle = {process = SignalSource.process_triangle, initialize = SignalSource.initialize_square_triangle_sawtooth, type = types.Float32},
        sawtooth = {process = SignalSource.process_sawtooth, initialize = SignalSource.initialize_square_triangle_sawtooth, type = types.Float32},
        constant = {process = SignalSource.process_constant, initialize = SignalSource.initialize_constant, type = types.Float32},
    }
    assert(signal, "Missing argument #1 (signal)")
    assert(supported_signals[signal], "Unsupported signal (\"" .. signal .. "\")")

    self.frequency = assert(frequency, "Missing argument #2 (frequency)")
    self.rate = assert(rate, "Missing argument #3 (rate)")
    self.options = options or {}
    self.chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", supported_signals[signal].type)}, supported_signals[signal].process, supported_signals[signal].initialize)
end

function SignalSource:get_rate()
    return self.rate
end

ffi.cdef[[
    float cosf(float x);
    float sinf(float x);
]]

-- Complex Exponential

function SignalSource:initialize_exponential()
    self.amplitude = self.options.amplitude or 1.0
    self.phase = self.options.phase or 0.0

    self.omega = 2*math.pi*(self.frequency/self.rate)

    self.out = types.ComplexFloat32.vector(self.chunk_size)
end

function SignalSource:process_exponential()
    local out = self.out

    for i = 0, out.length-1 do
        out.data[i].real = ffi.C.cosf(self.phase)*self.amplitude
        out.data[i].imag = ffi.C.sinf(self.phase)*self.amplitude
        self.phase = self.phase + self.omega
    end

    while self.phase > 2*math.pi do
        self.phase = self.phase - 2*math.pi
    end

    return out
end

-- Cosine and sine

function SignalSource:initialize_cosine_sine()
    self.amplitude = self.options.amplitude or 1.0
    self.phase = self.options.phase or 0.0
    self.offset = self.options.offset or 0.0

    self.omega = 2*math.pi*(self.frequency/self.rate)

    self.out = types.Float32.vector(self.chunk_size)
end

function SignalSource:process_cosine()
    local out = self.out

    for i = 0, out.length-1 do
        out.data[i].value = ffi.C.cosf(self.phase) * self.amplitude + self.offset
        self.phase = self.phase + self.omega
    end

    while self.phase > 2*math.pi do
        self.phase = self.phase - 2*math.pi
    end

    return out
end

function SignalSource:process_sine()
    local out = self.out

    for i = 0, out.length-1 do
        out.data[i].value = ffi.C.sinf(self.phase) * self.amplitude + self.offset
        self.phase = self.phase + self.omega
    end

    while self.phase > 2*math.pi do
        self.phase = self.phase - 2*math.pi
    end

    return out
end

-- Square, Triangle, Sawtooth

function SignalSource:initialize_square_triangle_sawtooth()
    self.amplitude = self.options.amplitude or 1.0
    self.phase = self.options.phase or 0.0
    self.offset = self.options.offset or 0.0

    self.omega = 2*math.pi*(self.frequency/self.rate)
    self.phi = self.phase

    self.out = types.Float32.vector(self.chunk_size)
end

function SignalSource:process_square()
    local out = self.out

    for i = 0, out.length-1 do
        if self.phi < math.pi then
            out.data[i].value = 1.0*self.amplitude + self.offset
        else
            out.data[i].value = -1.0*self.amplitude + self.offset
        end
        self.phi = self.phi + self.omega
        self.phi = (self.phi >= 2*math.pi) and (self.phi - 2*math.pi) or self.phi
    end

    return out
end

function SignalSource:process_triangle()
    local out = self.out

    for i = 0, out.length-1 do
        if self.phi < math.pi then
            out.data[i].value = (1 - (2 / math.pi)*self.phi)*self.amplitude + self.offset
        else
            out.data[i].value = (-1 + (2 / math.pi)*(self.phi - math.pi))*self.amplitude + self.offset
        end
        self.phi = self.phi + self.omega
        self.phi = (self.phi >= 2*math.pi) and (self.phi - 2*math.pi) or self.phi
    end

    return out
end

function SignalSource:process_sawtooth()
    local out = self.out

    for i = 0, out.length-1 do
        out.data[i].value = (-1 + (1 / math.pi)*self.phi)*self.amplitude + self.offset
        self.phi = self.phi + self.omega
        self.phi = (self.phi >= 2*math.pi) and (self.phi - 2*math.pi) or self.phi
    end

    return out
end

-- Constant

function SignalSource:initialize_constant()
    self.amplitude = self.options.amplitude or 1.0

    self.out = types.Float32.vector(self.chunk_size)
end

function SignalSource:process_constant()
    local out = self.out

    for i = 0, out.length-1 do
        out.data[i].value = self.amplitude
    end

    return out
end

return SignalSource
