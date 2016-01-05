local pipeline = require('pipeline')
local NullSourceBlock = require('blocks.sources.nullsource').NullSourceBlock
local FileDescriptorSinkBlock = require('blocks.sinks.filedescriptorsink').FileDescriptorSinkBlock

local src = NullSourceBlock()
local dst = FileDescriptorSinkBlock(1)

local p = pipeline.Pipeline('test')
p:connect(src, "out", dst, "in")
p:run()
