local ffi = require('ffi')

local ComplexFloat32Type = require('types.complexfloat32').ComplexFloat32Type
local pipe = require('pipe')
local block = require('block')

local FileDescriptorSinkBlock = block.BlockFactory("FileDescriptorSinkBlock")

function FileDescriptorSinkBlock:instantiate(fd)
    self.fd = fd

    self.inputs = {pipe.PipeInput("in", ComplexFloat32Type)}
    self.outputs = {}
end

ffi.cdef[[
    int write(int fd, const void *buf, size_t count);
]]

function FileDescriptorSinkBlock:process(x)
    ffi.C.write(self.fd, x.data, x.size)
end

return {FileDescriptorSinkBlock = FileDescriptorSinkBlock}
