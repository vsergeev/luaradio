local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

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

    typedef struct {
        uint8_t value;
    } wave_sample_u8_t;

    typedef struct {
        union { uint8_t bytes[2]; int16_t value; };
    } wave_sample_s16_t;

    typedef struct {
        union { uint8_t bytes[4]; int32_t value; };
    } wave_sample_s32_t;
]]

function WAVFileSink:instantiate(file, num_channels, bits_per_sample)
    local supported_formats = {
        [8]     = {ctype = "wave_sample_u8_t",  swap = false,           offset = 127.5, scale = 1.0/127.5},
        [16]    = {ctype = "wave_sample_s16_t", swap = ffi.abi("be"),   offset = 0,     scale = 1.0/32767.5},
        [32]    = {ctype = "wave_sample_s32_t", swap = ffi.abi("be"),   offset = 0,     scale = 1.0/2147483647.5},
    }

    assert(ffi.sizeof("riff_header_t") == 12)
    assert(ffi.sizeof("wave_subchunk1_header_t") == 24)
    assert(ffi.sizeof("wave_subchunk2_header_t") == 8)
    assert(ffi.sizeof("wave_sample_s16_t") == 2)

    if type(file) == "number" then
        self.fd = file
    else
        self.filename = file
    end

    self.num_channels = num_channels
    self.bits_per_sample = bits_per_sample or 16
    self.format = supported_formats[self.bits_per_sample]
    self.num_samples = 0
    self.count = 0

    if self.format == nil then
        error(string.format("Unsupported WAV file: unsupported bits per sample %d.", bits_per_sample))
    end

    -- Build type signature
    if num_channels == 1 then
        self:add_type_signature({block.Input("in", types.Float32Type)}, {})
    else
        local block_inputs = {}
        for i = 1, num_channels do
            block_inputs[#block_inputs+1] = block.Input("in" .. i, types.Float32Type)
        end
        self:add_type_signature(block_inputs, {})
    end
end

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
    else
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
end

local function swap_bytes(x)
    local len = ffi.sizeof(x.bytes)

    for i = 0, (len/2)-1 do
        x.bytes[i], x.bytes[len-i-1] = x.bytes[len-i-1], x.bytes[i]
    end
end

function WAVFileSink:process(...)
    local samples = {...}
    local num_samples_per_channel = samples[1].length

    self.count = self.count + samples[1].length

    -- Allocate buffer for binary samples
    local raw_samples = ffi.new(self.format.ctype .. "[?]", num_samples_per_channel * self.num_channels)

    -- Convert float32 samples to raw samples
    for i = 0, num_samples_per_channel-1 do
        for j = 1, self.num_channels do
            raw_samples[i*self.num_channels + (j-1)].value = bit.tobit((samples[j].data[i].value/self.format.scale) + self.format.offset)
        end
    end

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, (self.num_channels*num_samples_per_channel)-1 do
            swap_bytes(raw_samples[i])
        end
    end

    -- Write to file
    local num_samples = ffi.C.fwrite(raw_samples, ffi.sizeof(self.format.ctype), num_samples_per_channel * self.num_channels, self.file)
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

return {WAVFileSink = WAVFileSink}
