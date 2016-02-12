local ffi = require('ffi')
local math = require('math')

local object = require('radio.core.object')
local vector = require('radio.core.vector')

-- PipeInput class
local PipeInput = object.class_factory()

function PipeInput.new(owner, name)
    local self = setmetatable({}, PipeInput)
    self.owner = owner
    self.name = name
    self.pipe = nil
    return self
end

-- PipeOutput class
local PipeOutput = object.class_factory()

function PipeOutput.new(owner, name)
    local self = setmetatable({}, PipeOutput)
    self.owner = owner
    self.name = name
    self.pipes = {}
    return self
end

-- AliasedPipeInput class
local AliasedPipeInput = object.class_factory()

function AliasedPipeInput.new(owner, name)
    local self = setmetatable({}, AliasedPipeInput)
    self.owner = owner
    self.name = name
    self.real_input = nil
    return self
end

-- AliasedPipeOutput class
local AliasedPipeOutput = object.class_factory()

function AliasedPipeOutput.new(owner, name)
    local self = setmetatable({}, AliasedPipeOutput)
    self.owner = owner
    self.name = name
    self.real_output = nil
    return self
end

-- Pipe class
local Pipe = object.class_factory()

function Pipe.new(pipe_output, pipe_input, data_type)
    local self = setmetatable({}, Pipe)
    self.pipe_output = pipe_output
    self.pipe_input = pipe_input
    self.data_type = data_type
    return self
end

-- Aligned memory allocator/deallocator
ffi.cdef[[
    void *aligned_alloc(size_t alignment, size_t size);
    void free(void *ptr);

    char *strerror(int errnum);
]]

-- Pipe I/O
ffi.cdef[[
    int pipe(int pipefd[2]);
    struct iovec {
        void *iov_base;
        size_t iov_len;
    };
    int vmsplice(int fd, const struct iovec *iov, unsigned long nr_segs, unsigned int flags);
]]

function Pipe:initialize(multiprocess)
    if multiprocess then
        -- Create UNIX pipe
        local pipe_fds = ffi.new("int[2]")
        assert(ffi.C.pipe(pipe_fds) == 0, "pipe(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        self._rfd = pipe_fds[0]
        self._wfd = pipe_fds[1]

        -- Pre-allocate read buffer
        self._buf_capacity = 65536
        self._buf = ffi.gc(ffi.C.aligned_alloc(vector.PAGE_SIZE, self._buf_capacity), ffi.C.free)
        self._buf_size = 0
        self._buf_read_offset = 0

        self.read_max = self.read_max_mp
        self.read_n = self.read_n_mp
        self.write = self.write_mp
        self.read_update = self.read_update_mp
    else
        self.vec = nil

        self.read_max = self.read_max_sp
        self.read_n = self.read_n_sp
        self.write = self.write_sp
        self.read_update = self.read_update_sp
    end
end

function Pipe:get_rate()
    return self.pipe_output.owner:get_rate()
end

-- Single-threaded interface

function Pipe:read_max_sp()
    local vec = self.vec
    self.vec = nil
    return vec
end

function Pipe:read_n_sp(n)
    assert(n == self.vec.length, "Partial buffered reads unsupported.")
    local vec = self.vec
    self.vec = nil
    return vec
end

function Pipe:read_update()
    return self.vec.length
end


function Pipe:write_sp(vec)
    self.vec = vec
end

-- Multi-process interface

function Pipe:read_max_mp()
    -- Update our read buffer and read the maximum amount available
    return self:read_n(self:read_update())
end

function Pipe:read_n_mp(num)
    -- Create a vector from the buffer
    local vec, bytes_consumed = self.data_type.deserialize(ffi.cast("char *", self._buf) + self._buf_read_offset, num)

    -- Update the read offset
    self._buf_read_offset = self._buf_read_offset + bytes_consumed

    return vec
end

function Pipe:read_update_mp()
    -- Shift unread samples down to beginning of buffer
    local unread_length = self._buf_size - self._buf_read_offset
    if unread_length > 0 then
        ffi.C.memmove(self._buf, ffi.cast("char *", self._buf) + self._buf_read_offset, unread_length)
    end

    -- Read new samples in
    local iov = ffi.new("struct iovec", ffi.cast("char *", self._buf) + unread_length, self._buf_capacity - unread_length)
    local bytes_read = ffi.C.vmsplice(self._rfd, iov, 1, 0)
    assert(bytes_read > 0, "vmsplice(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    -- Update size and reset unread offset
    self._buf_size = unread_length + bytes_read
    self._buf_read_offset = 0

    -- Return number of elements in our read buffer
    return self.data_type.deserialize_count(self._buf, self._buf_size)
end

function Pipe:write_mp(vec)
    local iov = ffi.new("struct iovec")
    local len = 0

    -- Get buffer and size
    local data, size = self.data_type.serialize(vec)

    -- Write entire buffer
    while len < size do
        iov.iov_base = ffi.cast("char *", data) + len
        iov.iov_len = size - len

        local bytes_written = ffi.C.vmsplice(self._wfd, iov, 1, 0)
        assert(bytes_written > 0, "vmsplice(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

        len = len + bytes_written
    end
end

-- Helper function to read synchronously from a set of pipes

local function read_synchronous(pipes)
    -- Update all pipes and gather amount available
    local num_elems_avail = {}
    for i=1, #pipes do
        num_elems_avail[i] = pipes[i]:read_update()
    end

    -- Compute minimum available across all pipes
    local num_elems = math.min(unpack(num_elems_avail))

    -- Read that amount from all pipes
    local data_in = {}
    for i=1, #pipes do
        data_in[i] = pipes[i]:read_n(num_elems)
    end

    return unpack(data_in)
end

-- Exported module
return {PipeInput = PipeInput, PipeOutput = PipeOutput, AliasedPipeInput = AliasedPipeInput, AliasedPipeOutput = AliasedPipeOutput, Pipe = Pipe, read_synchronous = read_synchronous}
