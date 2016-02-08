local radio = require('radio')

function random_taps(n)
    taps = {}
    for i = 1, n do
        taps[i] = math.random()
    end
    return taps
end

local src = radio.NullSourceBlock()
local filter1 = radio.FIRFilterBlock(random_taps(256))
local filter2 = radio.FIRFilterBlock(random_taps(256))
local filter3 = radio.FIRFilterBlock(random_taps(256))
local filter4 = radio.FIRFilterBlock(random_taps(256))
local filter5 = radio.FIRFilterBlock(random_taps(256))
local dst = radio.FileDescriptorSinkBlock(1)
local top = radio.CompositeBlock(true)

top:connect(src, "out", filter1, "in")
top:connect(filter1, "out", filter2, "in")
top:connect(filter2, "out", filter3, "in")
top:connect(filter3, "out", filter4, "in")
top:connect(filter4, "out", filter5, "in")
top:connect(filter5, "out", dst, "in")
top:run(true)
