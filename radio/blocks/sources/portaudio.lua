---
-- Source one or more real-valued signals from the system's audio device with
-- PortAudio. This source requires PortAudio.
--
-- @category Sources
-- @block PortAudioSource
-- @tparam int num_channels Number of channels (e.g. 1 for mono, 2 for stereo)
-- @tparam int rate Sample rate in Hz
--
-- @signature > out:Float32
-- @signature > out1:Float32, out2:Float32, ...
--
-- @usage
-- -- Source one channel (mono) audio sampled at 44100 Hz
-- local src = radio.PortAudioSource(1, 44100)
--
-- -- Source two channel (stereo) audio sampled at 48000 Hz
-- local src = radio.PortAudioSource(2, 48000)
-- -- Compose the two channels into a complex-valued signal
-- local floattocomplex = radio.FloatToComplex()
-- top:connect(src, 'out1', floattocomplex, 'real')
-- top:connect(src, 'out2', floattocomplex, 'imag')
-- top:connect(floattocomplex, ...)

local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local PortAudioSource = block.factory("PortAudioSource")

function PortAudioSource:instantiate(num_channels, rate)
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

if not package.loaded['radio.blocks.sinks.portaudio'] then
    ffi.cdef[[
        typedef void PaStream;

        typedef int PaError;
        typedef int PaDeviceIndex;
        typedef int PaHostApiIndex;
        typedef double PaTime;
        typedef unsigned long PaSampleFormat;
        typedef unsigned long PaStreamFlags;
        typedef struct PaStreamCallbackTimeInfo PaStreamCallbackTimeInfo;
        typedef unsigned long PaStreamCallbackFlags;
        typedef int PaStreamCallback(const void *input, void *output, unsigned long frameCount, const PaStreamCallbackTimeInfo *timeInfo, PaStreamCallbackFlags statusFlags, void *userData);

        enum { paFramesPerBufferUnspecified = 0 };
        enum { paFloat32 = 0x00000001 };

        PaError Pa_Initialize(void);
        PaError Pa_Terminate(void);

        PaError Pa_OpenDefaultStream(PaStream **stream, int numInputChannels, int numOutputChannels, PaSampleFormat sampleFormat, double sampleRate, unsigned long framesPerBuffer, PaStreamCallback *streamCallback, void *userData);
        PaError Pa_StartStream(PaStream *stream);
        PaError Pa_WriteStream(PaStream *stream, const void *buffer, unsigned long frames);
        PaError Pa_ReadStream(PaStream *stream, void *buffer, unsigned long frames);
        PaError Pa_StopStream(PaStream *stream);
        PaError Pa_CloseStream(PaStream *stream);

        const char *Pa_GetErrorText(PaError errorCode);
    ]]
end
local libportaudio_available, libportaudio = pcall(ffi.load, "portaudio")

function PortAudioSource:initialize()
    -- Check library is available
    if not libportaudio_available then
        error("PortAudioSource: libportaudio not found. Is PortAudio installed?")
    end

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

function PortAudioSource:get_rate()
    return self.rate
end

function PortAudioSource:initialize_portaudio()
    -- Initialize PortAudio
    local err = libportaudio.Pa_Initialize()
    if err ~= 0 then
        error("Pa_Initialize(): " .. ffi.string(libportaudio.Pa_GetErrorText(err)))
    end

    -- Open default stream
    self.stream = ffi.new("PaStream *[1]")
    local err = libportaudio.Pa_OpenDefaultStream(self.stream, self.num_channels, 0, ffi.C.paFloat32, self.rate, ffi.C.paFramesPerBufferUnspecified, nil, nil)
    if err ~= 0 then
        error("Pa_OpenDefaultStream(): " .. ffi.string(libportaudio.Pa_GetErrorText(err)))
    end

    -- Start the stream
    local err = libportaudio.Pa_StartStream(self.stream[0])
    if err ~= 0 then
        error("Pa_StartStream(): " .. ffi.string(libportaudio.Pa_GetErrorText(err)))
    end
end

function PortAudioSource:process()
    -- Initialize PortAudio in our own running process
    if not self.stream then
        self:initialize_portaudio()
    end

    -- Read from our PortAudio stream
    local ret = libportaudio.Pa_ReadStream(self.stream[0], self.interleaved_samples.data, self.chunk_size)
    if ret < 0 then
        error("Pa_ReadStream(): " .. ffi.string(libportaudio.Pa_GetErrorText(err)))
    end

    if self.num_channels == 1 then
        return self.interleaved_samples
    end

    -- Deinterleave samples
    for i = 0, (self.interleaved_samples.length/self.num_channels)-1 do
        for j = 1, self.num_channels do
            self.out_vectors[j].data[i].value = self.interleaved_samples.data[self.num_channels*i + (j-1)].value
        end
    end

    return unpack(self.out_vectors)
end

return PortAudioSource
