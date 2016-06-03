local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local types = require('radio.types')

local RawFileSource = block.factory("RawFileSource")

function RawFileSource:instantiate(file, data_type, rate, repeat_on_eof)
    if type(file) == "string" then
        self.filename = file
    elseif type(file) == "number" then
        self.fd = file
    else
        self.file = file
    end

    self.type = data_type
    self.rate = rate
    self.repeat_on_eof = (repeat_on_eof == nil) and false or repeat_on_eof

    self:add_type_signature({}, {block.Output("out", data_type)})
end

function RawFileSource:get_rate()
    return self.rate
end

-- File I/O
ffi.cdef[[
    typedef struct FILE FILE;
    FILE *fopen(const char *path, const char *mode);
    FILE *fdopen(int fd, const char *mode);
    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    void rewind(FILE *stream);
    int feof(FILE *stream);
    int ferror(FILE *stream);
    int fclose(FILE *stream);

    void *memmove(void *dest, const void *src, size_t n);
]]

function RawFileSource:initialize()
    if self.filename then
        self.file = ffi.C.fopen(self.filename, "rb")
        if self.file == nil then
            error("fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    elseif self.fd then
        self.file = ffi.C.fdopen(self.fd, "rb")
        if self.file == nil then
            error("fdopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end

    -- Register open file
    self.files[self.file] = true

    -- Allocate buffer
    self.buf_capacity = 262144
    self.rawbuf = platform.alloc(self.buf_capacity)
    self.buf = ffi.cast("uint8_t *", self.rawbuf)
    self.buf_offset = 0
    self.buf_size = 0
end

function RawFileSource:process()
    -- Shift samples down
    local unread_length = self.buf_size - self.buf_offset
    if unread_length > 0 then
        ffi.C.memmove(self.buf, self.buf + self.buf_offset, unread_length)
    end

    -- Read from file
    local bytes_read = tonumber(ffi.C.fread(self.buf, 1, self.buf_capacity - unread_length, self.file))
    if bytes_read < (self.buf_capacity - unread_length) then
        if bytes_read == 0 and ffi.C.feof(self.file) ~= 0 then
            if self.repeat_on_eof then
                ffi.C.rewind(self.file)
            else
                return nil
            end
        else
            if ffi.C.ferror(self.file) ~= 0 then
                error("fread(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end
        end
    end

    -- Update size and reset unread offset
    self.buf_size = unread_length + bytes_read
    self.buf_offset = 0

    -- Deserialize as many elements as possible
    local count = self.type.deserialize_count(self.buf, self.buf_size)
    local samples, size = self.type.deserialize_partial(self.buf, count)
    self.buf_offset = size

    return samples
end

function RawFileSource:cleanup()
    if self.filename then
        if ffi.C.fclose(self.file) ~= 0 then
            error("fclose(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end
end

return RawFileSource
