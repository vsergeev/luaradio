local ffi = require('ffi')

local CStructType = require('radio.types.cstruct')

ffi.cdef[[
typedef struct {
    float value;
} float32_t;
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

function mt.approx_equal(x, y, epsilon)
    return math.abs((x - y).value) < epsilon
end

function mt:__tostring()
    return "Float32<value=" .. self.value .. ">"
end

local Float32Type = CStructType.factory("float32_t", mt)

return Float32Type
