---
-- Pulse amplitude modulate bits into a baseband real-valued signal. The
-- resulting signal is non-return-to-zero, bipolar, with normalized energy.
--
-- $$ y[n] = \text{PAM}(x[n], \text{symbol_rate}, \text{sample_rate}, \text{levels}) $$
--
-- @category Modulation
-- @block PulseAmplitudeModulatorBlock
-- @tparam number symbol_rate Symbol rate in Hz
-- @tparam number sample_rate Sample rate in Hz
-- @tparam number levels Number of amplitude levels (must be power of 2)
-- @tparam[opt={}] table options Additional options, specifying:
--                               * `msb_first` (boolean, default true)
--                               * `amplitudes` (table, mapping of symbol value
--                               to amplitude)
-- @signature in:Bit > out:Float32
--
-- @usage
-- -- 4-PAM modulator with 1200 Hz symbol rate, 96 kHz sample rate
-- local modulator = radio.PulseAmplitudeModulatorBlock(1200, 96000, 4)

local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local math_utils = require('radio.utilities.math_utils')

local PulseAmplitudeModulatorBlock = block.factory("PulseAmplitudeModulatorBlock")

function PulseAmplitudeModulatorBlock:instantiate(symbol_rate, sample_rate, levels, options)
    self.symbol_rate = assert(symbol_rate, "Missing argument #1 (symbol_rate)")
    self.sample_rate = assert(sample_rate, "Missing argument #2 (sample_rate)")
    self.levels = assert(levels, "Missing argument #3 (levels)")
    self.options = options or {}

    assert(levels > 1 and math_utils.is_pow2(levels), "Levels is not greater than 1 and a power of 2")

    self.symbol_bits = math.floor(math.log(self.levels, 2))
    self.symbol_period = math.floor(self.sample_rate / self.symbol_rate)
    self.amplitudes = self.options.amplitudes or self:_build_amplitudes(self.levels)
    self.msb_first = (self.options.msb_first == nil) and true or self.options.msb_first

    self:add_type_signature({block.Input("in", types.Bit)}, {block.Output("out", types.Float32)})
end

function PulseAmplitudeModulatorBlock:_build_amplitudes(levels)
    local amplitudes = {}
    local scaling = math.sqrt((levels ^ 2 - 1) / 3)
    for level=0, levels-1 do
        local gray_level = bit.bxor(level, bit.rshift(level, 1))
        amplitudes[gray_level] = (2 * level - levels + 1) / scaling
    end
    return amplitudes
end

function PulseAmplitudeModulatorBlock:initialize()
    -- Build symbol vectors
    self.symbol_vectors = {}
    for level=0, self.levels-1 do
        self.symbol_vectors[level] = types.Float32.vector(self.symbol_period)
        self.symbol_vectors[level]:fill(types.Float32(self.amplitudes[level]))
    end

    self.state = types.Bit.vector()
    self.out = types.Float32.vector()
end

function PulseAmplitudeModulatorBlock:process(x)
    local state = self.state
    local out = self.out:resize(math.floor((state.length + x.length) / self.symbol_bits) * self.symbol_period)
    local symbol_offset = 0

    for i = 0, x.length-1 do
        state:append(x.data[i])

        if state.length == self.symbol_bits then
            local value = types.Bit.tonumber(state, 0, self.symbol_bits, self.msb_first and "msb" or "lsb")
            ffi.copy(self.out.data + symbol_offset, self.symbol_vectors[value].data, self.symbol_period * ffi.sizeof(types.Float32))
            symbol_offset = symbol_offset + self.symbol_period

            state:resize(0)
        end
    end

    return out
end

return PulseAmplitudeModulatorBlock
