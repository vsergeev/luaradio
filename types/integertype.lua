local ffi = require('ffi')

require('types.helpers')
local ScalarType = require('types.scalartype').ScalarType

ffi.cdef[[
typedef struct {
    int32_t value;
} integer32_t;
]]

local mt = class_factory(ScalarType)
local IntegerType

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
