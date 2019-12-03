---
-- Source a signal from a network client. The source supports TCP and UNIX
-- socket transports. The samples are deserialized according to the specified
-- signedness, bit width, and endianness format.  Complex-valued signals are
-- deinterleaved as real component followed by imaginary component.  C
-- structure types may be deserialized raw with the "raw" format. Object types
-- may be deserialized from newline delimited JSON with the "json" format.
-- The source can be configured to automatically reconnect (default) or
-- terminate on connection loss.
--
-- @category Sources
-- @block NetworkClientSource
-- @tparam string data_type LuaRadio data type
-- @tparam number rate Sample rate of data
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
--                         * `reconnect` (bool, default true, reconnect on
--                         connection loss)
--
-- @signature > out:data_type
--
-- @usage
-- -- Source ComplexFloat32 samples sampled at 1 MHz decoded from little-endian
-- -- 32-bit float format from a TCP client connected to 192.168.1.105:5000
-- local src = radio.NetworkClientSource(radio.types.ComplexFloat32, 1e6, 'f32le', 'tcp', '192.168.1.105:5000')
--
-- -- Source Float32 samples sampled at 100 kHz decoded from little-endian
-- -- signed 16-bit real format from a UNIX socket client connected to
-- -- /tmp/radio.sock
-- local src = radio.NetworkClientSource(radio.types.Float32, 100e3, 's16le', 'unix', '/tmp/radio.sock')
--
-- -- Source RDSFrameType samples decoded from their C structure from a TCP
-- -- client connected to 192.168.1.105:5000
-- local src = radio.NetworkClientSource(radio.RDSFramerBlock.RDSFrameType, 0, 'raw', 'tcp', '192.168.1.105:5000')
--
-- -- Source RDSPacketType samples decoded from their JSON format from a TCP
-- -- client connected to 192.168.1.105:5000
-- local src = radio.NetworkClientSource(radio.RDSDecoderBlock.RDSPacketType, 0, 'json', 'tcp', '192.168.1.105:5000')

local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local vector = require('radio.core.vector')
local types = require('radio.types')
local format_utils = require('radio.utilities.format_utils')
local network_utils = require('radio.utilities.network_utils')

local NetworkClientSource = block.factory("NetworkClientSource")

function NetworkClientSource:instantiate(data_type, rate, format, transport, address, options)
    self.data_type = assert(data_type, "Missing argument #1 (data_type)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    if format == "raw" then
        self:add_type_signature({}, {block.Output("out", data_type)}, self.process_raw)
    elseif format == "json" then
        assert(data_type.to_json ~= nil, "Data type does not support JSON serialization")

        self:add_type_signature({}, {block.Output("out", data_type)}, self.process_json)
    elseif data_type == types.ComplexFloat32 or data_type == types.Float32 then
        assert(format, "Missing argument #3 (format)")
        self.format = assert(format_utils.formats[format], "Unsupported format (\"" .. format .. "\")")

        self:add_type_signature({}, {block.Output("out", data_type)}, data_type == types.ComplexFloat32 and self.process_complex or self.process_real)
    else
        error("Unsupported format \"" .. format .. "\" for specified data type")
    end

    self.options = options or {}
    self.reconnect = (self.options.reconnect == nil) and true or self.options.reconnect
    self.retry_delay = 0.5

    assert(transport, "Missing argument #4 (transport)")
    assert(address, "Missing argument #5 (address)")
    self.client = network_utils.NetworkClient(transport, address)
end

function NetworkClientSource:get_rate()
    return self.rate
end

function NetworkClientSource:initialize()
    -- Allocate receive buffer
    local buf_ctype = self.format == nil and ffi.typeof("uint8_t") or
                        (self.data_type == types.ComplexFloat32 and self.format.complex_ctype or self.format.real_ctype)
    self.raw_samples = vector.Vector(buf_ctype, 262144 / ffi.sizeof(buf_ctype))
    self.buf = ffi.cast("uint8_t *", self.raw_samples.data)
    self.buf_capacity = self.raw_samples.size
    self.buf_offset = 0
    self.buf_size = 0

    -- Create output vector
    self.out = self.data_type.vector()
end

function NetworkClientSource:recv()
    -- Connect on startup
    if not self.client:connected() then
        while self.client:connect() ~= true do
            ffi.C.usleep(self.retry_delay * 1e6)
        end
    end

    -- Shift existing bytes down
    local unread_length = self.buf_size - self.buf_offset
    if unread_length > 0 then
        ffi.C.memmove(self.buf, self.buf + self.buf_offset, unread_length)
    end

    -- Read up to buf_capacity from server
    local bytes_read = 0
    while bytes_read == 0 do
        bytes_read = tonumber(self.client:recv(self.buf + unread_length, self.buf_capacity - unread_length))
        if bytes_read == 0 then
            -- Disconnected
            if self.reconnect then
                unread_length = 0
                while self.client:connect() ~= true do
                    ffi.C.usleep(self.retry_delay * 1e6)
                end
            else
                return false
            end
        end
    end

    -- Update size and reset unread offset
    self.buf_size = unread_length + bytes_read
    self.buf_offset = 0

    return true
end

function NetworkClientSource:process_json(x)
    -- Read bytes into buffer
    if not self:recv() then
        return nil
    end

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

function NetworkClientSource:process_raw(x)
    -- Read bytes into buffer
    if not self:recv() then
        return nil
    end

    -- Deserialize samples
    local num_samples = self.data_type.deserialize_count(self.buf, self.buf_size)
    local out, size = self.data_type.deserialize_partial(self.buf, num_samples)

    -- Adjust buffer offset
    self.buf_offset = size

    return out
end

function NetworkClientSource:process_complex(x)
    -- Read bytes into buffer
    if not self:recv() then
        return nil
    end

    -- Cast buffer to raw samples
    local num_samples = math.floor(self.buf_size / ffi.sizeof(self.format.complex_ctype))

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, num_samples-1 do
            format_utils.swap_bytes(self.raw_samples.data[i].real)
            format_utils.swap_bytes(self.raw_samples.data[i].imag)
        end
    end

    -- Convert raw samples to complex float32 samples
    local out = self.out:resize(num_samples)

    for i = 0, num_samples-1 do
        out.data[i].real = (self.raw_samples.data[i].real.value - self.format.offset)/self.format.scale
        out.data[i].imag = (self.raw_samples.data[i].imag.value - self.format.offset)/self.format.scale
    end

    -- Update our buffer offset
    self.buf_offset = num_samples * ffi.sizeof(self.format.complex_ctype)

    return out
end

function NetworkClientSource:process_real(x)
    -- Read bytes into buffer
    if not self:recv() then
        return nil
    end

    -- Cast buffer to raw samples
    local num_samples = math.floor(self.buf_size / ffi.sizeof(self.format.real_ctype))

    -- Perform byte swap for endianness if needed
    if self.format.swap then
        for i = 0, num_samples-1 do
            format_utils.swap_bytes(self.raw_samples.data[i])
        end
    end

    -- Convert raw samples to float32 samples
    local out = self.out:resize(num_samples)

    for i = 0, num_samples-1 do
        out.data[i].value = (self.raw_samples.data[i].value - self.format.offset)/self.format.scale
    end

    -- Update our buffer offset
    self.buf_offset = num_samples * ffi.sizeof(self.format.real_ctype)

    return out
end

function NetworkClientSource:cleanup()
    self.client:close()
end

return NetworkClientSource
