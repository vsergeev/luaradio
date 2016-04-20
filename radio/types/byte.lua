local ffi = require('ffi')

local CStructType = require('radio.types.cstruct')

ffi.cdef[[
typedef struct {
    uint8_t value;
} byte_t;
]]

local mt = {}

function mt:__add(other)
    return self.new(self.value + other.value)
end

function mt:__sub(other)
    return self.new(self.value - other.value)
end

function mt:__mul(other)
    return self.new(self.value * other.value)
end

function mt:__div(other)
    return self.new(self.value / other.value)
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
    return "Byte<value=" .. self.value .. ">"
end

local ByteType = CStructType.factory("byte_t", mt)

return ByteType
