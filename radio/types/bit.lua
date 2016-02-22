local ffi = require('ffi')
local bit = require('bit')

local CStructType = require('radio.types.cstruct').CStructType

ffi.cdef[[
typedef struct {
    uint8_t value;
} bit_t;
]]

local mt = {}

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
    return self.new(bit.band(bit.bnot(self.value), 0x1))
end

function mt:__eq(other)
    return self.value == other.value
end

function mt:__tostring()
    return "Bit<value=" .. self.value .. ">"
end

local BitType = CStructType.factory("bit_t", mt)

-- Helper function

local function bits_to_number(bits, offset, length, msb_first)
    local x = 0

    offset = offset or 0
    length = length or (bits.length - offset)
    msb_first = (msb_first == nil) and true or msb_first

    for i = 0, length-1 do
        if bits.data[offset+i].value == 1 then
            local mask = msb_first and bit.lshift(1, length-1-i) or bit.lshift(1, i)
            x = bit.bor(x, mask)
        end
    end

    return x
end

return {BitType = BitType, bits_to_number = bits_to_number}
