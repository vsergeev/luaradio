local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <frequency>\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])
local tune_offset = -100e3
local bandwidth = 5e3

-- Blocks
local source = radio.RtlSdrSource(frequency + tune_offset, 1102500)
local tuner = radio.TunerBlock(tune_offset, 2*bandwidth, 50)
local am_demod = radio.ComplexMagnitudeBlock()
local dcr_filter = radio.SinglepoleHighpassFilterBlock(100)
local af_filter = radio.LowpassFilterBlock(128, bandwidth)
local af_gain = radio.AGCBlock('slow')
local sink = os.getenv('DISPLAY') and radio.PulseAudioSink(1) or radio.WAVFileSink('am_envelope.wav', 1)

-- Plotting sinks
local plot1 = radio.GnuplotSpectrumSink(2048, 'RF Spectrum', {yrange = {-120, -40}})
local plot2 = radio.GnuplotSpectrumSink(2048, 'AF Spectrum', {yrange = {-120, -40},
                                                              xrange = {0, bandwidth},
                                                              update_time = 0.05})

-- Connections
local top = radio.CompositeBlock()
top:connect(source, tuner, am_demod, dcr_filter, af_filter, af_gain, sink)
if os.getenv('DISPLAY') then
    top:connect(tuner, plot1)
    top:connect(af_gain, plot2)
end

top:run()
