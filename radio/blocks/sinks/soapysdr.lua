---
-- Sink a complex-valued signal to a SoapySDR device. This sink requires
-- [SoapySDR](https://github.com/pothosware/SoapySDR).
--
-- @category Sinks
-- @block SoapySDRSink
-- @tparam string|table driver Driver string or key-value table
-- @tparam number frequency Tuning frequency in Hz
-- @tparam[opt={}] table options Additional options, specifying:
--      * `channel` (int, default 0)
--      * `bandwidth` (number in Hz)
--      * `autogain` (bool)
--      * `antenna` (string)
--      * `gain` (number in dB, overall gain)
--      * `gains` (table, gain element name to value in dB)
--      * `frequencies` (table, frequency element name to value in Hz)
--      * `settings` (table, string key-value pairs of driver-specific settings)
--
-- @signature in:ComplexFloat32 >
--
-- @usage
-- -- Sink samples to a HackRF at 433.92 MHz
-- local snk = radio.SoapySDRSink("driver=hackrf", 433.92e6)
--
-- -- Sink samples to a LimeSDR at 915 MHz, with 10 dB overall gain and 5 MHz baseband bandwidth
-- local snk = radio.SoapySDRSink("driver=limesdr", 915e6, {gain = 10, bandwidth = 5e6})

local ffi = require('ffi')

local block = require('radio.core.block')
local platform = require('radio.core.platform')
local debug = require('radio.core.debug')
local types = require('radio.types')

local SoapySDRSink = block.factory("SoapySDRSink")

function SoapySDRSink:instantiate(driver, frequency, options)
    self.driver = assert(driver, "Missing argument #1 (driver)")
    self.frequency = assert(frequency, "Missing argument #2 (frequency)")

    assert(type(driver) == "string" or type(driver) == "table", "Invalid argument #1 (driver), should be string or table of string key-value pairs.")

    self.options = options or {}
    self.channel = self.options.channel or 0
    self.autogain = self.options.autogain
    self.bandwidth = self.options.bandwidth
    self.antenna = self.options.antenna
    self.gain = self.options.gain
    self.gains = self.options.gains
    self.frequencies = self.options.frequencies
    self.driver_settings = self.options.settings

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {})
end

if not package.loaded['radio.blocks.sources.soapysdr'] then
    ffi.cdef[[
        typedef struct SoapySDRDevice SoapySDRDevice;
        typedef struct SoapySDRStream SoapySDRStream;

        typedef struct
        {
            double minimum;
            double maximum;
        } SoapySDRRange;

        typedef struct
        {
            size_t size;
            char **keys;
            char **vals;
        } SoapySDRKwargs;

        enum { SOAPY_SDR_TX = 0, SOAPY_SDR_RX = 1 };

        const char *SoapySDR_getLibVersion(void);

        /* Error strings */
        const char *SoapySDR_errToStr(const int errorCode);
        const char *SoapySDRDevice_lastError(void);

        /* String / Keyword Args Helper Functions */
        void SoapySDRStrings_clear(char ***elems, const size_t length);
        void SoapySDRKwargs_set(SoapySDRKwargs *args, const char *key, const char *val);
        const char *SoapySDRKwargs_get(SoapySDRKwargs *args, const char *key);
        void SoapySDRKwargs_clear(SoapySDRKwargs *args);
        void SoapySDRKwargsList_clear(SoapySDRKwargs *args, const size_t length);

        /* Device creation */
        SoapySDRKwargs *SoapySDRDevice_enumerate(const SoapySDRKwargs *args, size_t *length);
        SoapySDRDevice *SoapySDRDevice_make(const SoapySDRKwargs *args);
        SoapySDRDevice *SoapySDRDevice_makeStrArgs(const char *args);
        void SoapySDRDevice_unmake(SoapySDRDevice *device);

        /* Device info */
        char *SoapySDRDevice_getDriverKey(const SoapySDRDevice *device);
         char *SoapySDRDevice_getHardwareKey(const SoapySDRDevice *device);
        SoapySDRKwargs SoapySDRDevice_getHardwareInfo(const SoapySDRDevice *device);

        /* Channel info */
        size_t SoapySDRDevice_getNumChannels(const SoapySDRDevice *device, const int direction);
         SoapySDRKwargs SoapySDRDevice_getChannelInfo(const SoapySDRDevice *device, const int direction, const size_t channel);

        /* Sample rate */
        int SoapySDRDevice_setSampleRate(SoapySDRDevice *device, const int direction, const size_t channel, const double rate);
        double SoapySDRDevice_getSampleRate(const SoapySDRDevice *device, const int direction, const size_t channel);
        double *SoapySDRDevice_listSampleRates(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length);

        /* Frequency */
        SoapySDRRange *SoapySDRDevice_getFrequencyRange(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length);
        int SoapySDRDevice_setFrequency(SoapySDRDevice *device, const int direction, const size_t channel, const double frequency, const SoapySDRKwargs *args);
        double SoapySDRDevice_getFrequency(const SoapySDRDevice *device, const int direction, const size_t channel);
        int SoapySDRDevice_setFrequencyComponent(SoapySDRDevice *device, const int direction, const size_t channel, const char *name, const double frequency, const SoapySDRKwargs *args);
        double SoapySDRDevice_getFrequencyComponent(const SoapySDRDevice *device, const int direction, const size_t channel, const char *name);
        char **SoapySDRDevice_listFrequencies(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length);
        SoapySDRRange *SoapySDRDevice_getFrequencyRangeComponent(const SoapySDRDevice *device, const int direction, const size_t channel, const char *name, size_t *length);

        /* Bandwidth */
        double *SoapySDRDevice_listBandwidths(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length);
        SoapySDRRange *SoapySDRDevice_getBandwidthRange(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length);
        int SoapySDRDevice_setBandwidth(SoapySDRDevice *device, const int direction, const size_t channel, const double bw);
        double SoapySDRDevice_getBandwidth(const SoapySDRDevice *device, const int direction, const size_t channel);

        /* Gains */
        char **SoapySDRDevice_listGains(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length);
        bool SoapySDRDevice_hasGainMode(const SoapySDRDevice *device, const int direction, const size_t channel);
        int SoapySDRDevice_setGainMode(SoapySDRDevice *device, const int direction, const size_t channel, const bool automatic);
        bool SoapySDRDevice_getGainMode(const SoapySDRDevice *device, const int direction, const size_t channel);
        SoapySDRRange SoapySDRDevice_getGainRange(const SoapySDRDevice *device, const int direction, const size_t channel);
        int SoapySDRDevice_setGain(SoapySDRDevice *device, const int direction, const size_t channel, const double value);
        double SoapySDRDevice_getGain(const SoapySDRDevice *device, const int direction, const size_t channel);
        int SoapySDRDevice_setGainElement(SoapySDRDevice *device, const int direction, const size_t channel, const char *name, const double value);
        double SoapySDRDevice_getGainElement(const SoapySDRDevice *device, const int direction, const size_t channel, const char *name);
        SoapySDRRange SoapySDRDevice_getGainElementRange(const SoapySDRDevice *device, const int direction, const size_t channel, const char *name);

        /* Antenna */
        char **SoapySDRDevice_listAntennas(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length);
        int SoapySDRDevice_setAntenna(SoapySDRDevice *device, const int direction, const size_t channel, const char *name);
        char *SoapySDRDevice_getAntenna(const SoapySDRDevice *device, const int direction, const size_t channel);

        /* Device-specific Settings */
        void SoapySDRDevice_writeSetting(SoapySDRDevice *device, const char *key, const char *value);
        char *SoapySDRDevice_readSetting(const SoapySDRDevice *device, const char *key);

        /* Stream setup/close */
        int SoapySDRDevice_setupStream(SoapySDRDevice *device, SoapySDRStream **stream, const int direction, const char *format, const size_t *channels, const size_t numChans, const SoapySDRKwargs *args);
        void SoapySDRDevice_closeStream(SoapySDRDevice *device, SoapySDRStream *stream);
        size_t SoapySDRDevice_getStreamMTU(const SoapySDRDevice *device, SoapySDRStream *stream);

        /* Stream activate/deactivate */
        int SoapySDRDevice_activateStream(SoapySDRDevice *device, SoapySDRStream *stream, const int flags, const long long timeNs, const size_t numElems);
        int SoapySDRDevice_deactivateStream(SoapySDRDevice *device, SoapySDRStream *stream, const int flags, const long long timeNs);

        /* Stream I/O */
        int SoapySDRDevice_readStream(SoapySDRDevice *device, SoapySDRStream *stream, void * const *buffs, const size_t numElems, int *flags, long long *timeNs, const long timeoutUs);
        int SoapySDRDevice_writeStream(SoapySDRDevice *device, SoapySDRStream *stream, const void * const *buffs, const size_t numElems, int *flags, const long long timeNs, const long timeoutUs);
        int SoapySDRDevice_readStreamStatus(SoapySDRDevice *device, SoapySDRStream *stream, size_t *chanMask, int *flags, long long *timeNs, const long timeoutUs);
    ]]
end
local libsoapysdr_available, libsoapysdr = pcall(ffi.load, "libSoapySDR")

function SoapySDRSink:initialize()
    -- Check library is available
    if not libsoapysdr_available then
        error("SoapySDRSink: libSoapySDR not found. Is SoapySDR installed?")
    end
end

local function table2kwargs(t)
    local kwargs = ffi.new("SoapySDRKwargs")

    for k,v in pairs(t) do
        libsoapysdr.SoapySDRKwargs_set(kwargs, k, v)
    end

    return ffi.gc(kwargs, libsoapysdr.SoapySDRKwargs_clear)
end

local function kwargs2array(kwargs)
    local arr = {}

    for i=0, tonumber(kwargs.size)-1 do
        arr[i+1] = {ffi.string(kwargs.keys[i]), ffi.string(kwargs.vals[i])}
    end

    return arr
end

function SoapySDRSink:debug_dump_soapysdr()
    local ret

    -- Driver and hardware key
    debug.printf("[SoapySDRSink] Driver key: %s\n", ffi.string(libsoapysdr.SoapySDRDevice_getDriverKey(self.dev)))
    debug.printf("[SoapySDRSink] Hardware key: %s\n", ffi.string(libsoapysdr.SoapySDRDevice_getDriverKey(self.dev)))

    -- Hardware info
    debug.printf("[SoapySDRSink] Hardware info:\n", ffi.string(libsoapysdr.SoapySDRDevice_getDriverKey(self.dev)))
    local hardware_info_kwargs = libsoapysdr.SoapySDRDevice_getHardwareInfo(self.dev)
    local hardware_info = kwargs2array(hardware_info_kwargs)
    libsoapysdr.SoapySDRKwargs_clear(hardware_info_kwargs)
    for i = 1, #hardware_info do
        debug.printf("[SoapySDRSink]     %s: %s\n", hardware_info[i][1], hardware_info[i][2])
    end
    if #hardware_info == 0 then
        debug.printf("[SoapySDRSink]     (no hardware info)\n")
    end

    -- Number of channels
    local num_channels = libsoapysdr.SoapySDRDevice_getNumChannels(self.dev, ffi.C.SOAPY_SDR_TX)
    debug.printf("[SoapySDRSink] Number of TX channels: %u\n", tonumber(num_channels))

    -- Channel info
    debug.printf("[SoapySDRSink] TX Channel %u info:\n", self.channel)
    local channel_info_kwargs = libsoapysdr.SoapySDRDevice_getChannelInfo(self.dev, ffi.C.SOAPY_SDR_TX, self.channel)
    local channel_info = kwargs2array(channel_info_kwargs)
    libsoapysdr.SoapySDRKwargs_clear(channel_info_kwargs)
    for i = 1, #channel_info do
        debug.printf("[SoapySDRSink]     %s: %s\n", channel_info[i][1], channel_info[i][2])
    end
    if #channel_info == 0 then
        debug.printf("[SoapySDRSink]     (no channel info)\n")
    end

    -- Supported sample rates
    debug.printf("[SoapySDRSink] TX Channel %u sample rates:\n", self.channel)
    local num_rates = ffi.new("size_t[1]")
    local rates = libsoapysdr.SoapySDRDevice_listSampleRates(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, num_rates)
    for i = 0, tonumber(num_rates[0])-1 do
        debug.printf("[SoapySDRSink]     %f\n", rates[i])
    end
    if num_rates[0] == 0 then
        debug.printf("[SoapySDRSink]     (no sample rates)\n")
    end
    ffi.C.free(rates)

    -- Frequency ranges
    debug.printf("[SoapySDRSink] TX Channel %u center frequency ranges:\n", self.channel)
    local num_freq_ranges = ffi.new("size_t[1]")
    local freq_ranges = libsoapysdr.SoapySDRDevice_getFrequencyRange(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, num_freq_ranges)
    for i = 0, tonumber(num_freq_ranges[0])-1 do
        debug.printf("[SoapySDRSink]     %f - %f\n", freq_ranges[i].minimum, freq_ranges[i].maximum)
    end
    if num_freq_ranges[0] == 0 then
        debug.printf("[SoapySDRSink]     (no frequency ranges)\n")
    end
    ffi.C.free(freq_ranges)

    -- Frequency element ranges
    debug.printf("[SoapySDRSink] TX Channel %u frequency element ranges:\n", self.channel)
    local num_freq_elements = ffi.new("size_t[1]")
    local freq_elements = libsoapysdr.SoapySDRDevice_listFrequencies(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, num_freq_elements)
    for i = 0, tonumber(num_freq_elements[0])-1 do
        debug.printf("[SoapySDRSink]     %s\n", ffi.string(freq_elements[i]))
        local num_freq_ranges = ffi.new("size_t[1]")
        local freq_ranges = libsoapysdr.SoapySDRDevice_getFrequencyRangeComponent(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, freq_elements[i], num_freq_ranges)
        for i = 0, tonumber(num_freq_ranges[0])-1 do
            debug.printf("[SoapySDRSink]         %f - %f\n", freq_ranges[i].minimum, freq_ranges[i].maximum)
        end
        if num_freq_ranges[0] == 0 then
            debug.printf("[SoapySDRSink]         (no frequency ranges)\n", freq_ranges[i].minimum, freq_ranges[i].maximum)
        end
        ffi.C.free(freq_ranges)
    end
    if num_freq_elements[0] == 0 then
        debug.printf("[SoapySDRSink]     (no frequency elements)\n")
    end
    libsoapysdr.SoapySDRStrings_clear(ffi.new("char **[1]", {freq_elements}), num_freq_elements[0])

    -- Bandwidths
    debug.printf("[SoapySDRSink] TX Channel %u bandwidths:\n", self.channel)
    local num_bandwidths = ffi.new("size_t[1]")
    local bandwidths = libsoapysdr.SoapySDRDevice_listBandwidths(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, num_bandwidths)
    for i = 0, tonumber(num_bandwidths[0])-1 do
        debug.printf("[SoapySDRSink]     %f\n", bandwidths[i])
    end
    if num_bandwidths[0] == 0 then
        debug.printf("[SoapySDRSink]     (no bandwidths)\n")
    end
    ffi.C.free(bandwidths)

    -- Bandwidth ranges
    debug.printf("[SoapySDRSink] TX Channel %u bandwidth ranges:\n", self.channel)
    local num_bandwidth_ranges = ffi.new("size_t[1]")
    local bandwidth_ranges = libsoapysdr.SoapySDRDevice_getBandwidthRange(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, num_bandwidth_ranges)
    for i = 0, tonumber(num_bandwidth_ranges[0])-1 do
        debug.printf("[SoapySDRSink]     %f - %f\n", bandwidth_ranges[i].minimum, bandwidth_ranges[i].maximum)
    end
    if num_bandwidth_ranges[0] == 0 then
        debug.printf("[SoapySDRSink]     (no bandwidth ranges)\n")
    end
    ffi.C.free(bandwidth_ranges)

    -- Overall gain range
    local gain_range = libsoapysdr.SoapySDRDevice_getGainRange(self.dev, ffi.C.SOAPY_SDR_TX, self.channel)
    debug.printf("[SoapySDRSink] TX Channel %u overall gain range:\n", self.channel)
    debug.printf("[SoapySDRSink]     %f - %f\n", gain_range.minimum, gain_range.maximum)

    -- Gain element ranges
    debug.printf("[SoapySDRSink] TX Channel %u gain element ranges:\n", self.channel)
    local num_gain_elements = ffi.new("size_t[1]")
    local gain_elements = libsoapysdr.SoapySDRDevice_listGains(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, num_gain_elements)
    for i = 0, tonumber(num_gain_elements[0])-1 do
        local range = libsoapysdr.SoapySDRDevice_getGainElementRange(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, gain_elements[i])
        debug.printf("[SoapySDRSink]     %s: %f - %f\n", ffi.string(gain_elements[i]), range.minimum, range.maximum)
    end
    if num_gain_elements[0] == 0 then
        debug.printf("[SoapySDRSink]     (no gain elements)\n")
    end
    libsoapysdr.SoapySDRStrings_clear(ffi.new("char **[1]", {gain_elements}), num_gain_elements[0])

    -- Antennas
    debug.printf("[SoapySDRSink] TX Channel %u antennas:\n", self.channel)
    local num_antennas = ffi.new("size_t[1]")
    local antennas = libsoapysdr.SoapySDRDevice_listAntennas(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, num_antennas)
    for i = 0, tonumber(num_antennas[0])-1 do
        debug.printf("[SoapySDRSink]     %s\n", ffi.string(antennas[i]))
    end
    if num_antennas[0] == 0 then
        debug.printf("[SoapySDRSink]     (no antennas)\n")
    end
    libsoapysdr.SoapySDRStrings_clear(ffi.new("char **[1]", {antennas}), num_antennas[0])
end

function SoapySDRSink:initialize_soapysdr()
    local ret

    -- (Debug) Dump version info
    if debug.enabled then
        -- Look up library version
        debug.printf("[SoapySDRSink] SoapySDR library version: %s\n", ffi.string(libsoapysdr.SoapySDR_getLibVersion()))
    end

    -- Make device
    if type(self.driver) == "string" then
        self.dev = libsoapysdr.SoapySDRDevice_makeStrArgs(self.driver)
    else
        self.dev = libsoapysdr.SoapySDRDevice_make(table2kwargs(self.driver))
    end
    if self.dev == nil then
        error("Making device: " .. ffi.string(libsoapysdr.SoapySDRDevice_lastError()))
    end

    -- (Debug) Dump device info
    if debug.enabled then
        self:debug_dump_soapysdr()
    end

    -- (Debug) Print frequency and sample rate
    debug.printf("[SoapySDRSink] Frequency: %f Hz, Sample rate: %f Hz\n", self.frequency, self:get_rate())

    -- Set sample rate
    ret = libsoapysdr.SoapySDRDevice_setSampleRate(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, self:get_rate())
    if ret < 0 then
        local errstr = ffi.string(libsoapysdr.SoapySDRDevice_lastError())

        io.stderr:write(string.format("[SoapySDRSink] Error setting sample rate %f Hz.\n", self:get_rate()))
        io.stderr:write("[SoapySDRSink] Supported sample rates:\n")
        local num_rates = ffi.new("size_t[1]")
        local rates = libsoapysdr.SoapySDRDevice_listSampleRates(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, num_rates)
        if rates == nil then
            io.stderr:write(string.format("[SoapySDRSink] Error SoapySDRDevice_listSampleRates(): %s\n", ffi.string(libsoapysdr.SoapySDRDevice_lastError())))
        else
            for i = 0, tonumber(num_rates[0])-1 do
                io.stderr:write(string.format("[SoapySDRSink]     %f\n", rates[i]))
            end
            ffi.C.free(rates)
        end

        error("SoapySDRDevice_setSampleRate(): " .. errstr)
    end

    -- Set frequency
    ret = libsoapysdr.SoapySDRDevice_setFrequency(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, self.frequency, nil)
    if ret < 0 then
        local errstr = ffi.string(libsoapysdr.SoapySDRDevice_lastError())

        io.stderr:write(string.format("[SoapySDRSink] Error setting frequency %f Hz.\n", self.frequency))
        io.stderr:write("[SoapySDRSink] Supported frequency ranges:\n")
        local num_freq_ranges = ffi.new("size_t[1]")
        local freq_ranges = libsoapysdr.SoapySDRDevice_getFrequencyRange(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, num_freq_ranges)
        if freq_ranges == nil then
            io.stderr:write(string.format("[SoapySDRSink] Error SoapySDRDevice_getFrequencyRange(): %s\n", ffi.string(libsoapysdr.SoapySDRDevice_lastError())))
        else
            for i = 0, tonumber(num_freq_ranges[0])-1 do
                io.stderr:write(string.format("[SoapySDRSink]     %f - %f\n", freq_ranges[i].minimum, freq_ranges[i].maximum))
            end
            ffi.C.free(freq_ranges)
        end

        error("SoapySDRDevice_setFrequency(): " .. errstr)
    end

    -- Set bandwidth (if specified)
    if self.bandwidth then
        ret = libsoapysdr.SoapySDRDevice_setBandwidth(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, self.bandwidth)
        if ret < 0 then
            error("SoapySDRDevice_setBandwidth(): " .. ffi.string(libsoapysdr.SoapySDRDevice_lastError()))
        end
    end

    -- (Debug) Print bandwidth
    if debug.enabled then
        local bandwidth = libsoapysdr.SoapySDRDevice_getBandwidth(self.dev, ffi.C.SOAPY_SDR_TX, self.channel)
        debug.printf("[SoapySDRSink] Bandwidth: %f\n", bandwidth)
    end

    -- Set frequencies (if specified)
    if self.frequencies then
        for name, value in pairs(self.frequencies) do
            ret = libsoapysdr.SoapySDRDevice_setFrequencyComponent(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, name, value, nil)
            if ret < 0 then
                error(string.format("SoapySDRDevice_setFrequencyComponent(\"%s\", %f): %s", name, value, ffi.string(libsoapysdr.SoapySDRDevice_lastError())))
            end
        end
    end

    -- Set gain (if specified)
    if self.gain then
        ret = libsoapysdr.SoapySDRDevice_setGain(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, self.gain)
        if ret < 0 then
            error("SoapySDRDevice_setGain(): " .. ffi.string(libsoapysdr.SoapySDRDevice_lastError()))
        end
    end

    -- Set gains (if specified)
    if self.gains then
        for name, value in pairs(self.gains) do
            ret = libsoapysdr.SoapySDRDevice_setGainElement(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, name, value)
            if ret < 0 then
                error(string.format("SoapySDRDevice_setGainElement(\"%s\", %f): %s", name, value, ffi.string(libsoapysdr.SoapySDRDevice_lastError())))
            end
        end
    end

    -- Set autogain (if specified)
    if self.autogain ~= nil then
        ret = libsoapysdr.SoapySDRDevice_setGainMode(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, self.autogain)
        if ret < 0 then
            error("SoapySDRDevice_setGainMode(): " .. ffi.string(libsoapysdr.SoapySDRDevice_lastError()))
        end
    end

    -- Set antenna (if specified)
    if self.antenna then
        ret = libsoapysdr.SoapySDRDevice_setAntenna(self.dev, ffi.C.SOAPY_SDR_TX, self.channel, self.antenna)
        if ret < 0 then
            error("SoapySDRDevice_setAntenna(): " .. ffi.string(libsoapysdr.SoapySDRDevice_lastError()))
        end
    end

    -- Set additional settings (if specified)
    if self.driver_settings then
        for name, value in pairs(self.driver_settings) do
            libsoapysdr.SoapySDRDevice_writeSetting(self.dev, name, value)
        end
    end

    -- Setup the stream
    self.stream = ffi.new("SoapySDRStream*[1]")
    local channels = ffi.new("size_t[1]", {self.channel})
    ret = libsoapysdr.SoapySDRDevice_setupStream(self.dev, self.stream, ffi.C.SOAPY_SDR_TX, "CF32", channels, 1, nil)
    if ret < 0 then
        error("SoapySDRDevice_setupStream(): " .. ffi.string(libsoapysdr.SoapySDR_errToStr(ret)))
    end

    -- Activate the stream
    ret = libsoapysdr.SoapySDRDevice_activateStream(self.dev, self.stream[0], 0, 0, 0)
    if ret < 0 then
        error("SoapySDRDevice_activateStream(): " .. ffi.string(libsoapysdr.SoapySDR_errToStr(ret)))
    end

    -- Mark ourselves initialized
    self.initialized = true
end

function SoapySDRSink:cleanup()
    if self.initialized then
        -- Deactivate the stream
        ret = libsoapysdr.SoapySDRDevice_deactivateStream(self.dev, self.stream[0], 0, 0)
        if ret < 0 then
            error("SoapySDRDevice_deactivateStream(): " .. ffi.string(libsoapysdr.SoapySDR_errToStr(ret)))
        end

        -- Close the stream
        libsoapysdr.SoapySDRDevice_closeStream(self.dev, self.stream[0])

        -- Close the device
        libsoapysdr.SoapySDRDevice_unmake(self.dev)
    end
end

function SoapySDRSink:process(x)
    if not self.initialized then
        -- Initialize the SoapySDR in our own running process
        self:initialize_soapysdr()
    end

    local buffs = ffi.new("const void *[1]")
    local flags = ffi.new("int[1]")

    -- Write vector to stream
    local len = 0
    while len < x.length do
        buffs[0] = x.data + len
        local elems_written = libsoapysdr.SoapySDRDevice_writeStream(self.dev, self.stream[0], buffs, x.length - len, flags, 0, 1e12)
        if elems_written < 0 then
            error("SoapySDRDevice_writeStream(): " .. ffi.string(libsoapysdr.SoapySDR_errToStr(elems_written)))
        end
        len = len + elems_written
    end
end

return SoapySDRSink
