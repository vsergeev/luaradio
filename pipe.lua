require('oo')

local ffi = require('ffi')

-- PipeInput class
local PipeInput = class_factory()

function PipeInput.new(name, data_type)
    local self = setmetatable({}, PipeInput)
    self.name = name
    self.data_type = data_type
    self.owner = nil
    self.pipe = nil
    return self
end

function PipeInput:get_data_type()
    error('not implemented')
end

function PipeInput:get_rate()
    error('not implemented')
end

-- PipeOutput class
local PipeOutput = class_factory()

function PipeOutput.new(name, data_type, rate)
    local self = setmetatable({}, PipeOutput)
    self.name = name
    self.data_type = data_type
    self.owner = nil
    self.pipes = {}
    self._rate = rate
    return self
end

function PipeOutput:get_data_type()
    error('not implemented')
end

function PipeOutput:get_rate()
    error('not implemented')
end

-- InternalPipe class
local InternalPipe = class_factory()

function InternalPipe.new(pipe_output, pipe_input)
    local self = setmetatable({}, InternalPipe)
    self.output = pipe_output
    self.input = pipe_input
    self._data = nil

    pipe_output.pipes[#pipe_output.pipes + 1] = self
    pipe_input.pipe = self

    return self
end

function InternalPipe:read()
    local obj = self._data
    self._data = nil
    return obj
end

function InternalPipe:write(obj)
    self._data = obj
end

-- ProcessPipe class
local ProcessPipe = class_factory()

ffi.cdef[[
    int pipe(int pipefd[2]);
    int socketpair(int domain, int type, int protocol, int socket_vector[2]);

    int read(int fd, void *buf, size_t count);
    int write(int fd, const void *buf, size_t count);
    void *calloc(size_t nmemb, size_t size);
    void free(void *ptr);

    void *aligned_alloc(size_t alignment, size_t size);

    struct iovec {
        void *iov_base;
        size_t iov_len;
    };
    int vmsplice(int fd, const struct iovec *iov, unsigned long nr_segs, unsigned int flags);
]]

function ProcessPipe.new(pipe_output, pipe_input)
    local self = setmetatable({}, ProcessPipe)
    self.output = pipe_output
    self.input = pipe_input
    self._data = nil

    pipe_output.pipes[#pipe_output.pipes + 1] = self
    pipe_input.pipe = self

    -- Create UNIX pipe
    local pipe_fds = ffi.new("int[2]")
    assert(ffi.C.pipe(pipe_fds) == 0, "Creating pipe.")

    self._rfd = pipe_fds[0]
    self._wfd = pipe_fds[1]

    self._read_size = 4096*8

    -- FIXME resolve type
    self._type = ComplexFloatType

    -- FIXME use OS page size
    self.buf = ffi.gc(ffi.C.aligned_alloc(4096, self._read_size), ffi.C.free)

    return self
end

function ProcessPipe:read()
    local iov = ffi.new("struct iovec", self.buf, self._read_size)
    local len = ffi.C.vmsplice(self._rfd, iov, 1, 0)
    assert(len == self._read_size, "Read failed.")
    return self._type.from_buffer(self.buf, len)
end

function ProcessPipe:write(obj)
    local iov = ffi.new("struct iovec", obj.data, obj.raw_length)
    local len = ffi.C.vmsplice(self._wfd, iov, 1, 0)
    assert(len == obj.raw_length, "Write failed: " .. len .. " " .. obj.raw_length)
end

function ProcessPipe:fd()
    return self._rfd
end

-- Exported module
return {PipeInput = PipeInput, PipeOutput = PipeOutput, InternalPipe = InternalPipe, ProcessPipe = ProcessPipe}
