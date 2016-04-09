local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <FM radio frequency>\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])
local offset = -200e3
local bandwidth = 15e3

local top = radio.CompositeBlock()
local source = radio.RtlSdrSource(frequency + offset, 1102500, {autogain = true})
local tuner = radio.TunerBlock(offset, 200e3, 5)
local fm_demod = radio.FrequencyDiscriminatorBlock(6.0)
local hilbert = radio.HilbertTransformBlock(257)
local delay = radio.DelayBlock(129)
local pilot_filter = radio.ComplexBandpassFilterBlock(129, {18e3, 20e3})
local pilot_pll = radio.PLLBlock(100, 19e3-50, 19e3+50, 2)
local mixer = radio.MultiplyConjugateBlock()
-- L+R
local lpr_filter = radio.LowpassFilterBlock(128, bandwidth)
local lpr_am_demod = radio.ComplexToRealBlock()
-- L-R
local lmr_filter = radio.LowpassFilterBlock(128, bandwidth)
local lmr_am_demod = radio.ComplexToRealBlock()
-- L
local l_summer = radio.SumBlock()
local l_af_deemphasis = radio.FMDeemphasisFilterBlock(75e-6)
local l_decimator = radio.DecimatorBlock(5)
-- R
local r_subtractor = radio.SubtractBlock()
local r_af_deemphasis = radio.FMDeemphasisFilterBlock(75e-6)
local r_decimator = radio.DecimatorBlock(5)
-- Sink
local sink = radio.PulseAudioSink(2)

local plot1 = radio.GnuplotSpectrumSink(2048, 'Demodulated FM Spectrum', {yrange = {-120, -40}})
local plot2 = radio.GnuplotSpectrumSink(2048, 'L+R AF Spectrum', {yrange = {-160, -40}, xrange = {0, bandwidth}, update_time = 0.05})
local plot3 = radio.GnuplotSpectrumSink(2048, 'L-R AF Spectrum', {yrange = {-160, -40}, xrange = {0, bandwidth}, update_time = 0.05})

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
top:connect(l_summer, l_af_deemphasis, l_decimator)
top:connect(r_subtractor, r_af_deemphasis, r_decimator)
top:connect(l_decimator, 'out', sink, 'in1')
top:connect(r_decimator, 'out', sink, 'in2')
top:connect(fm_demod, plot1)
top:connect(lpr_am_demod, plot2)
top:connect(lmr_am_demod, plot3)
top:run()
