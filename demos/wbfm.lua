local radio = require('radio')

if #arg < 2 then
    io.stderr:write("Usage: " .. arg[0] .. " <IQ recording (u8)> <sample rate> <frequency offset>\n")
    os.exit(1)
end

local sample_rate = tonumber(arg[2])
local offset = tonumber(arg[3])

local b0 = radio.FileIQSourceBlock(arg[1], 'u8', sample_rate)
local b1 = radio.TunerBlock(offset, 190e3, 10)
local b2 = radio.FrequencyDiscriminatorBlock(10.0)
local b3 = radio.FMDeemphasisFilterBlock(75e-6)
local b4 = radio.LowpassFilterBlock(64, 15e3)
local b5 = radio.DownsamplerBlock(4)
local b6 = radio.FileDescriptorSinkBlock(1)
local top = radio.CompositeBlock()

top:connect(b0, b1, b2, b3, b4, b5, b6)
top:run(true)
