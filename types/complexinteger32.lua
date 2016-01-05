local ffi = require('ffi')
local math = require('math')

ffi.cdef[[
void *malloc(size_t size);
void *calloc(size_t nmemb, size_t size);
void free(void *ptr);

typedef struct {
    int32_t real;
    int32_t imag;
} complex_integer32_t;
]]

local ComplexInteger32Type

function complex_mul(x, y)
    if type(y) == "number" then
        return ComplexInteger32Type(x.real*y, x.imag*y)
    end
    return ComplexInteger32Type(x.real*y.real - x.imag*y.imag, x.imag*y.real + x.real*y.imag)
end

local mt = {
    __add = function(x, y) return ComplexInteger32Type(x.real+y.real, x.imag+y.imag) end,
    __sub = function(x, y) return ComplexInteger32Type(x.real-y.real, x.imag-y.imag) end,
    __mul = complex_mul,
    __eq = function(x, y) return x.real == y.real and x.imag == y.imag end,
    __tostring = function(x) return "ComplexInteger32<real=" .. x.real .. ", imag=" .. x.imag .. ">" end,
    __index = {
        conj = function(x) return ComplexInteger32Type(x.real, -x.imag) end,
        abs = function(x) return math.sqrt(x.real*x.real + x.imag*x.imag) end,
        arg = function(x) return math.atan2(x.imag, x.real) end,
    }
}
ComplexInteger32Type = ffi.metatype("complex_integer32_t", mt)

mt.__index.alloc = function(n)
    local data = ffi.cast("complex_integer32_t *", ffi.gc(ffi.C.calloc(n, ffi.sizeof(ComplexInteger32Type)), ffi.C.free))
    return setmetatable({data = data, length = n, raw_length = n*ffi.sizeof(ComplexInteger32Type)}, {__index = data, __newindex = data})
end

return {ComplexInteger32Type = ComplexInteger32Type}
