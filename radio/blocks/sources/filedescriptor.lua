local io = require('io')
local os = require('os')
local ffi = require('ffi')

local block = require('radio.core.block')
local Float32Type = require('radio.types.float32').Float32Type

local FileDescriptorSource = block.factory("FileDescriptorSource")

-- IQ Formats
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

function FileDescriptorSource:instantiate(fd, format, rate)
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
    assert(supported_formats[format], "Unsupported format \"" .. format .. "\".")

    self.fd = fd
    self.format = supported_formats[format]
    self.rate = rate

    self.chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", Float32Type)})
end

function FileDescriptorSource:get_rate()
    return self.rate
end

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fdopen(int fd, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    int feof(FILE *stream);
    int ferror(FILE *stream);
]]

function FileDescriptorSource:initialize()
    self.file = ffi.C.fdopen(self.fd, "rb")
    assert(self.file ~= nil, "fdopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

local function swap_bytes(x)
    local len = ffi.sizeof(x.bytes)
    for i = 0, (len/2)-1 do
        x.bytes[i], x.bytes[len-i-1] = x.bytes[len-i-1], x.bytes[i]
    end
end

function FileDescriptorSource:process()
    -- Allocate buffer for raw samples
    local raw_samples = ffi.new(self.format.ctype .. "[?]", self.chunk_size)

    -- Read from file
    local num_samples = tonumber(ffi.C.fread(raw_samples, ffi.sizeof(self.format.ctype), self.chunk_size, self.file))
    if num_samples < self.chunk_size then
        if num_samples == 0 and ffi.C.feof(self.file) ~= 0 then
            return nil
        else
            assert(ffi.C.ferror(self.file) == 0, "fread(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, num_samples-1 do
            swap_bytes(raw_samples[i])
        end
    end

    -- Convert raw samples to float32 samples
    local samples = Float32Type.vector(num_samples)
    for i = 0, num_samples-1 do
        samples.data[i].value = (raw_samples[i].value - self.format.offset)*self.format.scale
    end

    return samples
end

return {FileDescriptorSource = FileDescriptorSource}
