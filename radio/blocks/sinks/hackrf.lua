---
-- Sink a complex-valued signal to a HackRF One. This sink requires the
-- libhackrf library.
--
-- @category Sinks
-- @block HackRFSink
-- @tparam number frequency Tuning frequency in Hz
-- @tparam[opt={}] table options Additional options, specifying:
--      * `vga_gain` (int in dB, default 0 dB, range 0 to 47 dB, 1 dB step)
--      * `bandwidth` (number in Hz, default round down from sample rate)
--      * `rf_amplifier_enable` (bool, default false)
--      * `antenna_power_enable` (bool, default false)
--
-- @signature in:ComplexFloat32 >
--
-- @usage
-- -- Sink samples to 146 MHz
-- local snk = radio.HackRFSink(146e6)
--
-- -- Sink samples to 433.92 MHz, with 1.75 MHz baseband bandwidth
-- local src = radio.HackRFSink(433.92e6, {bandwidth = 1.75e6})
--
-- -- Sink samples to 915 MHz, with 22 dB VGA gain
-- local src = radio.HackRFSink(915e6, {vga_gain = 22})
--
-- -- Sink samples to 144.390 MHz, with antenna power enabled
-- local src = radio.HackRFSink(144.390e6, {antenna_power_enable = true})

local ffi = require('ffi')

local block = require('radio.core.block')
local platform = require('radio.core.platform')
local debug = require('radio.core.debug')
local types = require('radio.types')
local async = require('radio.core.async')

local HackRFSink = block.factory("HackRFSink")

function HackRFSink:instantiate(frequency, options)
    self.frequency = assert(frequency, "Missing argument #1 (frequency)")

    self.options = options or {}
    self.vga_gain = self.options.vga_gain or 0
    self.bandwidth = self.options.bandwidth
    self.rf_amplifier_enable = self.options.rf_amplifier_enable or false
    self.antenna_power_enable = self.options.antenna_power_enable or false

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {})
end

if not package.loaded['radio.blocks.sources.hackrf'] then
    ffi.cdef[[
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

        const char* hackrf_error_name(int errcode);

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

function HackRFSink:initialize()
    -- Check library is available
    if not libhackrf_available then
        error("HackRFSink: libhackrf not found. Is libhackrf installed?")
    end
end

function HackRFSink:initialize_hackrf()
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

        debug.printf("[HackRFSink] Firmware version:  %s\n", firmware_version)
        debug.printf("[HackRFSink] Board ID:          %s\n", board_id)
    end

    -- Check sample rate
    if self:get_rate() < 8e6 then
        io.stderr:write(string.format("[HackRFSink] Warning: low sample rate (%u Hz).\n", self:get_rate()))
        io.stderr:write("[HackRFSink] Using a sample rate under 8 MHz is not recommended!\n")
    end

    -- Set sample rate
    ret = libhackrf.hackrf_set_sample_rate(self.dev[0], self:get_rate())
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
        computed_bandwidth = libhackrf.hackrf_compute_baseband_filter_bw_round_down_lt(self:get_rate())
    end

    debug.printf("[HackRFSink] Frequency: %u Hz, Sample rate: %u Hz\n", self.frequency, self:get_rate())
    debug.printf("[HackRFSink] Requested Bandwidth: %u Hz, Actual Bandwidth: %u Hz\n", self.bandwidth or computed_bandwidth, computed_bandwidth)

    -- Set baseband filter bandwidth
    ret = libhackrf.hackrf_set_baseband_filter_bandwidth(self.dev[0], computed_bandwidth)
    if ret ~= 0 then
        error("hackrf_set_baseband_filter_bandwidth(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Set TX VGA gain
    ret = libhackrf.hackrf_set_txvga_gain(self.dev[0], self.vga_gain)
    if ret ~= 0 then
        error("hackrf_set_txvga_gain(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
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

local function write_callback_factory(fd)
    local ffi = require('ffi')
    local radio = require('radio')

    local vec = radio.types.ComplexFloat32.vector()

    local function write_callback(transfer)
        -- Resize vector
        vec:resize(transfer.valid_length/2)

        -- Read fd into vector
        local total_bytes_read = 0
        while total_bytes_read < vec.size do
            local bytes_read = tonumber(ffi.C.read(fd, ffi.cast("uint8_t *", vec.data) + total_bytes_read, vec.size - total_bytes_read))
            if bytes_read < 0 then
                error("read(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            elseif bytes_read == 0 and total_bytes_read == 0 then
                -- EOF and no bytes read into vec
                return -1
            elseif bytes_read == 0 then
                -- Zero out remainder of vec
                ffi.fill(ffi.cast("uint8_t *", vec.data) + total_bytes_read, vec.size - total_bytes_read)
                break
            end
            total_bytes_read = total_bytes_read + bytes_read
        end

        -- Convert complex floats in vector to complex s8 in buffer
        for i = 0, vec.length-1 do
            ffi.cast("int8_t *", transfer.buffer)[2*i] = vec.data[i].real*127.5
            ffi.cast("int8_t *", transfer.buffer)[2*i+1] = vec.data[i].imag*127.5
        end

        return 0
    end

    return ffi.cast('int (*)(hackrf_transfer *)', write_callback)
end

function HackRFSink:run()
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

    -- Start transmitting
    local write_callback, write_callback_state = async.callback(write_callback_factory, self.inputs[1]:filenos()[1])
    local ret = libhackrf.hackrf_start_tx(self.dev[0], write_callback, nil)
    if ret ~= 0 then
        error("hackrf_start_tx(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- While it's still transmitting
    while libhackrf.hackrf_is_streaming(self.dev[0]) == 1 do
        ffi.C.usleep(500000)
    end

    -- Stop transmitting
    ret = libhackrf.hackrf_stop_tx(self.dev[0])
    if ret ~= 0 then
        error("hackrf_stop_tx(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end

    -- Close hackrf
    ret = libhackrf.hackrf_close(self.dev[0])
    if ret ~= 0 then
        error("hackrf_close(): " .. ffi.string(libhackrf.hackrf_error_name(ret)))
    end
end

return HackRFSink
