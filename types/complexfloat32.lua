local ffi = require('ffi')
local math = require('math')

ffi.cdef[[
void *malloc(size_t size);
void *calloc(size_t nmemb, size_t size);
void free(void *ptr);

typedef struct {
    float real;
    float imag;
} complex_float32_t;
]]

local ComplexFloat32Type

function complex_mul(x, y)
    if type(y) == "number" then
        return ComplexFloat32Type(x.real*y, x.imag*y)
    end
    -- FIXME hardcoded for Float32
    return ComplexFloat32Type(x.real*y.value, x.imag*y.value)
end

local mt = {
    __add = function(x, y) return ComplexFloat32Type(x.real+y.real, x.imag+y.imag) end,
    __sub = function(x, y) return ComplexFloat32Type(x.real-y.real, x.imag-y.imag) end,
    __mul = complex_mul,
    __eq = function(x, y) return x.real == y.real and x.imag == y.imag end,
    __tostring = function(x) return "ComplexFloat32<real=" .. x.real .. ", imag=" .. x.imag .. ">" end,
    __index = {
        conj = function(x) return ComplexFloat32Type(x.real, -x.imag) end,
        abs = function(x) return math.sqrt(x.real*x.real + x.imag*x.imag) end,
        arg = function(x) return math.atan2(x.imag, x.real) end,
    }
}
ComplexFloat32Type = ffi.metatype("complex_float32_t", mt)

mt.__index.alloc = function(n)
    local data = ffi.cast("complex_float32_t *", ffi.gc(ffi.C.calloc(n, ffi.sizeof(ComplexFloat32Type)), ffi.C.free))
    return setmetatable({data = data, length = n, raw_length = n*ffi.sizeof(ComplexFloat32Type)}, {__index = data, __newindex = data})
end

return {ComplexFloat32Type = ComplexFloat32Type}
