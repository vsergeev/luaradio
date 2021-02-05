---
-- Source a complex-valued signal from an SDRplay RSP (1, 1A, 2, Duo, or Dx).
-- This source requires the libsdrplay_api or libmirsdrapi-rsp library.
--
-- @category Sources
-- @block SDRplaySource
-- @tparam number frequency Tuning frequency in Hz
-- @tparam number rate Sample rate in Hz
-- @tparam[opt={}] table options Additional options, specifying:
--      * `gain_reduction` (int, default 40 dB, range of 20 to 59 dB)
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
-- -- Source samples from 15 MHz sampled at 10 MHz, with 30 dB gain reduction
-- local src = radio.SDRplaySource(15e6, 10e6, {gain_reduction = 30})

local ffi = require('ffi')

local block = require('radio.core.block')
local platform = require('radio.core.platform')
local debug = require('radio.core.debug')
local types = require('radio.types')
local async = require('radio.core.async')
local pipe = require('radio.core.pipe')

local SDRplaySource = block.factory("SDRplaySource")

function SDRplaySource:instantiate(frequency, rate, options)
    self.frequency = assert(frequency, "Missing argument #1 (frequency)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    self.options = options or {}
    self.gain_reduction = self.options.gain_reduction or 40
    self.bandwidth = self.options.bandwidth

    self:add_type_signature({}, {block.Output("out", types.ComplexFloat32)})
end

function SDRplaySource:get_rate()
    return self.rate
end

local libsdrplay_api_available, libsdrplay_api = pcall(ffi.load, "libsdrplay_api")
local libmirsdrapi_rsp_available, libmirsdrapi_rsp = pcall(ffi.load, "libmirsdrapi-rsp")

-- Prefer newer SDRplay API if available
if libsdrplay_api_available then

ffi.cdef[[
    /************************************/
    /* sdrplay_api_tuner.h */
    /************************************/

    typedef enum
    {
        sdrplay_api_BW_Undefined = 0,
        sdrplay_api_BW_0_200     = 200,
        sdrplay_api_BW_0_300     = 300,
        sdrplay_api_BW_0_600     = 600,
        sdrplay_api_BW_1_536     = 1536,
        sdrplay_api_BW_5_000     = 5000,
        sdrplay_api_BW_6_000     = 6000,
        sdrplay_api_BW_7_000     = 7000,
        sdrplay_api_BW_8_000     = 8000
    } sdrplay_api_Bw_MHzT;

    typedef enum
    {
        sdrplay_api_IF_Undefined = -1,
        sdrplay_api_IF_Zero      = 0,
        sdrplay_api_IF_0_450     = 450,
        sdrplay_api_IF_1_620     = 1620,
        sdrplay_api_IF_2_048     = 2048
    } sdrplay_api_If_kHzT;

    typedef enum
    {
        sdrplay_api_LO_Undefined = 0,
        sdrplay_api_LO_Auto      = 1,
        sdrplay_api_LO_120MHz    = 2,
        sdrplay_api_LO_144MHz    = 3,
        sdrplay_api_LO_168MHz    = 4
    } sdrplay_api_LoModeT;

    typedef enum
    {
        sdrplay_api_EXTENDED_MIN_GR = 0,
        sdrplay_api_NORMAL_MIN_GR   = 20
    } sdrplay_api_MinGainReductionT;

    typedef enum
    {
        sdrplay_api_Tuner_Neither  = 0,
        sdrplay_api_Tuner_A        = 1,
        sdrplay_api_Tuner_B        = 2,
        sdrplay_api_Tuner_Both     = 3,
    } sdrplay_api_TunerSelectT;

    typedef struct
    {
        float curr;
        float max;
        float min;
    } sdrplay_api_GainValuesT;

    typedef struct
    {
        int gRdB;                            // default: 50
        unsigned char LNAstate;              // default: 0
        unsigned char syncUpdate;            // default: 0
        sdrplay_api_MinGainReductionT minGr; // default: sdrplay_api_NORMAL_MIN_GR
        sdrplay_api_GainValuesT gainVals;    // output parameter
    } sdrplay_api_GainT;

    typedef struct
    {
        double rfHz;                         // default: 200000000.0
        unsigned char syncUpdate;            // default: 0
    } sdrplay_api_RfFreqT;

    typedef struct
    {
        unsigned char dcCal;                 // default: 3 (Periodic mode)
        unsigned char speedUp;               // default: 0 (No speedup)
        int trackTime;                       // default: 1    (=> time in uSec = (72 * 3 * trackTime) / 24e6       = 9uSec)
        int refreshRateTime;                 // default: 2048 (=> time in uSec = (72 * 3 * refreshRateTime) / 24e6 = 18432uSec)
    } sdrplay_api_DcOffsetTunerT;

    typedef struct
    {
        sdrplay_api_Bw_MHzT bwType;          // default: sdrplay_api_BW_0_200
        sdrplay_api_If_kHzT ifType;          // default: sdrplay_api_IF_Zero
        sdrplay_api_LoModeT loMode;          // default: sdrplay_api_LO_Auto
        sdrplay_api_GainT gain;
        sdrplay_api_RfFreqT rfFreq;
        sdrplay_api_DcOffsetTunerT dcOffsetTuner;
    } sdrplay_api_TunerParamsT;

    /************************************/
    /* sdrplay_api_control.h */
    /************************************/

    typedef enum
    {
        sdrplay_api_AGC_DISABLE  = 0,
        sdrplay_api_AGC_100HZ    = 1,
        sdrplay_api_AGC_50HZ     = 2,
        sdrplay_api_AGC_5HZ      = 3,
        sdrplay_api_AGC_CTRL_EN  = 4
    } sdrplay_api_AgcControlT;

    typedef enum
    {
        sdrplay_api_ADSB_DECIMATION                  = 0,
        sdrplay_api_ADSB_NO_DECIMATION_LOWPASS       = 1,
        sdrplay_api_ADSB_NO_DECIMATION_BANDPASS_2MHZ = 2,
        sdrplay_api_ADSB_NO_DECIMATION_BANDPASS_3MHZ = 3
    } sdrplay_api_AdsbModeT;

    typedef struct
    {
        unsigned char DCenable;          // default: 1
        unsigned char IQenable;          // default: 1
    } sdrplay_api_DcOffsetT;

    typedef struct
    {
        unsigned char enable;            // default: 0
        unsigned char decimationFactor;  // default: 1
        unsigned char wideBandSignal;    // default: 0
    } sdrplay_api_DecimationT;

    typedef struct
    {
        sdrplay_api_AgcControlT enable;    // default: sdrplay_api_AGC_50HZ
        int setPoint_dBfs;                 // default: -60
        unsigned short attack_ms;          // default: 0
        unsigned short decay_ms;           // default: 0
        unsigned short decay_delay_ms;     // default: 0
        unsigned short decay_threshold_dB; // default: 0
        int syncUpdate;                    // default: 0
    } sdrplay_api_AgcT;

    typedef struct
    {
        sdrplay_api_DcOffsetT dcOffset;
        sdrplay_api_DecimationT decimation;
        sdrplay_api_AgcT agc;
        sdrplay_api_AdsbModeT adsbMode;  //default: sdrplay_api_ADSB_DECIMATION
    } sdrplay_api_ControlParamsT;

    /************************************/
    /* sdrplay_api_rsp1a.h */
    /************************************/

    typedef struct
    {
        unsigned char rfNotchEnable;                              // default: 0
        unsigned char rfDabNotchEnable;                           // default: 0
    } sdrplay_api_Rsp1aParamsT;

    typedef struct
    {
        unsigned char biasTEnable;                   // default: 0
    } sdrplay_api_Rsp1aTunerParamsT;

    /************************************/
    /* sdrplay_api_rsp2.h */
    /************************************/

    typedef enum
    {
        sdrplay_api_Rsp2_ANTENNA_A = 5,
        sdrplay_api_Rsp2_ANTENNA_B = 6,
    } sdrplay_api_Rsp2_AntennaSelectT;

    typedef enum
    {
        sdrplay_api_Rsp2_AMPORT_1 = 1,
        sdrplay_api_Rsp2_AMPORT_2 = 0,
    } sdrplay_api_Rsp2_AmPortSelectT;

    typedef struct
    {
        unsigned char extRefOutputEn;                // default: 0
    } sdrplay_api_Rsp2ParamsT;

    typedef struct
    {
        unsigned char biasTEnable;                   // default: 0
        sdrplay_api_Rsp2_AmPortSelectT amPortSel;    // default: sdrplay_api_Rsp2_AMPORT_2
        sdrplay_api_Rsp2_AntennaSelectT antennaSel;  // default: sdrplay_api_Rsp2_ANTENNA_A
        unsigned char rfNotchEnable;                 // default: 0
    } sdrplay_api_Rsp2TunerParamsT;

    /************************************/
    /* sdrplay_api_rspDuo.h */
    /************************************/

    typedef enum
    {
        sdrplay_api_RspDuoMode_Unknown      = 0,
        sdrplay_api_RspDuoMode_Single_Tuner = 1,
        sdrplay_api_RspDuoMode_Dual_Tuner   = 2,
        sdrplay_api_RspDuoMode_Master       = 4,
        sdrplay_api_RspDuoMode_Slave        = 8,
    } sdrplay_api_RspDuoModeT;

    typedef enum
    {
        sdrplay_api_RspDuo_AMPORT_1 = 1,
        sdrplay_api_RspDuo_AMPORT_2 = 0,
    } sdrplay_api_RspDuo_AmPortSelectT;

    typedef struct
    {
        int extRefOutputEn;                             // default: 0
    } sdrplay_api_RspDuoParamsT;

    typedef struct
    {
        unsigned char biasTEnable;                      // default: 0
        sdrplay_api_RspDuo_AmPortSelectT tuner1AmPortSel; // default: sdrplay_api_RspDuo_AMPORT_2
        unsigned char tuner1AmNotchEnable;              // default: 0
        unsigned char rfNotchEnable;                    // default: 0
        unsigned char rfDabNotchEnable;                 // default: 0
    } sdrplay_api_RspDuoTunerParamsT;

    /************************************/
    /* sdrplay_api_rspDx.h */
    /************************************/

    typedef enum
    {
        sdrplay_api_RspDx_ANTENNA_A = 0,
        sdrplay_api_RspDx_ANTENNA_B = 1,
        sdrplay_api_RspDx_ANTENNA_C = 2,
    } sdrplay_api_RspDx_AntennaSelectT;

    typedef enum
    {
        sdrplay_api_RspDx_HDRMODE_BW_0_200  = 0,
        sdrplay_api_RspDx_HDRMODE_BW_0_500  = 1,
        sdrplay_api_RspDx_HDRMODE_BW_1_200  = 2,
        sdrplay_api_RspDx_HDRMODE_BW_1_700  = 3,
    } sdrplay_api_RspDx_HdrModeBwT;

    typedef struct
    {
        unsigned char hdrEnable;                            // default: 0
        unsigned char biasTEnable;                          // default: 0
        sdrplay_api_RspDx_AntennaSelectT antennaSel;        // default: sdrplay_api_RspDx_ANTENNA_A
        unsigned char rfNotchEnable;                        // default: 0
        unsigned char rfDabNotchEnable;                     // default: 0
    } sdrplay_api_RspDxParamsT;

    typedef struct
    {
        sdrplay_api_RspDx_HdrModeBwT hdrBw;                 // default: sdrplay_api_RspDx_HDRMODE_BW_1_700
    } sdrplay_api_RspDxTunerParamsT;

    /************************************/
    /* sdrplay_api_rx_channel.h */
    /************************************/

    typedef struct
    {
        sdrplay_api_TunerParamsT        tunerParams;
        sdrplay_api_ControlParamsT      ctrlParams;
        sdrplay_api_Rsp1aTunerParamsT   rsp1aTunerParams;
        sdrplay_api_Rsp2TunerParamsT    rsp2TunerParams;
        sdrplay_api_RspDuoTunerParamsT  rspDuoTunerParams;
        sdrplay_api_RspDxTunerParamsT   rspDxTunerParams;
    } sdrplay_api_RxChannelParamsT;

    /************************************/
    /* sdrplay_api_dev.h */
    /************************************/

    typedef enum
    {
        sdrplay_api_ISOCH = 0,
        sdrplay_api_BULK  = 1
    } sdrplay_api_TransferModeT;

    typedef struct
    {
        double fsHz;                        // default: 2000000.0
        unsigned char syncUpdate;           // default: 0
        unsigned char reCal;                // default: 0
    } sdrplay_api_FsFreqT;

    typedef struct
    {
        unsigned int sampleNum;             // default: 0
        unsigned int period;                // default: 0
    } sdrplay_api_SyncUpdateT;

    typedef struct
    {
        unsigned char resetGainUpdate;      // default: 0
        unsigned char resetRfUpdate;        // default: 0
        unsigned char resetFsUpdate;        // default: 0
    } sdrplay_api_ResetFlagsT;

    typedef struct
    {
        double ppm;                         // default: 0.0
        sdrplay_api_FsFreqT fsFreq;
        sdrplay_api_SyncUpdateT syncUpdate;
        sdrplay_api_ResetFlagsT resetFlags;
        sdrplay_api_TransferModeT mode;     // default: sdrplay_api_ISOCH
        unsigned int samplesPerPkt;         // default: 0 (output param)
        sdrplay_api_Rsp1aParamsT rsp1aParams;
        sdrplay_api_Rsp2ParamsT rsp2Params;
        sdrplay_api_RspDuoParamsT rspDuoParams;
        sdrplay_api_RspDxParamsT rspDxParams;
    } sdrplay_api_DevParamsT;

    /************************************/
    /* sdrplay_api_callback.h */
    /************************************/

    typedef enum
    {
        sdrplay_api_GainChange            = 0,
        sdrplay_api_PowerOverloadChange   = 1,
        sdrplay_api_DeviceRemoved         = 2,
        sdrplay_api_RspDuoModeChange      = 3,
    } sdrplay_api_EventT;

    typedef union { } sdrplay_api_EventParamsT;

    typedef struct
    {
        unsigned int firstSampleNum;
        int grChanged;
        int rfChanged;
        int fsChanged;
        unsigned int numSamples;
    } sdrplay_api_StreamCbParamsT;

    typedef void (*sdrplay_api_StreamCallback_t)(short *xi, short *xq, sdrplay_api_StreamCbParamsT *params, unsigned int numSamples, unsigned int reset, void *cbContext);
    typedef void (*sdrplay_api_EventCallback_t)(sdrplay_api_EventT eventId, sdrplay_api_TunerSelectT tuner, sdrplay_api_EventParamsT *params, void *cbContext);

    typedef struct
    {
        sdrplay_api_StreamCallback_t StreamACbFn;
        sdrplay_api_StreamCallback_t StreamBCbFn;
        sdrplay_api_EventCallback_t  EventCbFn;
    } sdrplay_api_CallbackFnsT;

    /************************************/
    /* sdrplay_api.h */
    /************************************/

    typedef void *HANDLE;

    enum
    {
        SDRPLAY_RSP1_ID   = 1,
        SDRPLAY_RSP1A_ID  = 255,
        SDRPLAY_RSP2_ID   = 2,
        SDRPLAY_RSPduo_ID = 3,
        SDRPLAY_RSPdx_ID  = 4,
    };

    typedef enum
    {
        sdrplay_api_Success               = 0,
    } sdrplay_api_ErrT;

    typedef enum
    {
        sdrplay_api_Update_None                        = 0x00000000,
        sdrplay_api_Update_Dev_Fs                      = 0x00000001,
        sdrplay_api_Update_Dev_Ppm                     = 0x00000002,
        sdrplay_api_Update_Dev_SyncUpdate              = 0x00000004,
        sdrplay_api_Update_Dev_ResetFlags              = 0x00000008,
        sdrplay_api_Update_Rsp1a_BiasTControl          = 0x00000010,
        sdrplay_api_Update_Rsp1a_RfNotchControl        = 0x00000020,
        sdrplay_api_Update_Rsp1a_RfDabNotchControl     = 0x00000040,
        sdrplay_api_Update_Rsp2_BiasTControl           = 0x00000080,
        sdrplay_api_Update_Rsp2_AmPortSelect           = 0x00000100,
        sdrplay_api_Update_Rsp2_AntennaControl         = 0x00000200,
        sdrplay_api_Update_Rsp2_RfNotchControl         = 0x00000400,
        sdrplay_api_Update_Rsp2_ExtRefControl          = 0x00000800,
        sdrplay_api_Update_RspDuo_ExtRefControl        = 0x00001000,
        sdrplay_api_Update_Master_Spare_1              = 0x00002000,
        sdrplay_api_Update_Master_Spare_2              = 0x00004000,
        sdrplay_api_Update_Tuner_Gr                    = 0x00008000,
        sdrplay_api_Update_Tuner_GrLimits              = 0x00010000,
        sdrplay_api_Update_Tuner_Frf                   = 0x00020000,
        sdrplay_api_Update_Tuner_BwType                = 0x00040000,
        sdrplay_api_Update_Tuner_IfType                = 0x00080000,
        sdrplay_api_Update_Tuner_DcOffset              = 0x00100000,
        sdrplay_api_Update_Tuner_LoMode                = 0x00200000,
        sdrplay_api_Update_Ctrl_DCoffsetIQimbalance    = 0x00400000,
        sdrplay_api_Update_Ctrl_Decimation             = 0x00800000,
        sdrplay_api_Update_Ctrl_Agc                    = 0x01000000,
        sdrplay_api_Update_Ctrl_AdsbMode               = 0x02000000,
        sdrplay_api_Update_Ctrl_OverloadMsgAck         = 0x04000000,
        sdrplay_api_Update_RspDuo_BiasTControl         = 0x08000000,
        sdrplay_api_Update_RspDuo_AmPortSelect         = 0x10000000,
        sdrplay_api_Update_RspDuo_Tuner1AmNotchControl = 0x20000000,
        sdrplay_api_Update_RspDuo_RfNotchControl       = 0x40000000,
        sdrplay_api_Update_RspDuo_RfDabNotchControl    = 0x80000000,
    } sdrplay_api_ReasonForUpdateT;

    typedef enum
    {
        sdrplay_api_Update_Ext1_None                   = 0x00000000,
        sdrplay_api_Update_RspDx_HdrEnable             = 0x00000001,
        sdrplay_api_Update_RspDx_BiasTControl          = 0x00000002,
        sdrplay_api_Update_RspDx_AntennaControl        = 0x00000004,
        sdrplay_api_Update_RspDx_RfNotchControl        = 0x00000008,
        sdrplay_api_Update_RspDx_RfDabNotchControl     = 0x00000010,
        sdrplay_api_Update_RspDx_HdrBw                 = 0x00000020,
    } sdrplay_api_ReasonForUpdateExtension1T;

    enum { SDRPLAY_MAX_SER_NO_LEN = 64 };

    typedef enum
    {
        sdrplay_api_DbgLvl_Disable       = 0,
        sdrplay_api_DbgLvl_Verbose       = 1,
        sdrplay_api_DbgLvl_Warning       = 2,
        sdrplay_api_DbgLvl_Error         = 3,
        sdrplay_api_DbgLvl_Message       = 4,
    } sdrplay_api_DbgLvl_t;

    typedef struct
    {
        char SerNo[SDRPLAY_MAX_SER_NO_LEN];
        unsigned char hwVer;
        sdrplay_api_TunerSelectT tuner;
        sdrplay_api_RspDuoModeT rspDuoMode;
        double rspDuoSampleFreq;
        HANDLE dev;
    } sdrplay_api_DeviceT;

    typedef struct
    {
        sdrplay_api_DevParamsT       *devParams;
        sdrplay_api_RxChannelParamsT *rxChannelA;
        sdrplay_api_RxChannelParamsT *rxChannelB;
    } sdrplay_api_DeviceParamsT;

    typedef struct
    {
        char file[256];
        char function_[256];
        int  line;
        char message[1024];
    } sdrplay_api_ErrorInfoT;

    sdrplay_api_ErrT sdrplay_api_Open(void);
    sdrplay_api_ErrT sdrplay_api_Close(void);
    sdrplay_api_ErrT sdrplay_api_ApiVersion(float *apiVer);
    sdrplay_api_ErrT sdrplay_api_LockDeviceApi(void);
    sdrplay_api_ErrT sdrplay_api_UnlockDeviceApi(void);
    sdrplay_api_ErrT sdrplay_api_GetDevices(sdrplay_api_DeviceT *devices, unsigned int *numDevs, unsigned int maxDevs);
    sdrplay_api_ErrT sdrplay_api_SelectDevice(sdrplay_api_DeviceT *device);
    sdrplay_api_ErrT sdrplay_api_ReleaseDevice(sdrplay_api_DeviceT *device);
    const char*      sdrplay_api_GetErrorString(sdrplay_api_ErrT err);
    sdrplay_api_ErrorInfoT* sdrplay_api_GetLastError(sdrplay_api_DeviceT *device);
    sdrplay_api_ErrT sdrplay_api_DebugEnable(HANDLE dev, sdrplay_api_DbgLvl_t enable);
    sdrplay_api_ErrT sdrplay_api_GetDeviceParams(HANDLE dev, sdrplay_api_DeviceParamsT **deviceParams);
    sdrplay_api_ErrT sdrplay_api_Init(HANDLE dev, sdrplay_api_CallbackFnsT *callbackFns, void *cbContext);
    sdrplay_api_ErrT sdrplay_api_Uninit(HANDLE dev);
    sdrplay_api_ErrT sdrplay_api_Update(HANDLE dev, sdrplay_api_TunerSelectT tuner, sdrplay_api_ReasonForUpdateT reasonForUpdate, sdrplay_api_ReasonForUpdateExtension1T reasonForUpdateExt1);
]]

function SDRplaySource:initialize()
    -- Check library is available
    if not libsdrplay_api_available then
        error("SDRplaySource: libsdrplay_api not found. Is libsdrplay_api installed?")
    end
end

local function libsdrplay_compute_bandwidth_closest(bandwidth)
    local libsdrplay_bandwidths = {
        ffi.C.sdrplay_api_BW_8_000, ffi.C.sdrplay_api_BW_7_000,
        ffi.C.sdrplay_api_BW_6_000, ffi.C.sdrplay_api_BW_5_000,
        ffi.C.sdrplay_api_BW_1_536, ffi.C.sdrplay_api_BW_0_600,
        ffi.C.sdrplay_api_BW_0_300, ffi.C.sdrplay_api_BW_0_200,
    }

    -- Return closest API bandwidth that is less than specified one
    for _, api_bandwidth in ipairs(libsdrplay_bandwidths) do
        if api_bandwidth < bandwidth/1e3 then
            return api_bandwidth
        end
    end

    -- Default to lowest bandwidth
    return libsdrplay_bandwidths[#libsdrplay_bandwidths]
end

local function libsdrplay_format_error(ret, device)
    if not device then
        return ffi.string(libsdrplay_api.sdrplay_api_GetErrorString(ret))
    end

    local err_str = libsdrplay_api.sdrplay_api_GetErrorString(ret)
    local err_info = libsdrplay_api.sdrplay_api_GetLastError(device)

    if debug.enabled then
        return string.format("%s: %s:%d %s(): %s", ffi.string(err_str), ffi.string(err_info.file), err_info.line, ffi.string(err_info.function_), ffi.string(err_info.message))
    else
        return string.format("%s: %s", ffi.string(err_str), ffi.string(err_info.message))
    end
end

function SDRplaySource:initialize_sdrplay()
    local ret

    -- Open API
    ret = libsdrplay_api.sdrplay_api_Open()
    if ret ~= ffi.C.sdrplay_api_Success then
        error("sdrplay_api_Open(): " .. libsdrplay_format_error(ret))
    end

    -- Dump library version
    if debug.enabled then
        local lib_version = ffi.new("float [1]")
        ret = libsdrplay_api.sdrplay_api_ApiVersion(lib_version)
        if ret ~= ffi.C.sdrplay_api_Success then
            error("sdrplay_api_ApiVersion(): " .. libsdrplay_format_error(ret))
        end

        debug.printf("[SDRplaySource] Library version: %.2f\n", lib_version[0])
    end

    -- Lock API to get devices
    ret = libsdrplay_api.sdrplay_api_LockDeviceApi()
    if ret ~= ffi.C.sdrplay_api_Success then
        error("sdrplay_api_LockDeviceApi(): " .. libsdrplay_format_error(ret))
    end

    -- Get list of devices
    local devices = ffi.new("sdrplay_api_DeviceT [1]")
    local num_devices = ffi.new("unsigned int [1]")
    ret = libsdrplay_api.sdrplay_api_GetDevices(devices, num_devices, 1)
    if ret ~= ffi.C.sdrplay_api_Success then
        error("sdrplay_api_GetDevices(): " .. libsdrplay_format_error(ret))
    end

    -- If there are no devices
    if num_devices[0] == 0 then
        ret = libsdrplay_api.sdrplay_api_UnlockDeviceApi()
        if ret ~= ffi.C.sdrplay_api_Success then
            error("sdrplay_api_UnlockDeviceApi(): " .. libsdrplay_format_error(ret))
        end

        error("SDRplay device not found")
    end

    -- Select first device
    ret = libsdrplay_api.sdrplay_api_SelectDevice(devices[0])
    if ret ~= ffi.C.sdrplay_api_Success then
        error("sdrplay_api_SelectDevice(): " .. libsdrplay_format_error(ret))
    end

    -- Unlock API
    ret = libsdrplay_api.sdrplay_api_UnlockDeviceApi()
    if ret ~= ffi.C.sdrplay_api_Success then
        error("sdrplay_api_UnlockDeviceApi(): " .. libsdrplay_format_error(ret))
    end

    -- Save selected device
    self.device = devices[0]

    if debug.enabled then
        -- Enable debug logging
        ret = libsdrplay_api.sdrplay_api_DebugEnable(self.device.dev, ffi.C.sdrplay_api_DbgLvl_Verbose)
        if ret ~= ffi.C.sdrplay_api_Success then
            error("sdrplay_api_DebugEnable(): " .. libsdrplay_format_error(ret, self.device))
        end

        local hw_id_map = {
            [ffi.C.SDRPLAY_RSP1_ID] = "RSP1", [ffi.C.SDRPLAY_RSP1A_ID] = "RSP1A",
            [ffi.C.SDRPLAY_RSP2_ID] = "RSP2", [ffi.C.SDRPLAY_RSPduo_ID] = "RSPduo",
            [ffi.C.SDRPLAY_RSPdx_ID] = "RSPdx",
        }

        debug.printf("[SDRplaySource] Hardware version: %s\n", hw_id_map[devices[0].hwVer] or "Unknown")
        debug.printf("[SDRplaySource] Serial number:    %s\n", ffi.string(devices[0].SerNo))
    end

    -- Get device parameters
    local device_params = ffi.new("sdrplay_api_DeviceParamsT *[1]")
    ret = libsdrplay_api.sdrplay_api_GetDeviceParams(self.device.dev, device_params)
    if ret ~= ffi.C.sdrplay_api_Success then
        error("sdrplay_api_GetDeviceParams(): " .. libsdrplay_format_error(ret, self.device))
    end

    -- Compute API bandwidth parameter
    local api_bandwidth = self.bandwidth and libsdrplay_compute_bandwidth_closest(self.bandwidth) or libsdrplay_compute_bandwidth_closest(self.rate)

    debug.printf("[SDRplaySource] Frequency: %u Hz, Sample rate: %u Hz\n", self.frequency, self.rate)
    debug.printf("[SDRplaySource] Requested Bandwidth: %u Hz, Actual Bandwidth: %u Hz\n", self.bandwidth or self.rate, api_bandwidth*1e3)

    -- Configure device parameters
    device_params[0].devParams.fsFreq.fsHz = self.rate
    device_params[0].rxChannelA.tunerParams.bwType = libsdrplay_compute_bandwidth_closest(self.rate)
    device_params[0].rxChannelA.tunerParams.ifType = ffi.C.sdrplay_api_IF_Zero
    device_params[0].rxChannelA.tunerParams.loMode = ffi.C.sdrplay_api_LO_Auto
    device_params[0].rxChannelA.tunerParams.gain.gRdB = self.gain_reduction
    device_params[0].rxChannelA.tunerParams.gain.minGr = ffi.C.sdrplay_api_NORMAL_MIN_GR
    device_params[0].rxChannelA.tunerParams.rfFreq.rfHz = self.frequency
end

local function stream_callback_factory(...)
    local ffi = require('ffi')

    local radio = require('radio')
    local pipe = require('radio.core.pipe')

    -- Convert fds on stack to Pipe objects
    local output_pipes = {}
    for i, fd in ipairs({...}) do
        output_pipes[i] = pipe.Pipe()
        output_pipes[i]:initialize(radio.types.ComplexFloat32, nil, fd)
    end

    -- Create PipeMux for write multiplexing
    local pipe_mux = pipe.PipeMux({}, {output_pipes})

    -- Create output vector
    local out = radio.types.ComplexFloat32.vector()

    local function stream_callback(xi, xq, params, numSamples, reset, hwRemoved, cbContext)
        -- Resize output vector
        out:resize(numSamples)

        -- Convert raw int16 samples to complex float32 samples
        for i = 0, out.length-1 do
            out.data[i].real = xi[i]*1.0/32767.5
            out.data[i].imag = xq[i]*1.0/32767.5
        end

        -- Write to output pipes
        local eof, eof_pipe = pipe_mux:write({out})
        if eof then
            io.stderr:write("[SDRplaySource] Downstream block terminated unexpectedly.\n")
        end
    end

    return ffi.cast('sdrplay_api_StreamCallback_t', stream_callback)
end

local function event_callback_factory()
    local ffi = require('ffi')
    local radio = require('radio')

    local function event_callback(eventId, tuner, params, cbContext)
        -- Do nothing for now
    end

    return ffi.cast('sdrplay_api_EventCallback_t', event_callback)
end

function SDRplaySource:run()
    local ret

    -- Initialize the SDRplay in our own running process
    self:initialize_sdrplay()

    -- Create pipe mux for control socket
    local pipe_mux = pipe.PipeMux({}, {}, self.control_socket)

    -- Prepare callbacks
    local stream_callback, stream_callback_state = async.callback(stream_callback_factory, unpack(self.outputs[1]:filenos()))
    local event_callback, event_callback_state = async.callback(event_callback_factory)
    local callback_fns = ffi.new("sdrplay_api_CallbackFnsT")
    callback_fns.StreamACbFn = stream_callback
    callback_fns.EventCbFn = event_callback

    -- Start stream
    ret = libsdrplay_api.sdrplay_api_Init(self.device.dev, callback_fns, nil)
    if ret ~= ffi.C.sdrplay_api_Success then
        error("sdrplay_api_Init(): " .. libsdrplay_format_error(ret, self.device))
    end

    -- Wait for shutdown from control socket
    while true do
        -- Read control socket
        local _, _, shutdown = pipe_mux:read()
        if shutdown then
            break
        end
    end

    -- Stop stream
    ret = libsdrplay_api.sdrplay_api_Uninit(self.device.dev)
    if ret ~= ffi.C.sdrplay_api_Success then
        error("sdrplay_api_Uninit(): " .. libsdrplay_format_error(ret, self.device))
    end

    -- Release device
    ret = libsdrplay_api.sdrplay_api_ReleaseDevice(self.device)
    if ret ~= ffi.C.sdrplay_api_Success then
        error("sdrplay_api_ReleaseDevice(): " .. libsdrplay_format_error(ret, self.device))
    end

    -- Close API
    ret = libsdrplay_api.sdrplay_api_Close()
    if ret ~= ffi.C.sdrplay_api_Success then
        error("sdrplay_api_Close(): " .. libsdrplay_format_error(ret))
    end
end

else

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
    local pipe = require('radio.core.pipe')

    -- Convert fds on stack to Pipe objects
    local output_pipes = {}
    for i, fd in ipairs({...}) do
        output_pipes[i] = pipe.Pipe()
        output_pipes[i]:initialize(radio.types.ComplexFloat32, nil, fd)
    end

    -- Create PipeMux for write multiplexing
    local pipe_mux = pipe.PipeMux({}, {output_pipes})

    -- Create output vector
    local out = radio.types.ComplexFloat32.vector()

    local function stream_callback(xi, xq, firstSampleNum, grChanged, rfChanged, fsChanged, numSamples, reset, hwRemoved, cbContext)
        -- Resize output vector
        out:resize(numSamples)

        -- Convert raw int16 samples to complex float32 samples
        for i = 0, out.length-1 do
            out.data[i].real = xi[i]*1.0/32767.5
            out.data[i].imag = xq[i]*1.0/32767.5
        end

        -- Write to output pipes
        local eof, eof_pipe = pipe_mux:write({out})
        if eof then
            io.stderr:write("[SDRplaySource] Downstream block terminated unexpectedly.\n")
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
    local api_bandwidth = self.bandwidth and libmirsdrapi_compute_bandwidth_closest(self.bandwidth) or libmirsdrapi_compute_bandwidth_closest(self.rate)

    debug.printf("[SDRplaySource] Frequency: %u Hz, Sample rate: %u Hz\n", self.frequency, self.rate)
    debug.printf("[SDRplaySource] Requested Bandwidth: %u Hz, Actual Bandwidth: %u Hz\n", self.bandwidth or self.rate, api_bandwidth*1e3)

    -- Create pipe mux for control socket
    local pipe_mux = pipe.PipeMux({}, {}, self.control_socket)

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

    -- Wait for shutdown from control socket
    while true do
        -- Read control socket
        local _, _, shutdown = pipe_mux:read()
        if shutdown then
            break
        end
    end

    -- Stop stream
    ret = libmirsdrapi_rsp.mir_sdr_StreamUninit()
    if ret ~= 0 then
        error("mir_sdr_Init(): " .. libmirsdrapi_strerror(ret))
    end
end

end

return SDRplaySource
