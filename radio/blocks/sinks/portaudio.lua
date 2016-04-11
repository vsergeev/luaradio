local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local PortAudioSink = block.factory("PortAudioSink")

function PortAudioSink:instantiate(num_channels)
    self.num_channels = num_channels or 1

    if self.num_channels == 1 then
        self:add_type_signature({block.Input("in", types.Float32Type)}, {})
    else
        local block_inputs = {}
        for i = 1, self.num_channels do
            block_inputs[#block_inputs+1] = block.Input("in" .. i, types.Float32Type)
        end
        self:add_type_signature(block_inputs, {})
    end
end

ffi.cdef[[
    typedef void PaStream;

    typedef int PaError;
    typedef int PaDeviceIndex;
    typedef int PaHostApiIndex;
    typedef double PaTime;
    typedef unsigned long PaSampleFormat;
    typedef unsigned long PaStreamFlags;
    typedef void PaStreamCallbackTimeInfo;
    typedef unsigned long PaStreamCallbackFlags;
    typedef int PaStreamCallback(const void *input, void *output, unsigned long frameCount, const PaStreamCallbackTimeInfo *timeInfo, PaStreamCallbackFlags statusFlags, void *userData);

    enum { paFloat32 = 0x00000001 };

    PaError Pa_Initialize(void);
    PaError Pa_Terminate(void);

    PaError Pa_OpenDefaultStream(PaStream **stream, int numInputChannels, int numOutputChannels, PaSampleFormat sampleFormat, double sampleRate, unsigned long framesPerBuffer, PaStreamCallback *streamCallback, void *userData);
    PaError Pa_StartStream(PaStream *stream);
    PaError Pa_WriteStream(PaStream *stream, const void *buffer, unsigned long frames);
    PaError Pa_StopStream(PaStream *stream);
    PaError Pa_CloseStream(PaStream *stream);

    const char *Pa_GetErrorText(PaError errorCode);
]]
local libportaudio_available, libportaudio = pcall(ffi.load, "portaudio")

function PortAudioSink:initialize()
    -- Check library is available
    if not libportaudio_available then
        error("PortAudioSink: libportaudio not found. Is PortAudio installed?")
    end
end

function PortAudioSink:initialize_portaudio()
    -- Initialize PortAudio
    local err = libportaudio.Pa_Initialize()
    if err ~= 0 then
        error("Pa_Initialize(): " .. ffi.string(libportaudio.Pa_GetErrorText(err)))
    end

    -- Open default stream
    self.stream = ffi.new("PaStream *[1]")
    local err = libportaudio.Pa_OpenDefaultStream(self.stream, 0, self.num_channels, ffi.C.paFloat32, self:get_rate(), 32768, nil, nil)
    if err ~= 0 then
        error("Pa_OpenDefaultStream(): " .. ffi.string(libportaudio.Pa_GetErrorText(err)))
    end

    -- Start the stream
    local err = libportaudio.Pa_StartStream(self.stream[0])
    if err ~= 0 then
        error("Pa_StartStream(): " .. ffi.string(libportaudio.Pa_GetErrorText(err)))
    end
end

function PortAudioSink:process(...)
    local samples = {...}

    -- Initialize PortAudio in our own process
    if not self.stream then
        self:initialize_portaudio()
    end

    local interleaved_samples
    if self.num_channels == 1 then
        interleaved_samples = samples[1]
    else
        -- Interleave samples
        interleaved_samples = types.Float32Type.vector(self.num_channels*samples[1].length)
        for i = 0, samples[1].length-1 do
            for j = 0, self.num_channels-1 do
                interleaved_samples.data[i*self.num_channels + j] = samples[j+1].data[i]
            end
        end
    end

    -- Write to our PortAudio connection
    local err = libportaudio.Pa_WriteStream(self.stream[0], interleaved_samples.data, samples[1].length)
    if err ~= 0 then
        error("Pa_WriteStream(): " .. ffi.string(libportaudio.Pa_GetErrorText(err)))
    end
end

function PortAudioSink:cleanup()
    -- If we never got around to creating a stream
    if not self.stream then
        return
    end

    -- Stop the stream
    local err = libportaudio.Pa_StopStream(self.stream[0])
    if err ~= 0 then
        error("Pa_StopStream(): " .. ffi.string(libportaudio.Pa_GetErrorText(err)))
    end

    -- Close the stream
    local err = libportaudio.Pa_CloseStream(self.stream[0])
    if err ~= 0 then
        error("Pa_StopStream(): " .. ffi.string(libportaudio.Pa_GetErrorText(err)))
    end

    -- Terminate PortAudio
    local err = libportaudio.Pa_Terminate()
    if err ~= 0 then
        error("Pa_Terminate(): " .. ffi.string(libportaudio.Pa_GetErrorText(err)))
    end
end

return {PortAudioSink = PortAudioSink}
