local ffi = require('ffi')
local bit = require('bit')

local object = require('radio.core.object')
local vector = require('radio.core.vector')

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

function mt.vector(n)
    return vector.vector_calloc("bit_t *", n, ffi.sizeof(BitType))
end

function mt.vector_from_array(arr)
    local vec = mt.vector(#arr)
    for i = 0, vec.length-1 do
        vec.data[i] = BitType(arr[i+1])
    end
    return vec
end

function mt.vector_from_buf(buf, size)
    return vector.vector_cast("bit_t *", buf, size, ffi.sizeof(BitType))
end

function mt.const_vector_from_buf(buf, size)
    return vector.vector_cast("const bit_t *", buf, size, ffi.sizeof(BitType))
end

-- FFI type binding

BitType = ffi.metatype("bit_t", mt)

return {BitType = BitType}
