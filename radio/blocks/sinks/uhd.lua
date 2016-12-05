---
-- Sink a complex-valued signal to a USRP. This sink requires the libuhd
-- library.
--
-- @category Sinks
-- @block UHDSink
-- @tparam string device_address Device address string
-- @tparam number frequency Tuning frequency in Hz
-- @tparam[opt={}] table options Additional options, specifying:
--      * `channel` (int, default 0)
--      * `gain` (number in dB, overall gain, default 0.0 dB)
--      * `bandwidth` (number in Hz)
--      * `antenna` (string)
--      * `gains` (table, gain element name to value in dB)
--
-- @signature in:ComplexFloat32 >
--
-- @usage
-- -- Sink samples to a B200 at 433.92 MHz
-- local snk = radio.UHDSink("type=b200", 433.92e6)
--
-- -- Sink samples to a B200 at 915 MHz, with 10 dB overall gain and 5 MHz baseband bandwidth
-- local snk = radio.UHDSink("type=b200", 915e6, {gain = 10, bandwidth = 5e6})

local ffi = require('ffi')

local block = require('radio.core.block')
local debug = require('radio.core.debug')
local types = require('radio.types')

local UHDSink = block.factory("UHDSink")

function UHDSink:instantiate(device_address, frequency, options)
    self.device_address = assert(device_address, "Missing argument #1 (device_address)")
    self.frequency = assert(frequency, "Missing argument #1 (frequency)")

    assert(type(device_address) == "string", "Invalid argument #1 (device_address), should be string.")

    self.options = options or {}
    self.channel = self.options.channel or 0
    self.gain = self.options.gain or 0.0
    self.bandwidth = self.options.bandwidth
    self.antenna = self.options.antenna
    self.gains = self.options.gains

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {})
end

if not package.loaded['radio.blocks.sources.uhd'] then
	ffi.cdef[[
	    /* Opaque handles */
	    typedef struct uhd_usrp* uhd_usrp_handle;
	    typedef struct uhd_rx_streamer* uhd_rx_streamer_handle;
	    typedef struct uhd_tx_streamer* uhd_tx_streamer_handle;
	    typedef struct uhd_rx_metadata_t* uhd_rx_metadata_handle;
	    typedef struct uhd_tx_metadata_t* uhd_tx_metadata_handle;

	    /* Structures and enums */
	    typedef enum {
	        UHD_TUNE_REQUEST_POLICY_NONE   = 78,
	        UHD_TUNE_REQUEST_POLICY_AUTO   = 65,
	        UHD_TUNE_REQUEST_POLICY_MANUAL = 77
	    } uhd_tune_request_policy_t;

	    typedef struct {
	        double target_freq;
	        uhd_tune_request_policy_t rf_freq_policy;
	        double rf_freq;
	        uhd_tune_request_policy_t dsp_freq_policy;
	        double dsp_freq;
	        char* args;
	    } uhd_tune_request_t;

	    typedef struct {
	        double clipped_rf_freq;
	        double target_rf_freq;
	        double actual_rf_freq;
	        double target_dsp_freq;
	        double actual_dsp_freq;
	    } uhd_tune_result_t;

	    typedef struct {
	        char* cpu_format;
	        char* otw_format;
	        char* args;
	        size_t* channel_list;
	        int n_channels;
	    } uhd_stream_args_t;

	    typedef enum {
	        UHD_STREAM_MODE_START_CONTINUOUS   = 97,
	        UHD_STREAM_MODE_STOP_CONTINUOUS    = 111,
	        UHD_STREAM_MODE_NUM_SAMPS_AND_DONE = 100,
	        UHD_STREAM_MODE_NUM_SAMPS_AND_MORE = 109
	    } uhd_stream_mode_t;

	    typedef struct {
	        uhd_stream_mode_t stream_mode;
	        size_t num_samps;
	        bool stream_now;
	        time_t time_spec_full_secs;
	        double time_spec_frac_secs;
	    } uhd_stream_cmd_t;

	    typedef enum {
	        UHD_RX_METADATA_ERROR_CODE_NONE         = 0x0,
	        UHD_RX_METADATA_ERROR_CODE_TIMEOUT      = 0x1,
	        UHD_RX_METADATA_ERROR_CODE_LATE_COMMAND = 0x2,
	        UHD_RX_METADATA_ERROR_CODE_BROKEN_CHAIN = 0x4,
	        UHD_RX_METADATA_ERROR_CODE_OVERFLOW     = 0x8,
	        UHD_RX_METADATA_ERROR_CODE_ALIGNMENT    = 0xC,
	        UHD_RX_METADATA_ERROR_CODE_BAD_PACKET   = 0xF
	    } uhd_rx_metadata_error_code_t;

	    typedef enum {
	        UHD_ERROR_NONE = 0,
	        UHD_ERROR_INVALID_DEVICE = 1,
	        UHD_ERROR_INDEX = 10,
	        UHD_ERROR_KEY = 11,
	        UHD_ERROR_NOT_IMPLEMENTED = 20,
	        UHD_ERROR_USB = 21,
	        UHD_ERROR_IO = 30,
	        UHD_ERROR_OS = 31,
	        UHD_ERROR_ASSERTION = 40,
	        UHD_ERROR_LOOKUP = 41,
	        UHD_ERROR_TYPE = 42,
	        UHD_ERROR_VALUE = 43,
	        UHD_ERROR_RUNTIME = 44,
	        UHD_ERROR_ENVIRONMENT = 45,
	        UHD_ERROR_SYSTEM = 46,
	        UHD_ERROR_EXCEPT = 47,
	        UHD_ERROR_BOOSTEXCEPT = 60,
	        UHD_ERROR_STDEXCEPT = 70,
	        UHD_ERROR_UNKNOWN = 100
	    } uhd_error;

	    struct uhd_meta_range_t;
	    typedef struct uhd_meta_range_t* uhd_meta_range_handle;

	    struct uhd_string_vector_t;
	    typedef struct uhd_string_vector_t* uhd_string_vector_handle;

	    /* Functions */
	    uhd_error uhd_usrp_make(uhd_usrp_handle *h, const char *args);
	    uhd_error uhd_usrp_free(uhd_usrp_handle *h);

	    uhd_error uhd_rx_streamer_make(uhd_rx_streamer_handle *h);
	    uhd_error uhd_rx_streamer_free(uhd_rx_streamer_handle *h);
	    uhd_error uhd_tx_streamer_make(uhd_tx_streamer_handle *h);
	    uhd_error uhd_tx_streamer_free(uhd_tx_streamer_handle *h);

	    uhd_error uhd_rx_metadata_make(uhd_rx_metadata_handle* handle);
	    uhd_error uhd_rx_metadata_free(uhd_rx_metadata_handle* handle);
		uhd_error uhd_tx_metadata_make(uhd_tx_metadata_handle* handle, bool has_time_spec, time_t full_secs, double frac_secs, bool start_of_burst, bool end_of_burst);
	    uhd_error uhd_tx_metadata_free(uhd_tx_metadata_handle* handle);

	    uhd_error uhd_meta_range_make(uhd_meta_range_handle* h);
	    uhd_error uhd_meta_range_free(uhd_meta_range_handle* h);

	    uhd_error uhd_string_vector_make(uhd_string_vector_handle *h);
	    uhd_error uhd_string_vector_free(uhd_string_vector_handle *h);

	    uhd_error uhd_usrp_get_rx_num_channels(uhd_usrp_handle h, size_t *num_channels_out);
	    uhd_error uhd_usrp_get_tx_num_channels(uhd_usrp_handle h, size_t *num_channels_out);
	    uhd_error uhd_usrp_set_rx_antenna(uhd_usrp_handle h, const char* ant, size_t chan);
	    uhd_error uhd_usrp_set_tx_antenna(uhd_usrp_handle h, const char* ant, size_t chan);
	    uhd_error uhd_usrp_get_rx_antennas(uhd_usrp_handle h, size_t chan, uhd_string_vector_handle *antennas_out);
	    uhd_error uhd_usrp_get_tx_antennas(uhd_usrp_handle h, size_t chan, uhd_string_vector_handle *antennas_out);
	    uhd_error uhd_usrp_get_rx_rates(uhd_usrp_handle h, size_t chan, uhd_meta_range_handle rates_out);
	    uhd_error uhd_usrp_get_tx_rates(uhd_usrp_handle h, size_t chan, uhd_meta_range_handle rates_out);
	    uhd_error uhd_usrp_set_rx_rate(uhd_usrp_handle h, double rate, size_t chan);
	    uhd_error uhd_usrp_set_tx_rate(uhd_usrp_handle h, double rate, size_t chan);
	    uhd_error uhd_usrp_get_rx_rate(uhd_usrp_handle h, size_t chan, double *rate_out);
	    uhd_error uhd_usrp_get_tx_rate(uhd_usrp_handle h, size_t chan, double *rate_out);
	    uhd_error uhd_usrp_set_rx_bandwidth(uhd_usrp_handle h, double bandwidth, size_t chan);
	    uhd_error uhd_usrp_set_tx_bandwidth(uhd_usrp_handle h, double bandwidth, size_t chan);
	    uhd_error uhd_usrp_get_rx_bandwidth(uhd_usrp_handle h, size_t chan, double *bandwidth_out);
	    uhd_error uhd_usrp_get_tx_bandwidth(uhd_usrp_handle h, size_t chan, double *bandwidth_out);
	    uhd_error uhd_usrp_get_rx_bandwidth_range(uhd_usrp_handle h, size_t chan, uhd_meta_range_handle bandwidth_range_out);
	    uhd_error uhd_usrp_get_tx_bandwidth_range(uhd_usrp_handle h, size_t chan, uhd_meta_range_handle bandwidth_range_out);
	    uhd_error uhd_usrp_set_rx_agc(uhd_usrp_handle h, bool enable, size_t chan);
	    uhd_error uhd_usrp_set_rx_gain(uhd_usrp_handle h, double gain, size_t chan, const char *gain_name);
	    uhd_error uhd_usrp_set_tx_gain(uhd_usrp_handle h, double gain, size_t chan, const char *gain_name);
	    uhd_error uhd_usrp_get_rx_gain(uhd_usrp_handle h, size_t chan, const char *gain_name, double *gain_out);
	    uhd_error uhd_usrp_get_tx_gain(uhd_usrp_handle h, size_t chan, const char *gain_name, double *gain_out);
	    uhd_error uhd_usrp_get_rx_gain_range(uhd_usrp_handle h, const char* name, size_t chan, uhd_meta_range_handle gain_range_out);
	    uhd_error uhd_usrp_get_tx_gain_range(uhd_usrp_handle h, const char* name, size_t chan, uhd_meta_range_handle gain_range_out);
	    uhd_error uhd_usrp_get_rx_gain_names(uhd_usrp_handle h, size_t chan, uhd_string_vector_handle *gain_names_out);
	    uhd_error uhd_usrp_get_tx_gain_names(uhd_usrp_handle h, size_t chan, uhd_string_vector_handle *gain_names_out);
	    uhd_error uhd_usrp_get_rx_freq_range(uhd_usrp_handle h, size_t chan, uhd_meta_range_handle freq_range_out);
	    uhd_error uhd_usrp_get_tx_freq_range(uhd_usrp_handle h, size_t chan, uhd_meta_range_handle freq_range_out);
	    uhd_error uhd_usrp_set_rx_freq(uhd_usrp_handle h, uhd_tune_request_t *tune_request, size_t chan, uhd_tune_result_t *tune_result);
	    uhd_error uhd_usrp_set_tx_freq(uhd_usrp_handle h, uhd_tune_request_t *tune_request, size_t chan, uhd_tune_result_t *tune_result);
	    uhd_error uhd_usrp_get_rx_freq(uhd_usrp_handle h, size_t chan, double *freq_out);
	    uhd_error uhd_usrp_get_tx_freq(uhd_usrp_handle h, size_t chan, double *freq_out);

	    uhd_error uhd_usrp_get_rx_stream(uhd_usrp_handle h, uhd_stream_args_t *stream_args, uhd_rx_streamer_handle h_out);
	    uhd_error uhd_usrp_get_tx_stream(uhd_usrp_handle h, uhd_stream_args_t *stream_args, uhd_tx_streamer_handle h_out);
	    uhd_error uhd_rx_streamer_max_num_samps(uhd_rx_streamer_handle h, size_t *max_num_samps_out);
	    uhd_error uhd_tx_streamer_max_num_samps(uhd_tx_streamer_handle h, size_t *max_num_samps_out);
	    uhd_error uhd_rx_streamer_issue_stream_cmd(uhd_rx_streamer_handle h, const uhd_stream_cmd_t *stream_cmd);

	    uhd_error uhd_rx_metadata_error_code(uhd_rx_metadata_handle h, uhd_rx_metadata_error_code_t *error_code_out);
	    uhd_error uhd_rx_metadata_strerror(uhd_rx_metadata_handle h, char* strerror_out, size_t strbuffer_len);

	    uhd_error uhd_usrp_last_error(uhd_usrp_handle h, char* error_out, size_t strbuffer_len);
	    uhd_error uhd_rx_streamer_last_error(uhd_rx_streamer_handle h, char* error_out, size_t strbuffer_len);
	    uhd_error uhd_tx_streamer_last_error(uhd_tx_streamer_handle h, char* error_out, size_t strbuffer_len);

	    uhd_error uhd_meta_range_to_pp_string(uhd_meta_range_handle h, char* pp_string_out, size_t strbuffer_len);
	    uhd_error uhd_meta_range_start(uhd_meta_range_handle h, double *start_out);
	    uhd_error uhd_meta_range_stop(uhd_meta_range_handle h, double *stop_out);
	    uhd_error uhd_meta_range_step(uhd_meta_range_handle h, double *step_out);

	    uhd_error uhd_string_vector_at(uhd_string_vector_handle h, size_t index, char* value_out, size_t strbuffer_len);
	    uhd_error uhd_string_vector_size(uhd_string_vector_handle h, size_t *size_out);

	    uhd_error uhd_rx_streamer_recv(uhd_rx_streamer_handle h, void** buffs, size_t samps_per_buff, uhd_rx_metadata_handle *md, double timeout, bool one_packet, size_t *items_recvd);
	    uhd_error uhd_tx_streamer_send(uhd_tx_streamer_handle h, const void **buffs, size_t samps_per_buff, uhd_tx_metadata_handle *md, double timeout, size_t *items_sent);
	]]
end
local libuhd_available, libuhd

function UHDSink:initialize()
    -- Load UHD library here, because it writes some version information to
    -- stdout
    libuhd_available, libuhd = pcall(ffi.load, "libuhd")

    -- Check library is available
    if not libuhd_available then
        error("UHDSink: libuhd not found. Is libuhd installed?")
    end
end

local function uhd_code_strerror(code)
    local uhd_error_codes = {
        [ffi.C.UHD_ERROR_NONE] = "UHD_ERROR_NONE",
        [ffi.C.UHD_ERROR_INVALID_DEVICE] = "UHD_ERROR_INVALID_DEVICE",
        [ffi.C.UHD_ERROR_INDEX] = "UHD_ERROR_INDEX",
        [ffi.C.UHD_ERROR_KEY] = "UHD_ERROR_KEY",
        [ffi.C.UHD_ERROR_NOT_IMPLEMENTED] = "UHD_ERROR_NOT_IMPLEMENTED",
        [ffi.C.UHD_ERROR_USB] = "UHD_ERROR_USB",
        [ffi.C.UHD_ERROR_IO] = "UHD_ERROR_IO",
        [ffi.C.UHD_ERROR_OS] = "UHD_ERROR_OS",
        [ffi.C.UHD_ERROR_ASSERTION] = "UHD_ERROR_ASSERTION",
        [ffi.C.UHD_ERROR_LOOKUP] = "UHD_ERROR_LOOKUP",
        [ffi.C.UHD_ERROR_TYPE] = "UHD_ERROR_TYPE",
        [ffi.C.UHD_ERROR_VALUE] = "UHD_ERROR_VALUE",
        [ffi.C.UHD_ERROR_RUNTIME] = "UHD_ERROR_RUNTIME",
        [ffi.C.UHD_ERROR_ENVIRONMENT] = "UHD_ERROR_ENVIRONMENT",
        [ffi.C.UHD_ERROR_SYSTEM] = "UHD_ERROR_SYSTEM",
        [ffi.C.UHD_ERROR_EXCEPT] = "UHD_ERROR_EXCEPT",
        [ffi.C.UHD_ERROR_BOOSTEXCEPT] = "UHD_ERROR_BOOSTEXCEPT",
        [ffi.C.UHD_ERROR_STDEXCEPT] = "UHD_ERROR_STDEXCEPT",
        [ffi.C.UHD_ERROR_UNKNOWN] = "UHD_ERROR_UNKNOWN",
    }
    return uhd_error_codes[tonumber(code)] or "Unknown"
end

local function uhd_last_strerror(usrp_handle)
    local errmsg = ffi.new("char[512]")
    ffi.C.uhd_usrp_last_error(usrp_handle, errmsg, ffi.sizeof(errmsg))
    return ffi.string(errmsg)
end

local function tx_streamer_last_strerror(tx_streamer_handle)
    local errmsg = ffi.new("char[512]")
    ffi.C.uhd_tx_streamer_last_error(tx_streamer_handle, errmsg, ffi.sizeof(errmsg))
    return ffi.string(errmsg)
end

function UHDSink:debug_dump_usrp(usrp_handle)
    local ret

    -- Number of channels
    local num_channels = ffi.new("size_t[1]")
    ret = libuhd.uhd_usrp_get_tx_num_channels(usrp_handle, num_channels)
    if ret ~= 0 then
        error("uhd_usrp_get_tx_num_channels(): " .. uhd_last_strerror(usrp_handle))
    end
    debug.printf("[UHDSink] Number of TX channels: %u\n", tonumber(num_channels[0]))

    -- Helper functions to construct and access metarange objects
    local function uhd_meta_range_new()
        local meta_range_handle = ffi.new("uhd_meta_range_handle[1]")
        local ret = libuhd.uhd_meta_range_make(meta_range_handle)
        if ret ~= 0 then
            error("uhd_meta_range_make(): " .. uhd_code_strerror(ret))
        end
        meta_range_handle = ffi.gc(meta_range_handle, libuhd.uhd_meta_range_free)
        return meta_range_handle
    end

    local function uhd_meta_range_start(meta_range_handle)
        local value = ffi.new("double[1]")
        local ret = libuhd.uhd_meta_range_start(meta_range_handle, value)
        if ret ~= 0 then
            error("uhd_meta_range_start(): " .. uhd_code_strerror(ret))
        end
        return value[0]
    end

    local function uhd_meta_range_stop(meta_range_handle)
        local value = ffi.new("double[1]")
        local ret = libuhd.uhd_meta_range_stop(meta_range_handle, value)
        if ret ~= 0 then
            error("uhd_meta_range_stop(): " .. uhd_code_strerror(ret))
        end
        return value[0]
    end

    local function uhd_string_vector_new()
        local string_vector_handle = ffi.new("uhd_string_vector_handle[1]")
        local ret = libuhd.uhd_string_vector_make(string_vector_handle)
        if ret ~= 0 then
            error("uhd_string_vector_make(): " .. uhd_code_strerror(ret))
        end
        string_vector_handle = ffi.gc(string_vector_handle, libuhd.uhd_string_vector_free)
        return string_vector_handle
    end

    local function uhd_string_vector_to_array(string_vector_handle)
        local length = ffi.new("size_t[1]")
        local ret = libuhd.uhd_string_vector_size(string_vector_handle, length)
        if ret ~= 0 then
            error("uhd_string_vector_make(): " .. uhd_code_strerror(ret))
        end

        local strings = {}
        for i = 0, tonumber(length[0])-1 do
            local s = ffi.new("char[128]")
            ret = libuhd.uhd_string_vector_at(string_vector_handle, i, s, ffi.sizeof(s))
            if ret ~= 0 then
                error("uhd_string_vector_at(): " .. uhd_code_strerror(ret))
            end
            strings[i+1] = ffi.string(s)
        end

        return strings
    end

    for channel=0, tonumber(num_channels[0])-1 do
        debug.printf("[UHDSink] TX Channel %d\n", channel)

        -- Supported sample rates
        local rates_range = uhd_meta_range_new()
        ret = libuhd.uhd_usrp_get_tx_rates(usrp_handle, channel, rates_range[0])
        if ret ~= 0 then
            error("uhd_usrp_get_tx_rates(): " .. uhd_last_strerror(usrp_handle))
        end
        debug.printf("[UHDSink]     Sample rate:      %f - %f Hz\n", uhd_meta_range_start(rates_range[0]), uhd_meta_range_stop(rates_range[0]))

        -- Center frequency range
        local freq_range = uhd_meta_range_new()
        ret = libuhd.uhd_usrp_get_tx_freq_range(usrp_handle, channel, freq_range[0])
        if ret ~= 0 then
            error("uhd_usrp_get_tx_freq_range(): " .. uhd_last_strerror(usrp_handle))
        end
        debug.printf("[UHDSink]     Center frequency: %f - %f Hz\n", uhd_meta_range_start(freq_range[0]), uhd_meta_range_stop(freq_range[0]))

        -- Bandwidth ranges
        local bandwidth_range = uhd_meta_range_new()
        ret = libuhd.uhd_usrp_get_tx_bandwidth_range(usrp_handle, channel, bandwidth_range[0])
        if ret ~= 0 then
            error("uhd_usrp_get_tx_bandwidth_range(): " .. uhd_last_strerror(usrp_handle))
        end
        debug.printf("[UHDSink]     Bandwidth:        %f - %f Hz\n", uhd_meta_range_start(bandwidth_range[0]), uhd_meta_range_stop(bandwidth_range[0]))

        -- Overall gain range
        local gain_range = uhd_meta_range_new()
        ret = libuhd.uhd_usrp_get_tx_gain_range(usrp_handle, "", channel, gain_range[0])
        if ret ~= 0 then
            error("uhd_usrp_get_tx_gain_range(): " .. uhd_last_strerror(usrp_handle))
        end
        debug.printf("[UHDSink]     Overall gain:     %f - %f dB\n", uhd_meta_range_start(gain_range[0]), uhd_meta_range_stop(gain_range[0]))

        -- Gain element ranges
        debug.printf("[UHDSink]     Gain elements:\n")
        local gain_names_vector = uhd_string_vector_new()
        ret = libuhd.uhd_usrp_get_tx_gain_names(usrp_handle, channel, gain_names_vector)
        if ret ~= 0 then
            error("uhd_usrp_get_tx_gain_names(): " .. uhd_last_strerror(usrp_handle))
        end

        local gain_names = uhd_string_vector_to_array(gain_names_vector[0])
        for _, gain_name in ipairs(gain_names) do
            local gain_range = uhd_meta_range_new()
            ret = libuhd.uhd_usrp_get_tx_gain_range(usrp_handle, gain_name, channel, gain_range[0])
            if ret ~= 0 then
                error("uhd_usrp_get_tx_gain_range(): " .. uhd_last_strerror(usrp_handle))
            end
            debug.printf("[UHDSink]         %-8s      %f - %f dB\n", gain_name, uhd_meta_range_start(gain_range[0]), uhd_meta_range_stop(gain_range[0]))
        end

        -- Antennas
        debug.printf("[UHDSink]     Antennas:\n")
        local antennas_vector = uhd_string_vector_new()
        ret = libuhd.uhd_usrp_get_tx_antennas(usrp_handle, channel, antennas_vector)
        if ret ~= 0 then
            error("uhd_usrp_get_tx_antennas(): " .. uhd_last_strerror(usrp_handle))
        end

        local antennas = uhd_string_vector_to_array(antennas_vector[0])
        for _, antenna in ipairs(antennas) do
            debug.printf("[UHDSink]         %s\n", antenna)
        end
    end
end

function UHDSink:initialize_uhd()
    local ret

    -- Dump version info
    if debug.enabled then
        -- FIXME UHD is missing C API for getting UHD version and ABI string
    end

    -- Create USRP handle
    self.usrp_handle = ffi.new("uhd_usrp_handle[1]")
    ret = libuhd.uhd_usrp_make(self.usrp_handle, self.device_address)
    if ret ~= 0 then
        error("uhd_usrp_make(): " .. uhd_code_strerror(ret))
    end
    self.usrp_handle = ffi.gc(self.usrp_handle, libuhd.uhd_usrp_free)

    -- Create TX streamer handle
    self.tx_streamer_handle = ffi.new("uhd_tx_streamer_handle[1]")
    ret = libuhd.uhd_tx_streamer_make(self.tx_streamer_handle)
    if ret ~= 0 then
        error("uhd_tx_streamer_make(): " .. uhd_code_strerror(ret))
    end
    self.tx_streamer_handle = ffi.gc(self.tx_streamer_handle, libuhd.uhd_tx_streamer_free)

    -- Create TX metadata handle
    self.tx_metadata_handle = ffi.new("uhd_tx_metadata_handle[1]")
    ret = libuhd.uhd_tx_metadata_make(self.tx_metadata_handle, false, 0.0, 0.1, true, false)
    if ret ~= 0 then
        error("uhd_tx_metadata_make(): " .. uhd_code_strerror(ret))
    end
    self.tx_metadata_handle = ffi.gc(self.tx_metadata_handle, libuhd.uhd_tx_metadata_make)

    -- (Debug) Dump USRP info
    if debug.enabled then
        self:debug_dump_usrp(self.usrp_handle[0])
    end

    -- Set antenna (if specified)
    if self.antenna then
        ret = libuhd.uhd_usrp_set_tx_antenna(self.usrp_handle[0], self.antenna, self.channel)
        if ret ~= 0 then
            error("uhd_usrp_set_tx_antenna(): " .. uhd_last_strerror(self.usrp_handle))
        end
    end

    -- Set rate
    ret = libuhd.uhd_usrp_set_tx_rate(self.usrp_handle[0], self:get_rate(), self.channel)
    if ret ~= 0 then
        error("uhd_usrp_set_tx_rate(): " .. uhd_last_strerror(self.usrp_handle))
    end

    -- (Debug) Report actual rate
    if debug.enabled then
        local actual_rate = ffi.new("double[1]")
        ret = libuhd.uhd_usrp_get_tx_rate(self.usrp_handle[0], self.channel, actual_rate)
        if ret ~= 0 then
            error("uhd_usrp_get_tx_rate(): " .. uhd_last_strerror(self.usrp_handle))
        end

        debug.printf("[UHDSink] Requested rate: %f Hz, Actual rate: %f Hz\n", self:get_rate(), actual_rate[0])
    end

    if self.bandwidth then
        -- Set bandwidth
        ret = libuhd.uhd_usrp_set_tx_bandwidth(self.usrp_handle[0], self.bandwidth, self.channel)
        if ret ~= 0 then
            error("uhd_usrp_set_tx_bandwidth(): " .. uhd_last_strerror(self.usrp_handle))
        end

        -- (Debug) Report actual bandwidth
        if debug.enabled then
            local actual_bandwidth = ffi.new("double[1]")
            ret = libuhd.uhd_usrp_get_tx_bandwidth(self.usrp_handle[0], self.channel, actual_bandwidth)
            if ret ~= 0 then
                error("uhd_usrp_get_tx_bandwidth(): " .. uhd_last_strerror(self.usrp_handle))
            end

            debug.printf("[UHDSink] Requested bandwidth: %f Hz, Actual bandwidth: %f Hz\n", self.bandwidth, actual_bandwidth[0])
        end
    end

    -- Set gain (if specified)
    if self.gain then
        ret = libuhd.uhd_usrp_set_tx_gain(self.usrp_handle[0], self.gain, self.channel, "")
        if ret ~= 0 then
            error("uhd_usrp_set_tx_gain(): " .. uhd_last_strerror(self.usrp_handle))
        end

        -- (Debug) Report actual gain
        if debug.enabled then
            local actual_gain = ffi.new("double[1]")
            ret = libuhd.uhd_usrp_get_tx_gain(self.usrp_handle[0], self.channel, "", actual_gain)
            if ret ~= 0 then
                error("uhd_usrp_get_tx_gain(): " .. uhd_last_strerror(self.usrp_handle))
            end

            debug.printf("[UHDSink] Requested gain: %f dB, Actual gain: %f dB\n", self.gain, actual_gain[0])
        end
    end

    -- Set gains (if specified)
    if self.gains then
        for name, value in pairs(self.gains) do
            ret = libuhd.uhd_usrp_set_tx_gain(self.usrp_handle[0], value, self.channel, name)
            if ret ~= 0 then
                error("uhd_usrp_set_tx_gain(): " .. uhd_last_strerror(self.usrp_handle))
            end
        end
    end

    -- Set frequency
    local tune_request = ffi.new("uhd_tune_request_t")
    local tune_result = ffi.new("uhd_tune_result_t")

    tune_request.target_freq = self.frequency
    tune_request.rf_freq_policy = ffi.C.UHD_TUNE_REQUEST_POLICY_AUTO
    tune_request.dsp_freq_policy = ffi.C.UHD_TUNE_REQUEST_POLICY_AUTO

    ret = libuhd.uhd_usrp_set_tx_freq(self.usrp_handle[0], tune_request, self.channel, tune_result)
    if ret ~= 0 then
        error("uhd_usrp_set_tx_freq(): " .. uhd_last_strerror(self.usrp_handle))
    end

    -- (Debug) Report actual frequency
    if debug.enabled then
        local actual_freq = ffi.new("double[1]")
        ret = libuhd.uhd_usrp_get_tx_freq(self.usrp_handle[0], self.channel, actual_freq)
        if ret ~= 0 then
            error("uhd_usrp_get_tx_freq(): " .. uhd_last_strerror(self.usrp_handle))
        end

        debug.printf("[UHDSink] Requested frequency: %f Hz, Actual frequency: %f Hz\n", self.frequency, actual_freq[0])
    end

    -- Setup TX streamer
	local cpu_format = ffi.new("char[8]", "fc32")
	local otw_format = ffi.new("char[8]", "sc16")
	local extra_args = ffi.new("char[8]", "")
	local channel_list = ffi.new("size_t[1]", {self.channel})
    local stream_args = ffi.new("uhd_stream_args_t")
    stream_args.cpu_format = cpu_format
    stream_args.otw_format = otw_format
    stream_args.args = extra_args
    stream_args.channel_list = channel_list
    stream_args.n_channels = 1

    ret = libuhd.uhd_usrp_get_tx_stream(self.usrp_handle[0], stream_args, self.tx_streamer_handle[0])
    if ret ~= 0 then
        error("uhd_usrp_get_tx_stream(): " .. uhd_last_strerror(self.usrp_handle))
    end

    -- Mark ourselves initialized
    self.initialized = true
end

function UHDSink:process(x)
    if not self.initialized then
        -- Initialize the USRP in our own running process
        self:initialize_uhd()
    end

	-- Write vector to stream
    local buffs, num_samples = ffi.new("const void * [1]", {x.data}), ffi.new("size_t[1]")
	local len = 0
	while len < x.length do
		buffs[0] = x.data + len
		local ret = libuhd.uhd_tx_streamer_send(self.tx_streamer_handle[0], buffs, x.length - len, self.tx_metadata_handle, 3.0, num_samples)
    	if ret ~= 0 then
    	    error("uhd_tx_streamer_send(): " .. tx_streamer_last_strerror(self.tx_streamer_handle))
    	end
		len = len + tonumber(num_samples[0])
	end
end

return UHDSink
