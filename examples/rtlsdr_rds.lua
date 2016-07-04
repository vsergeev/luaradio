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
local mixer_delay = radio.DelayBlock(129)
local pilot_filter = radio.ComplexBandpassFilterBlock(129, {18e3, 20e3})
local pll_baseband = radio.PLLBlock(1500.0, 19e3-100, 19e3+100, 3.0)
local mixer = radio.MultiplyConjugateBlock()
local baseband_filter = radio.LowpassFilterBlock(128, 4e3)
local baseband_rrc = radio.RootRaisedCosineFilterBlock(101, 1, 1187.5)
local phase_corrector = radio.BinaryPhaseCorrectorBlock(8000)
local clock_demod = radio.ComplexToRealBlock()
local clock_recoverer = radio.ZeroCrossingClockRecoveryBlock(1187.5*2)
local sampler = radio.SamplerBlock()
local bit_demod = radio.ComplexToRealBlock()
local bit_slicer = radio.SlicerBlock()
local bit_decoder = radio.ManchesterDecoderBlock()
local bit_diff_decoder = radio.DifferentialDecoderBlock()
local framer = radio.RDSFramerBlock()
local decoder = radio.RDSDecoderBlock()
local sink = radio.JSONSink()

-- Plotting sinks
local plot1 = radio.GnuplotSpectrumSink(2048, 'Demodulated FM Spectrum', {yrange = {-120, -40}})
local plot2 = radio.GnuplotSpectrumSink(2048, 'BPSK Spectrum', {yrange = {-130, -60},
                                                                xrange = {-8000, 8000}})
local plot3 = radio.GnuplotXYPlotSink(1024, 'BPSK Constellation', {complex = true,
                                                                   yrange = {-0.02, 0.02},
                                                                   xrange = {-0.02, 0.02}})

-- Connections
local top = radio.CompositeBlock()
top:connect(source, tuner, fm_demod, hilbert, mixer_delay)
top:connect(hilbert, pilot_filter, pll_baseband)
top:connect(mixer_delay, 'out', mixer, 'in1')
top:connect(pll_baseband, 'out', mixer, 'in2')
top:connect(mixer, baseband_filter, baseband_rrc, phase_corrector)
top:connect(phase_corrector, clock_demod, clock_recoverer)
top:connect(phase_corrector, 'out', sampler, 'data')
top:connect(clock_recoverer, 'out', sampler, 'clock')
top:connect(sampler, bit_demod, bit_slicer, bit_decoder, bit_diff_decoder, framer, decoder, sink)
if os.getenv('DISPLAY') then
    top:connect(fm_demod, plot1)
    top:connect(baseband_rrc, plot2)
    top:connect(sampler, plot3)
end

top:run()
