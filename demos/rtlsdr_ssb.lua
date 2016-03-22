local radio = require('radio')

if #arg < 2 then
    io.stderr:write("Usage: " .. arg[0] .. " <frequency> <sideband> [audio gain]\n")
    os.exit(1)
end

assert(arg[2] == "usb" or arg[2] == "lsb", "Sideband should be 'lsb' or 'usb'.")

local frequency = tonumber(arg[1])
local sideband = arg[2]
local ifreq = 50e3
local bandwidth = 3e3
local gain = tonumber(arg[3]) or 1.0

local top = radio.CompositeBlock()
local source = radio.RtlSdrSource(frequency - ifreq, 1102500)
local rf_decimator = radio.DecimatorBlock(5)
local sb_filter = radio.BandpassFilterBlock(257, (sideband == "lsb") and {ifreq - bandwidth, ifreq} or {ifreq, ifreq + bandwidth})
local translator = radio.FrequencyTranslatorBlock(-ifreq)
local am_demod = radio.ComplexToRealBlock()
local af_gain = radio.MultiplyConstantBlock(gain)
local af_filter = radio.LowpassFilterBlock(256, bandwidth)
local af_decimator = radio.DecimatorBlock(10)
local sink = radio.PulseAudioSink()

local plot1 = radio.GnuplotSpectrumSink(2048, 'RF Spectrum', {xrange = {ifreq - 6*bandwidth, ifreq + 6*bandwidth}, yrange = {-120, -40}})
local plot2 = radio.GnuplotSpectrumSink(2048, 'AF Spectrum', {yrange = {-160, -40}, xrange = {0, bandwidth}, update_time = 0.05})

top:connect(source, rf_decimator, sb_filter, translator, am_demod, af_gain, af_filter, af_decimator, sink)
top:connect(rf_decimator, plot1)
top:connect(af_decimator, plot2)
top:run()
