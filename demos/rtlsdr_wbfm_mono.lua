local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <FM radio frequency>\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])
local tune_offset = -200e3
local bandwidth = 15e3

local top = radio.CompositeBlock()
local b0 = radio.RtlSdrSource(frequency + tune_offset, 1102500, {autogain = true})
local b1 = radio.TunerBlock(tune_offset, 200e3, 5)
local b2 = radio.FrequencyDiscriminatorBlock(6.0)
local b3 = radio.LowpassFilterBlock(128, bandwidth)
local b4 = radio.FMDeemphasisFilterBlock(75e-6)
local b5 = radio.DecimatorBlock(5)
local b6 = radio.PulseAudioSink()

local p1 = radio.GnuplotSpectrumSink(2048, 'Demodulated FM Spectrum', {reference_level = -120, yrange = {0, 80}})

top:connect(b0, b1, b2, b3, b4, b5, b6)
top:connect(b2, p1)
top:run()
