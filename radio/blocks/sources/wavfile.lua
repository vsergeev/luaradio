local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local WAVFileSource = block.factory("WAVFileSource")

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

function WAVFileSource:instantiate(file, num_channels, repeat_on_eof)
    if type(file) == "string" then
        self.filename = file
    elseif type(file) == "number" then
        self.fd = file
    else
        self.file = file
    end

    self.num_channels = num_channels
    self.rate = nil
    self.chunk_size = 8192
    self.repeat_on_eof = (repeat_on_eof == nil) and false or repeat_on_eof

    -- Build type signature
    if num_channels == 1 then
        self:add_type_signature({}, {block.Output("out", types.Float32)})
    else
        local block_outputs = {}
        for i = 1, num_channels do
            block_outputs[#block_outputs+1] = block.Output("out" .. i, types.Float32)
        end
        self:add_type_signature({}, block_outputs)
    end
end

function WAVFileSource:get_rate()
    return self.rate
end

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    FILE *fdopen(int fd, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fseek(FILE *stream, long offset, int whence);
    int feof(FILE *stream);
    int ferror(FILE *stream);
    int fclose(FILE *stream);
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

-- Initialization

function WAVFileSource:initialize()
    local supported_formats = {
        [8]     = {ctype = "wave_sample_u8_t",  swap = false,           offset = 127.5, scale = 1.0/127.5},
        [16]    = {ctype = "wave_sample_s16_t", swap = ffi.abi("be"),   offset = 0,     scale = 1.0/32767.5},
        [32]    = {ctype = "wave_sample_s32_t", swap = ffi.abi("be"),   offset = 0,     scale = 1.0/2147483647.5},
    }

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

    -- Read headers
    self.riff_header = ffi.new("riff_header_t")
    if ffi.C.fread(self.riff_header, ffi.sizeof(self.riff_header), 1, self.file) ~= 1 then
        error("fread(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
    self.wave_subchunk1_header = ffi.new("wave_subchunk1_header_t")
    if ffi.C.fread(self.wave_subchunk1_header, ffi.sizeof(self.wave_subchunk1_header), 1, self.file) ~= 1 then
        error("fread(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
    self.wave_subchunk2_header = ffi.new("wave_subchunk2_header_t")
    if ffi.C.fread(self.wave_subchunk2_header, ffi.sizeof(self.wave_subchunk2_header), 1, self.file) ~= 1 then
        error("fread(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Byte swap if needed for endianness
    if ffi.abi("be") then
        bswap_riff_header(self.riff_header)
        bswap_wave_subchunk1_header(self.wave_subchunk1_header)
        bswap_wave_subchunk2_header(self.wave_subchunk2_header)
    end

    -- Check RIFF header
    if ffi.string(self.riff_header.id, 4) ~= "RIFF" then
        error("Invalid WAV file: invalid RIFF header id.")
    end
    if ffi.string(self.riff_header.format, 4) ~= "WAVE" then
        error("Invalid WAV file: invalid RIFF header format.")
    end

    -- Check WAVE Subchunk 1 Header
    if ffi.string(self.wave_subchunk1_header.id, 4) ~= "fmt " then
        error("Invalid WAV file: invalid WAVE subchunk1 header id.")
    end
    if self.wave_subchunk1_header.audio_format ~= 1 then
        error(string.format("Unsupported WAV file: unsupported audio format %d (not PCM).", self.wave_subchunk1_header.audio_format))
    end
    if self.wave_subchunk1_header.num_channels ~= self.num_channels then
        error(string.format("Block number of channels (%d) does not match WAV file number of channels (%d).", self.num_channels, self.wave_subchunk1_header.num_channels))
    end
    if supported_formats[self.wave_subchunk1_header.bits_per_sample] == nil then
        error(string.format("Unsupported WAV file: unsupported bits per sample %d.", self.wave_subchunk1_header.bits_per_sample))
    end

    -- Check WAVE Subchunk 2 Header
    if ffi.string(self.wave_subchunk2_header.id, 4) ~= "data" then
        error("Invalid WAV file: invalid WAVE subchunk2 header id.")
    end

    -- Pull out sample rate and format
    self.rate = self.wave_subchunk1_header.sample_rate
    self.format = supported_formats[self.wave_subchunk1_header.bits_per_sample]
end

local function swap_bytes(x)
    local len = ffi.sizeof(x.bytes)
    for i = 0, (len/2)-1 do
        x.bytes[i], x.bytes[len-i-1] = x.bytes[len-i-1], x.bytes[i]
    end
end

function WAVFileSource:process()
    -- Allocate buffer for raw samples
    local raw_samples = ffi.new(self.format.ctype .. "[?]", self.chunk_size)

    -- Read from file
    local num_samples = tonumber(ffi.C.fread(raw_samples, ffi.sizeof(self.format.ctype), self.chunk_size, self.file))
    if num_samples < self.chunk_size then
        if num_samples == 0 and ffi.C.feof(self.file) ~= 0 then
            if self.repeat_on_eof then
                -- Rewind past header
                local header_length = ffi.sizeof("riff_header_t") + ffi.sizeof("wave_subchunk1_header_t") + ffi.sizeof("wave_subchunk2_header_t")
                if ffi.C.fseek(self.file, header_length, ffi.C.SEEK_SET) ~= 0 then
                    error("fseek(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
                end
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
            swap_bytes(raw_samples[i])
        end
    end

    -- Build an samples vector for each channel
    local samples = {}
    for i = 1, self.num_channels do
        samples[i] = types.Float32.vector(num_samples/self.num_channels)
    end

    -- Convert raw samples to float32 samples for each channel
    for i = 0, (num_samples/self.num_channels)-1 do
        for j = 1, self.num_channels do
            samples[j].data[i].value = (raw_samples[i*self.num_channels + (j-1)].value - self.format.offset)*self.format.scale
        end
    end

    return unpack(samples)
end

function WAVFileSource:cleanup()
    if self.filename then
        if ffi.C.fclose(self.file) ~= 0 then
            error("fclose(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end
end

return WAVFileSource
