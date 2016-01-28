local ffi = require('ffi')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type

local FileIQSourceBlock = block.BlockFactory("FileIQSourceBlock")

function FileIQSourceBlock:instantiate(filename, format, rate, chunksize)
    assert(format == "f32le", "Only little endian 32-bit float format supported.")

    self._filename = filename
    self._format = format
    self._rate = rate
    self._chunksize = chunksize or 4096

    self:add_type_signature({}, {block.Output("out", ComplexFloat32Type)})
end

function FileIQSourceBlock:get_rate()
    return self._rate
end

ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
]]

function FileIQSourceBlock:initialize()
    self.f = ffi.C.fopen(self._filename, "rb")
    assert(self.f ~= nil, "fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

function FileIQSourceBlock:process()
    local samples = ComplexFloat32Type.vector(self._chunksize)
    -- FIXME interpret data
    ffi.C.fread(samples.data, 1, samples.size, self.f)
    return samples
end

return {FileIQSourceBlock = FileIQSourceBlock}
