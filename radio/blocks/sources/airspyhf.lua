---
-- Source a complex-valued signal from an Airspy HF+. This source requires the
-- libairspyhf library.
--
-- @category Sources
-- @block AirspyHFSource
-- @tparam number frequency Tuning frequency in Hz
-- @tparam number rate Sample rate in Hz (192 kHz, 256 kHz, 384 kHz, 768 kHz)
-- @tparam[opt={}] table options Additional options, specifying:
--      * `hf_agc` (bool, default true)
--      * `hf_agc_threshold` (string, default "low", choice of "low" or "high")
--      * `hf_att` (int, default 0 dB, for manual attenuation when HF AGC is
--                  disabled, range of 0 to 48 dB, 6 dB step)
--      * `hf_lna` (bool, default false)
--
-- @signature > out:ComplexFloat32
--
-- @usage
-- -- Source samples from 91.1 MHz sampled at 768 kHz
-- local src = radio.AirspyHFSource(91.1e6, 768e3)
--
-- -- Source samples from 7.150 MHz sampled at 192 kHz, with HF AGC
-- -- enabled (default) and HF LNA enabled
-- local src = radio.AirspyHFSource(7.150e6, 192e3, {hf_lna = true})
--
-- -- Source samples from 14.175 MHz sampled at 192 kHz, with HF AGC disabled
-- -- and 24 dB HF attenuation
-- local src = radio.AirspyHFSource(14.175e6, 192e3, {hf_agc = false, hf_att = 24})

local ffi = require('ffi')

local block = require('radio.core.block')
local platform = require('radio.core.platform')
local debug = require('radio.core.debug')
local types = require('radio.types')
local async = require('radio.core.async')

local AirspyHFSource = block.factory("AirspyHFSource")

function AirspyHFSource:instantiate(frequency, rate, options)
    self.frequency = assert(frequency, "Missing argument #1 (frequency)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    self.options = options or {}
    self.hf_agc = (self.options.hf_agc == nil) and true or self.options.hf_agc
    self.hf_agc_threshold = self.options.hf_agc_threshold or "low"
    self.hf_att = self.options.hf_att or 0
    self.hf_lna = self.options.hf_lna or false

    assert(self.hf_agc_threshold == "low" or self.hf_agc_threshold == "high", "Invalid HF AGC Threshold, should be \"low\" or \"high\".")

    self:add_type_signature({}, {block.Output("out", types.ComplexFloat32)})
end

function AirspyHFSource:get_rate()
    return self.rate
end

ffi.cdef[[
    enum airspyhf_error {
        AIRSPYHF_SUCCESS = 0,
        AIRSPYHF_FAILURE = -1,
    };

    enum airspyhf_board_id {
        AIRSPYHF_BOARD_ID_UNKNOWN_AIRSPYHF = 0,
        AIRSPYHF_BOARD_ID_AIRSPYHF_REV_A = 1,
        AIRSPYHF_BOARD_ID_INVALID = 0xFF,
    };

    typedef struct airspyhf_device airspyhf_device_t;

    typedef struct {
        float re;
        float im;
    } airspyhf_complex_float_t;

    typedef struct {
        uint32_t part_id;
        uint32_t serial_no[4];
    } airspyhf_read_partid_serialno_t;

    typedef struct {
        uint32_t major_version;
        uint32_t minor_version;
        uint32_t revision;
    } airspyhf_lib_version_t;

    typedef struct {
        airspyhf_device_t* device;
        void* ctx;
        airspyhf_complex_float_t* samples;
        int sample_count;
        uint64_t dropped_samples;
    } airspyhf_transfer_t;

    typedef int (*airspyhf_sample_block_cb_fn) (airspyhf_transfer_t* transfer_fn);

    void airspyhf_lib_version(airspyhf_lib_version_t* lib_version);
    int airspyhf_list_devices(uint64_t *serials, int count);
    int airspyhf_open(airspyhf_device_t** device);
    int airspyhf_open_sn(airspyhf_device_t** device, uint64_t serial_number);
    int airspyhf_close(airspyhf_device_t* device);
    int airspyhf_get_output_size(airspyhf_device_t* device);
    int airspyhf_start(airspyhf_device_t* device, airspyhf_sample_block_cb_fn callback, void* ctx);
    int airspyhf_stop(airspyhf_device_t* device);
    int airspyhf_is_streaming(airspyhf_device_t* device);
    int airspyhf_is_low_if(airspyhf_device_t* device);
    int airspyhf_set_freq(airspyhf_device_t* device, const uint32_t freq_hz);
    int airspyhf_set_lib_dsp(airspyhf_device_t* device, const uint8_t flag);
    int airspyhf_get_samplerates(airspyhf_device_t* device, uint32_t* buffer, const uint32_t len);
    int airspyhf_set_samplerate(airspyhf_device_t* device, uint32_t samplerate);
    int airspyhf_get_calibration(airspyhf_device_t* device, int32_t* ppb);
    int airspyhf_set_calibration(airspyhf_device_t* device, int32_t ppb);
    int airspyhf_set_optimal_iq_correction_point(airspyhf_device_t* device, float w);
    int airspyhf_iq_balancer_configure(airspyhf_device_t* device, int buffers_to_skip, int fft_integration, int fft_overlap, int correlation_integration);
    int airspyhf_flash_calibration(airspyhf_device_t* device);
    int airspyhf_board_partid_serialno_read(airspyhf_device_t* device, airspyhf_read_partid_serialno_t* read_partid_serialno);
    int airspyhf_version_string_read(airspyhf_device_t* device, char* version, uint8_t length);
    int airspyhf_set_hf_agc(airspyhf_device_t* device, uint8_t flag);
    int airspyhf_set_hf_agc_threshold(airspyhf_device_t* device, uint8_t flag);
    int airspyhf_set_hf_att(airspyhf_device_t* device, uint8_t value);
    int airspyhf_set_hf_lna(airspyhf_device_t* device, uint8_t flag);
]]
local libairspyhf_available, libairspyhf = pcall(ffi.load, "airspyhf")

function AirspyHFSource:initialize()
    -- Check library is available
    if not libairspyhf_available then
        error("AirspyHFSource: libairspyhf not found. Is libairspyhf installed?")
    end
end

function AirspyHFSource:initialize_airspyhf()
    self.dev = ffi.new("airspyhf_device_t *[1]")

    local ret

    -- Open device
    ret = libairspyhf.airspyhf_open(self.dev)
    if ret ~= 0 then
        error("airspyhf_open(): " .. ret)
    end

    -- Dump version info
    if debug.enabled then
        -- Look up library version
        local lib_version = ffi.new("airspyhf_lib_version_t")
        libairspyhf.airspyhf_lib_version(lib_version)

        -- Look up firmware version
        local firmware_version = ffi.new("char[64]")
        ret = libairspyhf.airspyhf_version_string_read(self.dev[0], firmware_version, ffi.sizeof(firmware_version))
        if ret ~= 0 then
            error("airspyhf_version_string_read(): " .. ret)
        end
        firmware_version = ffi.string(firmware_version)

        -- Look up board info
        local board_info = ffi.new('airspyhf_read_partid_serialno_t[1]')
        ret = libairspyhf.airspyhf_board_partid_serialno_read(self.dev[0], board_info)
        if ret ~= 0 then
            error("airspyhf_board_partid_serialno_read(): " .. ret)
        end

        debug.printf("[AirspyHFSource] Library version:   %u.%u.%u\n", lib_version.major_version, lib_version.minor_version, lib_version.revision)
        debug.printf("[AirspyHFSource] Firmware version:  %s\n", firmware_version)
        debug.printf("[AirspyHFSource] Part ID:           0x%08x\n", board_info[0].part_id)
        debug.printf("[AirspyHFSource] Serial Number:     0x%08x%08x\n", board_info[0].serial_no[0], board_info[0].serial_no[1])
    end

    -- Set sample rate
    ret = libairspyhf.airspyhf_set_samplerate(self.dev[0], self.rate)
    if ret ~= 0 then
        local ret_save = ret

        io.stderr:write(string.format("[AirspyHFSource] Error setting sample rate %u S/s.\n", self.rate))

        local num_sample_rates, sample_rates

        -- Look up number of sample rates
        num_sample_rates = ffi.new("uint32_t[1]")
        ret = libairspyhf.airspyhf_get_samplerates(self.dev[0], num_sample_rates, 0)
        if ret ~= 0 then
            goto set_samplerate_error
        end

        -- Look up sample rates
        sample_rates = ffi.new("uint32_t[?]", num_sample_rates[0])
        ret = libairspyhf.airspyhf_get_samplerates(self.dev[0], sample_rates, num_sample_rates[0])
        if ret ~= 0 then
            goto set_samplerate_error
        end

        -- Print supported sample rates
        io.stderr:write("[AirspyHFSource] Supported sample rates:\n")
        for i=0, num_sample_rates[0]-1 do
            io.stderr:write(string.format("[AirspyHFSource]    %u\n", sample_rates[i]))
        end

        ::set_samplerate_error::
        error("airspyhf_set_samplerate(): " .. ret_save)
    end

    debug.printf("[AirspyHFSource] Frequency: %u Hz, Sample rate: %u Hz\n", self.frequency, self.rate)

    -- Set HF AGC
    ret = libairspyhf.airspyhf_set_hf_agc(self.dev[0], self.hf_agc)
    if ret ~= 0 then
        error("airspyhf_set_hf_agc(): " .. ret)
    end

    if self.hf_agc then
        -- Set HF AGC Threshold
        ret = libairspyhf.airspyhf_set_hf_agc_threshold(self.dev[0], self.hf_agc_threshold == "high" and 1 or 0)
        if ret ~= 0 then
            error("airspyhf_set_hf_agc_threshold(): " .. ret)
        end
    else
        -- Set HF Attenuator
        ret = libairspyhf.airspyhf_set_hf_att(self.dev[0], self.hf_att)
        if ret ~= 0 then
            error("airspyhf_set_hf_agc(): " .. ret)
        end
    end

    -- Set HF LNA
    ret = libairspyhf.airspyhf_set_hf_lna(self.dev[0], self.hf_lna)
    if ret ~= 0 then
        error("airspyhf_set_hf_lna(): " .. ret)
    end

    -- Set frequency
    ret = libairspyhf.airspyhf_set_freq(self.dev[0], self.frequency)
    if ret ~= 0 then
        error("airspyhf_set_freq(): " .. ret)
    end
end

local function read_callback_factory(...)
    local ffi = require('ffi')
    local radio = require('radio')

    local fds = {...}

    local function read_callback(transfer)
        -- Check for dropped samples
        if transfer.dropped_samples ~= 0 then
            io.stderr:write(string.format("[AirspyHFSource] Warning: %u samples dropped.\n", tonumber(transfer.dropped_samples)))
        end

        -- Calculate size of samples in bytes
        local size = transfer.sample_count*ffi.sizeof("airspyhf_complex_float_t")

        -- Write to each output fd
        for i = 1, #fds do
            local total_bytes_written = 0
            while total_bytes_written < size do
                local bytes_written = tonumber(ffi.C.write(fds[i], ffi.cast("uint8_t *", transfer.samples) + total_bytes_written, size - total_bytes_written))
                if bytes_written <= 0 then
                    error("write(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
                end

                total_bytes_written = total_bytes_written + bytes_written
            end
        end

        return 0
    end

    return ffi.cast('int (*)(airspyhf_transfer_t *)', read_callback)
end

function AirspyHFSource:run()
    -- Initialize the airspyhf in our own running process
    self:initialize_airspyhf()

    -- Build signal set with SIGTERM
    local sigset = ffi.new("sigset_t[1]")
    ffi.C.sigemptyset(sigset)
    ffi.C.sigaddset(sigset, ffi.C.SIGTERM)

    -- Block handling of SIGTERM
    if ffi.C.sigprocmask(ffi.C.SIG_BLOCK, sigset, nil) ~= 0 then
        error("sigprocmask(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Start receiving
    local read_callback, read_callback_state = async.callback(read_callback_factory, unpack(self.outputs[1]:filenos()))
    local ret = libairspyhf.airspyhf_start(self.dev[0], read_callback, nil)
    if ret ~= 0 then
        error("airspyhf_start(): " .. ret)
    end

    -- Wait for SIGTERM
    local sig = ffi.new("int[1]")
    if ffi.C.sigwait(sigset, sig) ~= 0 then
        error("sigwait(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Stop receiving
    ret = libairspyhf.airspyhf_stop(self.dev[0])
    if ret ~= 0 then
        error("airspyhf_stop(): " .. ret)
    end

    -- Close airspyhf
    ret = libairspyhf.airspyhf_close(self.dev[0])
    if ret ~= 0 then
        error("airspyhf_close(): " .. ret)
    end
end

return AirspyHFSource
