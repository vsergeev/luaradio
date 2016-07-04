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
local hilbert = radio.HilbertTransformBlock(129)
local delay = radio.DelayBlock(129)
local pilot_filter = radio.ComplexBandpassFilterBlock(129, {18e3, 20e3})
local pilot_pll = radio.PLLBlock(100, 19e3-50, 19e3+50, 2)
local mixer = radio.MultiplyConjugateBlock()
-- L+R
local lpr_filter = radio.LowpassFilterBlock(128, 15e3)
local lpr_am_demod = radio.ComplexToRealBlock()
-- L-R
local lmr_filter = radio.LowpassFilterBlock(128, 15e3)
local lmr_am_demod = radio.ComplexToRealBlock()
-- L
local l_summer = radio.AddBlock()
local l_af_deemphasis = radio.FMDeemphasisFilterBlock(75e-6)
local l_downsampler = radio.DownsamplerBlock(5)
-- R
local r_subtractor = radio.SubtractBlock()
local r_af_deemphasis = radio.FMDeemphasisFilterBlock(75e-6)
local r_downsampler = radio.DownsamplerBlock(5)
-- Sink
local sink = os.getenv('DISPLAY') and radio.PulseAudioSink(2) or radio.WAVFileSink('wbfm_stereo.wav', 2)

-- Plotting sinks
local plot1 = radio.GnuplotSpectrumSink(2048, 'Demodulated FM Spectrum', {yrange = {-120, -40}})
local plot2 = radio.GnuplotSpectrumSink(2048, 'L+R AF Spectrum', {yrange = {-120, -40},
                                                                  xrange = {0, 15e3},
                                                                  update_time = 0.05})
local plot3 = radio.GnuplotSpectrumSink(2048, 'L-R AF Spectrum', {yrange = {-120, -40},
                                                                  xrange = {0, 15e3},
                                                                  update_time = 0.05})

-- Connections
local top = radio.CompositeBlock()
top:connect(source, tuner, fm_demod, hilbert, delay)
top:connect(hilbert, pilot_filter, pilot_pll)
top:connect(delay, 'out', mixer, 'in1')
top:connect(pilot_pll, 'out', mixer, 'in2')
top:connect(delay, lpr_filter, lpr_am_demod)
top:connect(mixer, lmr_filter, lmr_am_demod)
top:connect(lpr_am_demod, 'out', l_summer, 'in1')
top:connect(lmr_am_demod, 'out', l_summer, 'in2')
top:connect(lpr_am_demod, 'out', r_subtractor, 'in1')
top:connect(lmr_am_demod, 'out', r_subtractor, 'in2')
top:connect(l_summer, l_af_deemphasis, l_downsampler)
top:connect(r_subtractor, r_af_deemphasis, r_downsampler)
top:connect(l_downsampler, 'out', sink, 'in1')
top:connect(r_downsampler, 'out', sink, 'in2')
if os.getenv('DISPLAY') then
    top:connect(fm_demod, plot1)
    top:connect(lpr_am_demod, plot2)
    top:connect(lmr_am_demod, plot3)
end

top:run()
