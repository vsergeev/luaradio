local ffi = require('ffi')

local object = require('object')
require('types.vector')
local ScalarType = require('types.scalartype').ScalarType

ffi.cdef[[
typedef struct {
    int32_t value;
} integer32_t;
]]

local IntegerType
local mt = object.class_factory(ScalarType)

function mt.new(value)
    return IntegerType(value)
end

function mt.alloc(n)
    return vector_alloc(IntegerType, n)
end

function mt:__tostring()
    return "Integer32<value=" .. self.value .. ">"
end

IntegerType = ffi.metatype("integer32_t", mt)

return {IntegerType = IntegerType}
