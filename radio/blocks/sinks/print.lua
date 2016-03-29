local ffi = require('ffi')

local block = require('radio.core.block')

local PrintSink = block.factory("PrintSink")

function PrintSink:instantiate(file)
    if type(file) == "number" then
        self.fd = file
    elseif type(file) == "string" then
        self.filename = file
    elseif file == nil then
        -- Default to io.stdout
        self.file = io.stdout
    end

    -- Accept all input types that implement __tostring()
    self:add_type_signature({block.Input("in", function (type) return type.__tostring ~= nil end)}, {})
end

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    FILE *fdopen(int fd, const char *mode);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fclose(FILE *stream);
    int fflush(FILE *stream);
]]

function PrintSink:initialize()
    if self.filename then
        self.file = ffi.C.fopen(self.filename, "wb")
        assert(self.file ~= nil, "fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    elseif self.fd then
        self.file = ffi.C.fdopen(self.fd, "wb")
        assert(self.file ~= nil, "fdopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    elseif self.file then
        -- Noop
    end
end

function PrintSink:process(x)
    for i = 0, x.length-1 do
        local s = tostring(x.data[i]) .. "\n"

        -- Write to file
        local bytes_written = ffi.C.fwrite(s, 1, #s, self.file)
        assert(bytes_written == #s, "fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Flush file
    assert(ffi.C.fflush(self.file) == 0, "fflush(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

function PrintSink:cleanup()
    if self.filename then
        assert(ffi.C.fclose(self.file) == 0, "fclose(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    elseif self.fd then
        assert(ffi.C.fflush(self.file) == 0, "fflush(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    else
        self.file:flush()
    end
end

return {PrintSink = PrintSink}
