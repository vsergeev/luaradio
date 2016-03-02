local ffi = require('ffi')

local block = require('radio.core.block')

local RawFileSink = block.factory("RawFileSink")

function RawFileSink:instantiate(file)
    if type(file) == "number" then
        self.fd = file
    else
        self.filename = file
    end

    -- Accept all input types
    self:add_type_signature({block.Input("in", function (type) return true end)}, {})
end

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    FILE *fdopen(int fd, const char *mode);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
]]

function RawFileSink:initialize()
    if self.filename then
        self.file = ffi.C.fopen(self.filename, "wb")
        assert(self.file ~= nil, "fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    else
        self.file = ffi.C.fdopen(self.fd, "wb")
        assert(self.file ~= nil, "fdopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
end

function RawFileSink:process(x)
    local data, size = x.type.serialize(x)

    -- Write to file
    local bytes_written = ffi.C.fwrite(data, 1, size, self.file)
    assert(bytes_written == size, "fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

return {RawFileSink = RawFileSink}
