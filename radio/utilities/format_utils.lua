---
-- Binary sample format conversion structures and tables.
--
-- @module radio.utilities.format_utils

local ffi = require('ffi')

ffi.cdef[[
    typedef struct {
        union { uint8_t bytes[1]; uint8_t value; };
    } format_u8_t;

    typedef struct {
        union { uint8_t bytes[1]; int8_t value; };
    } format_s8_t;

    typedef struct {
        union { uint8_t bytes[2]; uint16_t value; };
    } format_u16_t;

    typedef struct {
        union { uint8_t bytes[2]; int16_t value; };
    } format_s16_t;

    typedef struct {
        union { uint8_t bytes[4]; uint32_t value; };
    } format_u32_t;

    typedef struct {
        union { uint8_t bytes[4]; int32_t value; };
    } format_s32_t;

    typedef struct {
        union { uint8_t bytes[4]; float value; };
    } format_f32_t;

    typedef struct {
        union { uint8_t bytes[8]; double value; };
    } format_f64_t;

    typedef struct {
        union { uint8_t bytes[1]; uint8_t value; } real;
        union { uint8_t bytes[1]; uint8_t value; } imag;
    } iq_format_u8_t;

    typedef struct {
        union { uint8_t bytes[1]; int8_t value; } real;
        union { uint8_t bytes[1]; int8_t value; } imag;
    } iq_format_s8_t;

    typedef struct {
        union { uint8_t bytes[2]; uint16_t value; } real;
        union { uint8_t bytes[2]; uint16_t value; } imag;
    } iq_format_u16_t;

    typedef struct {
        union { uint8_t bytes[2]; int16_t value; } real;
        union { uint8_t bytes[2]; int16_t value; } imag;
    } iq_format_s16_t;

    typedef struct {
        union { uint8_t bytes[4]; uint32_t value; } real;
        union { uint8_t bytes[4]; uint32_t value; } imag;
    } iq_format_u32_t;

    typedef struct {
        union { uint8_t bytes[4]; int32_t value; } real;
        union { uint8_t bytes[4]; int32_t value; } imag;
    } iq_format_s32_t;

    typedef struct {
        union { uint8_t bytes[4]; float value; } real;
        union { uint8_t bytes[4]; float value; } imag;
    } iq_format_f32_t;

    typedef struct {
        union { uint8_t bytes[8]; double value; } real;
        union { uint8_t bytes[8]; double value; } imag;
    } iq_format_f64_t;
]]

local formats = {
    u8    = {real_ctype = ffi.typeof("format_u8_t"),  complex_ctype = ffi.typeof("iq_format_u8_t"),  swap = false,         offset = 127.5,         scale = 127.5},
    s8    = {real_ctype = ffi.typeof("format_s8_t"),  complex_ctype = ffi.typeof("iq_format_s8_t"),  swap = false,         offset = 0,             scale = 127.5},
    u16le = {real_ctype = ffi.typeof("format_u16_t"), complex_ctype = ffi.typeof("iq_format_u16_t"), swap = ffi.abi("be"), offset = 32767.5,       scale = 32767.5},
    u16be = {real_ctype = ffi.typeof("format_u16_t"), complex_ctype = ffi.typeof("iq_format_u16_t"), swap = ffi.abi("le"), offset = 32767.5,       scale = 32767.5},
    s16le = {real_ctype = ffi.typeof("format_s16_t"), complex_ctype = ffi.typeof("iq_format_s16_t"), swap = ffi.abi("be"), offset = 0,             scale = 32767.5},
    s16be = {real_ctype = ffi.typeof("format_s16_t"), complex_ctype = ffi.typeof("iq_format_s16_t"), swap = ffi.abi("le"), offset = 0,             scale = 32767.5},
    u32le = {real_ctype = ffi.typeof("format_u32_t"), complex_ctype = ffi.typeof("iq_format_u32_t"), swap = ffi.abi("be"), offset = 2147483647.5,  scale = 2147483647.5},
    u32be = {real_ctype = ffi.typeof("format_u32_t"), complex_ctype = ffi.typeof("iq_format_u32_t"), swap = ffi.abi("le"), offset = 2147483647.5,  scale = 2147483647.5},
    s32le = {real_ctype = ffi.typeof("format_s32_t"), complex_ctype = ffi.typeof("iq_format_s32_t"), swap = ffi.abi("be"), offset = 0,             scale = 2147483647.5},
    s32be = {real_ctype = ffi.typeof("format_s32_t"), complex_ctype = ffi.typeof("iq_format_s32_t"), swap = ffi.abi("le"), offset = 0,             scale = 2147483647.5},
    f32le = {real_ctype = ffi.typeof("format_f32_t"), complex_ctype = ffi.typeof("iq_format_f32_t"), swap = ffi.abi("be"), offset = 0,             scale = 1.0},
    f32be = {real_ctype = ffi.typeof("format_f32_t"), complex_ctype = ffi.typeof("iq_format_f32_t"), swap = ffi.abi("le"), offset = 0,             scale = 1.0},
    f64le = {real_ctype = ffi.typeof("format_f64_t"), complex_ctype = ffi.typeof("iq_format_f64_t"), swap = ffi.abi("be"), offset = 0,             scale = 1.0},
    f64be = {real_ctype = ffi.typeof("format_f64_t"), complex_ctype = ffi.typeof("iq_format_f64_t"), swap = ffi.abi("le"), offset = 0,             scale = 1.0},
}

---
-- Swap bytes of a value.
--
-- @internal
-- @function swap_bytes
-- @tparam cdata x Union type with a bytes array member.
local function swap_bytes(x)
    local len = ffi.sizeof(x.bytes)

    for i = 0, (len/2)-1 do
        x.bytes[i], x.bytes[len-i-1] = x.bytes[len-i-1], x.bytes[i]
    end
end

return {formats = formats, swap_bytes = swap_bytes}
