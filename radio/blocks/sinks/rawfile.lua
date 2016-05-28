local ffi = require('ffi')

local block = require('radio.core.block')

local RawFileSink = block.factory("RawFileSink")

function RawFileSink:instantiate(file)
    if type(file) == "string" then
        self.filename = file
    elseif type(file) == "number" then
        self.fd = file
    else
        self.file = file
    end

    -- Accept all input types
    self:add_type_signature({block.Input("in", function (type) return true end)}, {})
end

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    int fileno(FILE *stream);
    ssize_t write(int fd, const void *buf, size_t count);
    int fclose(FILE *stream);
]]

function RawFileSink:initialize()
    if self.filename then
        self.file = ffi.C.fopen(self.filename, "wb")
        if self.file == nil then
            error("fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    if not self.fd then
        self.fd = ffi.C.fileno(self.file)
        if self.fd < 0 then
            error("fileno(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    -- Register open file
    self.files[self.fd] = true
end

function RawFileSink:process(x)
    local data, size = x.type.serialize(x)

    -- Write to file
    if ffi.C.write(self.fd, data, size) ~= size then
        error("write(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
end

function RawFileSink:cleanup()
    if self.filename then
        if ffi.C.fclose(self.file) ~= 0 then
            error("fclose(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end
end

return RawFileSink
