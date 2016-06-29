local radio = require('radio')

if #arg < 4 then
    io.stderr:write("Usage: " .. arg[0] .. " <WAV file in> <IQ f32le file out> <bandwidth> <sideband>\n")
    os.exit(1)
end

assert(arg[4] == "usb" or arg[4] == "lsb", "Sideband should be 'lsb' or 'usb'.")

local wav_filepath = arg[1]
local iq_filepath = arg[2]
local bandwidth = tonumber(arg[3])
local sideband = arg[4]

-- Blocks
local source = radio.WAVFileSource(wav_filepath, 1)
local af_filter = radio.LowpassFilterBlock(128, bandwidth)
local hilbert = radio.HilbertTransformBlock(129)
local conjugate = radio.ComplexConjugateBlock()
local sb_filter = radio.ComplexBandpassFilterBlock(129, (sideband == "lsb") and {-bandwidth, 0}
                                                                             or {0, bandwidth})
local sink = radio.IQFileSink(iq_filepath, 'f32le')

-- Connections
local top = radio.CompositeBlock()
if sideband == "lsb" then
    top:connect(source, af_filter, hilbert, conjugate, sb_filter, sink)
else
    top:connect(source, af_filter, hilbert, sb_filter, sink)
end

top:run()
