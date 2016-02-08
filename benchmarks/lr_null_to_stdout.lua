local radio = require('radio')

local src = radio.NullSourceBlock()
local dst = radio.FileDescriptorSinkBlock(1)
local top = radio.CompositeBlock()

top:connect(src, "out", dst, "in")
top:run(true)
