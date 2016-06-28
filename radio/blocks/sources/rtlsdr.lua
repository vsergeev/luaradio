---
-- Source a complex-valued signal from an RTL-SDR dongle. This source requires
-- the librtlsdr library.
--
-- @category Sources
-- @block RtlSdrSource
-- @tparam number frequency Tuning frequency in Hz
-- @tparam number rate Sample rate in Hz
-- @tparam[opt={}] table options Additional options, specifying:
--                         * `autogain` (bool, default false)
--                         * `rf_gain` (number, default 10.0 dB)
--                         * `freq_correction` PPM (number, default 0.0)
--
-- @signature > out:ComplexFloat32
--
-- @usage
-- -- Source samples from 162.400 MHz sampled at 1 MHz, with autogain enabled
-- local src = radio.RtlSdrSource(162.400e6, 1e6, {autogain = true})
--
-- -- Source samples from 91.1 MHz sampled at 1.102500 MHz, with -1 PPM correction
-- local src = radio.RtlSdrSource(91.1e6, 1102500, {freq_correction = -1.0})
--
-- -- Source samples from 144.390 MHz sampled at 1 MHz, with RF gain of 15dB
-- local src = radio.RtlSdrSource(144.390e6, 1e6, {rf_gain = 15.0})

local ffi = require('ffi')

local block = require('radio.core.block')
local platform = require('radio.core.platform')
local types = require('radio.types')

local RtlSdrSource = block.factory("RtlSdrSource")

function RtlSdrSource:instantiate(frequency, rate, options)
    self.frequency = assert(frequency, "Missing argument #1 (frequency)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    self.options = options or {}
    self.autogain = self.options.autogain or false
    self.rf_gain = self.options.rf_gain or 10.0
    self.freq_correction = self.options.freq_correction or 0.0

    self:add_type_signature({}, {block.Output("out", types.ComplexFloat32)})
end

function RtlSdrSource:get_rate()
    return self.rate
end

ffi.cdef[[
    typedef struct rtlsdr_dev rtlsdr_dev_t;

    int rtlsdr_open(rtlsdr_dev_t **dev, uint32_t index);
    int rtlsdr_close(rtlsdr_dev_t *dev);

    int rtlsdr_set_sample_rate(rtlsdr_dev_t *dev, uint32_t rate);
    int rtlsdr_set_center_freq(rtlsdr_dev_t *dev, uint32_t freq);
    int rtlsdr_set_tuner_gain_mode(rtlsdr_dev_t *dev, int manual);
    int rtlsdr_set_agc_mode(rtlsdr_dev_t *dev, int on);
    int rtlsdr_set_tuner_gain(rtlsdr_dev_t *dev, int gain);
    int rtlsdr_set_tuner_if_gain(rtlsdr_dev_t *dev, int stage, int gain);
    int rtlsdr_set_freq_correction(rtlsdr_dev_t *dev, int ppm);

    int rtlsdr_reset_buffer(rtlsdr_dev_t *dev);

    typedef void(*rtlsdr_read_async_cb_t)(unsigned char *buf, uint32_t len, void *ctx);
    int rtlsdr_read_async(rtlsdr_dev_t *dev, rtlsdr_read_async_cb_t cb, void *ctx, uint32_t buf_num, uint32_t buf_len);
    int rtlsdr_cancel_async(rtlsdr_dev_t *dev);
]]
local librtlsdr_available, librtlsdr = pcall(ffi.load, "rtlsdr")

function RtlSdrSource:initialize()
    -- Check library is available
    if not librtlsdr_available then
        error("RtlSdrSource: librtlsdr not found. Is librtlsdr installed?")
    end
end

function RtlSdrSource:initialize_rtlsdr()
    self.dev = ffi.new("rtlsdr_dev_t *[1]")

    local ret

    -- Open device
    ret = librtlsdr.rtlsdr_open(self.dev, 0)
    if ret ~= 0 then
        error("rtlsdr_open(): " .. tostring(ret))
    end

    if self.autogain then
        -- Set autogain
        ret = librtlsdr.rtlsdr_set_tuner_gain_mode(self.dev[0], 0)
        if ret ~= 0 then
            error("rtlsdr_set_tuner_gain_mode(): " .. tostring(ret))
        end

        -- Enable AGC
        ret = librtlsdr.rtlsdr_set_agc_mode(self.dev[0], 1)
        if ret ~= 0 then
            error("rtlsdr_set_agc_mode(): " .. tostring(ret))
        end
    else
        -- Disable autogain
        ret = librtlsdr.rtlsdr_set_tuner_gain_mode(self.dev[0], 1)
        if ret ~= 0 then
            error("rtlsdr_set_tuner_gain_mode(): " .. tostring(ret))
        end

        -- Disable AGC
        ret = librtlsdr.rtlsdr_set_agc_mode(self.dev[0], 0)
        if ret ~= 0 then
            error("rtlsdr_set_agc_mode(): " .. tostring(ret))
        end

        -- Set RF gain
        ret = librtlsdr.rtlsdr_set_tuner_gain(self.dev[0], math.floor(self.rf_gain*10))
        if ret ~= 0 then
            error("rtlsdr_set_tuner_gain(): " .. tostring(ret))
        end
    end

    -- Set frequency correction
    local ret = librtlsdr.rtlsdr_set_freq_correction(self.dev[0], math.floor(self.freq_correction))
    if ret ~= 0 and ret ~= -2 then
        error("rtlsdr_set_freq_correction(): " .. tostring(ret))
    end

    -- Set frequency
    ret = librtlsdr.rtlsdr_set_center_freq(self.dev[0], self.frequency)
    if ret ~= 0 then
        error("rtlsdr_set_center_freq(): " .. tostring(ret))
    end

    -- Set sample rate
    ret = librtlsdr.rtlsdr_set_sample_rate(self.dev[0], self.rate)
    if ret ~= 0 then
        error("rtlsdr_set_sample_rate(): " .. tostring(ret))
    end

    -- Reset endpoint buffer
    ret = librtlsdr.rtlsdr_reset_buffer(self.dev[0])
    if ret ~= 0 then
        error("rtlsdr_reset_buffer(): " .. tostring(ret))
    end
end

local function read_async_callback_factory(pipes)
    local out = types.ComplexFloat32.vector()

    local function read_async_callback(buf, len, ctx)
        -- Size output vector
        out:resize(len/2)

        -- Convert to complex u8 in buf to complex floats in output vector
        for i = 0, out.length-1 do
            out.data[i].real = (buf[2*i]   - 127.5) * (1/127.5)
            out.data[i].imag = (buf[2*i+1] - 127.5) * (1/127.5)
        end

        -- Write output vector to output pipes
        for i=1, #pipes do
            pipes[i]:write(out)
        end
    end

    return read_async_callback
end

function RtlSdrSource:run()
    -- Initialize the rtlsdr in our own running process
    self:initialize_rtlsdr()

    -- Start asynchronous read
    local ret = librtlsdr.rtlsdr_read_async(self.dev[0], read_async_callback_factory(self.outputs[1].pipes), nil, 0, 32768)
    if ret ~= 0 then
        error("rtlsdr_read_async(): " .. tostring(ret))
    end
end

return RtlSdrSource
