---
-- Source a complex-valued signal from an SDRplay RSP. This source requires the
-- libmirsdrapi-rsp library.
--
-- @category Sources
-- @block SDRplaySource
-- @tparam number frequency Tuning frequency in Hz
-- @tparam number rate Sample rate in Hz
-- @tparam[opt={}] table options Additional options, specifying:
--      * `gain_reduction` (int, default 80 dB, range of 0 to 102 dB)
--      * `bandwidth` (number, default closest, choice of 0.200 MHz, 0.300 MHz,
--        0.600 MHz, 1.536 MHz, 5.000 MHz, 6.000 MHz, 7.000 MHz, 8.000 MHz)
--
-- @signature > out:ComplexFloat32
--
-- @usage
-- -- Source samples from 91.1 MHz sampled at 2 MHz
-- local src = radio.SDRplaySource(91.1e6, 2e6)
--
-- -- Source samples from 144.390 MHz sampled at 4 MHz, with 0.6 MHz bandwidth
-- local src = radio.SDRplaySource(144.390e6, 4e6, {bandwidth = 0.6e6})
--
-- -- Source samples from 15 MHz sampled at 10 MHz, with 75 dB gain reduction
-- local src = radio.SDRplaySource(15e6, 10e6, {gain_reduction = 75})

local ffi = require('ffi')

local block = require('radio.core.block')
local platform = require('radio.core.platform')
local debug = require('radio.core.debug')
local types = require('radio.types')
local async = require('radio.core.async')

local SDRplaySource = block.factory("SDRplaySource")

function SDRplaySource:instantiate(frequency, rate, options)
    self.frequency = assert(frequency, "Missing argument #1 (frequency)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    self.options = options or {}
    self.gain_reduction = self.options.gain_reduction or 80
    self.bandwidth = self.options.bandwidth

    self:add_type_signature({}, {block.Output("out", types.ComplexFloat32)})
end

function SDRplaySource:get_rate()
    return self.rate
end

ffi.cdef[[
    typedef enum {
        mir_sdr_Success            = 0,
        mir_sdr_Fail               = 1,
        mir_sdr_InvalidParam       = 2,
        mir_sdr_OutOfRange         = 3,
        mir_sdr_GainUpdateError    = 4,
        mir_sdr_RfUpdateError      = 5,
        mir_sdr_FsUpdateError      = 6,
        mir_sdr_HwError            = 7,
        mir_sdr_AliasingError      = 8,
        mir_sdr_AlreadyInitialised = 9,
        mir_sdr_NotInitialised     = 10,
        mir_sdr_NotEnabled         = 11,
        mir_sdr_HwVerError         = 12,
        mir_sdr_OutOfMemError      = 13,
        mir_sdr_HwRemoved          = 14
    } mir_sdr_ErrT;

    typedef enum {
        mir_sdr_BW_Undefined = 0,
        mir_sdr_BW_0_200     = 200,
        mir_sdr_BW_0_300     = 300,
        mir_sdr_BW_0_600     = 600,
        mir_sdr_BW_1_536     = 1536,
        mir_sdr_BW_5_000     = 5000,
        mir_sdr_BW_6_000     = 6000,
        mir_sdr_BW_7_000     = 7000,
        mir_sdr_BW_8_000     = 8000
    } mir_sdr_Bw_MHzT;

    typedef enum {
        mir_sdr_IF_Undefined = -1,
        mir_sdr_IF_Zero      = 0,
        mir_sdr_IF_0_450     = 450,
        mir_sdr_IF_1_620     = 1620,
        mir_sdr_IF_2_048     = 2048
    } mir_sdr_If_kHzT;

    typedef enum {
        mir_sdr_LO_Undefined = 0,
        mir_sdr_LO_Auto      = 1,
        mir_sdr_LO_120MHz    = 2,
        mir_sdr_LO_144MHz    = 3,
        mir_sdr_LO_168MHz    = 4
    } mir_sdr_LoModeT;

    typedef enum {
        mir_sdr_USE_SET_GR          = 0,
        mir_sdr_USE_SET_GR_ALT_MODE = 1,
        mir_sdr_USE_RSP_SET_GR      = 2
    } mir_sdr_SetGrModeT;

    typedef void (*mir_sdr_StreamCallback_t)(short *xi, short *xq, unsigned int firstSampleNum, int grChanged, int rfChanged, int fsChanged, unsigned int numSamples, unsigned int reset, unsigned int hwRemoved, void *cbContext);
    typedef void (*mir_sdr_GainChangeCallback_t)(unsigned int gRdB, unsigned int lnaGRdB, void *cbContext);

    mir_sdr_ErrT mir_sdr_ApiVersion(float *version);
    mir_sdr_ErrT mir_sdr_DebugEnable(unsigned int enable);

    mir_sdr_ErrT mir_sdr_StreamInit(int *gRdB, double fsMHz, double rfMHz, mir_sdr_Bw_MHzT bwType, mir_sdr_If_kHzT ifType, int LNAstate, int *gRdBsystem, mir_sdr_SetGrModeT setGrMode, int *samplesPerPacket, mir_sdr_StreamCallback_t StreamCbFn, mir_sdr_GainChangeCallback_t GainChangeCbFn, void *cbContext);
    mir_sdr_ErrT mir_sdr_StreamUninit(void);
]]
local libmirsdrapi_rsp_available, libmirsdrapi_rsp = pcall(ffi.load, "libmirsdrapi-rsp")

function SDRplaySource:initialize()
    -- Check library is available
    if not libmirsdrapi_rsp_available then
        error("SDRplaySource: libmirsdrapi-rsp not found. Is libmirsdrapi-rsp installed?")
    end
end

local function libmirsdrapi_strerror(code)
    local libmirsdrapi_error_strings = {
        [ffi.C.mir_sdr_Success] = "Success",
        [ffi.C.mir_sdr_Fail] = "Fail",
        [ffi.C.mir_sdr_InvalidParam] = "Invalid parameter",
        [ffi.C.mir_sdr_OutOfRange] = "Out of range",
        [ffi.C.mir_sdr_GainUpdateError] = "Gain update error",
        [ffi.C.mir_sdr_RfUpdateError] = "RF frequency update error",
        [ffi.C.mir_sdr_FsUpdateError] = "Sample rate update error",
        [ffi.C.mir_sdr_HwError] = "Hardware error",
        [ffi.C.mir_sdr_AliasingError] = "Aliasing error",
        [ffi.C.mir_sdr_AlreadyInitialised] = "Already initialised",
        [ffi.C.mir_sdr_NotInitialised] = "Not initialised",
        [ffi.C.mir_sdr_NotEnabled] = "Not enabled",
        [ffi.C.mir_sdr_HwVerError] = "Hardware version error",
        [ffi.C.mir_sdr_OutOfMemError] = "Out of memory error",
        [ffi.C.mir_sdr_HwRemoved] = "Hardware removed",
    }
    return libmirsdrapi_error_strings[tonumber(code)] or "Unknown"
end

local function libmirsdrapi_compute_bandwidth_closest(bandwidth)
    local libmirsdrapi_bandwidths = {
        ffi.C.mir_sdr_BW_8_000, ffi.C.mir_sdr_BW_7_000,
        ffi.C.mir_sdr_BW_6_000, ffi.C.mir_sdr_BW_5_000,
        ffi.C.mir_sdr_BW_1_536, ffi.C.mir_sdr_BW_0_600,
        ffi.C.mir_sdr_BW_0_300, ffi.C.mir_sdr_BW_0_200,
    }

    -- Return closest API bandwidth that is less than specified one
    for _, api_bandwidth in ipairs(libmirsdrapi_bandwidths) do
        if api_bandwidth < bandwidth/1e3 then
            return api_bandwidth
        end
    end

    -- Default to lowest bandwidth
    return libmirsdrapi_bandwidths[#libmirsdrapi_bandwidths]
end

local function stream_callback_factory(...)
    local ffi = require('ffi')
    local radio = require('radio')

    local fds = {...}

    local out = radio.types.ComplexFloat32.vector()

    local function stream_callback(xi, xq, firstSampleNum, grChanged, rfChanged, fsChanged, numSamples, reset, hwRemoved, cbContext)
        out:resize(numSamples)

        -- Convert raw samples to complex float32 samples
        for i = 0, out.length-1 do
            out.data[i].real = xi[i]*1.0/32767.5
            out.data[i].imag = xq[i]*1.0/32767.5
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
    end

    return ffi.cast('mir_sdr_StreamCallback_t', stream_callback)
end

local function gain_change_callback_factory(a)
    local ffi = require('ffi')
    local radio = require('radio')

    local function gain_change_callback(gRdb, lnaGRdb, cbContext)
        -- Do nothing for now
    end

    return ffi.cast('mir_sdr_GainChangeCallback_t', gain_change_callback)
end

function SDRplaySource:run()
    local ret

    -- Dump version info
    if debug.enabled then
        -- Look up library version
        local lib_version = ffi.new("float [1]")
        ret = libmirsdrapi_rsp.mir_sdr_ApiVersion(lib_version)
        if ret ~= ffi.C.mir_sdr_Success then
            error("mir_sdr_ApiVersion(): " .. libmirsdrapi_strerror(ret))
        end

        -- Enable debug
        ret = libmirsdrapi_rsp.mir_sdr_DebugEnable(1)
        if ret ~= ffi.C.mir_sdr_Success then
            error("mir_sdr_DebugEnable(): " .. libmirsdrapi_strerror(ret))
        end

        debug.printf("[SDRplaySource] Library version: %.2f\n", lib_version[0])
    end

    -- Compute API bandwidth parameter
    local api_bandwidth = self.bandwidth and libmirsdrapi_compute_bandwidth_closest(self.bandwidth/1e3) or libmirsdrapi_compute_bandwidth_closest(self.rate)

    debug.printf("[SDRplaySource] Frequency: %u Hz, Sample rate: %u Hz\n", self.frequency, self.rate)
    debug.printf("[SDRplaySource] Requested Bandwidth: %u Hz, Actual Bandwidth: %u Hz\n", (self.bandwidth or api_bandwidth)*1e3, api_bandwidth*1e3)

    -- Build signal set with SIGTERM
    local sigset = ffi.new("sigset_t[1]")
    ffi.C.sigemptyset(sigset)
    ffi.C.sigaddset(sigset, ffi.C.SIGTERM)

    -- Block handling of SIGTERM
    if ffi.C.sigprocmask(ffi.C.SIG_BLOCK, sigset, nil) ~= 0 then
        error("sigprocmask(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Initialize device and start receiving
    local stream_callback, stream_callback_state = async.callback(stream_callback_factory, unpack(self.outputs[1]:filenos()))
    local gain_change_callback, gain_change_callback_state = async.callback(gain_change_callback_factory)
    local samples_per_packet = ffi.new("int [1]")
    local gain_reduction = ffi.new("int [1]", self.gain_reduction)
    local gain_reduction_system = ffi.new("int [1]")
    ret = libmirsdrapi_rsp.mir_sdr_StreamInit(gain_reduction, self.rate/1e6, self.frequency/1e6, api_bandwidth, ffi.C.mir_sdr_IF_Zero, 0, gain_reduction_system, ffi.C.mir_sdr_USE_SET_GR, samples_per_packet, stream_callback, gain_change_callback, nil)
    if ret ~= ffi.C.mir_sdr_Success then
        error("mir_sdr_Init(): " .. libmirsdrapi_strerror(ret))
    end

    -- Wait for SIGTERM
    local sig = ffi.new("int[1]")
    if ffi.C.sigwait(sigset, sig) ~= 0 then
        error("sigwait(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Stop stream
    ret = libmirsdrapi_rsp.mir_sdr_StreamUninit()
    if ret ~= 0 then
        error("mir_sdr_Init(): " .. libmirsdrapi_strerror(ret))
    end
end

return SDRplaySource
