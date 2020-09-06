---
-- Bit data type, a C structure defined as:
--
-- ``` c
-- typedef struct bit {
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
typedef struct bit {
    uint8_t value;
} bit_t;
]]

local mt = {}

---
-- Construct a zero-initialized Bit vector.
--
-- @function Bit.vector
-- @tparam int num Number of elements in the vector
-- @treturn Vector Bit vector
--
-- @usage
-- local vec = radio.types.Bit.vector(100)

---
-- Construct a Bit vector initialized from an array.
--
-- @function Bit.vector_from_array
-- @tparam array arr Array with element initializers
-- @treturn Vector Bit vector
--
-- @usage
-- local vec = radio.types.Bit.vector_from_array({1, 0, 1, 0, 1, 1, 0})

---
-- Bitwise-AND two Bits.
--
-- @function Bit:band
-- @tparam Bit other Operand
-- @treturn Bit Result
function mt:band(other)
    return self.new(bit.band(self.value, other.value))
end

---
-- Bitwise-OR two Bits.
--
-- @function Bit:bor
-- @tparam Bit other Operand
-- @treturn Bit Result
function mt:bor(other)
    return self.new(bit.bor(self.value, other.value))
end

---
-- Bitwise-XOR two Bits.
--
-- @function Bit:bxor
-- @tparam Bit other Operand
-- @treturn Bit Result
function mt:bxor(other)
    return self.new(bit.bxor(self.value, other.value))
end

---
-- Bitwise-NOT a Bit.
--
-- @function Bit:bnot
-- @treturn Bit Result
function mt:bnot()
    return self.new(bit.band(bit.bnot(self.value), 0x1))
end

---
-- Compare two Bits for equality.
--
-- @function Bit:__eq
-- @tparam Bit other Other bit
-- @treturn bool Result
function mt:__eq(other)
    return self.value == other.value
end

---
-- Get a string representation.
--
-- @function Bit:__tostring
-- @treturn string String representation
-- @usage
-- local x = radio.types.Bit()
-- print(x)) --> Bit<value=0>
function mt:__tostring()
    return "Bit<value=" .. self.value .. ">"
end

---
-- Type name of Bit.
--
-- @property Bit.type_name
-- @treturn string Type name
-- @usage
-- print(radio.types.Bit.type_name) --> Bit
mt.type_name = "Bit"

---
-- Convert a Bit vector to a number.
--
-- @function Bit.tonumber
-- @tparam Vector vec Bit vector
-- @tparam[opt=0] int offset Offset in bits
-- @tparam[opt] int length Length in bits
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

---
-- Convert a Bit vector to a byte string. Assumes MSB bit order.
--
-- @function Bit.tobytes
-- @tparam Vector vec Bit vector
-- @tparam[opt=0] int offset Offset in bits
-- @tparam[opt] int length Length in bits
-- @treturn string Extracted bytes
--
-- @usage
-- -- Convert bits starting at offset 16 to an 8-byte byte string
-- local data = radio.types.Bit.tobytes(vec, 16, 10*8)
function mt.tobytes(vec, offset, length)
    offset = offset or 0
    length = length or (vec.length - offset)

    assert(length % 8 == 0, "Length is not a multiple of 8 bits")

    local s = ""

    for i = 0, length-1, 8 do
        local x = 0
        for j = 0, 7 do
            if vec.data[offset + i + j].value == 1 then
                x = bit.bor(x, bit.lshift(1, 7 - j))
            end
        end
        s = s .. string.char(x)
    end

    return s
end

---
-- Format a Bit vector to a string. Assumes MSB bit order.
--
-- @function Bit.tostring
-- @tparam Vector vec Bit vector
-- @tparam[opt=0] int offset Offset in bits
-- @tparam[opt] int length Length in bits
-- @treturn string Formatted bit string
--
-- @usage
-- local vec = radio.types.Bit.vector_from_array({0, 1, 0, 1, 1, 1})
-- print(radio.types.Bit.tostring(vec)) --> '010111'
-- print(radio.types.Bit.tostring(vec, 1, 4)) --> '1011'
function mt.tostring(vec, offset, length)
    offset = offset or 0
    length = length or (vec.length - offset)

    local s = ""

    for i = 0, length-1 do
        s = s .. (vec.data[offset + i].value == 1 and '1' or '0')
    end

    return s
end

local Bit = CStructType.factory("bit_t", mt)

return Bit
