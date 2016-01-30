local ffi = require('ffi')

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

-- InternalPipe class
local InternalPipe = object.class_factory()

function InternalPipe.new(pipe_output, pipe_input, data_type)
    local self = setmetatable({}, InternalPipe)
    self.pipe_output = pipe_output
    self.pipe_input = pipe_input
    self.data_type = data_type

    self._data = nil
    return self
end

function InternalPipe:get_rate()
    return self.pipe_output.owner:get_rate()
end

function InternalPipe:read()
    local vec = self._data
    self._data = nil
    return vec
end

function InternalPipe:write(vec)
    self._data = vec
end

-- ProcessPipe class
local ProcessPipe = object.class_factory()


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

function ProcessPipe.new(pipe_output, pipe_input, data_type)
    local self = setmetatable({}, ProcessPipe)
    self.pipe_output = pipe_output
    self.pipe_input = pipe_input
    self.data_type = data_type

    -- Create UNIX pipe
    local pipe_fds = ffi.new("int[2]")
    assert(ffi.C.pipe(pipe_fds) == 0, "pipe(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    self._rfd = pipe_fds[0]
    self._wfd = pipe_fds[1]

    -- Pre-allocate read buffer
    self._buf_size = 32768
    self._buf = ffi.gc(ffi.C.aligned_alloc(vector.PAGE_SIZE, self._buf_size), ffi.C.free)

    return self
end

function ProcessPipe:get_rate()
    return self.pipe_output.owner:get_rate()
end

function ProcessPipe:read()
    local iov = ffi.new("struct iovec", self._buf, self._buf_size)
    local len = ffi.C.vmsplice(self._rfd, iov, 1, 0)
    assert(len == self._buf_size, "Read failed.")
    return self.data_type.vector_from_const_buf(self._buf, len)
end

function ProcessPipe:write(vec)
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

-- Exported module
return {PipeInput = PipeInput, PipeOutput = PipeOutput, InternalPipe = InternalPipe, ProcessPipe = ProcessPipe}
