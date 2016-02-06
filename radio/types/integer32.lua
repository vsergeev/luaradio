local ffi = require('ffi')

local object = require('radio.core.object')
local vector = require('radio.core.vector')

ffi.cdef[[
typedef struct {
    int32_t value;
} integer32_t;
]]

local Integer32Type
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
    return "Integer32<value=" .. self.value .. ">"
end

-- Constructors

function mt.new(value)
    return Integer32Type(value)
end

function mt.vector(n)
    return vector.vector_calloc("integer32_t *", n, ffi.sizeof(Integer32Type))
end

function mt.vector_from_buf(buf, size)
    return vector.vector_cast("integer32_t *", buf, size, ffi.sizeof(Integer32Type))
end

function mt.const_vector_from_buf(buf, size)
    return vector.vector_cast("const integer32_t *", buf, size, ffi.sizeof(Integer32Type))
end

-- FFI type binding

Integer32Type = ffi.metatype("integer32_t", mt)

return {Integer32Type = Integer32Type}
