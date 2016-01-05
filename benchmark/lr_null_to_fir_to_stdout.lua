local pipeline = require('pipeline')
local NullSourceBlock = require('blocks.sources.nullsource').NullSourceBlock
local FIRFilterBlock = require('blocks.signal.firfilter').FIRFilterBlock
local FileDescriptorSinkBlock = require('blocks.sinks.filedescriptorsink').FileDescriptorSinkBlock

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

local p = pipeline.Pipeline('test')
p:connect(src, "out", filter1, "in")
p:connect(filter1, "out", filter2, "in")
p:connect(filter2, "out", filter3, "in")
p:connect(filter3, "out", filter4, "in")
p:connect(filter4, "out", filter5, "in")
p:connect(filter5, "out", dst, "in")
p:run()
