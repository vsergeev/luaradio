local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <frequency>\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])
local ifreq = 50e3
local bandwidth = 5e3

-- Blocks
local source = radio.RtlSdrSource(frequency - ifreq, 1102500)
local rf_decimator = radio.DecimatorBlock(5)
local if_filter = radio.ComplexBandpassFilterBlock(129, {ifreq - bandwidth, ifreq + bandwidth})
local pll = radio.PLLBlock(1000, ifreq - 100, ifreq + 100)
local mixer = radio.MultiplyConjugateBlock()
local am_demod = radio.ComplexToRealBlock()
local dcr_filter = radio.SinglepoleHighpassFilterBlock(100)
local af_filter = radio.LowpassFilterBlock(128, bandwidth)
local af_downsampler = radio.DownsamplerBlock(10)
local af_gain = radio.AGCBlock('slow')
local sink = os.getenv('DISPLAY') and radio.PulseAudioSink(1) or radio.WAVFileSink('am_synchronous.wav', 1)

-- Plotting sinks
local plot1 = radio.GnuplotSpectrumSink(2048, 'RF Spectrum', {xrange = {ifreq - 3*bandwidth,
                                                                        ifreq + 3*bandwidth},
                                                              yrange = {-120, -40}})
local plot2 = radio.GnuplotSpectrumSink(2048, 'AF Spectrum', {yrange = {-120, -40},
                                                              xrange = {0, bandwidth},
                                                              update_time = 0.05})

-- Connections
local top = radio.CompositeBlock()
top:connect(source, rf_decimator, if_filter)
top:connect(if_filter, pll)
top:connect(if_filter, 'out', mixer, 'in1')
top:connect(pll, 'out', mixer, 'in2')
top:connect(mixer, am_demod, dcr_filter, af_filter, af_downsampler, af_gain, sink)
if os.getenv('DISPLAY') then
    top:connect(rf_decimator, plot1)
    top:connect(af_downsampler, plot2)
end

top:run()
