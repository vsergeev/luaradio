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
        mir_sdr_Success = 0,
        mir_sdr_Fail = 1,
        mir_sdr_InvalidParam = 2,
        mir_sdr_OutOfRange = 3,
        mir_sdr_GainUpdateError = 4,
        mir_sdr_RfUpdateError = 5,
        mir_sdr_FsUpdateError = 6,
        mir_sdr_HwError = 7,
        mir_sdr_AliasingError = 8,
        mir_sdr_AlreadyInitialised = 9,
        mir_sdr_NotInitialised = 10
    } mir_sdr_ErrT;

    typedef enum {
        mir_sdr_BW_0_200 = 200,
        mir_sdr_BW_0_300 = 300,
        mir_sdr_BW_0_600 = 600,
        mir_sdr_BW_1_536 = 1536,
        mir_sdr_BW_5_000 = 5000,
        mir_sdr_BW_6_000 = 6000,
        mir_sdr_BW_7_000 = 7000,
        mir_sdr_BW_8_000 = 8000
    } mir_sdr_Bw_MHzT;

    typedef enum {
        mir_sdr_IF_Zero = 0,
        mir_sdr_IF_0_450 = 450,
        mir_sdr_IF_1_620 = 1620,
        mir_sdr_IF_2_048 = 2048
    } mir_sdr_If_kHzT;

    mir_sdr_ErrT mir_sdr_Init(int gRdB, double fsMHz, double rfMHz, mir_sdr_Bw_MHzT bwType, mir_sdr_If_kHzT ifType, int *samplesPerPacket);
    mir_sdr_ErrT mir_sdr_Uninit(void);

    mir_sdr_ErrT mir_sdr_ApiVersion(float *version);

    mir_sdr_ErrT mir_sdr_ReadPacket(short *xi, short *xq, unsigned int *firstSampleNum, int *grChanged, int *rfChanged, int *fsChanged);

    mir_sdr_ErrT mir_sdr_SetRf(double drfHz, int abs, int syncUpdate);
    mir_sdr_ErrT mir_sdr_SetFs(double dfsHz, int abs, int syncUpdate, int reCal);
    mir_sdr_ErrT mir_sdr_SetGr(int gRdB, int abs, int syncUpdate);
    mir_sdr_ErrT mir_sdr_SetGrParams(int minimumGr, int lnaGrThreshold);
    mir_sdr_ErrT mir_sdr_SetDcMode(int dcCal, int speedUp);
    mir_sdr_ErrT mir_sdr_SetDcTrackTime(int trackTime);
    mir_sdr_ErrT mir_sdr_SetSyncUpdateSampleNum(unsigned int sampleNum);
    mir_sdr_ErrT mir_sdr_SetSyncUpdatePeriod(unsigned int period);
    mir_sdr_ErrT mir_sdr_SetParam(int ParamterId, int value);

    mir_sdr_ErrT mir_sdr_ResetUpdateFlags(int resetGainUpdate, int resetRfUpdate, int resetFsUpdate);
    mir_sdr_ErrT mir_sdr_DownConvert(short *in, short *xi, short *xq, unsigned int samplesPerPacket, mir_sdr_If_kHzT ifType, unsigned int M, unsigned int preReset);
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

function SDRplaySource:initialize_sdrplay()
    local ret

    -- Dump version info
    if debug.enabled then
        -- Look up library version
        local lib_version = ffi.new("float [1]")
        ret = libmirsdrapi_rsp.mir_sdr_ApiVersion(lib_version)
        if ret ~= ffi.C.mir_sdr_Success then
            error("mir_sdr_ApiVersion(): " .. libmirsdrapi_strerror(ret))
        end

        debug.printf("[SDRplaySource] Library version: %.2f\n", lib_version[0])
    end

    -- Compute API bandwidth parameter
    local api_bandwidth = self.bandwidth and libmirsdrapi_compute_bandwidth_closest(self.bandwidth/1e3) or libmirsdrapi_compute_bandwidth_closest(self.rate)

    debug.printf("[SDRplaySource] Frequency: %u Hz, Sample rate: %u Hz\n", self.frequency, self.rate)
    debug.printf("[SDRplaySource] Requested Bandwidth: %u Hz, Actual Bandwidth: %u Hz\n", (self.bandwidth or api_bandwidth)*1e3, api_bandwidth*1e3)

    -- Open and initialize device
    local samples_per_packet = ffi.new("int [1]")
    ret = libmirsdrapi_rsp.mir_sdr_Init(self.gain_reduction, self.rate/1e6, self.frequency/1e6, api_bandwidth, ffi.C.mir_sdr_IF_Zero, samples_per_packet)
    if ret ~= 0 then
        error("mir_sdr_Init(): " .. libmirsdrapi_strerror(ret))
    end
    self.samples_per_packet = samples_per_packet[0]

    -- Create raw sample buffers
    self.chunk_size = math.floor(32768 / self.samples_per_packet)*self.samples_per_packet
    self.raw_samples_i = ffi.new("short [?]", self.chunk_size)
    self.raw_samples_q = ffi.new("short [?]", self.chunk_size)

    -- Create output vector
    self.out = types.ComplexFloat32.vector(self.chunk_size)

    -- Mark ourselves initialized
    self.initialized = true
end

function SDRplaySource:process()
    if not self.initialized then
        -- Initialize the SDRplay in our own running process
        self:initialize_sdrplay()
    end

    -- Extra arguments to mir_sdr_ReadPacket()
    local firstSampleNum, grChanged, rfChanged, fsChanged = ffi.new("unsigned int [1]"), ffi.new("int [1]"), ffi.new("int [1]"), ffi.new("int [1]")

    -- Read packets up to chunk size
    for i = 0, (self.chunk_size/self.samples_per_packet)-1 do
        -- Read packet
        local ret = libmirsdrapi_rsp.mir_sdr_ReadPacket(self.raw_samples_i + i*self.samples_per_packet, self.raw_samples_q + i*self.samples_per_packet, firstSampleNum, grChanged, rfChanged, fsChanged)
        if ret ~= ffi.C.mir_sdr_Success then
            error("mir_sdr_ReadPacket(): " .. libmirsdrapi_strerror(ret))
        end
    end

    -- Convert raw samples to complex float32 samples
    for i = 0, self.chunk_size-1 do
        self.out.data[i].real = self.raw_samples_i[i]*1.0/32767.5
        self.out.data[i].imag = self.raw_samples_q[i]*1.0/32767.5
    end

    return self.out
end

return SDRplaySource
