---
-- Source a signal from a JSON file. Samples are deserialized from individual,
-- newline delimited objects. This source supports any data type that
-- implements `from_json()`.
--
-- @category Sources
-- @block JSONSource
-- @tparam string|file|int file Filename, file object, or file descriptor
-- @tparam type data_type LuaRadio data type that implements `from_json()`
-- @tparam number rate Sample rate of file
-- @tparam[opt=false] bool repeat_on_eof Repeat on end of file
--
-- @signature > out:data_type
--
-- @usage
-- -- Source AX25FrameType samples sampled at 1 Hz from a file descriptor
-- local src = radio.JSONSource(3, radio.AX25FramerBlock.AX25FrameType, 1)
--
-- -- Source AX25FrameType samples sampled at 1 Hz from a file, repeating on EOF
-- local src = radio.JSONSource('data.bin', radio.AX25FramerBlock.AX25FrameType, 1, true)

local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local types = require('radio.types')

local JSONSource = block.factory("JSONSource")

function JSONSource:instantiate(file, data_type, rate, repeat_on_eof)
    if type(file) == "string" then
        self.filename = file
    elseif type(file) == "number" then
        self.fd = file
    else
        self.file = assert(file, "Missing argument #1 (file)")
    end

    self.data_type = assert(data_type, "Missing argument #2 (data_type)")
    self.rate = assert(rate, "Missing argument #3 (rate)")
    self.repeat_on_eof = repeat_on_eof or false

    assert(data_type.to_json ~= nil, "Data type does not support JSON serialization")

    self:add_type_signature({}, {block.Output("out", data_type)})
end

function JSONSource:get_rate()
    return self.rate
end

function JSONSource:initialize()
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

    -- Create output vector
    self.out = self.data_type.vector()
end

function JSONSource:process()
    -- Shift samples down
    local unread_length = self.buf_size - self.buf_offset
    if unread_length > 0 then
        ffi.C.memmove(self.buf, self.buf + self.buf_offset, unread_length)
    end

    -- Read from file
    local bytes_read = tonumber(ffi.C.fread(self.buf + unread_length, 1, self.buf_capacity - unread_length, self.file))
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

    -- Clear output vector
    local out = self.out:resize(0)

    while self.buf_offset < self.buf_size do
        -- Find next newline delimiter
        local delimiter = ffi.cast("uint8_t *", ffi.C.memchr(self.buf + self.buf_offset, string.byte("\n"), self.buf_size - self.buf_offset))
        if delimiter == nil then
            break
        end

        -- Calculate JSON size
        local size = (delimiter - self.buf) - self.buf_offset
        -- Extract JSON string
        local str = ffi.string(self.buf + self.buf_offset, size)

        -- Deserialize object and add to output vector
        out:append(self.data_type.from_json(str))

        -- Update buffer offset
        self.buf_offset = (delimiter - self.buf) + 1
    end

    return out
end

function JSONSource:cleanup()
    if self.filename then
        if ffi.C.fclose(self.file) ~= 0 then
            error("fclose(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    end
end

return JSONSource
