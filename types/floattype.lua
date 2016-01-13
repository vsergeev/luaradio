local ffi = require('ffi')

require('types.helpers')
local ScalarType = require('types.scalartype').ScalarType

ffi.cdef[[
typedef struct {
    float value;
} float32_t;
]]

local mt = class_factory(ScalarType)
local FloatType

function mt.new(value)
    return FloatType(value)
end

function mt.alloc(n)
    return vector_alloc(FloatType, n)
end

function mt:__tostring()
    return "Float32<value=" .. self.value .. ">"
end

FloatType = ffi.metatype("float32_t", mt)

return {FloatType = FloatType}
