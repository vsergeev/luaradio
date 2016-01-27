local ffi = require('ffi')

local object = require('object')
require('types.vector')
local ComplexType = require('types.complextype').ComplexType

ffi.cdef[[
typedef struct {
    int32_t real;
    int32_t imag;
} complex_integer32_t;
]]

local ComplexIntegerType
local mt = object.class_factory(ComplexType)

function mt.new(value)
    return ComplexIntegerType(value)
end

function mt.alloc(n)
    return vector_alloc(ComplexIntegerType, n)
end

function mt:__tostring()
    return "ComplexInteger32<real=" .. self.real .. ", imag=" .. self.imag .. ">"
end

ComplexIntegerType = ffi.metatype("complex_integer32_t", mt)

return {ComplexIntegerType = ComplexIntegerType}
