local os = require('os')
local io = require('io')
local radio = require('radio')

if #arg < 2 then
    io.stderr:write("Usage: " .. arg[0] .. " <IQ recording (u8)> <sample rate> <frequency offset>\n")
    os.exit(1)
end

local sample_rate = tonumber(arg[2])
local frequency_offset = tonumber(arg[3])

local b0 = radio.FileIQSourceBlock(arg[1], 'u8', sample_rate)
local b1 = radio.SignalSourceBlock({signal='exponential', frequency=frequency_offset}, sample_rate)
local b2 = radio.MultiplierBlock()
local b3 = radio.LowpassFilterBlock(64, 190e3)
local b4 = radio.DownsamplerBlock(10)
local b5 = radio.FrequencyDiscriminatorBlock(10.0)
local b6 = radio.FMDeemphasisFilterBlock(75e-6)
local b7 = radio.LowpassFilterBlock(64, 15e3)
local b8 = radio.DownsamplerBlock(4)
local b9 = radio.FileDescriptorSinkBlock(1)
local top = radio.CompositeBlock()

top:connect(b0, "out", b2, "in1")
top:connect(b1, "out", b2, "in2")
top:connect(b2, b3, b4, b5, b6, b7, b8, b9)
top:run(true)
