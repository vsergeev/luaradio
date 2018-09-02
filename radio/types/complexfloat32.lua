---
-- ComplexFloat32 data type, a C structure defined as:
--
-- ``` c
-- typedef struct {
--     float real;
--     float imag;
-- } complex_float32_t;
-- ```
--
-- @datatype ComplexFloat32
-- @tparam[opt=0.0] float real Initial real part
-- @tparam[opt=0.0] float imag Initial imaginary part

local ffi = require('ffi')

local CStructType = require('radio.types.cstruct')

ffi.cdef[[
typedef struct {
    float real;
    float imag;
} complex_float32_t;
]]

ffi.cdef[[
float atan2f(float y, float x);
float sqrtf(float x);
]]

local mt = {}

---
-- Construct a zero-initialized ComplexFloat32 vector.
--
-- @function ComplexFloat32.vector
-- @tparam int num Number of elements in the vector
-- @treturn Vector ComplexFloat32 vector
--
-- @usage
-- local vec = radio.types.ComplexFloat32.vector(100)

---
-- Construct a ComplexFloat32 vector initialized from an array.
--
-- @function ComplexFloat32.vector_from_array
-- @tparam array arr Array with element initializers
-- @treturn Vector ComplexFloat32 vector
--
-- @usage
-- local vec = radio.types.ComplexFloat32.vector_from_array({{1.0, 2.0}, {2.0, 3.0}, {3.0, 4.0}})

---
-- Add two ComplexFloat32s.
--
-- @function ComplexFloat32:__add
-- @tparam ComplexFloat32 other Operand
-- @treturn ComplexFloat32 Result
function mt:__add(other)
    return self.new(self.real + other.real, self.imag + other.imag)
end

---
-- Subtract two ComplexFloat32s.
--
-- @function ComplexFloat32:__sub
-- @tparam ComplexFloat32 other Operand
-- @treturn ComplexFloat32 Result
function mt:__sub(other)
    return self.new(self.real - other.real, self.imag - other.imag)
end

---
-- Multiply two ComplexFloat32s.
--
-- @function ComplexFloat32:__mul
-- @tparam ComplexFloat32 other Operand
-- @treturn ComplexFloat32 Result
function mt:__mul(other)
    return self.new(self.real * other.real - self.imag * other.imag, self.real * other.imag + self.imag * other.real)
end

---
-- Divide two ComplexFloat32s.
--
-- @function ComplexFloat32:__div
-- @tparam ComplexFloat32 other Operand
-- @treturn ComplexFloat32 Result
function mt:__div(other)
    local real = (self.real * other.real + self.imag * other.imag) / (other.real * other.real + other.imag * other.imag)
    local imag = (self.imag * other.real - self.real * other.imag) / (other.real * other.real + other.imag * other.imag)
    return self.new(real, imag)
end

---
-- Compare two ComplexFloat32s for equality.
--
-- @function ComplexFloat32:__eq
-- @tparam ComplexFloat32 other Other ComplexFloat32
-- @treturn bool Result
function mt:__eq(other)
    return self.real == other.real and self.imag == other.imag
end

---
-- Compare two ComplexFloat32s for less than.
--
-- @function ComplexFloat32:__lt
-- @tparam ComplexFloat32 other Other ComplexFloat32
-- @treturn bool Result
function mt:__lt(other)
    return (self.real < other.real) and (self.imag < other.imag)
end

---
-- Compare two ComplexFloat32s for less than or equal.
--
-- @function ComplexFloat32:__le
-- @tparam ComplexFloat32 other Other ComplexFloat32
-- @treturn bool Result
function mt:__le(other)
    return (self.real <= other.real) and (self.imag <= other.imag)
end

---
-- Multiply a ComplexFloat32 by a scalar.
--
-- @function ComplexFloat32:scalar_mul
-- @tparam number other Scalar
-- @treturn ComplexFloat32 Result
function mt:scalar_mul(other)
    return self.new(self.real * other, self.imag * other)
end

---
-- Divide a ComplexFloat32 by a scalar.
--
-- @function ComplexFloat32:scalar_div
-- @tparam number other Scalar
-- @treturn ComplexFloat32 Result
function mt:scalar_div(other)
    return self.new(self.real / other, self.imag / other)
end

---
-- Compute the complex argument, in interval $$ (-\pi, \pi] $$.
--
-- $$ \angle z = \text{atan2}(\text{Im}(z), \text{Re}(z)) $$
--
-- @function ComplexFloat32:arg
-- @treturn number Result
function mt:arg()
    return ffi.C.atan2f(self.imag, self.real)
end

---
-- Compute the complex magnitude.
--
-- $$ |z| = \sqrt{\text{Re}(z)^2 + \text{Im}(z)^2} $$
--
-- @function ComplexFloat32:abs
-- @treturn number Result
function mt:abs()
    return ffi.C.sqrtf(self.real*self.real + self.imag*self.imag)
end

---
-- Compute the complex magnitude squared.
--
-- $$ |z|^2 = \text{Re}(z)^2 + \text{Im}(z)^2 $$
--
-- @function ComplexFloat32:abs_squared
-- @treturn number Result
function mt:abs_squared()
    return self.real*self.real + self.imag*self.imag
end

---
-- Get the complex conjugate.
--
-- @function ComplexFloat32:conj
-- @treturn ComplexFloat32 Result
function mt:conj()
    return self.new(self.real, -self.imag)
end

---
-- Compare two ComplexFloat32s for approximate equality within the specified epsilon.
--
-- @function ComplexFloat32.approx_equal
-- @tparam ComplexFloat32 x First ComplexFloat32
-- @tparam ComplexFloat32 y Second ComplexFloat32
-- @tparam number epsilon Epsilon
-- @treturn bool Result
function mt.approx_equal(x, y, epsilon)
    return (x - y):abs() < epsilon
end

---
-- Get a string representation.
--
-- @function ComplexFloat32:__tostring
-- @treturn string String representation
-- @usage
-- local x = radio.types.ComplexFloat32()
-- print(x)) --> ComplexFloat32<real=0, imag=0>
function mt:__tostring()
    return "ComplexFloat32<real=" .. self.real .. ", imag=" .. self.imag .. ">"
end

local ComplexFloat32 = CStructType.factory("complex_float32_t", mt)

return ComplexFloat32
