local ffi = require('ffi')

local block = require('block')
local ComplexFloat32Type = require('types.complexfloat32').ComplexFloat32Type

local FileDescriptorSinkBlock = block.BlockFactory("FileDescriptorSinkBlock")

function FileDescriptorSinkBlock:instantiate(fd)
    self.fd = fd

    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {})
end

ffi.cdef[[
    int write(int fd, const void *buf, size_t count);
]]

function FileDescriptorSinkBlock:process(x)
    assert(ffi.C.write(self.fd, x.data, x.size) == x.size, "write(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

return {FileDescriptorSinkBlock = FileDescriptorSinkBlock}
