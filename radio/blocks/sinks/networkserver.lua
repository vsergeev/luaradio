---
-- Sink a signal to a network server. The sink supports TCP and UNIX socket
-- transports. The samples are serialized according to the specified
-- signedness, bit width, and endianness format.  Complex-valued signals are
-- interleaved as real component followed by imaginary component.  C structure
-- types are serialized raw with the "raw" format. Object types are serialized
-- as newline delimited JSON with the "json" format. The sink will
-- automatically reconnect on connection loss.
--
-- @category Sinks
-- @block NetworkServerSink
-- @tparam string format Binary format of the samples specifying signedness,
--                       bit width, and endianness of samples, or "raw" (for
--                       raw serialization, useful for C structure types), or
--                       "json" (for JSON serialization, useful for Object
--                       types). Choice of "s8", "u8", "u16le", "u16be",
--                       "s16le", "s16be", "u32le", "u32be", "s32le", "s32be",
--                       "f32le", "f32be", "f64le", "f64be", "raw", "json".
-- @tparam string transport Transport type. Choice of "tcp" or "unix".
-- @tparam string address Address, as host:port for TCP, or as a file path for
--                        UNIX.
-- @tparam[opt={}] table options Additional options, specifying:
--                         * `backpressure` (bool, default false, backpressure
--                         samples on connection loss)
--
-- @signature in:ComplexFloat32 >
-- @signature in:Float32 >
-- @signature in:supported >
--
-- @usage
-- -- Sink ComplexFloat32 samples encoded as little-endian 32-bit float IQ to a
-- -- TCP server listening on 0.0.0.0:5000
-- local snk = radio.NetworkServerSink('f32le', 'tcp', '0.0.0.0:5000')
--
-- -- Sink Float32 samples encoded as little-endian 16-bit real to a UNIX
-- -- socket server listening on /tmp/radio.sock
-- local snk = radio.NetworkServerSink('s16le', 'unix', '/tmp/radio.sock')
--
-- -- Sink C structure type samples to a TCP server listening on 0.0.0.0:5000
-- local snk = radio.NetworkServerSink('raw', 'tcp', '0.0.0.0:5000')
--
-- -- Sink JSON serialized objects to a TCP server listening on 0.0.0.0:5000
-- local snk = radio.NetworkServerSink('json', 'tcp', '0.0.0.0:5000')

local ffi = require('ffi')

local block = require('radio.core.block')
local vector = require('radio.core.vector')
local types = require('radio.types')
local format_utils = require('radio.utilities.format_utils')
local network_utils = require('radio.utilities.network_utils')

local NetworkServerSink = block.factory("NetworkServerSink")

function NetworkServerSink:instantiate(format, transport, address, options)
    if format == "raw" then
        self:add_type_signature({block.Input("in", function (type) return true end)}, {}, self.process_raw)
    elseif format == "json" then
        self:add_type_signature({block.Input("in", function (type) return type.to_json ~= nil end)}, {}, self.process_json)
    else
        assert(format, "Missing argument #1 (format)")
        self.format = assert(format_utils.formats[format], "Unsupported format (\"" .. format .. "\")")

        self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {}, self.process_complex)
        self:add_type_signature({block.Input("in", types.Float32)}, {}, self.process_real)
    end

    self.options = options or {}
    self.backpressure = self.options.backpressure or false

    assert(transport, "Missing argument #2 (transport)")
    assert(address, "Missing argument #3 (address)")
    self.server = network_utils.NetworkServer(transport, address)
end

function NetworkServerSink:initialize()
    -- Create output vector for formatted complex and real data types
    if self.format ~= nil then
        local buf_ctype = self.inputs[1].data_type == types.ComplexFloat32 and self.format.complex_ctype or self.format.real_ctype
        self.out = vector.Vector(buf_ctype)
    end

    -- Start server
    self.server:listen()

    -- Register file descriptor
    self.files[self.server.server_fd] = true
end

function NetworkServerSink:process_raw(x)
    -- Accept a client if not connected
    if not self.server:connected() then
        if self.backpressure then
            self.server:accept()
        elseif not self.server:try_accept() then
            return
        end
    end

    -- Serialize samples
    local data, size = x.data_type.serialize(x)

    -- Send to client
    self.server:sendall(data, size)
end

function NetworkServerSink:process_json(x)
    -- Accept a client if not connected
    if not self.server:connected() then
        if self.backpressure then
            self.server:accept()
        elseif not self.server:try_accept() then
            return
        end
    end

    for i = 0, x.length-1 do
        -- Serialize sample to JSON
        local s = x.data[i]:to_json() .. "\n"

        -- Send to client
        self.server:sendall(s, #s)
    end
end

function NetworkServerSink:process_complex(x)
    -- Accept a client if not connected
    if not self.server:connected() then
        if self.backpressure then
            self.server:accept()
        elseif not self.server:try_accept() then
            return
        end
    end

    -- Resize output vector
    local out = self.out:resize(x.length)

    -- Convert ComplexFloat32 samples to raw samples
    for i = 0, x.length-1 do
        out.data[i].real.value = (x.data[i].real*self.format.scale) + self.format.offset
        out.data[i].imag.value = (x.data[i].imag*self.format.scale) + self.format.offset
    end

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, x.length-1 do
            format_utils.swap_bytes(out.data[i].real)
            format_utils.swap_bytes(out.data[i].imag)
        end
    end

    -- Send to client
    self.server:sendall(out.data, out.size)
end

function NetworkServerSink:process_real(x)
    -- Accept a client if not connected
    if not self.server:connected() then
        if self.backpressure then
            self.server:accept()
        elseif not self.server:try_accept() then
            return
        end
    end

    -- Resize output vector
    local out = self.out:resize(x.length)

    -- Convert Float32 samples to raw samples
    for i = 0, x.length-1 do
        out.data[i].value = (x.data[i].value*self.format.scale) + self.format.offset
    end

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, x.length-1 do
            format_utils.swap_bytes(out.data[i])
        end
    end

    -- Send to server
    self.server:sendall(out.data, out.size)
end

function NetworkServerSink:cleanup()
    self.server:close()
end

return NetworkServerSink
