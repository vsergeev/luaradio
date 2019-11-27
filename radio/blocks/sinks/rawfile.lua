---
-- Sink a signal to a binary file. The samples are serialized raw, in their
-- native binary representation, with no signedness conversion, endian
-- conversion, or interpretation. This is useful for serializing data types
-- across a pipe or other file descriptor based IPC.
--
-- @category Sinks
-- @block RawFileSink
-- @tparam string|file|int file Filename, file object, or file descriptor
--
-- @signature in:any >
--
-- @usage
-- -- Sink raw samples to a file
-- local snk = radio.RawFileSink('samples.raw')
-- top:connect(src, snk)
--
-- -- Sink raw samples to file descriptor 3
-- local snk = radio.RawFileSink(3)
-- top:connect(src, snk)

local ffi = require('ffi')

local block = require('radio.core.block')

local RawFileSink = block.factory("RawFileSink")

function RawFileSink:instantiate(file)
    if type(file) == "string" then
        self.filename = file
    elseif type(file) == "number" then
        self.fd = file
    else
        self.file = assert(file, "Missing argument #1 (file)")
    end

    -- Accept all input types
    self:add_type_signature({block.Input("in", function (type) return true end)}, {})
end

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
    local data, size = x.data_type.serialize(x)

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
