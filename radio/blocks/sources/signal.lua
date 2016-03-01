local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local SignalSource = block.factory("SignalSource")

function SignalSource:instantiate(options, rate)
    local supported_signals = {
        exponential = {process = SignalSource.process_exponential, initialize = SignalSource.initialize_exponential},
        --cosine = {process = SignalSource.process_cosine, initialize = SignalSource.initialize_cosine},
        --sine = {process = SignalSource.process_sine, initialize = SignalSource.initialize_sine},
        --square = {process = SignalSource.process_square, initialize = SignalSource.initialize_square},
        --triangle = {process = SignalSource.process_triangle, initialize = SignalSource.initialize_triangle},
        --sawtooth = {process = SignalSource.process_sawtooth, initialize = SignalSource.initialize_sawtooth},
    }
    assert(supported_signals[options.signal], "Unsupported signal \"" .. options.signal .. "\".")

    self.options = options
    self.rate = rate
    self.chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", types.ComplexFloat32Type)}, supported_signals[options.signal].process, supported_signals[options.signal].initialize)
end

function SignalSource:get_rate()
    return self.rate
end

function SignalSource:initialize_exponential()
    self.frequency = self.options.frequency
    self.amplitude = self.options.amplitude or 1.0
    self.omega = 2*math.pi*(self.frequency/self.rate)

    self.rotation = types.ComplexFloat32Type(math.cos(self.omega), math.sin(self.omega))
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
