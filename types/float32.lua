local ffi = require('ffi')
local math = require('math')

ffi.cdef[[
typedef struct {
    float value;
} float32_t;
]]

local Float32Type
local mt = {
    __add = function(x, y) return Float32Type(x.value + y.value) end,
    __sub = function(x, y) return Float32Type(x.value - y.value) end,
    __mul = function(x, y) return Float32Type(x.value * y.value) end,
    __eq = function(x, y) return x.value == y.value end,
    __tostring = function(x) return "Float32<value=" .. x.value.. ">" end,
    __index = {
    }
}
Float32Type = ffi.metatype("float32_t", mt)

mt.__index.alloc = function(n)
    local data = ffi.cast("float32_t *", ffi.gc(ffi.C.calloc(n, ffi.sizeof(Float32Type)), ffi.C.free))
    return setmetatable({data = data, length = n, raw_length = n*ffi.sizeof(Float32Type)}, {__index = data, __newindex = data})
end

return {Float32Type = Float32Type}
