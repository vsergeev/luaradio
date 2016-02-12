local ffi = require('ffi')

local object = require('radio.core.object')
local Vector = require('radio.core.vector').Vector

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

function mt.vector(num)
    return Vector(Float32Type, num)
end

function mt.vector_from_array(arr)
    local vec = Vector(Float32Type, #arr)
    for i = 0, vec.length-1 do
        vec.data[i] = Float32Type(arr[i+1])
    end
    return vec
end

-- Buffer serialization interface

function mt.serialize(vec)
    return vec.data, vec.size
end

function mt.deserialize(buf, count)
    local size = count*ffi.sizeof(Float32Type)
    return Vector.cast(Float32Type, buf, size), size
end

function mt.deserialize_count(buf, size)
    return math.floor(size/ffi.sizeof(Float32Type))
end

-- FFI type binding

Float32Type = ffi.metatype("float32_t", mt)

return {Float32Type = Float32Type}
