local ffi = require('ffi')

local object = require('radio.core.object')
local vector = require('radio.core.vector')

ffi.cdef[[
typedef struct {
    uint8_t value;
} byte_t;
]]

local ByteType
local mt = object.class_factory()

-- Operations

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

-- Constructors

function mt.new(value)
    return ByteType(value)
end

function mt.vector(n)
    return vector.vector_calloc("byte_t *", n, ffi.sizeof(ByteType))
end

function mt.vector_from_buf(buf, size)
    return vector.vector_cast("byte_t *", buf, size, ffi.sizeof(ByteType))
end

function mt.vector_from_const_buf(buf, size)
    return vector.vector_cast("const byte_t *", buf, size, ffi.sizeof(ByteType))
end

-- FFI type binding

ByteType = ffi.metatype("byte_t", mt)

return {ByteType = ByteType}
