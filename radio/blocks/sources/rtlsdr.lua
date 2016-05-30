local ffi = require('ffi')

local block = require('radio.core.block')
local platform = require('radio.core.platform')
local types = require('radio.types')

local RtlSdrSource = block.factory("RtlSdrSource")

function RtlSdrSource:instantiate(frequency, rate, options)
    self.frequency = frequency
    self.rate = rate
    self.options = options or {}

    self.autogain = (self.options.autogain == nil) and false or self.options.autogain
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
    int rtlsdr_read_sync(rtlsdr_dev_t *dev, void *buf, int len, int *n_read);
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

    -- Set sample rate
    ret = librtlsdr.rtlsdr_set_sample_rate(self.dev[0], self.rate)
    if ret ~= 0 then
        error("rtlsdr_set_sample_rate(): " .. tostring(ret))
    end

    -- Set frequency
    ret = librtlsdr.rtlsdr_set_center_freq(self.dev[0], self.frequency)
    if ret ~= 0 then
        error("rtlsdr_set_center_freq(): " .. tostring(ret))
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

    -- Reset endpoint buffer
    ret = librtlsdr.rtlsdr_reset_buffer(self.dev[0])
    if ret ~= 0 then
        error("rtlsdr_reset_buffer(): " .. tostring(ret))
    end

    -- Allocate read buffer
    self.buf_size = 65536
    self.rawbuf = platform.alloc(self.buf_size)
    self.buf = ffi.cast("uint8_t *", self.rawbuf)
    self.n_read = ffi.new("int [1]")
end

function RtlSdrSource:process()
    -- Initialize the rtlsdr in our own running process
    if not self.dev then
        self:initialize_rtlsdr()
    end

    -- Read buffer
    local ret = librtlsdr.rtlsdr_read_sync(self.dev[0], self.buf, self.buf_size, self.n_read)
    if ret ~= 0 then
        error("rtlsdr_read_sync(): " .. tostring(ret))
    elseif self.n_read[0] ~= self.buf_size then
        error("Short read. Aborting...")
    end

    -- Convert to complex u8 to complex floats
    local out = types.ComplexFloat32.vector(self.buf_size/2)
    for i = 0, out.length-1 do
        out.data[i].real = (self.buf[2*i]   - 127.5) * (1/127.5)
        out.data[i].imag = (self.buf[2*i+1] - 127.5) * (1/127.5)
    end

    return out
end

return RtlSdrSource
