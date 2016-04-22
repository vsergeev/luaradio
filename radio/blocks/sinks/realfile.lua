---
-- Sink a real-valued signal to a binary file. The file format may be
-- 8/16/32-bit signed/unsigned integers or 32/64-bit floats, in little or big
-- endianness. This is the real-valued counterpart of
-- [`IQFileSink`](#iqfilesink).
--
-- @category Sinks
-- @block RealFileSink
-- @tparam string|file|int file Filename, file object, or file descriptor
-- @tparam string format File format specifying signedness, bit width, and
--                       endianness of samples. Choice of "s8", "u8", "u16le",
--                       "u16be", "s16le", "s16be", "u32le", "u32be", "s32le",
--                       "s32be", "f32le", "f32be", "f64le", "f64be".
--
-- @signature in:Float32 >
--
-- @usage
-- -- Sink signed 8-bit real samples to a file
-- local snk = radio.RealFileSink('samples.s8.real', 's8')
--
-- -- Sink little-endian 32-bit real samples to a file
-- local snk = radio.RealFileSink('samples.f32le.real', 'f32le', 1e6, true)
--
-- -- Sink little-endian signed 16-bit real samples to stdout
-- local snk = radio.RealFileSink(1, 's16le')

local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local RealFileSink = block.factory("RealFileSink")

-- Real Formats
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
]]

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    FILE *fdopen(int fd, const char *mode);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fclose(FILE *stream);
    int fflush(FILE *stream);
]]

function RealFileSink:instantiate(file, format)
    local supported_formats = {
        u8    = {ctype = "format_u8_t",  swap = false,         offset = 127.5,         scale = 1.0/127.5},
        s8    = {ctype = "format_s8_t",  swap = false,         offset = 0,             scale = 1.0/127.5},
        u16le = {ctype = "format_u16_t", swap = ffi.abi("be"), offset = 32767.5,       scale = 1.0/32767.5},
        u16be = {ctype = "format_u16_t", swap = ffi.abi("le"), offset = 32767.5,       scale = 1.0/32767.5},
        s16le = {ctype = "format_s16_t", swap = ffi.abi("be"), offset = 0,             scale = 1.0/32767.5},
        s16be = {ctype = "format_s16_t", swap = ffi.abi("le"), offset = 0,             scale = 1.0/32767.5},
        u32le = {ctype = "format_u32_t", swap = ffi.abi("be"), offset = 2147483647.5,  scale = 1.0/2147483647.5},
        u32be = {ctype = "format_u32_t", swap = ffi.abi("le"), offset = 2147483647.5,  scale = 1.0/2147483647.5},
        s32le = {ctype = "format_s32_t", swap = ffi.abi("be"), offset = 0,             scale = 1.0/2147483647.5},
        s32be = {ctype = "format_s32_t", swap = ffi.abi("le"), offset = 0,             scale = 1.0/2147483647.5},
        f32le = {ctype = "format_f32_t", swap = ffi.abi("be"), offset = 0,             scale = 1.0},
        f32be = {ctype = "format_f32_t", swap = ffi.abi("le"), offset = 0,             scale = 1.0},
        f64le = {ctype = "format_f64_t", swap = ffi.abi("be"), offset = 0,             scale = 1.0},
        f64be = {ctype = "format_f64_t", swap = ffi.abi("le"), offset = 0,             scale = 1.0},
    }

    if type(file) == "string" then
        self.filename = file
    elseif type(file) == "number" then
        self.fd = file
    else
        self.file = assert(file, "Missing argument #1 (file)")
    end

    self.format = assert(supported_formats[format], "Unsupported format (\"" .. format .. "\")")

    self:add_type_signature({block.Input("in", types.Float32)}, {})
end

function RealFileSink:initialize()
    if self.filename then
        self.file = ffi.C.fopen(self.filename, "wb")
        if self.file == nil then
            error("fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    elseif self.fd then
        self.file = ffi.C.fdopen(self.fd, "wb")
        if self.file == nil then
            error("fdopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    -- Register open file
    self.files[self.file] = true
end

local function swap_bytes(x)
    local len = ffi.sizeof(x.bytes)

    for i = 0, (len/2)-1 do
        x.bytes[i], x.bytes[len-i-1] = x.bytes[len-i-1], x.bytes[i]
    end
end

function RealFileSink:process(x)
    -- Allocate buffer for binary samples
    local raw_samples = ffi.new(self.format.ctype .. "[?]", x.length)

    -- Convert Float32 samples to raw samples
    for i = 0, x.length-1 do
        raw_samples[i].value = (x.data[i].value/self.format.scale) + self.format.offset
    end

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, x.length-1 do
            swap_bytes(raw_samples[i])
        end
    end

    -- Write to file
    local num_samples = ffi.C.fwrite(raw_samples, ffi.sizeof(self.format.ctype), x.length, self.file)
    if num_samples ~= x.length then
        error("fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
end

function RealFileSink:cleanup()
    if self.filename then
        if ffi.C.fclose(self.file) ~= 0 then
            error("fclose(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    else
        if ffi.C.fflush(self.file) ~= 0 then
            error("fflush(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end
end

return RealFileSink
