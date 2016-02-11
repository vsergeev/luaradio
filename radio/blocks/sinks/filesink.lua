local ffi = require('ffi')

local block = require('radio.core.block')

local FileSinkBlock = block.factory("FileSinkBlock")

function FileSinkBlock:instantiate(filename)
    self.filename = filename

    -- Accept all input types
    self:add_type_signature({block.Input("in", function (type) return true end)}, {})
end

ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
]]

function FileSinkBlock:initialize()
    self.file = ffi.C.fopen(self.filename, "w")
    assert(self.file ~= nil, "fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

function FileSinkBlock:process(x)
    assert(ffi.C.fwrite(x.data, 1, x.size, self.file) == x.size, "fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

return {FileSinkBlock = FileSinkBlock}
