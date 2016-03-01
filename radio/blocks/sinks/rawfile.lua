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

ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    int fileno(FILE *stream);
    int write(int fd, const void *buf, size_t count);
]]

function RawFileSink:initialize()
    if self.filename then
        self.file = ffi.C.fopen(self.filename, "w")
        assert(self.file ~= nil, "fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        self.fd = ffi.C.fileno(self.file)
    end
end

function RawFileSink:process(x)
    local data, size = x.type.serialize(x)
    assert(ffi.C.write(self.fd, data, size) == size, "write(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

return {RawFileSink = RawFileSink}
