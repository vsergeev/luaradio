---
-- Source one or more real-valued signals from the system's audio device with
-- PulseAudio. This source requires PulseAudio.
--
-- @category Sources
-- @block PulseAudioSource
-- @tparam int num_channels Number of channels (e.g. 1 for mono, 2 for stereo)
-- @tparam int rate Sample rate in Hz
--
-- @signature > out:Float32
-- @signature > out1:Float32, out2:Float32, ...
--
-- @usage
-- -- Source one channel (mono) audio sampled at 44100 Hz
-- local src = radio.PulseAudioSource(1, 44100)
--
-- -- Source two channel (stereo) audio sampled at 48000 Hz
-- local src = radio.PulseAudioSource(2, 48000)
-- -- Compose the two channels into a complex-valued signal
-- local floattocomplex = radio.FloatToComplex()
-- top:connect(src, 'out1', floattocomplex, 'real')
-- top:connect(src, 'out2', floattocomplex, 'imag')
-- top:connect(floattocomplex, ...)

local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local PulseAudioSource = block.factory("PulseAudioSource")

function PulseAudioSource:instantiate(num_channels, rate)
    self.num_channels = assert(num_channels, "Missing argument #1 (num_channels)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    if self.num_channels == 1 then
        self:add_type_signature({}, {block.Output("out", types.Float32)})
    else
        local block_outputs = {}
        for i = 1, self.num_channels do
            block_outputs[i] = block.Output("out" .. i, types.Float32)
        end
        self:add_type_signature({}, block_outputs)
    end

    self.chunk_size = 8192/4
end

if not package.loaded['radio.blocks.sinks.pulseaudio'] then
    ffi.cdef[[
        typedef struct pa_simple pa_simple;

        typedef enum pa_sample_format { PA_SAMPLE_FLOAT32LE = 5, PA_SAMPLE_FLOAT32BE = 6 } pa_sample_format_t;

        typedef struct pa_sample_spec {
            pa_sample_format_t format;
            uint32_t rate;
            uint8_t channels;
        } pa_sample_spec;
        typedef struct pa_buffer_attr pa_buffer_attr;
        typedef struct pa_channel_map pa_channel_map;

        typedef enum pa_stream_direction {
            PA_STREAM_NODIRECTION,
            PA_STREAM_PLAYBACK,
            PA_STREAM_RECORD,
            PA_STREAM_UPLOAD
        } pa_stream_direction_t;

        typedef struct pa_buffer_attr {
            uint32_t maxlength;
            uint32_t tlength;
            uint32_t prebuf;
            uint32_t minreq;
            uint32_t fragsize;
        } pa_buffer_attr;

        pa_simple* pa_simple_new(const char *server, const char *name, pa_stream_direction_t dir, const char *dev, const char *stream_name, const pa_sample_spec *ss, const pa_channel_map *map, const pa_buffer_attr *attr, int *error);

        void pa_simple_free(pa_simple *s);
        int pa_simple_write(pa_simple *s, const void *data, size_t bytes, int *error);
        int pa_simple_read(pa_simple *s, void *data, size_t bytes, int *error);

        const char* pa_strerror(int error);
    ]]
end
local libpulse_available, libpulse = pcall(ffi.load, "pulse-simple")

function PulseAudioSource:initialize()
    -- Check library is available
    if not libpulse_available then
        error("PulseAudioSource: libpulse-simple not found. Is PulseAudio installed?")
    end

    -- Prepare sample spec
    self.sample_spec = ffi.new("pa_sample_spec")
    self.sample_spec.format = ffi.abi("le") and ffi.C.PA_SAMPLE_FLOAT32LE or ffi.C.PA_SAMPLE_FLOAT32BE
    self.sample_spec.channels = self.num_channels
    self.sample_spec.rate = self.rate

    -- Prepare buffer attributes
    self.buffer_attr = ffi.new("pa_buffer_attr")
    self.buffer_attr.maxlength = -1
    self.buffer_attr.fragsize = self.chunk_size

    -- Create read buffer
    self.interleaved_samples = types.Float32.vector(self.chunk_size * self.num_channels)

    -- Create output vectors
    if self.num_channels > 1 then
        self.out_vectors = {}
        for i = 1, self.num_channels do
            self.out_vectors[i] = types.Float32.vector(self.chunk_size)
        end
    end
end

function PulseAudioSource:get_rate()
    return self.rate
end

function PulseAudioSource:initialize_pulseaudio()
    local error_code = ffi.new("int[1]")

    -- Open PulseAudio connection
    self.pa_conn = ffi.new("pa_simple *")
    self.pa_conn = libpulse.pa_simple_new(nil, "LuaRadio", ffi.C.PA_STREAM_RECORD, nil, "PulseAudioSource", self.sample_spec, nil, self.buffer_attr, error_code)
    if self.pa_conn == nil then
        error("pa_simple_new(): " .. ffi.string(libpulse.pa_strerror(error_code[0])))
    end
end

function PulseAudioSource:process()
    local error_code = ffi.new("int[1]")

    -- We can't fork with a PulseAudio connection, so we create it in our own
    -- running process
    if not self.pa_conn then
        self:initialize_pulseaudio()
    end

    -- Read from our PulseAudio connection
    print('before')
    local ret = libpulse.pa_simple_read(self.pa_conn, self.interleaved_samples.data, self.interleaved_samples.size, error_code)
    if ret < 0 then
        error("pa_simple_read(): " .. ffi.string(libpulse.pa_strerror(error_code[0])))
    end
    print('after')

    if self.num_channels == 1 then
        return self.interleaved_samples
    else
        -- Deinterleave samples
        for i = 0, (self.interleaved_samples.length/self.num_channels)-1 do
            for j = 1, self.num_channels do
                self.out_vectors[j].data[i].value = self.interleaved_samples.data[self.num_channels*i + (j-1)].value
            end
        end
    end

    return unpack(self.out_vectors)
end

return PulseAudioSource
