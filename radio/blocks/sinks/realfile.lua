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
local vector = require('radio.core.vector')
local types = require('radio.types')
local format_utils = require('radio.blocks.sources.format_utils')

local RealFileSink = block.factory("RealFileSink")

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
    if type(file) == "string" then
        self.filename = file
    elseif type(file) == "number" then
        self.fd = file
    else
        self.file = assert(file, "Missing argument #1 (file)")
    end

    self.format = assert(format_utils.formats[format], "Unsupported format (\"" .. format .. "\")")

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

    -- Allocate raw samples vector
    self.raw_samples = vector.Vector(self.format.real_ctype)

    -- Register open file
    self.files[self.file] = true
end

function RealFileSink:process(x)
    -- Resize raw samples vector
    self.raw_samples:resize(x.length)

    -- Convert Float32 samples to raw samples
    for i = 0, x.length-1 do
        self.raw_samples.data[i].value = (x.data[i].value*self.format.scale) + self.format.offset
    end

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, x.length-1 do
            format_utils.swap_bytes(self.raw_samples.data[i])
        end
    end

    -- Write to file
    local num_samples = ffi.C.fwrite(self.raw_samples.data, ffi.sizeof(self.format.real_ctype), x.length, self.file)
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
