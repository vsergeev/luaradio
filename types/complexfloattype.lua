local ffi = require('ffi')

local object = require('object')
require('types.vector')
local ComplexType = require('types.complextype').ComplexType

ffi.cdef[[
typedef struct {
    float real;
    float imag;
} complex_float32_t;
]]

local ComplexFloatType
local mt = object.class_factory(ComplexType)

function mt.new(value)
    return ComplexFloatType(value)
end

function mt.alloc(n)
    return vector_alloc(ComplexFloatType, n)
end

function mt.from_buffer(buf, len)
    return {data = ffi.cast(ffi.typeof("$ *", ComplexFloatType), buf), _buf = buf, length = len/ffi.sizeof(ComplexFloatType), raw_length = len}
end

function mt:__tostring()
    return "ComplexFloat32<real=" .. self.real .. ", imag=" .. self.imag .. ">"
end

ComplexFloatType = ffi.metatype("complex_float32_t", mt)

return {ComplexFloatType = ComplexFloatType}
