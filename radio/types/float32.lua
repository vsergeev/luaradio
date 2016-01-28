local ffi = require('ffi')

local object = require('radio.core.object')
local vector = require('radio.core.vector')

ffi.cdef[[
typedef struct {
    float value;
} float32_t;
]]

local Float32Type
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
    return "Float32<value=" .. self.value .. ">"
end

-- Constructors

function mt.new(value)
    return Float32Type(value)
end

function mt.vector(n)
    return vector.vector_calloc("float32_t *", n, ffi.sizeof(Float32Type))
end

function mt.vector_from_buf(buf, size)
    return vector.vector_cast("float32_t *", buf, size, ffi.sizeof(Float32Type))
end

function mt.vector_from_const_buf(buf, size)
    return vector.vector_cast("const float32_t *", buf, size, ffi.sizeof(Float32Type))
end

-- FFI type binding

Float32Type = ffi.metatype("float32_t", mt)

return {Float32Type = Float32Type}
