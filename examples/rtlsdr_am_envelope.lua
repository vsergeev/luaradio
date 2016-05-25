local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <frequency> [audio gain]\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])
local tune_offset = -100e3
local bandwidth = 5e3
local gain = tonumber(arg[2]) or 1.0

local top = radio.CompositeBlock()
local source = radio.RtlSdrSource(frequency + tune_offset, 1102500)
local tuner = radio.TunerBlock(tune_offset, 2*bandwidth, 50)
local am_demod = radio.ComplexMagnitudeBlock()
local af_filter = radio.LowpassFilterBlock(128, bandwidth)
local af_gain = radio.MultiplyConstantBlock(gain)
local sink = radio.PulseAudioSink(1)

local plot1 = radio.GnuplotSpectrumSink(2048, 'RF Spectrum', {yrange = {-120, -40}})
local plot2 = radio.GnuplotSpectrumSink(2048, 'AF Spectrum', {yrange = {-120, -20}, xrange = {0, bandwidth}, update_time = 0.05})

top:connect(source, tuner, am_demod, af_filter, af_gain, sink)
top:connect(tuner, plot1)
top:connect(af_filter, plot2)
top:run()
