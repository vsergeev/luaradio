local io = require('io')
local os = require('os')
local ffi = require('ffi')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type

local FileIQSource = block.factory("FileIQSource")

-- IQ Formats
ffi.cdef[[
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

function FileIQSource:instantiate(filename, format, rate)
    local supported_formats = {
        u8    = {ctype = "iq_format_u8_t",  swap = false,         offset = 127.5,         scale = 1.0/127.5},
        s8    = {ctype = "iq_format_s8_t",  swap = false,         offset = 0,             scale = 1.0/127.5},
        u16le = {ctype = "iq_format_u16_t", swap = ffi.abi("be"), offset = 32767.5,       scale = 1.0/32767.5},
        u16be = {ctype = "iq_format_u16_t", swap = ffi.abi("le"), offset = 32767.5,       scale = 1.0/32767.5},
        s16le = {ctype = "iq_format_s16_t", swap = ffi.abi("be"), offset = 0,             scale = 1.0/32767.5},
        s16be = {ctype = "iq_format_s16_t", swap = ffi.abi("le"), offset = 0,             scale = 1.0/32767.5},
        u32le = {ctype = "iq_format_u32_t", swap = ffi.abi("be"), offset = 2147483647.5,  scale = 1.0/2147483647.5},
        u32be = {ctype = "iq_format_u32_t", swap = ffi.abi("le"), offset = 2147483647.5,  scale = 1.0/2147483647.5},
        s32le = {ctype = "iq_format_s32_t", swap = ffi.abi("be"), offset = 2147483647.5,  scale = 1.0/2147483647.5},
        s32be = {ctype = "iq_format_s32_t", swap = ffi.abi("le"), offset = 2147483647.5,  scale = 1.0/2147483647.5},
        f32le = {ctype = "iq_format_f32_t", swap = ffi.abi("be"), offset = 0,             scale = 1.0},
        f32be = {ctype = "iq_format_f32_t", swap = ffi.abi("le"), offset = 0,             scale = 1.0},
        f64le = {ctype = "iq_format_f64_t", swap = ffi.abi("be"), offset = 0,             scale = 1.0},
        f64be = {ctype = "iq_format_f64_t", swap = ffi.abi("le"), offset = 0,             scale = 1.0},
    }
    assert(supported_formats[format], "Unsupported format \"" .. format .. "\".")

    self._filename = filename
    self._format = supported_formats[format]
    self._rate = rate

    self._chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", ComplexFloat32Type)})
end

function FileIQSource:get_rate()
    return self._rate
end

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    int feof(FILE *stream);
    int ferror(FILE *stream);
]]

function FileIQSource:initialize()
    self.file = ffi.C.fopen(self._filename, "rb")
    assert(self.file ~= nil, "fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

local function swap_bytes(x)
    local len = ffi.sizeof(x.bytes)
    for i = 0, (len/2)-1 do
        x.bytes[i], x.bytes[len-i-1] = x.bytes[len-i-1], x.bytes[i]
    end
end

function FileIQSource:process()
    -- Allocate buffer for raw samples
    local raw_samples = ffi.new(self._format.ctype .. "[?]", self._chunk_size)

    -- Read from file
    local num_samples = tonumber(ffi.C.fread(raw_samples, ffi.sizeof(self._format.ctype), self._chunk_size, self.file))
    if num_samples < self._chunk_size then
        if ffi.C.feof(self.file) ~= 0 then
            io.stderr:write("FileIQSource: EOF reached.\n")
            os.exit()
        else
            assert(ffi.C.ferror(self.file) == 0, "fread(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    -- Perform byte swap for endianness if needed
    if self._format.swap then
        for i = 0, num_samples-1 do
            swap_bytes(raw_samples[i].real)
            swap_bytes(raw_samples[i].imag)
        end
    end

    -- Convert raw samples to complex float32 samples
    local samples = ComplexFloat32Type.vector(num_samples)
    for i = 0, num_samples-1 do
        samples.data[i].real = (raw_samples[i].real.value - self._format.offset)*self._format.scale
        samples.data[i].imag = (raw_samples[i].imag.value - self._format.offset)*self._format.scale
    end

    return samples
end

return {FileIQSource = FileIQSource}
