local NullSourceBlock = require('blocks.sources.nullsource').NullSourceBlock
local FIRFilterBlock = require('blocks.signal.firfilter').FIRFilterBlock
local FileDescriptorSinkBlock = require('blocks.sinks.filedescriptorsink').FileDescriptorSinkBlock
local CompositeBlock = require('blocks.composite').CompositeBlock

function random_taps(n)
    taps = {}
    for i = 1, n do
        taps[i] = math.random()
    end
    return taps
end

local src = NullSourceBlock()
local filter1 = FIRFilterBlock(random_taps(256))
local filter2 = FIRFilterBlock(random_taps(256))
local filter3 = FIRFilterBlock(random_taps(256))
local filter4 = FIRFilterBlock(random_taps(256))
local filter5 = FIRFilterBlock(random_taps(256))
local dst = FileDescriptorSinkBlock(1)
local top = CompositeBlock(true)

top:connect(src, "out", filter1, "in")
top:connect(filter1, "out", filter2, "in")
top:connect(filter2, "out", filter3, "in")
top:connect(filter3, "out", filter4, "in")
top:connect(filter4, "out", filter5, "in")
top:connect(filter5, "out", dst, "in")
top:run()
