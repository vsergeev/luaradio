local ffi = require('ffi')

local object = require('radio.core.object')
local Vector = require('radio.core.vector').Vector

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

function mt.vector(num)
    return Vector(ByteType, num)
end

function mt.vector_from_array(arr)
    local vec = Vector(ByteType, #arr)
    for i = 0, vec.length-1 do
        vec.data[i] = ByteType(arr[i+1])
    end
    return vec
end

-- Buffer serialization interface

function mt.serialize(vec)
    return vec.data, vec.size
end

function mt.deserialize(buf, count)
    local size = count*ffi.sizeof(ByteType)
    return Vector.cast(ByteType, buf, size), size
end

function mt.deserialize_count(buf, size)
    return math.floor(size/ffi.sizeof(ByteType))
end

-- FFI type binding

ByteType = ffi.metatype("byte_t", mt)

return {ByteType = ByteType}
