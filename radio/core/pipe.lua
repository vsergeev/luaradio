local ffi = require('ffi')
local math = require('math')

local class = require('radio.core.class')
local platform = require('radio.core.platform')

-- PipeInput class
local PipeInput = class.factory()

function PipeInput.new(owner, name)
    local self = setmetatable({}, PipeInput)
    self.owner = owner
    self.name = name
    self.data_type = nil
    self.pipe = nil
    return self
end

function PipeInput:close()
    self.pipe:close_input()
end

-- PipeOutput class
local PipeOutput = class.factory()

function PipeOutput.new(owner, name)
    local self = setmetatable({}, PipeOutput)
    self.owner = owner
    self.name = name
    self.data_type = nil
    self.pipes = {}
    return self
end

function PipeOutput:close()
    for i=1, #self.pipes do
        self.pipes[i]:close_output()
    end
end

-- AliasedPipeInput class
local AliasedPipeInput = class.factory()

function AliasedPipeInput.new(owner, name)
    local self = setmetatable({}, AliasedPipeInput)
    self.owner = owner
    self.name = name
    self.real_inputs = {}
    return self
end

-- AliasedPipeOutput class
local AliasedPipeOutput = class.factory()

function AliasedPipeOutput.new(owner, name)
    local self = setmetatable({}, AliasedPipeOutput)
    self.owner = owner
    self.name = name
    self.real_output = nil
    return self
end

-- Pipe class
local Pipe = class.factory()

function Pipe.new(pipe_output, pipe_input)
    local self = setmetatable({}, Pipe)
    self.pipe_output = pipe_output
    self.pipe_input = pipe_input
    return self
end

function Pipe:get_rate()
    return self.pipe_output.owner:get_rate()
end

function Pipe:get_data_type()
    return self.pipe_output.data_type
end

ffi.cdef[[
    enum { AF_UNIX = 1 };
    enum { SOCK_STREAM = 1 };
    int socketpair(int domain, int type, int protocol, int socket_vector[2]);
    int close(int fildes);
]]

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

    -- Pre-allocate read buffer
    self._buf_capacity = 1048576
    self._buf = platform.alloc(self._buf_capacity)
    self._buf_size = 0
    self._buf_read_offset = 0
end

ffi.cdef[[
    ssize_t read(int fd, void *buf, size_t count);
    ssize_t write(int fd, const void *buf, size_t count);
]]

local function platform_read(fd, buf, size)
    local bytes_read = tonumber(ffi.C.read(fd, buf, size))
    if bytes_read < 0 then
        error("read(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
    return bytes_read
end

local function platform_write(fd, buf, size)
    local bytes_written = tonumber(ffi.C.write(fd, buf, size))
    if bytes_written <= 0 then
        error("write(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
    return bytes_written
end

function Pipe:read_update()
    -- Shift unread samples down to beginning of buffer
    local unread_length = self._buf_size - self._buf_read_offset
    if unread_length > 0 then
        ffi.C.memmove(self._buf, ffi.cast("char *", self._buf) + self._buf_read_offset, unread_length)
    end

    -- Read new samples in
    local bytes_read = platform_read(self._rfd, ffi.cast("char *", self._buf) + unread_length, self._buf_capacity - unread_length)

    -- Return nil on EOF
    if unread_length == 0 and bytes_read == 0 then
        return nil
    end

    -- Update size and reset unread offset
    self._buf_size = unread_length + bytes_read
    self._buf_read_offset = 0

    -- Return number of elements in our read buffer
    return self.data_type.deserialize_count(self._buf, self._buf_size)
end

function Pipe:read_n(num)
    -- Create a vector from the buffer
    local vec, bytes_consumed = self.data_type.deserialize_partial(ffi.cast("char *", self._buf) + self._buf_read_offset, num)

    -- Update the read offset
    self._buf_read_offset = self._buf_read_offset + bytes_consumed

    return vec
end

function Pipe:read()
    -- Update our read buffer and read the maximum amount available
    local num = self:read_update()

    -- Return nil on EOF
    if num == nil then
        return nil
    end

    return self:read_n(num)
end

function Pipe:write(vec)
    local len = 0

    -- Get buffer and size
    local data, size = self.data_type.serialize(vec)

    -- Write entire buffer
    while len < size do
        local bytes_written = platform_write(self._wfd, ffi.cast("char *", data) + len, size - len)
        len = len + bytes_written
    end
end

function Pipe:close_input()
    if self._rfd then
        if ffi.C.close(self._rfd) ~= 0 then
            error("close(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
        self._rfd = nil
    end
end

function Pipe:close_output()
    if self._wfd then
        if ffi.C.close(self._wfd) ~= 0 then
            error("close(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
        self._wfd = nil
    end
end

-- Helper function to read synchronously from a set of pipes

local function read_synchronous(pipes)
    -- Update read buffer of all pipes and gather amount available
    local num_elems_avail = {}
    for i=1, #pipes do
        num_elems_avail[i] = pipes[i]:read_update()

        -- If we've reached EOF, return nil
        if num_elems_avail[i] == nil then
            return nil
        end
    end

    -- Compute minimum available across all pipes
    local num_elems = math.min(unpack(num_elems_avail))

    -- Read that amount from all pipes
    local data_in = {}
    for i=1, #pipes do
        data_in[i] = pipes[i]:read_n(num_elems)
    end

    return data_in
end

-- Exported module
return {PipeInput = PipeInput, PipeOutput = PipeOutput, AliasedPipeInput = AliasedPipeInput, AliasedPipeOutput = AliasedPipeOutput, Pipe = Pipe, read_synchronous = read_synchronous}
