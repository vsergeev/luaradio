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
        self._buf_unread_offset = 0

        self.read = self.read_multiprocess
        self.write = self.write_multiprocess
        self.update_read_buffer = self.update_read_buffer_multiprocess
        self.read_buffered = self.read_buffered_multiprocess
    else
        self._data = nil

        self.read = self.read_singleprocess
        self.write = self.write_singleprocess
        self.update_read_buffer = self.update_read_buffer_singleprocess
        self.read_buffered = self.read_buffered_singleprocess
    end
end

function Pipe:get_rate()
    return self.pipe_output.owner:get_rate()
end

-- Single-threaded interface

function Pipe:read_singleprocess()
    local vec = self._data
    self._data = nil
    return vec
end

function Pipe:write_singleprocess(vec)
    self._data = vec
end

function Pipe:update_read_buffer_singleprocess()
    return self._data.size
end

function Pipe:read_buffered_singleprocess(n)
    assert(n == self._data.size, "Partial buffered reads unsupported.")
    local vec = self._data
    self._data = nil
    return vec
end

-- Multi-process interface

function Pipe:read_multiprocess()
    local iov = ffi.new("struct iovec", self._buf, self._buf_capacity)
    local bytes_read = ffi.C.vmsplice(self._rfd, iov, 1, 0)
    assert(bytes_read > 0, "vmsplice(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    return self.data_type.const_vector_from_buf(self._buf, bytes_read)
end

function Pipe:write_multiprocess(vec)
    local iov = ffi.new("struct iovec")
    local len = 0

    while len < vec.size do
        iov.iov_base = ffi.cast("char *", vec.data) + len
        iov.iov_len = vec.size - len

        local bytes_written = ffi.C.vmsplice(self._wfd, iov, 1, 0)
        assert(bytes_written > 0, "vmsplice(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

        len = len + bytes_written
    end
end

function Pipe:update_read_buffer_multiprocess()
    -- Shift unread samples down to beginning of buffer
    local unread_length = self._buf_size - self._buf_unread_offset
    ffi.C.memmove(self._buf, ffi.cast("char *", self._buf) + self._buf_unread_offset, unread_length)

    -- Read new samples in
    local iov = ffi.new("struct iovec", ffi.cast("char *", self._buf) + unread_length, self._buf_capacity - unread_length)
    local bytes_read = ffi.C.vmsplice(self._rfd, iov, 1, 0)
    assert(bytes_read > 0, "vmsplice(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    -- Update size and reset unread offset
    self._buf_size = unread_length + bytes_read
    self._buf_unread_offset = 0

    return self._buf_size
end

function Pipe:read_buffered_multiprocess(n)
    assert((self._buf_unread_offset + n) <= self._buf_size, "Size out of bounds.")
    local vec = self.data_type.const_vector_from_buf(ffi.cast("char *", self._buf) + self._buf_unread_offset, n)
    self._buf_unread_offset = self._buf_unread_offset + n
    return vec
end

-- Helper function to read synchronously from a set of pipes

local function read_synchronous(pipes)
    -- Update all pipes and gather amount available
    local num_elems_avail = {}
    for i=1, #pipes do
        num_elems_avail[i] = math.floor(pipes[i]:update_read_buffer()/ffi.sizeof(pipes[i].data_type))
    end

    -- Compute minimum available across all pipes
    local num_elems = math.min(unpack(num_elems_avail))

    -- Read that amount from all pipes
    local data_in = {}
    for i=1, #pipes do
        data_in[i] = pipes[i]:read_buffered(num_elems*ffi.sizeof(pipes[i].data_type))
    end

    return unpack(data_in)
end

-- Exported module
return {PipeInput = PipeInput, PipeOutput = PipeOutput, AliasedPipeInput = AliasedPipeInput, AliasedPipeOutput = AliasedPipeOutput, Pipe = Pipe, read_synchronous = read_synchronous}
