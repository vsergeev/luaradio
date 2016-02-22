local ffi = require('ffi')

local block = require('radio.core.block')
local FileIQDescriptorSource = require('radio.blocks.sources.fileiqdescriptor').FileIQDescriptorSource

local FileIQSource = block.factory("FileIQSource", FileIQDescriptorSource)

function FileIQSource:instantiate(filename, format, rate)
    self.filename = filename
    FileIQDescriptorSource.instantiate(self, nil, format, rate)
end

-- File I/O
ffi.cdef[[
    FILE *fopen(const char *path, const char *mode);
    int fileno(FILE *stream);
]]

function FileIQSource:initialize()
    self.file = ffi.C.fopen(self.filename, "rb")
    assert(self.file ~= nil, "fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    self.fd = ffi.C.fileno(self.file)
end

return {FileIQSource = FileIQSource}
