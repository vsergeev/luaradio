local ffi = require('ffi')

require('types')
local pipe = require('pipe')
local block = require('block')

local FileIQSourceBlock = block.BlockFactory("FileIQSourceBlock")

function FileIQSourceBlock:instantiate(filename, format, rate, chunksize)
    assert(format == "f32le", "Only little endian 32-bit float format supported.")

    self._filename = filename
    self._format = format
    self._rate = rate
    self._chunksize = chunksize or 4096

    self.inputs = {}
    self.outputs = {pipe.PipeOutput("out", ComplexIntegerType, rate)}
end

ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
]]

function FileIQSourceBlock:initialize()
    self.f = ffi.C.fopen(self._filename, "rb")
end

function FileIQSourceBlock:process()
    local samples = ComplexIntegerType.alloc(self._chunksize)
    ffi.C.fread(samples.data, 1, samples.raw_length, self.f)
    return samples
end

return {FileIQSourceBlock = FileIQSourceBlock}
