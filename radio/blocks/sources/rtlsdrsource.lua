local ffi = require('ffi')

local block = require('radio.core.block')
local vector = require('radio.core.vector')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type

local RtlSdrSourceBlock = block.factory("RtlSdrSourceBlock")

function RtlSdrSourceBlock:instantiate(frequency, rate)
    self._frequency = frequency
    self._rate = rate

    self:add_type_signature({}, {block.Output("out", ComplexFloat32Type)})
end

function RtlSdrSourceBlock:get_rate()
    return self._rate
end

ffi.cdef[[
    typedef struct rtlsdr_dev rtlsdr_dev_t;

    int rtlsdr_open(rtlsdr_dev_t **dev, uint32_t index);
    int rtlsdr_close(rtlsdr_dev_t *dev);

    int rtlsdr_set_sample_rate(rtlsdr_dev_t *dev, uint32_t rate);
    int rtlsdr_set_center_freq(rtlsdr_dev_t *dev, uint32_t freq);
    int rtlsdr_set_tuner_gain_mode(rtlsdr_dev_t *dev, int manual);
    int rtlsdr_set_freq_correction(rtlsdr_dev_t *dev, int ppm);

    int rtlsdr_reset_buffer(rtlsdr_dev_t *dev);
    int rtlsdr_read_sync(rtlsdr_dev_t *dev, void *buf, int len, int *n_read);
]]
local librtlsdr = ffi.load("librtlsdr.so")

function RtlSdrSourceBlock:initialize()
    self._dev = ffi.new("rtlsdr_dev_t *[1]")

    -- Open device
    assert(librtlsdr.rtlsdr_open(self._dev, 0) == 0, "rtlsdr_open() failed.")

    -- Set sample rate
    assert(librtlsdr.rtlsdr_set_sample_rate(self._dev[0], self._rate) == 0, "rtlsdr_set_sample_rate() failed.")

    -- Set frequency
    assert(librtlsdr.rtlsdr_set_center_freq(self._dev[0], self._frequency) == 0, "rtlsdr_set_center_freq() failed.")

    -- Set autogain
    assert(librtlsdr.rtlsdr_set_tuner_gain_mode(self._dev[0], 0) == 0, "rtlsdr_set_tuner_gain_mode() failed.")

    -- Reset endpoint buffer
    assert(librtlsdr.rtlsdr_reset_buffer(self._dev[0]) == 0, "rtlsdr_reset_buffer() failed.")

    -- Allocate read buffer
    self._buf_size = 65536
    self._rawbuf = ffi.gc(ffi.C.aligned_alloc(vector.PAGE_SIZE, self._buf_size), ffi.C.free)
    self._buf = ffi.cast("uint8_t *", self._rawbuf)
    self._n_read = ffi.new("int [1]")
end

function RtlSdrSourceBlock:process()
    -- Read buffer
    assert(librtlsdr.rtlsdr_read_sync(self._dev[0], self._buf, self._buf_size, self._n_read) == 0, "rtlsdr_read_sync() failed.")
    assert(self._n_read[0] == self._buf_size, "Short read. Aborting...")

    -- Convert to complex u8 to complex floats
    local out = ComplexFloat32Type.vector(self._buf_size/2)
    for i = 0, out.length-1 do
        out.data[i].real = (self._buf[2*i]   - 127.5) * (1/127.5)
        out.data[i].imag = (self._buf[2*i+1] - 127.5) * (1/127.5)
    end

    return out
end

return {RtlSdrSourceBlock = RtlSdrSourceBlock}
