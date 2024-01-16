---
-- Source a signal with values drawn from a uniform random distribution.
--
-- @category Sources
-- @block UniformRandomSource
-- @tparam type data_type LuaRadio data type, choice of
--                        `radio.types.ComplexFloat32`, `radio.types.Float32`,
--                        `radio.types.Byte`, or `radio.types.Bit` data types.
-- @tparam number rate Sample rate in Hz
-- @tparam[opt={}] array range Value range as an array, e.g `{10, 100}`.
-- @tparam[opt={}] table options Additional options, specifying:
--                               * `seed` (number)
--
-- @signature > out:ComplexFloat32
-- @signature > out:Float32
-- @signature > out:Byte
-- @signature > out:Bit
--
-- @usage
-- -- Source a random ComplexFloat32 signal sampled at 1 MHz
-- local src = radio.UniformRandomSource(radio.types.ComplexFloat32, 1e6)
--
-- -- Source a random Float32 signal sampled at 1 MHz
-- local src = radio.UniformRandomSource(radio.types.Float32, 1e6)
--
-- -- Source a random Byte signal sampled at 1 kHz, ranging from 65 to 90
-- local src = radio.UniformRandomSource(radio.types.Byte, 1e3, {65, 90})
--
-- -- Source a random bit stream sampled at 1 kHz
-- local src = radio.UniformRandomSource(radio.types.Bit, 1e3)

local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local UniformRandomSource = block.factory("UniformRandomSource")

local random_generator_table = {
    [types.ComplexFloat32] =
        function (a, b)
            a, b = a or -1.0, b or 1.0
            return function ()
                return types.ComplexFloat32(a+(b-a)*math.random(), a+(b-a)*math.random())
            end
        end,
    [types.Float32] =
        function (a, b)
            a, b = a or -1.0, b or 1.0
            return function ()
                return types.Float32(a+(b-a)*math.random())
            end
        end,
    [types.Byte] =
        function (a, b)
            a = a or 0, b or 255
            return function ()
                return types.Byte(math.random(a, b))
            end
        end,
    [types.Bit] =
        function (a, b)
            return function ()
                return types.Bit(math.random(0, 1))
            end
        end,
}

function UniformRandomSource:instantiate(data_type, rate, range, options)
    self.data_type = assert(data_type, "Missing argument #1 (data_type)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    assert(random_generator_table[data_type], "Unsupported data type")
    self.generator = random_generator_table[data_type](unpack(range or {}))

    options = options or {}
    self.chunk_size = 8192
    self.seed = options.seed or nil

    self:add_type_signature({}, {block.Output("out", data_type)})
end

function UniformRandomSource:get_rate()
    return self.rate
end

function UniformRandomSource:initialize()
    self.out = self.data_type.vector(self.chunk_size)
end

function UniformRandomSource:process()
    local out = self.out

    -- seed initialisation
    -- => done only once for each UniformRandomSource block
    --    as math.randomseed() returns nil
    self.seed = self.seed and math.randomseed(self.seed)

    for i=0, out.length-1 do
        out.data[i] = self.generator()
    end

    return out
end

return UniformRandomSource
