---
-- Generate a frequency modulated signal
-- Note: the "exponential" waveform generates a complex-valued signal, all
-- outer waveform types generate a real-valued signal.
--
-- @category Modulation
-- @block FrequencyModulatorBlock
-- @tparam string signal Waveform type, either "exponential", "cosine", "sine".
-- @tparam number center_frequency Center frequency in Hz
-- @tparam number bandwidth The bandwidth of the frequency modulated signal.
-- @tparam[opt={}] table options Additional options, specifying:
--                               * `ampliture` (number, default 1.0)
--                               * `offset` (number, default 0.0)
--                               * `phase` (number in radians, default 0.0)
-- @signature in:Float32 > out:ComplexFloat32
-- @signature in:Float32 > out:Float32
--

local ffi = require('ffi')
local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local FrequencyModulatorBlock = block.factory("FrequencyModulatorBlock")

function FrequencyModulatorBlock:instantiate(signal, bandwidth, options)
    local supported_signals = {
        exponential = {
            process = FrequencyModulatorBlock.process_exponential,
            initialize = FrequencyModulatorBlock.initialize_exponential,
            type = types.ComplexFloat32
        },
        cosine = {
            process = FrequencyModulatorBlock.process_cosine,
            initialize = FrequencyModulatorBlock.initialize_cosine_sine,
            type = types.Float32
        },
        sine = {
            process = FrequencyModulatorBlock.process_sine,
            initialize = FrequencyModulatorBlock.initialize_cosine_sine,
            type = types.Float32
        }
    }

    assert(signal, "Missing argument #1 (signal)")
    assert(supported_signals[signal], "Unsupported signal (\"" .. signal .. "\")")

    self.bandwidth = assert(bandwidth, "Missing argument #2 (bandwidth)")
    self.options = options or {}
    self.center_frequency = self.options.center_frequency or 0.0
    self.amplitude = self.options.amplitude or 1.0
    self.offset = self.options.offset or 0.0
    self.phase = self.options.phase or 0.0

    self:add_type_signature(
        {block.Input("in", types.Float32)},
        {block.Output("out", supported_signals[signal].type)},
        supported_signals[signal].process,
        supported_signals[signal].initialize
    )

end

ffi.cdef[[
    float cosf(float x);
    float sinf(float x);
]]

function FrequencyModulatorBlock:initialize_exponential()
    self.delta = 2*math.pi*(self.bandwidth/self:get_rate())
    self.omega = 2*math.pi*(self.center_frequency/self:get_rate())
    self.out = types.ComplexFloat32.vector()
end

function FrequencyModulatorBlock:process_exponential(x)
    local out = self.out
    out:resize(x.length)

    for i = 0, out.length-1 do
        out.data[i].real = ffi.C.cosf(self.phase)*self.amplitude
        out.data[i].imag = ffi.C.sinf(self.phase)*self.amplitude
        self.phase = self.phase + self.omega + self.delta*x.data[i].value
        if self.phase > 2*math.pi then
            self.phase = self.phase - 2*math.pi
        end
    end

    return out
end

function FrequencyModulatorBlock:initialize_cosine_sine()
    self.delta = 2*math.pi*(self.bandwidth/self:get_rate())
    self.omega = 2*math.pi*(self.center_frequency/self:get_rate())
    self.out = types.Float32.vector()
end

function FrequencyModulatorBlock:process_cosine(x)
    local out = self.out
    out.resize(x.length)
    
    for i = 0, out.length-1 do
        out.data[i].value = ffi.C.cosf(self.phase)*self.amplitude + self.offset
        self.phase = self.phase + self.omega + self.delta*x.data[i].value
        if self.phase > 2*math.pi then
            self.phase = self.phase - 2*math.pi
        end
    end
end

function FrequencyModulatorBlock:process_sine(x)
    local out = self.out
    out.resize(x.length)
    
    for i = 0, out.length-1 do
        out.data[i].value = ffi.C.sinf(self.phase)*self.amplitude + self.offset
        self.phase = self.phase + self.omega + self.delta*x.data[i].value
        if self.phase > 2*math.pi then
            self.phase = self.phase - 2*math.pi
        end
    end
end

return FrequencyModulatorBlock
