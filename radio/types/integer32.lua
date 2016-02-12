local ffi = require('ffi')

local object = require('radio.core.object')
local Vector = require('radio.core.vector').Vector

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

function mt.vector(num)
    return Vector(Integer32Type, num)
end

function mt.vector_from_array(arr)
    local vec = Vector(Integer32Type, #arr)
    for i = 0, vec.length-1 do
        vec.data[i] = Integer32Type(arr[i+1])
    end
    return vec
end

-- Buffer serialization interface

function mt.serialize(vec)
    return vec.data, vec.size
end

function mt.deserialize(buf, count)
    local size = count*ffi.sizeof(Integer32Type)
    return Vector.cast(Integer32Type, buf, size), size
end

function mt.deserialize_count(buf, size)
    return math.floor(size/ffi.sizeof(Integer32Type))
end

-- FFI type binding

Integer32Type = ffi.metatype("integer32_t", mt)

return {Integer32Type = Integer32Type}
