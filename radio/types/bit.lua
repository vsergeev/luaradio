local ffi = require('ffi')
local bit = require('bit')

local object = require('radio.core.object')
local Vector = require('radio.core.vector').Vector

ffi.cdef[[
typedef struct {
    uint8_t value;
} bit_t;
]]

local BitType
local mt = object.class_factory()

-- Operations

function mt:band(other)
    return self.new(bit.band(self.value, other.value))
end

function mt:bor(other)
    return self.new(bit.bor(self.value, other.value))
end

function mt:bxor(other)
    return self.new(bit.bxor(self.value, other.value))
end

function mt:bnot()
    return self.new(bit.bnot(self.value))
end

function mt:__eq(other)
    return self.value == other.value
end

function mt:__tostring()
    return "Bit<value=" .. self.value .. ">"
end

-- Constructors

function mt.new(value)
    return BitType(value)
end

function mt.vector(num)
    return Vector(BitType, num)
end

function mt.vector_from_array(arr)
    local vec = Vector(BitType, #arr)
    for i = 0, vec.length-1 do
        vec.data[i] = BitType(arr[i+1])
    end
    return vec
end

function mt.const_vector_from_buf(buf, size)
    return Vector.cast(BitType, buf, size)
end

-- FFI type binding

BitType = ffi.metatype("bit_t", mt)

return {BitType = BitType}
