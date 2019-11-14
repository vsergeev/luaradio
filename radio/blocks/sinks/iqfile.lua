---
-- Sink a complex-valued signal to a binary "IQ" file. The file format may be
-- 8/16/32-bit signed/unsigned integers or 32/64-bit floats, in little or big
-- endianness, and will be interleaved as real component followed by imaginary
-- component.
--
-- @category Sinks
-- @block IQFileSink
-- @tparam string|file|int file Filename, file object, or file descriptor
-- @tparam string format File format specifying signedness, bit width, and
--                       endianness of samples. Choice of "s8", "u8", "u16le",
--                       "u16be", "s16le", "s16be", "u32le", "u32be", "s32le",
--                       "s32be", "f32le", "f32be", "f64le", "f64be".
--
-- @signature in:ComplexFloat32 >
--
-- @usage
-- -- Sink signed 8-bit IQ samples to a file
-- local snk = radio.IQFileSink('samples.s8.iq', 's8')
--
-- -- Sink little-endian 32-bit IQ samples to a file
-- local snk = radio.IQFileSink('samples.f32le.iq', 'f32le')
--
-- -- Sink little-endian signed 16-bit IQ samples to stdout
-- local snk = radio.IQFileSink(1, 's16le')

local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')
local format_utils = require('radio.blocks.sources.format_utils')

local IQFileSink = block.factory("IQFileSink")

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    FILE *fdopen(int fd, const char *mode);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fclose(FILE *stream);
    int fflush(FILE *stream);
]]

function IQFileSink:instantiate(file, format)
    if type(file) == "string" then
        self.filename = file
    elseif type(file) == "number" then
        self.fd = file
    else
        self.file = assert(file, "Missing argument #1 (file)")
    end

    assert(format, "Missing argument #2 (format)")
    self.format = assert(format_utils.formats[format], "Unsupported format (\"" .. format .. "\")")

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {})
end

function IQFileSink:initialize()
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

function IQFileSink:process(x)
    -- Allocate buffer for binary samples
    local raw_samples = ffi.new(ffi.typeof("$ [?]", self.format.complex_ctype), x.length)

    -- Convert ComplexFloat32 samples to raw samples
    for i = 0, x.length-1 do
        raw_samples[i].real.value = (x.data[i].real*self.format.scale) + self.format.offset
        raw_samples[i].imag.value = (x.data[i].imag*self.format.scale) + self.format.offset
    end

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, x.length-1 do
            format_utils.swap_bytes(raw_samples[i].real)
            format_utils.swap_bytes(raw_samples[i].imag)
        end
    end

    -- Write to file
    local num_samples = ffi.C.fwrite(raw_samples, ffi.sizeof(self.format.complex_ctype), x.length, self.file)
    if num_samples ~= x.length then
        error("fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
end

function IQFileSink:cleanup()
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

return IQFileSink
