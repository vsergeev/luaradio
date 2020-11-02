---
-- Quadrature amplitude modulate bits into a baseband complex-valued signal.
--
-- $$ y[n] = \text{QAM}(x[n], \text{symbol_rate}, \text{sample_rate}, \text{points}) $$
--
-- @category Modulation
-- @block QuadratureAmplitudeModulatorBlock
-- @tparam number symbol_rate Symbol rate in Hz
-- @tparam number sample_rate Sample rate in Hz
-- @tparam number points Number of constellation points (must be power of 2)
-- @tparam[opt={}] table options Additional options, specifying:
--                               * `msb_first` (boolean, default true)
--                               * `constellation` (table, mapping of symbol
--                               value to complex amplitude)
-- @signature in:Bit > out:ComplexFloat32
--
-- @usage
-- -- 4-QAM modulator with 1200 Hz symbol rate, 96 kHz sample rate
-- local modulator = radio.QuadratureAmplitudeModulatorBlock(1200, 96000, 4)

local ffi = require('ffi')
local bit = require('bit')

local block = require('radio.core.block')
local types = require('radio.types')

local math_utils = require('radio.utilities.math_utils')

local QuadratureAmplitudeModulatorBlock = block.factory("QuadratureAmplitudeModulatorBlock")

function QuadratureAmplitudeModulatorBlock:instantiate(symbol_rate, sample_rate, points, options)
    self.symbol_rate = assert(symbol_rate, "Missing argument #1 (symbol_rate)")
    self.sample_rate = assert(sample_rate, "Missing argument #2 (sample_rate)")
    self.points = assert(points, "Missing argument #3 (points)")
    self.options = options or {}

    assert(points > 1 and math_utils.is_pow2(points), "Points is not greater than 1 and a power of 2")

    self.symbol_bits = math.floor(math.log(self.points, 2))
    self.symbol_period = math.floor(self.sample_rate / self.symbol_rate)
    self.constellation = self.options.constellation or self:_build_constellation(self.points)
    self.msb_first = (self.options.msb_first == nil) and true or self.options.msb_first

    self:add_type_signature({block.Input("in", types.Bit)}, {block.Output("out", types.ComplexFloat32)})
end

function QuadratureAmplitudeModulatorBlock:_build_constellation(points)
    local constellation = {}

    local symbol_bits = math.floor(math.log(points, 2))
    local i_bits = math.ceil(symbol_bits / 2)
    local q_bits = symbol_bits - math.ceil(symbol_bits / 2)
    local i_levels = 2 ^ i_bits
    local q_levels = 2 ^ q_bits
    local scaling = math.sqrt(2 * (points - 1) / 3)

    for point=0, points-1 do
        local i_value = bit.rshift(point, q_bits)
        local q_value = bit.band(point, 2 ^ q_bits - 1)
        local gray_point = bit.bor(bit.lshift(bit.bxor(i_value, bit.rshift(i_value, 1)), q_bits),
                                   bit.bxor(q_value, bit.rshift(q_value, 1)))

        constellation[gray_point] = types.ComplexFloat32(2 * i_value - i_levels + 1, 2 * q_value - q_levels + 1):scalar_div(scaling)
    end

    return constellation
end

function QuadratureAmplitudeModulatorBlock:initialize()
    -- Build symbol vectors
    self.symbol_vectors = {}
    for point=0, self.points-1 do
        self.symbol_vectors[point] = types.ComplexFloat32.vector(self.symbol_period)
        self.symbol_vectors[point]:fill(types.ComplexFloat32(self.constellation[point]))
    end

    self.state = types.Bit.vector()
    self.out = types.ComplexFloat32.vector()
end

function QuadratureAmplitudeModulatorBlock:process(x)
    local state = self.state
    local out = self.out:resize(math.floor((state.length + x.length) / self.symbol_bits) * self.symbol_period)
    local symbol_offset = 0

    for i = 0, x.length-1 do
        state:append(x.data[i])

        if state.length == self.symbol_bits then
            local value = types.Bit.tonumber(state, 0, self.symbol_bits, self.msb_first and "msb" or "lsb")
            ffi.copy(self.out.data + symbol_offset, self.symbol_vectors[value].data, self.symbol_period * ffi.sizeof(types.ComplexFloat32))
            symbol_offset = symbol_offset + self.symbol_period

            state:resize(0)
        end
    end

    return out
end

return QuadratureAmplitudeModulatorBlock
