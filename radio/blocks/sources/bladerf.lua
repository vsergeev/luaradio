---
-- Source a complex-valued signal from a BladeRF. This source requires the
-- libbladeRF library.
--
-- @category Sources
-- @block BladeRFSource
-- @tparam number frequency Tuning frequency in Hz
-- @tparam number rate Sample rate in Hz
-- @tparam[opt={}] table options Additional options, specifying:
--      * `device_id` (string, default "")
--      * `channel` (int, default 0)
--      * `gain` (number in dB, manual gain, default nil)
--      * `bandwidth` (number in Hz, default 80% of sample rate)
--      * `autogain` (bool, default true if manual gain is nil)
--
-- @signature > out:ComplexFloat32
--
-- @usage
-- -- Source samples from a BladeRF at 91.1 MHz sampled at 2 MHz
-- local src = radio.BladeRFSource(91.1e6, 2e6)
--
-- -- Source samples from a BladeRF at 915 MHz sampled at 10 MHz, with 20 dB
-- -- overall gain
-- local src = radio.BladeRFSource(915e6, 10e6, {gain = 20})
--
-- -- Source samples from a BladeRF at 144.390 MHz sampled at 8 MHz, with
-- -- 2.5 MHz baseband bandwidth
-- local src = radio.BladeRFSource(144.390e6, 8e6, {bandwidth = 2.5e6})

local ffi = require('ffi')

local block = require('radio.core.block')
local debug = require('radio.core.debug')
local vector = require('radio.core.vector')
local types = require('radio.types')
local format_utils = require('radio.utilities.format_utils')

local BladeRFSource = block.factory("BladeRFSource")

function BladeRFSource:instantiate(frequency, rate, options)
    self.frequency = assert(frequency, "Missing argument #1 (frequency)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    self.options = options or {}
    self.device_id = self.options.device_id or ""
    self.channel = self.options.channel or 0
    self.gain = self.options.gain or nil
    self.bandwidth = self.options.bandwidth or (0.80 * rate)
    self.autogain = (self.gain == nil) and true or self.options.autogain

    self:add_type_signature({}, {block.Output("out", types.ComplexFloat32)})
end

function BladeRFSource:get_rate()
    return self.rate
end

if not package.loaded['radio.blocks.sinks.bladerf'] then
    ffi.cdef[[
        /************************************************************/
        /* Opaque handles */
        /************************************************************/

        struct bladerf;
        struct bladerf_stream;

        /************************************************************/
        /* Structures and enums */
        /************************************************************/

        typedef enum {
            BLADERF_BACKEND_ANY,         /**< "Don't Care" -- use any available
                                          *   backend */
            BLADERF_BACKEND_LINUX,       /**< Linux kernel driver */
            BLADERF_BACKEND_LIBUSB,      /**< libusb */
            BLADERF_BACKEND_CYPRESS,     /**< CyAPI */
            BLADERF_BACKEND_DUMMY = 100, /**< Dummy used for development purposes */
        } bladerf_backend;

        /** Length of device description string, including NUL-terminator */
        enum { BLADERF_DESCRIPTION_LENGTH = 33 };

        /** Length of device serial number string, including NUL-terminator */
        enum { BLADERF_SERIAL_LENGTH = 33 };

        struct bladerf_range {
            int64_t min;  /**< Minimum value */
            int64_t max;  /**< Maximum value */
            int64_t step; /**< Step of value */
            float scale;  /**< Unit scale */
        };

        struct bladerf_serial {
            char serial[BLADERF_SERIAL_LENGTH]; /**< Device serial number string */
        };

        struct bladerf_version {
            uint16_t major;       /**< Major version */
            uint16_t minor;       /**< Minor version */
            uint16_t patch;       /**< Patch version */
            const char *describe; /**< Version string with any additional suffix
                                   *   information.
                                   *
                                   *   @warning Do not attempt to modify or free()
                                   *            this string. */
        };

        typedef enum {
            BLADERF_DEVICE_SPEED_UNKNOWN,
            BLADERF_DEVICE_SPEED_HIGH,
            BLADERF_DEVICE_SPEED_SUPER
        } bladerf_dev_speed;

        /************************************************************/
        /* Functions */
        /************************************************************/

        int bladerf_open(struct bladerf **device, const char *device_identifier);
        void bladerf_close(struct bladerf *device);

        int bladerf_get_serial_struct(struct bladerf *dev, struct bladerf_serial *serial);
        int bladerf_fw_version(struct bladerf *dev, struct bladerf_version *version);
        int bladerf_is_fpga_configured(struct bladerf *dev);
        int bladerf_fpga_version(struct bladerf *dev, struct bladerf_version *version);
        bladerf_dev_speed bladerf_device_speed(struct bladerf *dev);
        const char *bladerf_get_board_name(struct bladerf *dev);

        /************************************************************/
        /* Structures and enums */
        /************************************************************/

        typedef int bladerf_channel;

        typedef enum {
            BLADERF_RX = 0, /**< Receive direction */
            BLADERF_TX = 1, /**< Transmit direction */
        } bladerf_direction;

        typedef enum {
            BLADERF_RX_X1 = 0, /**< x1 RX (SISO) */
            BLADERF_TX_X1 = 1, /**< x1 TX (SISO) */
            BLADERF_RX_X2 = 2, /**< x2 RX (MIMO) */
            BLADERF_TX_X2 = 3, /**< x2 TX (MIMO) */
        } bladerf_channel_layout;

        typedef enum {
            BLADERF_GAIN_DEFAULT,
            BLADERF_GAIN_MGC,
            BLADERF_GAIN_FASTATTACK_AGC,
            BLADERF_GAIN_SLOWATTACK_AGC,
            BLADERF_GAIN_HYBRID_AGC,
        } bladerf_gain_mode;

        typedef int bladerf_gain;

        typedef unsigned int bladerf_sample_rate;

        typedef unsigned int bladerf_bandwidth;

        typedef uint64_t bladerf_frequency;

        typedef enum {
            BLADERF_CORR_DCOFF_I,
            BLADERF_CORR_DCOFF_Q,
            BLADERF_CORR_PHASE,
            BLADERF_CORR_GAIN
        } bladerf_correction;

        typedef int16_t bladerf_correction_value;

        typedef uint64_t bladerf_timestamp;

        typedef enum {
            BLADERF_FORMAT_SC16_Q11,
            BLADERF_FORMAT_SC16_Q11_META,
        } bladerf_format;

        struct bladerf_metadata {
            bladerf_timestamp timestamp;
            uint32_t flags;
            uint32_t status;
            unsigned int actual_count;
            uint8_t reserved[32];
        };

        /************************************************************/
        /* Functions */
        /************************************************************/

        size_t bladerf_get_channel_count(struct bladerf *dev, bladerf_direction dir);

        int bladerf_set_gain_mode(struct bladerf *dev, bladerf_channel ch, bladerf_gain_mode mode);
        int bladerf_get_gain_mode(struct bladerf *dev, bladerf_channel ch, bladerf_gain_mode *mode);

        int bladerf_set_gain(struct bladerf *dev, bladerf_channel ch, bladerf_gain gain);
        int bladerf_get_gain(struct bladerf *dev, bladerf_channel ch, bladerf_gain *gain);
        int bladerf_get_gain_range(struct bladerf *dev, bladerf_channel ch, const struct bladerf_range **range);

        int bladerf_set_sample_rate(struct bladerf *dev, bladerf_channel ch, bladerf_sample_rate rate, bladerf_sample_rate *actual);
        int bladerf_get_sample_rate(struct bladerf *dev, bladerf_channel ch, bladerf_sample_rate *rate);
        int bladerf_get_sample_rate_range(struct bladerf *dev, bladerf_channel ch, const struct bladerf_range **range);

        int bladerf_set_bandwidth(struct bladerf *dev, bladerf_channel ch, bladerf_bandwidth bandwidth, bladerf_bandwidth *actual);
        int bladerf_get_bandwidth(struct bladerf *dev, bladerf_channel ch, bladerf_bandwidth *bandwidth);
        int bladerf_get_bandwidth_range(struct bladerf *dev, bladerf_channel ch, const struct bladerf_range **range);

        int bladerf_set_frequency(struct bladerf *dev, bladerf_channel ch, bladerf_frequency frequency);
        int bladerf_get_frequency(struct bladerf *dev, bladerf_channel ch, bladerf_frequency *frequency);
        int bladerf_get_frequency_range(struct bladerf *dev, bladerf_channel ch, const struct bladerf_range **range);

        int bladerf_set_correction(struct bladerf *dev, bladerf_channel ch, bladerf_correction corr, bladerf_correction_value value);
        int bladerf_get_correction(struct bladerf *dev, bladerf_channel ch, bladerf_correction corr, bladerf_correction_value *value);

        int bladerf_interleave_stream_buffer(bladerf_channel_layout layout, bladerf_format format, unsigned int buffer_size, void *samples);
        int bladerf_deinterleave_stream_buffer(bladerf_channel_layout layout, bladerf_format format, unsigned int buffer_size, void *samples);

        int bladerf_sync_config(struct bladerf *dev, bladerf_channel_layout layout, bladerf_format format, unsigned int num_buffers,
                                unsigned int buffer_size, unsigned int num_transfers, unsigned int stream_timeout);

        int bladerf_enable_module(struct bladerf *dev, bladerf_channel ch, bool enable);

        int bladerf_sync_rx(struct bladerf *dev, void *samples, unsigned int num_samples, struct bladerf_metadata *metadata, unsigned int timeout_ms);
        int bladerf_sync_tx(struct bladerf *dev, const void *samples, unsigned int num_samples, struct bladerf_metadata *metadata, unsigned int timeout_ms);

        void bladerf_version(struct bladerf_version *version);
        const char *bladerf_strerror(int error);
    ]]
end
local libbladerf_available, libbladerf = pcall(ffi.load, "libbladeRF")

function BladeRFSource:initialize()
    -- Check library is available
    if not libbladerf_available then
        error("BladeRFSource: libbladeRF not found. Is libbladeRF installed?")
    end

    -- Create sample buffers
    self.format = format_utils.formats.s16le
    self.raw_samples = vector.Vector(self.format.complex_ctype, 8192)
    self.out = types.ComplexFloat32.vector(self.raw_samples.length)
end

function BladeRFSource:initialize_bladerf()
    local ret

    -- Create handle
    self.dev = ffi.new("struct bladerf *[1]")
    ret = libbladerf.bladerf_open(self.dev, self.device_id)
    if ret ~= 0 then
        error("bladerf_open(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
    end

    -- (Debug) Dump version info
    if debug.enabled then
        local serial = ffi.new("struct bladerf_serial")
        ret = libbladerf.bladerf_get_serial_struct(self.dev[0], serial)
        if ret ~= 0 then
            error("bladerf_get_serial_struct(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
        end

        local lib_version = ffi.new("struct bladerf_version")
        libbladerf.bladerf_version(lib_version)

        local fw_version = ffi.new("struct bladerf_version")
        ret = libbladerf.bladerf_fw_version(self.dev[0], fw_version)
        if ret ~= 0 then
            error("bladerf_fw_version(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
        end

        local fpga_configured = libbladerf.bladerf_is_fpga_configured(self.dev[0])
        if fpga_configured < 0 then
            error("bladerf_is_fpga_configured(): " .. ffi.string(libbladerf.bladerf_strerror(fpga_configured)))
        end

        local fpga_version = nil
        if fpga_configured == 1 then
            fpga_version = ffi.new("struct bladerf_version")
            ret = libbladerf.bladerf_fpga_version(self.dev[0], fpga_version)
            if ret ~= 0 then
                error("bladerf_fpga_version(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
            end
        end

        local device_speed = libbladerf.bladerf_device_speed(self.dev[0])
        local board_name = ffi.string(libbladerf.bladerf_get_board_name(self.dev[0]))

        debug.printf("[BladeRFSource] Board Name:       %s\n", board_name)
        debug.printf("[BladeRFSource] Library version:  %s\n", ffi.string(lib_version.describe))
        debug.printf("[BladeRFSource] Firmware version: %s\n", ffi.string(fw_version.describe))
        debug.printf("[BladeRFSource] FPGA version:     %s\n", fpga_configured == 1 and ffi.string(fpga_version.describe) or "Not configured")
        debug.printf("[BladeRFSource] Serial:           %s\n", ffi.string(serial.serial))
        debug.printf("[BladeRFSource] Bus Speed:        %s\n", (device_speed == ffi.C.BLADERF_DEVICE_SPEED_SUPER) and "Super" or
                                                           (device_speed == ffi.C.BLADERF_DEVICE_SPEED_HIGH) and "High" or "Unknown")
    end

    local channel = bit.band(bit.lshift(self.channel, 1), ffi.C.BLADERF_RX)

    -- Set frequency
    ret = libbladerf.bladerf_set_frequency(self.dev[0], channel, self.frequency)
    if ret ~= 0 then
        error("bladerf_set_frequency(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
    end

    -- Get the actual frequency
    local actual_frequency = ffi.new("bladerf_frequency [1]")
    ret = libbladerf.bladerf_get_frequency(self.dev[0], channel, actual_frequency)
    if ret ~= 0 then
        error("bladerf_get_frequency(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
    end

    -- (Debug) Report actual frequency
    if debug.enabled then
        debug.printf("[BladeRFSource] Requested frequency: %u Hz, Actual frequency: %u Hz\n", self.frequency, tonumber(actual_frequency[0]))
   end

    -- Check frequency did not get clamped
    if math.abs(self.frequency - tonumber(actual_frequency[0])) > 100 then
        error(string.format("Error setting frequency: requested %u Hz, got %u Hz", self.frequency, tonumber(actual_frequency[0])))
    end

    -- Set rate
    local actual_rate = ffi.new("bladerf_sample_rate [1]")
    ret = libbladerf.bladerf_set_sample_rate(self.dev[0], channel, self.rate, actual_rate)
    if ret ~= 0 then
        error("bladerf_set_sample_rate(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
    end

    -- (Debug) Report actual rate
    if debug.enabled then
        debug.printf("[BladeRFSource] Requested rate: %u Hz, Actual rate: %u Hz\n", self.rate, actual_rate[0])
    end

    -- Check sample rate did not get clamped
    if math.abs(self.rate - actual_rate[0]) > 100 then
        error(string.format("Error setting sample rate: requested %u Hz, got %u Hz", self.rate, actual_rate[0]))
    end

    -- Set bandwidth
    local actual_bandwidth = ffi.new("bladerf_bandwidth [1]")
    ret = libbladerf.bladerf_set_bandwidth(self.dev[0], channel, self.bandwidth, actual_bandwidth)
    if ret ~= 0 then
        error("bladerf_set_bandwidth(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
    end

    -- (Debug) Report actual bandwidth
    if debug.enabled then
        debug.printf("[BladeRFSource] Requested bandwidth: %u Hz, Actual bandwidth: %u Hz\n", self.bandwidth, actual_bandwidth[0])
    end

    -- Check bandwidth is less than sample rate
    if actual_bandwidth[0] > actual_rate[0] then
        error(string.format("Error setting bandwidth: requested %u Hz, got %u Hz, exceeds sample rate %u Hz", self.bandwidth, actual_bandwidth[0], actual_rate[0]))
    end

    if self.autogain then
        -- Enable AGC
        ret = libbladerf.bladerf_set_gain_mode(self.dev[0], channel, ffi.C.BLADERF_GAIN_DEFAULT)
        if ret ~= 0 then
            error("bladerf_set_gain_mode(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
        end
    else
        -- Set manual gain
        ret = libbladerf.bladerf_set_gain_mode(self.dev[0], channel, ffi.C.BLADERF_GAIN_MGC)

        ret = libbladerf.bladerf_set_gain(self.dev[0], channel, self.gain)
        if ret ~= 0 then
            error("bladerf_set_gain(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
        end

        -- (Debug) Report actual gain
        if debug.enabled then
            local actual_gain = ffi.new("bladerf_gain [1]")
            ret = libbladerf.bladerf_get_gain(self.dev[0], channel, actual_gain)
            if ret ~= 0 then
                error("bladerf_set_gain(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
            end

            debug.printf("[BladeRFSource] Requested gain: %u dB, Actual gain: %u dB\n", self.gain, actual_gain[0])
        end
    end

    -- Configure for synchronous reception
    local num_buffers = 16
    local buffer_size = 8192
    local num_transfers = 8
    local stream_timeout = 2500
    ret = libbladerf.bladerf_sync_config(self.dev[0], ffi.C.BLADERF_RX_X1, ffi.C.BLADERF_FORMAT_SC16_Q11, num_buffers, buffer_size, num_transfers, stream_timeout)
    if ret ~= 0 then
        error("bladerf_sync_config(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
    end

    -- Enable RX
    ret = libbladerf.bladerf_enable_module(self.dev[0], channel, true)
    if ret ~= 0 then
        error("bladerf_enable_module(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
    end

    -- Mark ourselves initialized
    self.initialized = true
end

function BladeRFSource:process()
    if not self.initialized then
        -- Initialize the BladeRF in our own running process
        self:initialize_bladerf()
    end

    -- Receive samples
    local ret = libbladerf.bladerf_sync_rx(self.dev[0], self.raw_samples.data, self.raw_samples.length, nil, 5000)
    if ret ~= 0 then
        error("bladerf_sync_rx(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
    end

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, self.raw_samples.length-1 do
            format_utils.swap_bytes(self.raw_samples.data[i].real)
            format_utils.swap_bytes(self.raw_samples.data[i].imag)
        end
    end

    -- Convert signed complex l2-bit samples to ComplexFloat32s
    for i=0, self.out.length-1 do
        self.out.data[i].real = self.raw_samples.data[i].real.value / 2047.5
        self.out.data[i].imag = self.raw_samples.data[i].imag.value / 2047.5
    end

    return self.out
end

function BladeRFSource:cleanup()
    local channel = bit.band(bit.lshift(self.channel, 1), ffi.C.BLADERF_RX)

    -- Disable RX
    local ret = libbladerf.bladerf_enable_module(self.dev[0], channel, false)
    if ret ~= 0 then
        error("bladerf_enable_module(): " .. ffi.string(libbladerf.bladerf_strerror(ret)))
    end

    -- Close device
    libbladerf.bladerf_close(self.dev[0])
end

return BladeRFSource
