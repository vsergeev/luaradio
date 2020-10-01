---
-- Pipe I/O handling.
--
-- @module radio.core.pipe

local ffi = require('ffi')
local math = require('math')

local class = require('radio.core.class')
local platform = require('radio.core.platform')

---
-- Pipe. This class implements the serialization/deserialization of sample
-- vectors between blocks.
--
-- @internal
-- @class
-- @tparam OutputPort output Pipe output port
-- @tparam InputPort input Pipe input port
local Pipe = class.factory()

function Pipe.new(output, input)
    local self = setmetatable({}, Pipe)
    self.output = output
    self.input = input
    return self
end

---
-- Get sample rate of pipe.
--
-- @internal
-- @function Pipe:get_rate
-- @treturn number Sample rate
function Pipe:get_rate()
    return self.output.owner:get_rate()
end

---
-- Get data type of pipe.
--
-- @internal
-- @function Pipe:get_data_type
-- @treturn data_type Data type
function Pipe:get_data_type()
    return self.output.data_type
end

ffi.cdef[[
    int socketpair(int domain, int type, int protocol, int socket_vector[2]);
]]

---
-- Initialize the pipe.
--
-- @internal
-- @function Pipe:initialize
function Pipe:initialize()
    -- Look up our data type
    self.data_type = self:get_data_type()

    -- Create UNIX socket pair
    local socket_fds = ffi.new("int[2]")
    if ffi.C.socketpair(ffi.C.AF_UNIX, ffi.C.SOCK_STREAM, 0, socket_fds) ~= 0 then
        error("socketpair(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
    self._rfd = socket_fds[0]
    self._wfd = socket_fds[1]
    self._eof = false

    -- Pre-allocate read buffer
    self._buf_capacity = 1048576
    self._buf = platform.alloc(self._buf_capacity)
    self._buf_size = 0
    self._buf_read_offset = 0
end

---
-- Update the Pipe's internal read buffer.
--
-- @internal
-- @function Pipe:_read_buffer_update
function Pipe:_read_buffer_update()
    -- Shift unread samples down to beginning of buffer
    local unread_length = self._buf_size - self._buf_read_offset
    if unread_length > 0 then
        ffi.C.memmove(self._buf, ffi.cast("char *", self._buf) + self._buf_read_offset, unread_length)
    end

    -- Read new samples in
    local bytes_read = tonumber(ffi.C.read(self._rfd, ffi.cast("char *", self._buf) + unread_length, self._buf_capacity - unread_length))
    if bytes_read < 0 then
        error("read(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    elseif unread_length == 0 and bytes_read == 0 then
        self._eof = true
    end

    -- Update size and reset unread offset
    self._buf_size = unread_length + bytes_read
    self._buf_read_offset = 0
end

---
-- Get the Pipe's internal read buffer's element count.
--
-- @internal
-- @function Pipe:_read_buffer_count
-- @treturn int Count
function Pipe:_read_buffer_count()
    -- Return nil on EOF
    if self._eof then
        return nil
    end

    -- Return item count in read buffer
    return self.data_type.deserialize_count(ffi.cast("char *", self._buf) + self._buf_read_offset, self._buf_size - self._buf_read_offset)
end

---
-- Test if the Pipe's internal read buffer is full.
--
-- @internal
-- @function Pipe:_read_buffer_full
-- @treturn bool Full
function Pipe:_read_buffer_full()
    -- Return full status of read buffer
    return (self._buf_size - self._buf_read_offset) == self._buf_capacity
end

---
-- Deserialize elements from the Pipe's internal read buffer into a vector.
--
-- @internal
-- @function Pipe:_read_buffer_deserialize
-- @tparam int num Number of elements to deserialize
-- @treturn Vector Vector
function Pipe:_read_buffer_deserialize(num)
    -- Shift samples down to beginning of buffer
    if self._buf_read_offset > 0 then
        ffi.C.memmove(self._buf, ffi.cast("char *", self._buf) + self._buf_read_offset, self._buf_size - self._buf_read_offset)
        self._buf_size = self._buf_size - self._buf_read_offset
        self._buf_read_offset = 0
    end

    -- Deserialize a vector from the read buffer
    local vec, size = self.data_type.deserialize_partial(ffi.cast("char *", self._buf), num)

    -- Update read offset
    self._buf_read_offset = self._buf_read_offset + size

    return vec
end

---
-- Read a sample vector from the Pipe.
--
-- @internal
-- @function Pipe:read
-- @tparam[opt=nil] int count Number of elements to read
-- @treturn Vector|nil Sample vector or nil on EOF
function Pipe:read(count)
    -- Update our read buffer
    self:_read_buffer_update()

    -- Get available item count
    local num = self:_read_buffer_count()

    -- Return nil on EOF
    if num == nil then
        return nil
    end

    return self:_read_buffer_deserialize(count and math.min(num, count) or num)
end

---
-- Write a sample vector to the Pipe.
--
-- @internal
-- @function Pipe:write
-- @tparam Vector vec Sample vector
function Pipe:write(vec)
    -- Get vector serialized buffer and size
    local data, size = self.data_type.serialize(vec)

    -- Write entire buffer
    local len = 0
    while len < size do
        local bytes_written = tonumber(ffi.C.write(self._wfd, ffi.cast("char *", data) + len, size - len))
        if bytes_written <= 0 then
            local errno = ffi.errno()
            if errno == ffi.C.EPIPE or errno == ffi.C.ECONNRESET then
                io.stderr:write(string.format("[%s] Downstream block %s terminated unexpectedly.\n", self.output.owner.name, self.input.owner.name))
            end
            error("write(): " .. ffi.string(ffi.C.strerror(errno)))
        end
        len = len + bytes_written
    end
end

---
-- Close the input end of the pipe.
--
-- @internal
-- @function Pipe:close_input
function Pipe:close_input()
    if self._rfd then
        if ffi.C.close(self._rfd) ~= 0 then
            error("close(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
        self._rfd = nil
    end
end

---
-- Close the output end of the pipe.
--
-- @internal
-- @function Pipe:close_output
function Pipe:close_output()
    if self._wfd then
        if ffi.C.close(self._wfd) ~= 0 then
            error("close(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
        self._wfd = nil
    end
end

---
-- Get the file descriptor of the input end of the Pipe.
--
-- @internal
-- @function Pipe:fileno_input
-- @treturn int File descriptor
function Pipe:fileno_input()
    return self._rfd
end

---
-- Get the file descriptor of the output end of the Pipe.
--
-- @internal
-- @function Pipe:fileno_output
-- @treturn int File descriptor
function Pipe:fileno_output()
    return self._wfd
end

-- Helper function to read synchronously from a set of pipes

local POLL_READ_EVENTS = bit.bor(ffi.C.POLLIN, ffi.C.POLLHUP)

---
-- Read synchronously from a set of pipe. The vectors returned
-- will all be of the same length.
--
-- @internal
-- @function read_synchronous
-- @tparam array pipes Array of Pipe objects
-- @treturn array|nil Array of sample vectors or nil on EOF
local function read_synchronous(pipes)
    -- Set up pollfd structures for all not-full pipes
    local pollfds = ffi.new("struct pollfd[?]", #pipes)
    for i=1, #pipes do
        pollfds[i-1].fd = pipes[i]:fileno_input()
        pollfds[i-1].events = not pipes[i]:_read_buffer_full() and POLL_READ_EVENTS or 0
    end

    -- Poll (non-blocking)
    local ret = ffi.C.poll(pollfds, #pipes, 0)
    if ret < 0 then
        error("poll(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Compute maximum available item count across all pipes
    local num_elems = math.huge
    for i=1, #pipes do
        -- Update read buffer if pipe is ready
        if pollfds[i-1].revents ~= 0 then
            pipes[i]:_read_buffer_update()
        end

        local count = pipes[i]:_read_buffer_count()

        -- Block updating read buffer if we've ran out of items
        if count == 0 then
            pipes[i]:_read_buffer_update()
            count = pipes[i]:_read_buffer_count()
        end

        -- If we've reached EOF, return nil
        if count == nil then
            return nil
        end

        -- Update maximum available item count
        num_elems = (count < num_elems) and count or num_elems
    end

    -- Read maximum available item count from all pipes
    local data_in = {}
    for i=1, #pipes do
        data_in[i] = pipes[i]:_read_buffer_deserialize(num_elems)
    end

    return data_in
end

-- Exported module
return {Pipe = Pipe, read_synchronous = read_synchronous}
