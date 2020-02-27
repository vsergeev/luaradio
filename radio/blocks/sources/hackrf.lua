---
-- Source a complex-valued signal from a HackRF One. This source requires the
-- libhackrf library.
--
-- @category Sources
-- @block HackRFSource
-- @tparam number frequency Tuning frequency in Hz
-- @tparam number rate Sample rate in Hz
-- @tparam[opt={}] table options Additional options, specifying:
--      * `lna_gain` (int, default 8 dB, range 0 to 40 dB, 8 dB step)
--      * `vga_gain` (int, default 40 dB, range 0 to 62 dB, 2 dB step)
--      * `bandwidth` (number in Hz, default round down from sample rate)
--      * `rf_amplifier_enable` (bool, default false)
--      * `antenna_power_enable` (bool, default false)
--
-- @signature > out:ComplexFloat32
--
-- @usage
-- -- Source samples from 135 MHz sampled at 10 MHz
-- local src = radio.HackRFSource(135e6, 10e6)
--
-- -- Source samples from 135 MHz sampled at 10 MHz, with 2.5 MHz bandwidth
-- local src = radio.HackRFSource(135e6, 10e6, {bandwidth = 2.5e6})
--
-- -- Source samples from 91.1 MHz sampled at 8 MHz, with custom gain settings
-- local src = radio.HackRFSource(91.1e6, 8e6, {lna_gain = 16, vga_gain = 22})
--
-- -- Source samples from 144.390 MHz sampled at 8 MHz, with antenna power enabled
-- local src = radio.HackRFSource(144.390e6, 8e6, {antenna_power_enable = true})

local ffi = require('ffi')

local block = require('radio.core.block')
local platform = require('radio.core.platform')
local debug = require('radio.core.debug')
local types = require('radio.types')
local async = require('radio.core.async')

local HackRFSource = block.factory("HackRFSource")

function HackRFSource:instantiate(frequency, rate, options)
    self.frequency = assert(frequency, "Missing argument #1 (frequency)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    self.options = options or {}
    self.lna_gain = self.options.lna_gain or 8
    self.vga_gain = self.options.vga_gain or 40
    self.bandwidth = self.options.bandwidth
    self.rf_amplifier_enable = self.options.rf_amplifier_enable or false
    self.antenna_power_enable = self.options.antenna_power_enable or false

    self:add_type_signature({}, {block.Output("out", types.ComplexFloat32)})
end

function HackRFSource:get_rate()
    return self.rate
end

if not package.loaded['radio.blocks.sinks.hackrf'] then
    ffi.cdef[[
        enum hackrf_error { HACKRF_SUCCESS = 0, };

        typedef struct hackrf_device hackrf_device;

        typedef struct {
            hackrf_device* device;
            uint8_t* buffer;
            int buffer_length;
            int valid_length;
            void* rx_ctx;
            void* tx_ctx;
        } hackrf_transfer;

        typedef int (*hackrf_sample_block_cb_fn)(hackrf_transfer* transfer);

        const char* hackrf_error_name(enum hackrf_error errcode);

        int hackrf_init(void);
        int hackrf_exit(void);

        int hackrf_open(hackrf_device** device);
        int hackrf_close(hackrf_device* device);

        int hackrf_board_id_read(hackrf_device* device, uint8_t* value);
        const char* hackrf_board_id_name(int board_id);
        int hackrf_version_string_read(hackrf_device* device, char* version, uint8_t length);

        int hackrf_start_rx(hackrf_device* device, hackrf_sample_block_cb_fn callback, void* rx_ctx);
        int hackrf_stop_rx(hackrf_device* device);
        int hackrf_start_tx(hackrf_device* device, hackrf_sample_block_cb_fn callback, void* tx_ctx);
        int hackrf_stop_tx(hackrf_device* device);
        int hackrf_is_streaming(hackrf_device* device);

        int hackrf_set_freq(hackrf_device* device, const uint64_t freq_hz);
        int hackrf_set_sample_rate(hackrf_device* device, const double freq_hz);
        int hackrf_set_sample_rate_manual(hackrf_device* device, const uint32_t freq_hz, const uint32_t divider);
        int hackrf_set_baseband_filter_bandwidth(hackrf_device* device, const uint32_t bandwidth_hz);
        int hackrf_set_lna_gain(hackrf_device* device, uint32_t value);
        int hackrf_set_vga_gain(hackrf_device* device, uint32_t value);
        int hackrf_set_txvga_gain(hackrf_device* device, uint32_t value);
        int hackrf_set_amp_enable(hackrf_device* device, const uint8_t value);
        int hackrf_set_antenna_enable(hackrf_device* device, const uint8_t value);

        uint32_t hackrf_compute_baseband_filter_bw_round_down_lt(const uint32_t bandwidth_hz);
        uint32_t hackrf_compute_baseband_filter_bw(const uint32_t bandwidth_hz);
    ]]
end
local libhackrf_available, libhackrf = pcall(ffi.load, "hackrf")

function HackRFSource:initialize()
    -- Check library is available
    if not libhackrf_available then
        error("HackRFSource: libhackrf not found. Is libhackrf installed?")
    end
end

function HackRFSource:initialize_hackrf()
    self.dev = ffi.new("struct hackrf_device *[1]")

    local ret

    -- Initialize library
    ret = libhackrf.hackrf_init()
    if ret ~= 0 then
        error("hackrf_init(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Open device
    ret = libhackrf.hackrf_open(self.dev)
    if ret ~= 0 then
        error("hackrf_open(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Dump version info
    if debug.enabled then
        -- Look up firmware version
        local firmware_version = ffi.new("char[128]")
        ret = libhackrf.hackrf_version_string_read(self.dev[0], firmware_version, 128)
        if ret ~= 0 then
            error("hackrf_version_string_read(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
        end
        firmware_version = ffi.string(firmware_version)

        -- Look up board ID
        local board_id = ffi.new("uint8_t[1]")
        ret = libhackrf.hackrf_board_id_read(self.dev[0], board_id)
        if ret ~= 0 then
            error("hackrf_board_id_read(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
        end
        board_id = ffi.string(libhackrf.hackrf_board_id_name(board_id[0]))

        debug.printf("[HackRFSource] Firmware version:  %s\n", firmware_version)
        debug.printf("[HackRFSource] Board ID:          %s\n", board_id)
    end

    -- Check sample rate
    if self.rate < 8e6 then
        io.stderr:write(string.format("[HackRFSource] Warning: low sample rate (%u Hz).\n", self.rate))
        io.stderr:write("[HackRFSource] Using a sample rate under 8 MHz is not recommended!\n")
    end

    -- Set sample rate
    ret = libhackrf.hackrf_set_sample_rate(self.dev[0], self.rate)
    if ret ~= 0 then
        error("hackrf_set_sample_rate(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Compute baseband filter bandwidth
    local computed_bandwidth
    if self.bandwidth then
        -- Snap supplied bandwidth to closest
        computed_bandwidth = libhackrf.hackrf_compute_baseband_filter_bw(self.bandwidth)
    else
        -- Round down from sample rate
        computed_bandwidth = libhackrf.hackrf_compute_baseband_filter_bw_round_down_lt(self.rate)
    end

    debug.printf("[HackRFSource] Frequency: %u Hz, Sample rate: %u Hz\n", self.frequency, self.rate)
    debug.printf("[HackRFSource] Requested Bandwidth: %u Hz, Actual Bandwidth: %u Hz\n", self.bandwidth or computed_bandwidth, computed_bandwidth)

    -- Set baseband filter bandwidth
    ret = libhackrf.hackrf_set_baseband_filter_bandwidth(self.dev[0], computed_bandwidth)
    if ret ~= 0 then
        error("hackrf_set_baseband_filter_bandwidth(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Set LNA gain
    ret = libhackrf.hackrf_set_lna_gain(self.dev[0], self.lna_gain)
    if ret ~= 0 then
        error("hackrf_set_lna_gain(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Set VGA gain
    ret = libhackrf.hackrf_set_vga_gain(self.dev[0], self.vga_gain)
    if ret ~= 0 then
        error("hackrf_set_vga_gain(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Set RF amplifier enable
    ret = libhackrf.hackrf_set_amp_enable(self.dev[0], self.rf_amplifier_enable)
    if ret ~= 0 then
        error("hackrf_set_amp_enable(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Set antenna power enable
    ret = libhackrf.hackrf_set_antenna_enable(self.dev[0], self.antenna_power_enable)
    if ret ~= 0 then
        error("hackrf_set_antenna_enable(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Set frequency
    ret = libhackrf.hackrf_set_freq(self.dev[0], self.frequency)
    if ret ~= 0 then
        error("hackrf_set_freq(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end
end

local function read_callback_factory(...)
    local ffi = require('ffi')
    local radio = require('radio')

    local fds = {...}

    local out = radio.types.ComplexFloat32.vector()

    local function read_callback(transfer)
        -- Resize output vector
        out:resize(transfer.valid_length/2)

        -- Convert complex s8 in buf to complex floats in output vector
        for i = 0, out.length-1 do
            out.data[i].real = ffi.cast("int8_t *", transfer.buffer)[2*i] * (1/127.5)
            out.data[i].imag = ffi.cast("int8_t *", transfer.buffer)[2*i+1] * (1/127.5)
        end

        -- Write to each output fd
        for i = 1, #fds do
            local total_bytes_written = 0
            while total_bytes_written < out.size do
                local bytes_written = tonumber(ffi.C.write(fds[i], ffi.cast("uint8_t *", out.data) + total_bytes_written, out.size - total_bytes_written))
                if bytes_written <= 0 then
                    error("write(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
                end

                total_bytes_written = total_bytes_written + bytes_written
            end
        end

        return 0
    end

    return ffi.cast('int (*)(hackrf_transfer *)', read_callback)
end

function HackRFSource:run()
    -- Initialize the hackrf in our own running process
    self:initialize_hackrf()

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
    local ret = libhackrf.hackrf_start_rx(self.dev[0], read_callback, nil)
    if ret ~= 0 then
        error("hackrf_start_rx(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Wait for SIGTERM
    local sig = ffi.new("int[1]")
    if ffi.C.sigwait(sigset, sig) ~= 0 then
        error("sigwait(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Stop receiving
    ret = libhackrf.hackrf_stop_rx(self.dev[0])
    if ret ~= 0 then
        error("hackrf_stop_rx(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Close hackrf
    ret = libhackrf.hackrf_close(self.dev[0])
    if ret ~= 0 then
        error("hackrf_close(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end
end

return HackRFSource
