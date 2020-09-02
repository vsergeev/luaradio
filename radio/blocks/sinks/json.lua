---
-- Sink a signal to a file, serialized in JSON. Samples are serialized
-- individually and newline delimited. This sink accepts any data type that
-- implements `to_json()`.
--
-- @category Sinks
-- @block JSONSink
-- @tparam[opt=io.stdout] string|file|int file Filename, file object, or file descriptor
--
-- @signature in:supported >
--
-- @usage
-- -- Sink JSON serialized samples to stdout
-- local snk = radio.JSONSink()
-- top:connect(src, snk)
--
-- -- Sink JSON serialized samples to a file
-- local snk = radio.JSONSink('out.json')
-- top:connect(src, snk)

local ffi = require('ffi')

local block = require('radio.core.block')

local JSONSink = block.factory("JSONSink")

function JSONSink:instantiate(file)
    -- Default to io.stdout
    self.file = file or io.stdout

    -- Accept all input types that implement to_json()
    self:add_type_signature({block.Input("in", function (type) return type.to_json ~= nil end)}, {})
end

function JSONSink:initialize()
    if type(self.file) == "number" then
        -- file descriptor
        self.file = ffi.C.fdopen(self.file, "wb")
        if self.file == nil then
            error("fdopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
    elseif type(self.file) == "string" then
        -- path
        self.file = ffi.C.fopen(self.file, "wb")
        if self.file == nil then
            error("fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
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
    if ffi.C.fclose(self.file) ~= 0 then
        error("fclose(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
end

return JSONSink
