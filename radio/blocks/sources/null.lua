---
-- Source a zero-valued signal of the specified data type.
--
-- @category Sources
-- @block NullSource
-- @tparam type data_type LuaRadio data type
-- @tparam number rate Sample rate in Hz
--
-- @signature > out:data_type
--
-- @usage
-- -- Source a zero complex-valued signal sampled at 1 MHz
-- local src = radio.NullSource(radio.types.ComplexFloat32, 1e6)
--
-- -- Source a zero real-valued stream sampled at 500 KHz
-- local src = radio.NullSource(radio.types.Bit, 500e3)
--
-- -- Source a zero bit stream sampled at 2 KHz
-- local src = radio.NullSource(radio.types.Bit, 2e3)

local block = require('radio.core.block')
local types = require('radio.types')

local NullSource = block.factory("NullSource")

function NullSource:instantiate(data_type, rate)
    self.data_type = assert(data_type, "Missing argument #1 (data_type)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    self.chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", data_type)})
end

function NullSource:get_rate()
    return self.rate
end

function NullSource:initialize()
    self.out = self.data_type.vector(self.chunk_size)
end

function NullSource:process()
    return self.out
end

return NullSource
