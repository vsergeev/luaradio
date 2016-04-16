local ffi = require('ffi')

local CStructType = require('radio.types.cstruct').CStructType

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

function mt:__add(other)
    return self.new(self.real + other.real, self.imag + other.imag)
end

function mt:__sub(other)
    return self.new(self.real - other.real, self.imag - other.imag)
end

function mt:__mul(other)
    return self.new(self.real * other.real - self.imag * other.imag, self.real * other.imag + self.imag * other.real)
end

function mt:__div(other)
    local real = (self.real * other.real + self.imag * other.imag) / (other.real * other.real + other.imag * other.imag)
    local imag = (self.imag * other.real - self.real * other.imag) / (other.real * other.real + other.imag * other.imag)
    return self.new(real, imag)
end

function mt:__eq(other)
    return self.real == other.real and self.imag == other.imag
end

function mt:__lt(other)
    return (self.real < other.real) and (self.imag < other.imag)
end

function mt:__le(other)
    return (self.real <= other.real) and (self.imag <= other.imag)
end

function mt:scalar_mul(other)
    return self.new(self.real * other, self.imag * other)
end

function mt:scalar_div(other)
    return self.new(self.real / other, self.imag / other)
end

function mt:arg()
    return ffi.C.atan2f(self.imag, self.real)
end

function mt:abs()
    return ffi.C.sqrtf(self.real*self.real + self.imag*self.imag)
end

function mt:abs_squared()
    return self.real*self.real + self.imag*self.imag
end

function mt:conj()
    return self.new(self.real, -self.imag)
end

function mt.approx_equal(x, y, epsilon)
    return (x - y):abs() < epsilon
end

function mt:__tostring()
    return "ComplexFloat32<real=" .. self.real .. ", imag=" .. self.imag .. ">"
end

local ComplexFloat32Type = CStructType.factory("complex_float32_t", mt)

return {ComplexFloat32Type = ComplexFloat32Type}
