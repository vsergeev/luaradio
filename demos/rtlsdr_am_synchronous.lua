local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <frequency> [audio gain]\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])
local ifreq = 50e3
local bandwidth = 5e3
local gain = tonumber(arg[2]) or 1.0

local top = radio.CompositeBlock()
local source = radio.RtlSdrSource(frequency - ifreq, 1102500)
local rf_decimator = radio.DecimatorBlock(5)
local if_filter = radio.BandpassFilterBlock(513, {ifreq - bandwidth, ifreq + bandwidth})
local pll = radio.PLLBlock(1000, ifreq - 100, ifreq + 100)
local mixer = radio.MultiplyConjugateBlock()
local am_demod = radio.ComplexToRealBlock()
local af_gain = radio.MultiplyConstantBlock(gain)
local af_filter = radio.LowpassFilterBlock(256, bandwidth)
local af_decimator = radio.DecimatorBlock(10)
local sink = radio.PulseAudioSink()

local plot1 = radio.GnuplotSpectrumSink(2048, 'RF Spectrum', {xrange = {ifreq - 3*bandwidth, ifreq + 3*bandwidth}, yrange = {-120, -40}})
local plot2 = radio.GnuplotSpectrumSink(2048, 'AF Spectrum', {yrange = {-160, -40}, xrange = {0, bandwidth}, update_time = 0.05})

top:connect(source, rf_decimator, if_filter)
top:connect(if_filter, pll)
top:connect(if_filter, 'out', mixer, 'in1')
top:connect(pll, 'out', mixer, 'in2')
top:connect(mixer, am_demod, af_gain, af_filter, af_decimator, sink)
top:connect(rf_decimator, plot1)
top:connect(af_decimator, plot2)
top:run()
