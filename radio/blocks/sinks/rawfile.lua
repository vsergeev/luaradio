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
    int fileno(FILE *stream);
    int write(int fd, const void *buf, size_t count);
    int fclose(FILE *stream);
]]

function RawFileSink:initialize()
    if self.filename then
        self.file = ffi.C.fopen(self.filename, "wb")
        assert(self.file ~= nil, "fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

        self.fd = ffi.C.fileno(self.file)
        assert(self.fd < 0, "fileno(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
end

function RawFileSink:process(x)
    local data, size = x.type.serialize(x)

    -- Write to file
    local bytes_written = ffi.C.write(self.fd, data, size)
    assert(bytes_written == size, "write(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

function RawFileSink:cleanup()
    if self.filename then
        assert(ffi.C.fclose(self.file) == 0, "fclose(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
end

return {RawFileSink = RawFileSink}
