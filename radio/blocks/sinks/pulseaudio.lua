local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local PulseAudioSink = block.factory("PulseAudioSink")

function PulseAudioSink:instantiate()
    self:add_type_signature({block.Input("in", types.Float32Type)}, {})
end

ffi.cdef[[
    typedef struct pa_simple pa_simple;

    typedef enum pa_sample_format { PA_SAMPLE_FLOAT32LE = 5, PA_SAMPLE_FLOAT32BE = 6 } pa_sample_format_t;

    typedef struct pa_sample_spec {
        pa_sample_format_t format;
        uint32_t rate;
        uint8_t channels;
    } pa_sample_spec;
    typedef void pa_buffer_attr;
    typedef void pa_channel_map;

    typedef enum pa_stream_direction {
        PA_STREAM_NODIRECTION,
        PA_STREAM_PLAYBACK,
        PA_STREAM_RECORD,
        PA_STREAM_UPLOAD
    } pa_stream_direction_t;

    pa_simple* pa_simple_new(const char *server, const char *name, pa_stream_direction_t dir, const char *dev, const char *stream_name, const pa_sample_spec *ss, const pa_channel_map *map, const pa_buffer_attr *attr, int *error);

    void pa_simple_free(pa_simple *s);
    int pa_simple_write(pa_simple *s, const void *data, size_t bytes, int *error);

    const char* pa_strerror(int error);
]]
local libpulse_available, libpulse = pcall(ffi.load, "pulse-simple")

function PulseAudioSink:initialize()
    -- Check library is available
    if not libpulse_available then
        error("PulseAudioSink: libpulse-simple not found.")
    end

    -- Prepare sample spec
    self.sample_spec = ffi.new("pa_sample_spec")
    self.sample_spec.format = ffi.abi("le") and ffi.C.PA_SAMPLE_FLOAT32LE or ffi.C.PA_SAMPLE_FLOAT32BE
    self.sample_spec.channels = 1
    self.sample_spec.rate = self:get_rate()
end

function PulseAudioSink:process(x)
    local error_code = ffi.new("int[1]")

    -- We can't fork with a PulseAudio connection, so we create here
    if not self.pa_conn then
        -- Open PulseAudio connection
        self.pa_conn = ffi.new("pa_simple *")
        self.pa_conn = libpulse.pa_simple_new(nil, "LuaRadio", ffi.C.PA_STREAM_PLAYBACK, nil, "PulseAudioSink", self.sample_spec, nil, nil, error_code)
        assert(self.pa_conn ~= nil, "pa_simple_new(): " .. ffi.string(libpulse.pa_strerror(error_code[0])))
    end

    -- Write to our PulseAudio connection
    local ret = libpulse.pa_simple_write(self.pa_conn, x.data, x.size, error_code)
    assert(ret >= 0, "pa_simple_write(): " .. ffi.string(libpulse.pa_strerror(error_code[0])))
end

return {PulseAudioSink = PulseAudioSink}
