---
-- Float32 data type, a C structure defined as:
-- ``` c
-- typedef struct {
--     float value;
-- } float32_t;
-- ```
--
-- @datatype Float32
-- @tparam[opt=0.0] float value Initial value

local ffi = require('ffi')

local CStructType = require('radio.types.cstruct')

ffi.cdef[[
typedef struct {
    float value;
} float32_t;
]]

local mt = {}

---
-- Construct a new zero-initialized Float32 vector.
--
-- @static
-- @function Float32.vector
-- @tparam int num Number of elements in the vector
-- @treturn Vector Float32 vector
--
-- @usage
-- local vec = radio.types.Float32.vector(100)

---
-- Construct a Float32 vector initialized from an array.
--
-- @static
-- @function Float32.vector_from_array
-- @tparam array arr Array with element initializers
-- @treturn Vector Float32 vector
--
-- @usage
-- local vec = radio.types.Float32.vector_from_array({1.0, 2.0, 3.0})

---
-- Add two Float32s.
--
-- @tparam Float32 other Operand
-- @treturn Float32 Result
function mt:__add(other)
    return self.new(self.value + other.value)
end

---
-- Subtract two Float32s.
--
-- @tparam Float32 other Operand
-- @treturn Float32 Result
function mt:__sub(other)
    return self.new(self.value - other.value)
end

---
-- Multiply two Float32s.
--
-- @tparam Float32 other Operand
-- @treturn Float32 Result
function mt:__mul(other)
    return self.new(self.value * other.value)
end

---
-- Divide two Float32s.
--
-- @tparam Float32 other Operand
-- @treturn Float32 Result
function mt:__div(other)
    return self.new(self.value / other.value)
end

---
-- Compare two Float32s for equality.
--
-- @tparam Float32 other Other Float32
-- @treturn bool Result
function mt:__eq(other)
    return self.value == other.value
end

---
-- Compare two Float32s for less than.
--
-- @tparam Float32 other Other Float32
-- @treturn bool Result
function mt:__lt(other)
    return self.value < other.value
end

---
-- Compare two Float32s for less than or equal.
--
-- @tparam Float32 other Other Float32
-- @treturn bool Result
function mt:__le(other)
    return self.value <= other.value
end

---
-- Compare two Float32s for approximate equality within the specified epsilon.
--
-- @static
-- @tparam Float32 x First Float32
-- @tparam Float32 y Second Float32
-- @tparam number epsilon Epsilon
-- @treturn bool Result
function mt.approx_equal(x, y, epsilon)
    return math.abs((x - y).value) < epsilon
end

---
-- Get a string representation.
--
-- @treturn string String representation
-- @usage
-- local x = radio.types.Float32()
-- print(x)) --> Float32<value=0>
function mt:__tostring()
    return "Float32<value=" .. self.value .. ">"
end

local Float32 = CStructType.factory("float32_t", mt)

return Float32
