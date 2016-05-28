local ffi = require('ffi')

local block = require('radio.core.block')

local JSONSink = block.factory("JSONSink")

function JSONSink:instantiate(file)
    if type(file) == "number" then
        self.fd = file
    elseif type(file) == "string" then
        self.filename = file
    elseif file == nil then
        -- Default to io.stdout
        self.file = io.stdout
    end

    -- Accept all input types that implement to_json()
    self:add_type_signature({block.Input("in", function (type) return type.to_json ~= nil end)}, {})
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

function JSONSink:initialize()
    if self.filename then
        self.file = ffi.C.fopen(self.filename, "wb")
        if self.file == nil then
            error("fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    elseif self.fd then
        self.file = ffi.C.fdopen(self.fd, "wb")
        if self.file == nil then
            error("fdopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    -- Register open file
    self.files[self.file] = true
end

function JSONSink:process(x)
    for i = 0, x.length-1 do
        local s = x.data[i]:to_json() .. "\n"

        -- Write to file
        if ffi.C.fwrite(s, 1, #s, self.file) ~= #s then
            error("fwrite(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    -- Flush file
    if ffi.C.fflush(self.file) ~= 0 then
        error("fflush(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
end

function JSONSink:cleanup()
    if self.filename then
        if ffi.C.fclose(self.file) ~= 0 then
            error("fclose(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    elseif self.fd then
        if ffi.C.fflush(self.file) ~= 0 then
            error("fflush(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    else
        self.file:flush()
    end
end

return JSONSink
