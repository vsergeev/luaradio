---
-- Source a signal of the specified data type from a binary file. The raw
-- binary samples are cast to the specified data type with no signedness
-- conversion, endian conversion, or interpretation. This is useful for
-- serializing data types across a pipe or other file descriptor based IPC.
--
-- @category Sources
-- @block RawFileSource
-- @tparam string|file|int file Filename, file object, or file descriptor
-- @tparam type data_type LuaRadio data type
-- @tparam number rate Sample rate of file
-- @tparam[opt=false] bool repeat_on_eof Repeat on end of file
--
-- @signature > out:data_type
--
-- @usage
-- -- Source ComplexFloat32 samples sampled at 1 MHz from a file descriptor
-- local src = radio.RawFileSource(3, radio.types.ComplexFloat32, 1e6)
--
-- -- Source Byte samples sampled at 100 kHz from a file, repeating on EOF
-- local src = radio.RawFileSource('data.bin', radio.types.Byte, 100e3, true)

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
        self.file = assert(file, "Missing argument #1 (file)")
    end

    self.data_type = assert(data_type, "Missing argument #2 (data_type)")
    self.rate = assert(rate, "Missing argument #3 (rate)")
    self.repeat_on_eof = repeat_on_eof or false

    self:add_type_signature({}, {block.Output("out", data_type)})
end

function RawFileSource:get_rate()
    return self.rate
end

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

    -- Deserialize as many elements as possible
    local count = self.data_type.deserialize_count(self.buf, self.buf_size)
    local samples, size = self.data_type.deserialize_partial(self.buf, count)
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
