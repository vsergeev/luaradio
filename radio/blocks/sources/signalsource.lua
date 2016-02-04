local math = require('math')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type

local SignalSourceBlock = block.BlockFactory("SignalSourceBlock")

function SignalSourceBlock:instantiate(options, rate)
    local supported_signals = {
        exponential = {process = SignalSourceBlock.process_exponential, initialize = SignalSourceBlock.initialize_exponential},
        --cosine = {process = SignalSourceBlock.process_cosine, initialize = SignalSourceBlock.initialize_cosine},
        --sine = {process = SignalSourceBlock.process_sine, initialize = SignalSourceBlock.initialize_sine},
        --square = {process = SignalSourceBlock.process_square, initialize = SignalSourceBlock.initialize_square},
        --triangle = {process = SignalSourceBlock.process_triangle, initialize = SignalSourceBlock.initialize_triangle},
        --sawtooth = {process = SignalSourceBlock.process_sawtooth, initialize = SignalSourceBlock.initialize_sawtooth},
    }
    assert(supported_signals[options.signal], "Unsupported signal \"" .. options.signal .. "\".")

    self.options = options
    self.rate = rate
    self._chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", ComplexFloat32Type)}, supported_signals[options.signal].process, supported_signals[options.signal].initialize)
end

function SignalSourceBlock:get_rate()
    return self.rate
end

function SignalSourceBlock:initialize_exponential()
    self.frequency = self.options.frequency
    self.amplitude = self.options.amplitude or 1.0
    self.omega = 2*math.pi*(self.frequency/self.rate)
    self.phi = 0.0
end

function SignalSourceBlock:process_exponential()
    local out = ComplexFloat32Type.vector(self._chunk_size)

    for i = 0, out.length-1 do
        out.data[i] = ComplexFloat32Type(math.cos(self.phi), math.sin(self.phi)):scalar_mul(self.amplitude)
        self.phi = self.phi + self.omega
        self.phi = (self.phi > 2*math.pi) and (self.phi - 2*math.pi) or self.phi
    end

    return out
end

return {SignalSourceBlock = SignalSourceBlock}
