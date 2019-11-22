---
-- Source a real-valued signal from a binary file. The file format may be
-- 8/16/32-bit signed/unsigned integers or 32/64-bit floats, in little or big
-- endianness. This is the real-valued counterpart of
-- [`IQFileSource`](#iqfilesource).
--
-- @category Sources
-- @block RealFileSource
-- @tparam string|file|int file Filename, file object, or file descriptor
-- @tparam string format File format specifying signedness, bit width, and
--                       endianness of samples. Choice of "s8", "u8", "u16le",
--                       "u16be", "s16le", "s16be", "u32le", "u32be", "s32le",
--                       "s32be", "f32le", "f32be", "f64le", "f64be".
-- @tparam number rate Sample rate in Hz
-- @tparam[opt=false] bool repeat_on_eof Repeat on end of file
--
-- @signature > out:Float32
--
-- @usage
-- -- Source signed 8-bit real samples from a file sampled at 1 MHz
-- local src = radio.RealFileSource('samples.s8.real', 's8', 1e6)
--
-- -- Source little-endian 32-bit real samples from a file sampled at 1 MHz, repeating on EOF
-- local src = radio.RealFileSource('samples.f32le.real', 'f32le', 1e6, true)
--
-- -- Source little-endian signed 16-bit real samples from stdin sampled at 500 kHz
-- local src = radio.RealFileSource(0, 's16le', 500e3)

local ffi = require('ffi')

local block = require('radio.core.block')
local vector = require('radio.core.vector')
local types = require('radio.types')
local format_utils = require('radio.utilities.format_utils')

local RealFileSource = block.factory("RealFileSource")

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    FILE *fdopen(int fd, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    void rewind(FILE *stream);
    int feof(FILE *stream);
    int ferror(FILE *stream);
    int fclose(FILE *stream);
]]

function RealFileSource:instantiate(file, format, rate, repeat_on_eof)
    if type(file) == "string" then
        self.filename = file
    elseif type(file) == "number" then
        self.fd = file
    else
        self.file = assert(file, "Missing argument #1 (file)")
    end

    assert(format, "Missing argument #2 (format)")
    self.format = assert(format_utils.formats[format], "Unsupported format (\"" .. format .. "\")")
    self.rate = assert(rate, "Missing argument #3 (rate)")
    self.repeat_on_eof = repeat_on_eof or false

    self.chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", types.Float32)})
end

function RealFileSource:get_rate()
    return self.rate
end

function RealFileSource:initialize()
    if self.filename then
        self.file = ffi.C.fopen(self.filename, "rb")
        if self.file == nil then
            error("fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    elseif self.fd then
        self.file = ffi.C.fdopen(self.fd, "rb")
        if self.file == nil then
            error("fdopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    -- Register open file
    self.files[self.file] = true

    -- Create sample vectors
    self.raw_samples = vector.Vector(self.format.real_ctype, self.chunk_size)
    self.out = types.Float32.vector()
end

function RealFileSource:process()
    -- Read from file
    local num_samples = tonumber(ffi.C.fread(self.raw_samples.data, ffi.sizeof(self.raw_samples.data_type), self.raw_samples.length, self.file))
    if num_samples < self.chunk_size then
        if num_samples == 0 and ffi.C.feof(self.file) ~= 0 then
            if self.repeat_on_eof then
                ffi.C.rewind(self.file)
            else
                return nil
            end
        else
            if ffi.C.ferror(self.file) ~= 0 then
                error("fread(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end
        end
    end

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, num_samples-1 do
            format_utils.swap_bytes(self.raw_samples.data[i])
        end
    end

    -- Convert raw samples to float32 samples
    local out = self.out:resize(num_samples)

    for i = 0, num_samples-1 do
        out.data[i].value = (self.raw_samples.data[i].value - self.format.offset)/self.format.scale
    end

    return out
end

function RealFileSource:cleanup()
    if self.filename then
        if ffi.C.fclose(self.file) ~= 0 then
            error("fclose(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end
end

return RealFileSource
