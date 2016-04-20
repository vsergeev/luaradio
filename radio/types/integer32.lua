local ffi = require('ffi')
local bit = require('bit')

local CStructType = require('radio.types.cstruct')

ffi.cdef[[
typedef struct {
    int32_t value;
} integer32_t;
]]

local mt = {}

function mt:__add(other)
    return self.new(bit.tobit(self.value + other.value))
end

function mt:__sub(other)
    return self.new(bit.tobit(self.value - other.value))
end

function mt:__mul(other)
    return self.new(bit.tobit(self.value * other.value))
end

function mt:__div(other)
    return self.new(bit.tobit(self.value / other.value))
end

function mt:__eq(other)
    return self.value == other.value
end

function mt:__lt(other)
    return self.value < other.value
end

function mt:__le(other)
    return self.value <= other.value
end

function mt:__tostring()
    return "Integer32<value=" .. self.value .. ">"
end

local Integer32Type = CStructType.factory("integer32_t", mt)

return Integer32Type
