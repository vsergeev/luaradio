---
-- Pipe I/O handling.
--
-- @module radio.core.pipe

local ffi = require('ffi')
local math = require('math')

local class = require('radio.core.class')
local platform = require('radio.core.platform')
local util = require('radio.core.util')

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

    -- Read buffer
    self._rbuf_capacity = 1048576
    self._rbuf_anchor = platform.alloc(self._rbuf_capacity)
    self._rbuf = ffi.cast("char *", self._rbuf_anchor)
    self._rbuf_size = 0
    self._rbuf_offset = 0

    -- Write buffer
    self._wbuf_anchor = nil
    self._wbuf = nil
    self._wbuf_size = 0
    self._wbuf_offset = 0
end

--------------------------------------------------------------------------------
-- Read methods
--------------------------------------------------------------------------------

---
-- Update the Pipe's internal read buffer.
--
-- @internal
-- @function Pipe:_read_buffer_update
-- @treturn int|nil Number of bytes read or nil on EOF
function Pipe:_read_buffer_update()
    -- Shift unread samples down to beginning of buffer
    local unread_length = self._rbuf_size - self._rbuf_offset
    if unread_length > 0 then
        ffi.C.memmove(self._rbuf, self._rbuf + self._rbuf_offset, unread_length)
    end

    -- Read new samples in
    local bytes_read = tonumber(ffi.C.read(self._rfd, self._rbuf + unread_length, self._rbuf_capacity - unread_length))
    if bytes_read < 0 then
        error("read(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    elseif unread_length == 0 and bytes_read == 0 then
        self._eof = true
        return nil
    end

    -- Update size and reset unread offset
    self._rbuf_size = unread_length + bytes_read
    self._rbuf_offset = 0

    return bytes_read
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
    return self.data_type.deserialize_count(self._rbuf + self._rbuf_offset, self._rbuf_size - self._rbuf_offset)
end

---
-- Test if the Pipe's internal read buffer is full.
--
-- @internal
-- @function Pipe:_read_buffer_full
-- @treturn bool Full
function Pipe:_read_buffer_full()
    -- Return full status of read buffer
    return (self._rbuf_size - self._rbuf_offset) == self._rbuf_capacity
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
    if self._rbuf_offset > 0 then
        ffi.C.memmove(self._rbuf, self._rbuf + self._rbuf_offset, self._rbuf_size - self._rbuf_offset)
        self._rbuf_size = self._rbuf_size - self._rbuf_offset
        self._rbuf_offset = 0
    end

    -- Deserialize a vector from the read buffer
    local vec, size = self.data_type.deserialize_partial(self._rbuf, num)

    -- Update read offset
    self._rbuf_offset = self._rbuf_offset + size

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
    local available = self:_read_buffer_count()

    -- Return nil on EOF
    if available == nil then
        return nil
    end

    return self:_read_buffer_deserialize(count and math.min(available, count) or available)
end

--------------------------------------------------------------------------------
-- Write methods
--------------------------------------------------------------------------------

---
-- Update the Pipe's internal write buffer.
--
-- @internal
-- @function Pipe:_write_buffer_update
-- @treturn int|nil Number of bytes written or nil on EOF
function Pipe:_write_buffer_update()
    local bytes_written = tonumber(ffi.C.write(self._wfd, self._wbuf + self._wbuf_offset, self._wbuf_size - self._wbuf_offset))
    if bytes_written < 0 then
        local errno = ffi.errno()
        if errno == ffi.C.EPIPE or errno == ffi.C.ECONNRESET then
            return nil
        end
        error("write(): " .. ffi.string(ffi.C.strerror(errno)))
    end

    self._wbuf_offset = self._wbuf_offset + bytes_written

    return bytes_written
end

---
-- Test if the Pipe's internal write buffer is empty.
--
-- @internal
-- @function Pipe:_write_buffer_full
-- @treturn bool Empty
function Pipe:_write_buffer_empty()
    -- Return empty status of write buffer
    return self._wbuf_offset == self._wbuf_size
end

---
-- Serialize elements from a vector to the Pipe's internal write buffer.
--
-- @internal
-- @function Pipe:_write_buffer_serialize
-- @tparam Vector vec Sample vector
function Pipe:_write_buffer_serialize(vec)
    -- Serialize to buffer
    self._wbuf_anchor, self._wbuf_size = self.data_type.serialize(vec)
    self._wbuf = ffi.cast("char *", self._wbuf_anchor)
    self._wbuf_offset = 0
end

---
-- Write a sample vector to the Pipe.
--
-- @internal
-- @function Pipe:write
-- @tparam Vector vec Sample vector
-- @teturn bool Success
function Pipe:write(vec)
    self:_write_buffer_serialize(vec)

    while not self:_write_buffer_empty() do
        if self:_write_buffer_update() == nil then
            return false
        end
    end

    return true
end

--------------------------------------------------------------------------------
-- Misc methods
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- PipeMux
--------------------------------------------------------------------------------

local POLL_READ_EVENTS = bit.bor(ffi.C.POLLIN, ffi.C.POLLHUP)
local POLL_WRITE_EVENTS = bit.bor(ffi.C.POLLOUT, ffi.C.POLLHUP)
local POLL_EOF_EVENTS = ffi.C.POLLHUP

---
-- Helper class to manage reading and writing to and from a group of pipes
-- efficiently.
--
-- @internal
-- @class
-- @tparam array input_pipes Input pipes
-- @tparam array output_pipes Output pipes
local PipeMux = class.factory()

function PipeMux.new(input_pipes, output_pipes)
    local self = setmetatable({}, PipeMux)

    -- Save input pipes
    self.input_pipes = input_pipes

    -- Save output pipes
    self.output_pipes = output_pipes
    self.output_pipes_flat = util.array_flatten(output_pipes, 1)

    -- Initialize input pollfds
    self.input_pollfds = ffi.new("struct pollfd[?]", #self.input_pipes)
    for i=1, #self.input_pipes do
        self.input_pollfds[i-1].fd = input_pipes[i]:fileno_input()
        self.input_pollfds[i-1].events = POLL_READ_EVENTS
    end

    -- Differentiate read() method
    if #self.input_pipes == 0 then
        self.read = self._read_none
    elseif #self.input_pipes == 1 then
        self.read = self._read_single
    elseif #self.input_pipes > 1 then
        self.read = self._read_multiple
    end

    -- Initialize output pollfds
    self.output_pollfds = ffi.new("struct pollfd[?]", #self.output_pipes_flat)
    for i=1, #self.output_pipes_flat do
        self.output_pollfds[i-1].fd = self.output_pipes_flat[i]:fileno_output()
        self.output_pollfds[i-1].events = POLL_WRITE_EVENTS
    end

    -- Differentiate write() method
    if #self.output_pipes_flat == 0 then
        self.write = self._write_none
    elseif #self.output_pipes_flat == 1 then
        self.write = self._write_single
    elseif #self.output_pipes_flat > 1 then
        self.write = self._write_multiple
    end

    return self
end

function PipeMux:_read_none()
    return {}, false
end

function PipeMux:_read_single()
    local num_elems

    while true do
        -- Poll (blocking)
        local ret = ffi.C.poll(self.input_pollfds, 1, -1)
        if ret < 0 then
            error("poll(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        -- Update pipe internal read buffer
        self.input_pipes[1]:_read_buffer_update()

        -- Check available item count
        local count = self.input_pipes[1]:_read_buffer_count()
        if count == nil then
            -- EOF encountered
            return {}, true
        elseif count > 0 then
            num_elems = count
            break
        end
    end

    -- Read input vector
    return {self.input_pipes[1]:_read_buffer_deserialize(num_elems)}, false
end

function PipeMux:_read_multiple()
    local num_elems

    while true do
        -- Update pollfd structures
        for i=1, #self.input_pipes do
            self.input_pollfds[i-1].events = not self.input_pipes[i]:_read_buffer_full() and POLL_READ_EVENTS or POLL_EOF_EVENTS
        end

        -- Poll (blocking)
        local ret = ffi.C.poll(self.input_pollfds, #self.input_pipes, -1)
        if ret < 0 then
            error("poll(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        -- Initialize available item count to maximum
        num_elems = math.huge

        -- Check each input pipe
        for i=1, #self.input_pipes do
            if self.input_pollfds[i-1].revents ~= 0 then
                -- Update pipe internal read buffer
                self.input_pipes[i]:_read_buffer_update()
            end

             -- Update available item count
            local count = self.input_pipes[i]:_read_buffer_count()
            if count == nil then
                -- EOF encountered
                return {}, true
            else
                num_elems = (count < num_elems) and count or num_elems
            end
        end

        -- If we have a non-zero, non-inf available item count
        if num_elems > 0 and num_elems < math.huge then
            break
        end
    end

    -- Read maxmium available item count from input vectors
    local data_in = {}
    for i=1, #self.input_pipes do
        data_in[i] = self.input_pipes[i]:_read_buffer_deserialize(num_elems)
    end

    return data_in, false
end

function PipeMux:_write_none(vecs)
    return false, nil
end

function PipeMux:_write_single(vecs)
    -- Serialize output vector to pipe write buffer
    self.output_pipes_flat[1]:_write_buffer_serialize(vecs[1])

    while true do
        -- Poll (blocking)
        local ret = ffi.C.poll(self.output_pollfds, 1, -1)
        if ret < 0 then
            error("poll(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        -- Update pipe internal write buffer
        if self.output_pipes_flat[1]:_write_buffer_update() == nil then
            return true, self.output_pipes_flat[1]
        end

        if self.output_pipes_flat[1]:_write_buffer_empty() then
            break
        end
    end

    return false, nil
end

function PipeMux:_write_multiple(vecs)
    -- Serialize output vectors to pipe write buffers
    for i=1, #self.output_pipes do
        for j=1, #self.output_pipes[i] do
            self.output_pipes[i][j]:_write_buffer_serialize(vecs[i])
        end
    end

    while true do
        -- Update pollfd structures
        for i=1, #self.output_pipes_flat do
            self.output_pollfds[i-1].events = not self.output_pipes_flat[i]:_write_buffer_empty() and POLL_WRITE_EVENTS or POLL_EOF_EVENTS
        end

        -- Poll (blocking)
        local ret = ffi.C.poll(self.output_pollfds, #self.output_pipes_flat, -1)
        if ret < 0 then
            error("poll(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        local all_written = true

        -- Check each output pipe
        for i=1, #self.output_pipes_flat do
            if self.output_pollfds[i-1].revents ~= 0 then
                -- Update pipe internal write buffer
                if self.output_pipes_flat[i]:_write_buffer_update() == nil then
                    return true, self.output_pipes_flat[i]
                end

                -- Update all written check
                all_written = all_written and self.output_pipes_flat[i]:_write_buffer_empty()
            end
        end

        if all_written then
            break
        end
    end

    return false, nil
end

---
-- Read input pipes into an array of sample vectors.
--
-- @internal
-- @function PipeMux:read
-- @treturn array Array of sample vectors
-- @treturn bool EOF encountered
function PipeMux:read()
    -- Differentiated at runtime to _read_single() or _read_multiple()
end

---
-- Write an array of sample vectors to output pipes.
--
-- @internal
-- @function PipeMux:write
-- @tparam array vecs Array of sample vectors
-- @treturn bool EOF encountered
-- @treturn Pipe|nil Pipe that caused EOF
function PipeMux:write(vecs)
    -- Differentiated at runtime to _write_single() or _write_multiple()
end

--------------------------------------------------------------------------------
-- Helper function to read synchronously from a set of pipes
--------------------------------------------------------------------------------

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
return {Pipe = Pipe, PipeMux = PipeMux, read_synchronous = read_synchronous}
