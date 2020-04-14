---
-- Byte data type, a C structure defined as:
--
-- ``` c
-- typedef struct byte {
--     uint8_t value;
-- } byte_t;
-- ```
--
-- @datatype Byte
-- @tparam[opt=0] int value Initial value

local ffi = require('ffi')

local CStructType = require('radio.types.cstruct')

ffi.cdef[[
typedef struct byte {
    uint8_t value;
} byte_t;
]]

local mt = {}

---
-- Construct a zero-initialized Byte vector.
--
-- @function Byte.vector
-- @tparam int num Number of elements in the vector
-- @treturn Vector Byte vector
--
-- @usage
-- local vec = radio.types.Byte.vector(100)

---
-- Construct a Byte vector initialized from an array.
--
-- @function Byte.vector_from_array
-- @tparam array arr Array with element initializers
-- @treturn Vector Byte vector
--
-- @usage
-- local vec = radio.types.Byte.vector_from_array({0xde, 0xad, 0xbe, 0xef})

---
-- Add two Bytes.
--
-- @function Byte:__add
-- @tparam Bit other Operand
-- @treturn Byte Result
function mt:__add(other)
    return self.new(self.value + other.value)
end

---
-- Subtract two Bytes.
--
-- @function Byte:__sub
-- @tparam Bit other Operand
-- @treturn Byte Result
function mt:__sub(other)
    return self.new(self.value - other.value)
end

---
-- Multiply two Bytes.
--
-- @function Byte:__mul
-- @tparam Bit other Operand
-- @treturn Byte Result
function mt:__mul(other)
    return self.new(self.value * other.value)
end

---
-- Divide two Bytes.
--
-- @function Byte:__div
-- @tparam Bit other Operand
-- @treturn Byte Result
function mt:__div(other)
    return self.new(self.value / other.value)
end

---
-- Compare two Bytes for equality.
--
-- @function Byte:__eq
-- @tparam Bit other Other byte
-- @treturn bool Result
function mt:__eq(other)
    return self.value == other.value
end

---
-- Compare two Bytes for less than.
--
-- @function Byte:__lt
-- @tparam Bit other Other byte
-- @treturn bool Result
function mt:__lt(other)
    return self.value < other.value
end

---
-- Compare two Bytes for less than or equal.
--
-- @function Byte:__le
-- @tparam Bit other Other byte
-- @treturn bool Result
function mt:__le(other)
    return self.value <= other.value
end

---
-- Get a string representation.
--
-- @function Byte:__tostring
-- @treturn string String representation
-- @usage
-- local x = radio.types.Byte()
-- print(x)) --> Byte<value=0>
function mt:__tostring()
    return "Byte<value=" .. self.value .. ">"
end

---
-- Type name of Byte.
--
-- @property Byte.type_name
-- @treturn string Type name
-- @usage
-- print(radio.types.Byte.type_name) --> Byte
mt.type_name = "Byte"

local Byte = CStructType.factory("byte_t", mt)

return Byte
