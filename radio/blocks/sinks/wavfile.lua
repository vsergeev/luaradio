---
-- Sink one or more real-valued signals to a WAV file. The supported sample
-- formats are 8-bit unsigned integer, 16-bit signed integer, and 32-bit signed
-- integer.
--
-- @category Sinks
-- @block WAVFileSink
-- @tparam string|file|int file Filename, file object, or file descriptor
-- @tparam int num_channels Number of channels (e.g. 1 for mono, 2 for stereo, etc.)
-- @tparam[opt=16] int bits_per_sample Bits per sample, choice of 8, 16, or 32
--
-- @signature in:Float32 >
-- @signature in1:Float32, in2:Float32, ... >
--
-- @usage
-- -- Sink to a one channel WAV file
-- local snk = radio.WAVFileSink('test.wav', 1)
-- top:connect(src, snk)
--
-- -- Sink to a two channel WAV file
-- local snk = radio.WAVFileSink('test.wav', 2)
-- top:connect(src1, 'out', snk, 'in1')
-- top:connect(src2, 'out', snk, 'in2')

local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')
local format_utils = require('radio.blocks.sources.format_utils')

local WAVFileSink = block.factory("WAVFileSink")

-- WAV File Headers and Samples
ffi.cdef[[
    typedef struct {
        char id[4];
        uint32_t size;
        char format[4];
    } riff_header_t;

    typedef struct {
        char id[4];
        uint32_t size;
        uint16_t audio_format;
        uint16_t num_channels;
        uint32_t sample_rate;
        uint32_t byte_rate;
        uint16_t block_align;
        uint16_t bits_per_sample;
    } wave_subchunk1_header_t;

    typedef struct {
        char id[4];
        uint32_t size;
    } wave_subchunk2_header_t;
]]

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    FILE *fdopen(int fd, const char *mode);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
    void rewind(FILE *stream);
    int fseek(FILE *stream, long offset, int whence);
    enum {SEEK_SET = 0, SEEK_CUR = 1, SEEK_END = 2};
    int fclose(FILE *stream);
    int fflush(FILE *stream);
]]

local wave_formats = {
    [8]     = format_utils.formats.u8,
    [16]    = format_utils.formats.s16le,
    [32]    = format_utils.formats.s32le,
}

function WAVFileSink:instantiate(file, num_channels, bits_per_sample)
    if type(file) == "string" then
        self.filename = file
    elseif type(file) == "number" then
        self.fd = file
    else
        self.file = assert(file, "Missing argument #1 (file)")
    end

    self.num_channels = assert(num_channels, "Missing argument #2 (num_channels)")
    self.bits_per_sample = bits_per_sample or 16
    self.format = assert(wave_formats[self.bits_per_sample], string.format("Unsupported bits per sample (%s)", tostring(bits_per_sample)))

    self.num_samples = 0
    self.count = 0

    -- Build type signature
    if num_channels == 1 then
        self:add_type_signature({block.Input("in", types.Float32)}, {})
    else
        local block_inputs = {}
        for i = 1, num_channels do
            block_inputs[#block_inputs+1] = block.Input("in" .. i, types.Float32)
        end
        self:add_type_signature(block_inputs, {})
    end
end

-- Header endianness conversion

local function bswap32(x)
    return bit.bswap(x)
end

local function bswap16(x)
    return bit.rshift(bit.bswap(x), 16)
end

local function bswap_riff_header(riff_header)
    riff_header.size = bswap32(riff_header.size)
end

local function bswap_wave_subchunk1_header(wave_subchunk1_header)
    wave_subchunk1_header.size = bswap32(wave_subchunk1_header.size)
    wave_subchunk1_header.audio_format = bswap16(wave_subchunk1_header.audio_format)
    wave_subchunk1_header.num_channels = bswap16(wave_subchunk1_header.num_channels)
    wave_subchunk1_header.sample_rate = bswap32(wave_subchunk1_header.sample_rate)
    wave_subchunk1_header.byte_rate = bswap32(wave_subchunk1_header.byte_rate)
    wave_subchunk1_header.block_align = bswap16(wave_subchunk1_header.block_align)
    wave_subchunk1_header.bits_per_sample = bswap16(wave_subchunk1_header.bits_per_sample)
end

local function bswap_wave_subchunk2_header(wave_subchunk2_header)
    wave_subchunk2_header.id = bswap32(wave_subchunk2_header.id)
    wave_subchunk2_header.size = bswap32(wave_subchunk2_header.size)
end

function WAVFileSink:initialize()
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

    -- Create headers
    self.riff_header = ffi.new("riff_header_t")
    self.wave_subchunk1_header = ffi.new("wave_subchunk1_header_t")
    self.wave_subchunk2_header = ffi.new("wave_subchunk2_header_t")

    -- Pre-populate headers
    self.riff_header.id = "RIFF"
    self.riff_header.size = 0 -- Populate in cleanup()
    self.riff_header.format = "WAVE"

    self.wave_subchunk1_header.id = "fmt "
    self.wave_subchunk1_header.size = 16
    self.wave_subchunk1_header.audio_format = 1 -- PCM
    self.wave_subchunk1_header.num_channels = self.num_channels
    self.wave_subchunk1_header.sample_rate = self:get_rate()
    self.wave_subchunk1_header.byte_rate = self:get_rate() * self.num_channels * (self.bits_per_sample/8)
    self.wave_subchunk1_header.block_align = self.num_channels * (self.bits_per_sample/8)
    self.wave_subchunk1_header.bits_per_sample = self.bits_per_sample

    self.wave_subchunk2_header.id = "data"
    self.wave_subchunk2_header.size = 0 -- Populate in cleanup()

    -- Seek file past headers for now
    if ffi.C.fseek(self.file, ffi.sizeof(self.riff_header) + ffi.sizeof(self.wave_subchunk1_header) + ffi.sizeof(self.wave_subchunk2_header), ffi.C.SEEK_SET) ~= 0 then
        error("fseek(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Register open file
    self.files[self.file] = true
end

function WAVFileSink:process(...)
    local samples = {...}
    local num_samples_per_channel = samples[1].length

    self.count = self.count + samples[1].length

    -- Allocate buffer for binary samples
    local raw_samples = ffi.new(ffi.typeof("$ [?]", self.format.real_ctype), num_samples_per_channel * self.num_channels)

    -- Convert float32 samples to raw samples
    for i = 0, num_samples_per_channel-1 do
        for j = 1, self.num_channels do
            raw_samples[i*self.num_channels + (j-1)].value = (samples[j].data[i].value*self.format.scale) + self.format.offset
        end
    end

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, (self.num_channels*num_samples_per_channel)-1 do
            format_utils.swap_bytes(raw_samples[i])
        end
    end

    -- Write to file
    local num_samples = ffi.C.fwrite(raw_samples, ffi.sizeof(self.format.real_ctype), num_samples_per_channel * self.num_channels, self.file)
    if num_samples ~= num_samples_per_channel * self.num_channels then
        error("fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Update our sample count
    self.num_samples = self.num_samples + num_samples_per_channel
end

function WAVFileSink:cleanup()
    -- Update headers with number of samples
    self.wave_subchunk2_header.size = self.num_samples * self.num_channels * (self.bits_per_sample/8)
    self.riff_header.size = 4 + (8 + 16) + (8 + self.wave_subchunk2_header.size)

    -- Adjust headers for endianess
    if ffi.abi("be") then
        bswap_riff_header(self.riff_header)
        bswap_wave_subchunk1_header(self.wave_subchunk1_header)
        bswap_wave_subchunk2_header(self.wave_subchunk2_header)
    end

    -- Rewind file
    ffi.C.rewind(self.file)

    -- Write headers
    if ffi.C.fwrite(self.riff_header, ffi.sizeof(self.riff_header), 1, self.file) ~= 1 then
        error("fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
    if ffi.C.fwrite(self.wave_subchunk1_header, ffi.sizeof(self.wave_subchunk1_header), 1, self.file) ~= 1 then
        error("fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
    if ffi.C.fwrite(self.wave_subchunk2_header, ffi.sizeof(self.wave_subchunk2_header), 1, self.file) ~= 1 then
        error("fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Seek to the end of file
    if ffi.C.fseek(self.file, 0, ffi.C.SEEK_END) ~= 0 then
        error("fseek(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

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

return WAVFileSink
