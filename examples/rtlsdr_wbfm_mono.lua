local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <FM radio frequency>\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])
local tune_offset = -250e3

-- Blocks
local source = radio.RtlSdrSource(frequency + tune_offset, 1102500)
local tuner = radio.TunerBlock(tune_offset, 200e3, 5)
local fm_demod = radio.FrequencyDiscriminatorBlock(1.25)
local af_filter = radio.LowpassFilterBlock(128, 15e3)
local af_deemphasis = radio.FMDeemphasisFilterBlock(75e-6)
local af_downsampler = radio.DownsamplerBlock(5)
local sink = os.getenv('DISPLAY') and radio.PulseAudioSink(1) or radio.WAVFileSink('wbfm_mono.wav', 1)

-- Plotting sinks
local plot1 = radio.GnuplotSpectrumSink(2048, 'Demodulated FM Spectrum', {yrange = {-120, -40}})
local plot2 = radio.GnuplotSpectrumSink(2048, 'L+R AF Spectrum', {yrange = {-120, -40},
                                                                  xrange = {0, 15e3},
                                                                  update_time = 0.05})

-- Connections
local top = radio.CompositeBlock()
top:connect(source, tuner, fm_demod, af_filter, af_deemphasis, af_downsampler, sink)
if os.getenv('DISPLAY') then
    top:connect(fm_demod, plot1)
    top:connect(af_deemphasis, plot2)
end

top:run()
