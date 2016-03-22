local radio = require('radio')

if #arg < 2 then
    io.stderr:write("Usage: " .. arg[0] .. " <frequency> <sideband> [audio gain]\n")
    os.exit(1)
end

assert(arg[2] == "usb" or arg[2] == "lsb", "Sideband should be 'lsb' or 'usb'.")

local frequency = tonumber(arg[1])
local sideband = arg[2]
local gain = tonumber(arg[3]) or 1.0
local tune_offset = -100e3
local bandwidth = 3e3

local top = radio.CompositeBlock()
local source = radio.RtlSdrSource(frequency + tune_offset, 1102500)
local tuner = radio.TunerBlock(tune_offset, 2*bandwidth, 50)
local sb_filter = radio.ComplexBandpassFilterBlock(257, (sideband == "lsb") and {0, -bandwidth} or {0, bandwidth})
local am_demod = radio.ComplexToRealBlock()
local af_gain = radio.MultiplyConstantBlock(gain)
local af_filter = radio.LowpassFilterBlock(256, bandwidth)
local sink = radio.PulseAudioSink()

local plot1 = radio.GnuplotSpectrumSink(2048, 'RF Spectrum', {xrange = {-6*bandwidth, 6*bandwidth}, yrange = {-120, -40}})
local plot2 = radio.GnuplotSpectrumSink(2048, 'AF Spectrum', {yrange = {-160, -40}, xrange = {0, bandwidth}, update_time = 0.05})

top:connect(source, tuner, sb_filter, am_demod, af_gain, af_filter, sink)
top:connect(tuner, plot1)
top:connect(af_filter, plot2)
top:run()
