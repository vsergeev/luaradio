---
-- Source a complex-valued signal from an Airspy. This source requires the
-- libairspy library. The Airspy R2 and Airspy Mini dongles are supported.
--
-- @category Sources
-- @block AirspySource
-- @tparam number frequency Tuning frequency in Hz
-- @tparam number rate Sample rate in Hz (3 MHz or 6 MHz for Airspy Mini,
--                                        2.5 MHz or 10 MHz for Airspy R2)
-- @tparam[opt={}] table options Additional options, specifying:
--      * `gain_mode` (string, default "linearity", choice of "custom", "linearity", "sensitivity")
--      * `lna_gain` (int, default 5 dB, for custom gain mode, range 0 to 15 dB)
--      * `mixer_gain` (int, default 1 dB, for custom gain mode, range 0 to 15 dB)
--      * `vga_gain` (int, default 5 dB, for custom gain mode, range 0 to 15 dB)
--      * `lna_agc` (bool, default false, for custom gain mode)
--      * `mixer_agc` (bool, default false, for custom gain mode)
--      * `linearity_gain` (int, default 10, for linearity gain mode, range 0 to 21)
--      * `sensitivity_gain` (int, default 10, for sensitivity gain mode, range 0 to 21)
--      * `biastee_enable` (bool, default false)
--
-- @signature > out:ComplexFloat32
--
-- @usage
-- -- Source samples from 135 MHz sampled at 6 MHz
-- local src = radio.AirspySource(135e6, 6e6)
--
-- -- Source samples from 91.1 MHz sampled at 3 MHz, with custom gain settings
-- local src = radio.AirspySource(91.1e6, 3e6, {gain_mode = "custom", lna_gain = 4, mixer_gain = 1, vga_gain = 6})
--
-- -- Source samples from 91.1 MHz sampled at 2.5 MHz, with linearity gain mode
-- local src = radio.AirspySource(91.1e6, 2.5e6, {gain_mode = "linearity", linearity_gain = 8})
--
-- -- Source samples from 91.1 MHz sampled at 2.5 MHz, with sensitivity gain mode
-- local src = radio.AirspySource(91.1e6, 2.5e6, {gain_mode = "sensitivity", sensitivity_gain = 8})
--
-- -- Source samples from 144.390 MHz sampled at 2.5 MHz, with bias tee enabled
-- local src = radio.AirspySource(144.390e6, 2.5e6, {biastee_enable = true})

local ffi = require('ffi')

local block = require('radio.core.block')
local platform = require('radio.core.platform')
local debug = require('radio.core.debug')
local types = require('radio.types')
local async = require('radio.core.async')

local AirspySource = block.factory("AirspySource")

function AirspySource:instantiate(frequency, rate, options)
    self.frequency = assert(frequency, "Missing argument #1 (frequency)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    self.options = options or {}
    self.gain_mode = self.options.gain_mode or "linearity"
    self.biastee_enable = self.options.biastee_enable or false

    if self.gain_mode == "custom" then
        self.lna_gain = self.options.lna_gain or 5
        self.mixer_gain = self.options.mixer_gain or 1
        self.vga_gain = self.options.vga_gain or 5
        self.lna_agc = self.options.lna_agc or false
        self.mixer_agc = self.options.mixer_agc or false
    elseif self.gain_mode == "linearity" then
        self.linearity_gain = self.options.linearity_gain or 10
    elseif self.gain_mode == "sensitivity" then
        self.sensitivity_gain = self.options.sensitivity_gain or 10
    else
        error(string.format("Unsupported gain mode \"%s\".", self.gain_mode))
    end

    self:add_type_signature({}, {block.Output("out", types.ComplexFloat32)})
end

function AirspySource:get_rate()
    return self.rate
end

ffi.cdef[[
    struct airspy_device;

    typedef struct {
        uint32_t major_version;
        uint32_t minor_version;
        uint32_t revision;
    } airspy_lib_version_t;

    typedef struct {
        struct airspy_device* device;
        void* ctx;
        void* samples;
        int sample_count;
        uint64_t dropped_samples;
        int sample_type;
    } airspy_transfer_t, airspy_transfer;

    typedef int (*airspy_sample_block_cb_fn)(airspy_transfer* transfer);

    const char* airspy_error_name(int errcode);

    int airspy_open(struct airspy_device** device);
    int airspy_close(struct airspy_device* device);

    void airspy_lib_version(airspy_lib_version_t* lib_version);
    int airspy_board_id_read(struct airspy_device* device, uint8_t* value);
    const char* airspy_board_id_name(int board_id);
    int airspy_version_string_read(struct airspy_device* device, char* version, uint8_t length);

    int airspy_start_rx(struct airspy_device* device, airspy_sample_block_cb_fn callback, void* rx_ctx);
    int airspy_stop_rx(struct airspy_device* device);

    int airspy_get_samplerates(struct airspy_device* device, uint32_t* buffer, const uint32_t len);
    int airspy_set_samplerate(struct airspy_device* device, uint32_t samplerate);

    enum airspy_sample_type { AIRSPY_SAMPLE_FLOAT32_IQ = 0, };
    int airspy_set_sample_type(struct airspy_device* device, enum airspy_sample_type sample_type);
    int airspy_set_freq(struct airspy_device* device, const uint32_t freq_hz);
    int airspy_set_lna_gain(struct airspy_device* device, uint8_t value);
    int airspy_set_mixer_gain(struct airspy_device* device, uint8_t value);
    int airspy_set_vga_gain(struct airspy_device* device, uint8_t value);
    int airspy_set_lna_agc(struct airspy_device* device, uint8_t value);
    int airspy_set_mixer_agc(struct airspy_device* device, uint8_t value);
    int airspy_set_linearity_gain(struct airspy_device* device, uint8_t value);
    int airspy_set_sensitivity_gain(struct airspy_device* device, uint8_t value);
    int airspy_set_rf_bias(struct airspy_device* device, uint8_t value);
    int airspy_set_packing(struct airspy_device* device, uint8_t value);
]]
local libairspy_available, libairspy = pcall(ffi.load, "airspy")

function AirspySource:initialize()
    -- Check library is available
    if not libairspy_available then
        error("AirspySource: libairspy not found. Is libairspy installed?")
    end
end

function AirspySource:initialize_airspy()
    self.dev = ffi.new("struct airspy_device *[1]")

    local ret

    -- Open device
    ret = libairspy.airspy_open(self.dev)
    if ret ~= 0 then
        error("airspy_open(): " .. ffi.string(libairspy.airspy_error_name(ret)))
    end

    -- Dump version info
    if debug.enabled then
        -- Look up library version
        local lib_version = ffi.new("airspy_lib_version_t")
        libairspy.airspy_lib_version(lib_version)

        -- Look up firmware version
        local firmware_version = ffi.new("char[128]")
        ret = libairspy.airspy_version_string_read(self.dev[0], firmware_version, 128)
        if ret ~= 0 then
            error("airspy_version_string_read(): " .. ffi.string(libairspy.airspy_error_name(ret)))
        end
        firmware_version = ffi.string(firmware_version)

        -- Look up board ID
        local board_id = ffi.new("uint8_t[1]")
        ret = libairspy.airspy_board_id_read(self.dev[0], board_id)
        if ret ~= 0 then
            error("airspy_board_id_read(): " .. ffi.string(libairspy.airspy_error_name(ret)))
        end
        board_id = ffi.string(libairspy.airspy_board_id_name(board_id[0]))

        debug.printf("[AirspySource] Library version:   %u.%u.%u\n", lib_version.major_version, lib_version.minor_version, lib_version.revision)
        debug.printf("[AirspySource] Firmware version:  %s\n", firmware_version)
        debug.printf("[AirspySource] Board ID:          %s\n", board_id)
    end

    -- Set sample type
    ret = libairspy.airspy_set_sample_type(self.dev[0], ffi.C.AIRSPY_SAMPLE_FLOAT32_IQ)
    if ret ~= 0 then
        error("airspy_set_sample_type(): " .. ffi.string(libairspy.airspy_error_name(ret)))
    end

    -- Set sample rate
    ret = libairspy.airspy_set_samplerate(self.dev[0], self.rate)
    if ret ~= 0 then
        local ret_save = ret

        io.stderr:write(string.format("[AirspySource] Error setting sample rate %u S/s.\n", self.rate))

        local num_sample_rates, sample_rates

        -- Look up number of sample rates
        num_sample_rates = ffi.new("uint32_t[1]")
        ret = libairspy.airspy_get_samplerates(self.dev[0], num_sample_rates, 0)
        if ret ~= 0 then
            goto set_samplerate_error
        end

        -- Look up sample rates
        sample_rates = ffi.new("uint32_t[?]", num_sample_rates[0])
        ret = libairspy.airspy_get_samplerates(self.dev[0], sample_rates, num_sample_rates[0])
        if ret ~= 0 then
            goto set_samplerate_error
        end

        -- Print supported sample rates
        io.stderr:write("[AirspySource] Supported sample rates:\n")
        for i=0, num_sample_rates[0]-1 do
            io.stderr:write(string.format("[AirspySource]    %u\n", sample_rates[i]))
        end

        ::set_samplerate_error::
        error("airspy_set_samplerate(): " .. ffi.string(libairspy.airspy_error_name(ret_save)))
    end

    debug.printf("[AirspySource] Frequency: %u Hz, Sample rate: %u Hz\n", self.frequency, self.rate)

    -- Disable packing
    ret = libairspy.airspy_set_packing(self.dev[0], 0)
    if ret ~= 0 then
        error("airspy_set_packing(): " .. ffi.string(libairspy.airspy_error_name(ret)))
    end

    -- Set bias tee
    ret = libairspy.airspy_set_rf_bias(self.dev[0], self.biastee_enable)
    if ret ~= 0 then
        error("airspy_set_rf_bias(): " .. ffi.string(libairspy.airspy_error_name(ret)))
    end

    if self.gain_mode == "custom" then
        -- LNA gain
        if not self.lna_agc then
            -- Disable LNA AGC
            ret = libairspy.airspy_set_lna_agc(self.dev[0], 0)
            if ret ~= 0 then
                error("airspy_set_lna_agc(): " .. ffi.string(libairspy.airspy_error_name(ret)))
            end

            -- Set LNA gain
            ret = libairspy.airspy_set_lna_gain(self.dev[0], self.lna_gain)
            if ret ~= 0 then
                error("airspy_set_lna_gain(): " .. ffi.string(libairspy.airspy_error_name(ret)))
            end
        else
            -- Enable LNA AGC
            ret = libairspy.airspy_set_lna_agc(self.dev[0], 1)
            if ret ~= 0 then
                error("airspy_set_lna_agc(): " .. ffi.string(libairspy.airspy_error_name(ret)))
            end
        end

        -- Mixer gain
        if not self.mixer_agc then
            -- Disable mixer AGC
            ret = libairspy.airspy_set_mixer_agc(self.dev[0], 0)
            if ret ~= 0 then
                error("airspy_set_mixer_agc(): " .. ffi.string(libairspy.airspy_error_name(ret)))
            end

            -- Set mixer gain
            ret = libairspy.airspy_set_mixer_gain(self.dev[0], self.mixer_gain)
            if ret ~= 0 then
                error("airspy_set_mixer_gain(): " .. ffi.string(libairspy.airspy_error_name(ret)))
            end
        else
            -- Enable mixer AGC
            ret = libairspy.airspy_set_mixer_agc(self.dev[0], 1)
            if ret ~= 0 then
                error("airspy_set_mixer_agc(): " .. ffi.string(libairspy.airspy_error_name(ret)))
            end
        end

        -- Set VGA gain
        ret = libairspy.airspy_set_vga_gain(self.dev[0], self.vga_gain)
        if ret ~= 0 then
            error("airspy_set_vga_gain(): " .. ffi.string(libairspy.airspy_error_name(ret)))
        end
    elseif self.gain_mode == "linearity" then
        -- Set linearity gain
        ret = libairspy.airspy_set_linearity_gain(self.dev[0], self.linearity_gain)
        if ret ~= 0 then
            error("airspy_set_linearity_gain(): " .. ffi.string(libairspy.airspy_error_name(ret)))
        end
    elseif self.gain_mode == "sensitivity" then
        -- Set sensitivity gain
        ret = libairspy.airspy_set_sensitivity_gain(self.dev[0], self.sensitivity_gain)
        if ret ~= 0 then
            error("airspy_set_sensitivity_gain(): " .. ffi.string(libairspy.airspy_error_name(ret)))
        end
    end

    -- Set frequency
    ret = libairspy.airspy_set_freq(self.dev[0], self.frequency)
    if ret ~= 0 then
        error("airspy_set_freq(): " .. ffi.string(libairspy.airspy_error_name(ret)))
    end
end

local function read_callback_factory(...)
    local ffi = require('ffi')
    local radio = require('radio')

    local fds = {...}

    local function read_callback(transfer)
        -- Check for dropped samples
        if transfer.dropped_samples ~= 0 then
            io.stderr:write(string.format("[AirspySource] Warning: %u samples dropped.\n", tonumber(transfer.dropped_samples)))
        end

        -- Calculate size of samples in bytes
        local size = transfer.sample_count*ffi.sizeof("float")*2

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

    return ffi.cast('int (*)(airspy_transfer *)', read_callback)
end

function AirspySource:run()
    -- Initialize the airspy in our own running process
    self:initialize_airspy()

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
    local ret = libairspy.airspy_start_rx(self.dev[0], read_callback, nil)
    if ret ~= 0 then
        error("airspy_start_rx(): " .. ffi.string(libairspy.airspy_error_name(ret)))
    end

    -- Wait for SIGTERM
    local sig = ffi.new("int[1]")
    if ffi.C.sigwait(sigset, sig) ~= 0 then
        error("sigwait(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Stop receiving
    ret = libairspy.airspy_stop_rx(self.dev[0])
    if ret ~= 0 then
        error("airspy_stop_rx(): " .. ffi.string(libairspy.airspy_error_name(ret)))
    end

    -- Close airspy
    ret = libairspy.airspy_close(self.dev[0])
    if ret ~= 0 then
        error("airspy_close(): " .. ffi.string(libairspy.airspy_error_name(ret)))
    end
end

return AirspySource
