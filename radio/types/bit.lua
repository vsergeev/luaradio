---
-- Bit data type, a C structure defined as:
-- ``` c
-- typedef struct {
--     uint8_t value;
-- } bit_t;
-- ```
--
-- @datatype Bit
-- @tparam[opt=0] int value Initial value

local ffi = require('ffi')
local bit = require('bit')

local CStructType = require('radio.types.cstruct')

ffi.cdef[[
typedef struct {
    uint8_t value;
} bit_t;
]]

local mt = {}

---
-- Construct a new zero-initialized Bit vector.
--
-- @static
-- @function Bit.vector
-- @tparam int num Number of elements in the vector
-- @treturn Vector Bit vector
--
-- @usage
-- local vec = radio.types.Bit.vector(100)

---
-- Construct a Bit vector initialized from an array.
--
-- @static
-- @function Bit.vector_from_array
-- @tparam array arr Array with element initializers
-- @treturn Vector Bit vector
--
-- @usage
-- local vec = radio.types.Bit.vector_from_array({1, 0, 1, 0, 1, 1, 0})

---
-- Bitwise-AND two Bits.
--
-- @tparam Bit other Operand
-- @treturn Bit Result
function mt:band(other)
    return self.new(bit.band(self.value, other.value))
end

---
-- Bitwise-OR two Bits.
--
-- @tparam Bit other Operand
-- @treturn Bit Result
function mt:bor(other)
    return self.new(bit.bor(self.value, other.value))
end

---
-- Bitwise-XOR two Bits.
--
-- @tparam Bit other Operand
-- @treturn Bit Result
function mt:bxor(other)
    return self.new(bit.bxor(self.value, other.value))
end

---
-- Bitwise-NOT a Bit.
--
-- @treturn Bit Result
function mt:bnot()
    return self.new(bit.band(bit.bnot(self.value), 0x1))
end

---
-- Compare two Bits for equality.
--
-- @tparam Bit other Other bit
-- @treturn bool Result
function mt:__eq(other)
    return self.value == other.value
end

---
-- Get a string representation.
--
-- @treturn string String representation
-- @usage
-- local x = radio.types.Bit()
-- print(x)) --> Bit<value=0>
function mt:__tostring()
    return "Bit<value=" .. self.value .. ">"
end

---
-- Convert a Bit vector to a number.
--
-- @static
-- @tparam Vector vec Bit vector
-- @tparam[opt=0] int offset Offset
-- @tparam[opt=0] int length Length
-- @tparam[opt="msb"] string order Bit order. Choice of "msb" or "lsb".
-- @treturn number Extracted number
--
-- @usage
-- local vec = radio.types.Bit.vector_from_array({0, 1, 0, 1})
-- assert(radio.types.Bit.tonumber(vec) == 5)
-- assert(radio.types.Bit.tonumber(vec, 0, 4, 'lsb') == 10)
-- assert(radio.types.Bit.tonumber(vec, 2, 2, 'msb') == 1)
-- assert(radio.types.Bit.tonumber(vec, 2, 2, 'lsb') == 2)
function mt.tonumber(vec, offset, length, order)
    offset = offset or 0
    length = length or (vec.length - offset)
    order = order or "msb"

    local x = 0
    local msb_first = (order == "msb")

    for i = 0, length-1 do
        if vec.data[offset+i].value == 1 then
            local mask = msb_first and bit.lshift(1, length-1-i) or bit.lshift(1, i)
            x = bit.bor(x, mask)
        end
    end

    return x
end

local Bit = CStructType.factory("bit_t", mt)

return Bit
