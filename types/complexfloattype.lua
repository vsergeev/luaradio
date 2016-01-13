local ffi = require('ffi')

require('types.helpers')
local ComplexType = require('types.complextype').ComplexType

ffi.cdef[[
typedef struct {
    float real;
    float imag;
} complex_float32_t;
]]

local mt = class_factory(ComplexType)
local ComplexFloatType

function mt.new(value)
    return ComplexFloatType(value)
end

function mt.alloc(n)
    return vector_alloc(ComplexFloatType, n)
end

function mt:__tostring()
    return "ComplexFloat32<real=" .. self.real .. ", imag=" .. self.imag .. ">"
end

ComplexFloatType = ffi.metatype("complex_float32_t", mt)

return {ComplexFloatType = ComplexFloatType}
