local ffi = require('ffi')

local block = require('radio.core.block')
local FileDescriptorSource = require('radio.blocks.sources.filedescriptor').FileDescriptorSource

local FileSource = block.factory("FileSource", FileDescriptorSource)

function FileSource:instantiate(filename, format, rate)
    self.filename = filename
    FileDescriptorSource.instantiate(self, nil, format, rate)
end

-- File I/O
ffi.cdef[[
    FILE *fopen(const char *path, const char *mode);
    int fileno(FILE *stream);
]]

function FileSource:initialize()
    self.file = ffi.C.fopen(self.filename, "rb")
    assert(self.file ~= nil, "fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    self.fd = ffi.C.fileno(self.file)
end

return {FileSource = FileSource}
