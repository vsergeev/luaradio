local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <frequency>\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])
local tune_offset = -100e3
local deviation = 5e3
local bandwidth = 4e3

-- Blocks
local source = radio.RtlSdrSource(frequency + tune_offset, 1102500)
local tuner = radio.TunerBlock(tune_offset, 2*(deviation+bandwidth), 50)
local fm_demod = radio.FrequencyDiscriminatorBlock(deviation/bandwidth)
local af_filter = radio.LowpassFilterBlock(128, bandwidth)
local sink = os.getenv('DISPLAY') and radio.PulseAudioSink(1) or radio.WAVFileSink('nbfm.wav', 1)

-- Plotting sinks
local plot1 = radio.GnuplotSpectrumSink(2048, 'RF Spectrum', {yrange = {-120, -40}})
local plot2 = radio.GnuplotSpectrumSink(2048, 'AF Spectrum', {yrange = {-120, -40},
                                                              xrange = {0, bandwidth},
                                                              update_time = 0.05})

-- Connections
local top = radio.CompositeBlock()
top:connect(source, tuner, fm_demod, af_filter, sink)
if os.getenv('DISPLAY') then
    top:connect(tuner, plot1)
    top:connect(af_filter, plot2)
end

top:run()
