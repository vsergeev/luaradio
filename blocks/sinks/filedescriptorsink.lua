local ffi = require('ffi')

require('types')
local pipe = require('pipe')
local block = require('block')

local FileDescriptorSinkBlock = block.BlockFactory("FileDescriptorSinkBlock")

function FileDescriptorSinkBlock:instantiate(fd)
    self.fd = fd

    self.inputs = {pipe.PipeInput("in", AnyType)}
    self.outputs = {}
end

ffi.cdef[[
    int write(int fd, const void *buf, size_t count);
]]

function FileDescriptorSinkBlock:process(x)
    ffi.C.write(self.fd, x.data, x.raw_length)
end

return {FileDescriptorSinkBlock = FileDescriptorSinkBlock}
