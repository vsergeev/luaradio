local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local SignalSource = block.factory("SignalSource")

function SignalSource:instantiate(signal, frequency, rate, options)
    local supported_signals = {
        exponential = {process = SignalSource.process_exponential, initialize = SignalSource.initialize_exponential, type = types.ComplexFloat32Type},
        --cosine = {process = SignalSource.process_cosine, initialize = SignalSource.initialize_cosine},
        --sine = {process = SignalSource.process_sine, initialize = SignalSource.initialize_sine},
        --square = {process = SignalSource.process_square, initialize = SignalSource.initialize_square},
        --triangle = {process = SignalSource.process_triangle, initialize = SignalSource.initialize_triangle},
        --sawtooth = {process = SignalSource.process_sawtooth, initialize = SignalSource.initialize_sawtooth},
    }
    assert(supported_signals[signal], "Unsupported signal \"" .. signal .. "\".")

    self.frequency = frequency
    self.rate = rate
    self.options = options or {}
    self.chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", supported_signals[signal].type)}, supported_signals[signal].process, supported_signals[signal].initialize)
end

function SignalSource:get_rate()
    return self.rate
end

function SignalSource:initialize_exponential()
    self.amplitude = self.options.amplitude or 1.0

    local omega = 2*math.pi*(self.frequency/self.rate)
    self.rotation = types.ComplexFloat32Type(math.cos(omega), math.sin(omega))
    self.phi = types.ComplexFloat32Type(1, 0)
end

function SignalSource:process_exponential()
    local out = types.ComplexFloat32Type.vector(self.chunk_size)

    for i = 0, out.length-1 do
        out.data[i] = self.phi:scalar_mul(self.amplitude)
        self.phi = self.phi * self.rotation
    end

    return out
end

return {SignalSource = SignalSource}
