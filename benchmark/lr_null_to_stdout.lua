local NullSourceBlock = require('blocks.sources.nullsource').NullSourceBlock
local FileDescriptorSinkBlock = require('blocks.sinks.filedescriptorsink').FileDescriptorSinkBlock
local CompositeBlock = require('blocks.composite').CompositeBlock

local src = NullSourceBlock()
local dst = FileDescriptorSinkBlock(1)
local top = CompositeBlock(true)

top:connect(src, "out", dst, "in")
top:run()
