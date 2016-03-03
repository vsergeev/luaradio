local ffi = require('ffi')

ffi.cdef[[
    typedef void FILE;
    FILE *fopen(const char *path, const char *mode);
    int fileno(FILE *stream);
    int unlink(const char *pathname);

    int write(int fd, const void *buf, size_t count);
    int read(int fd, void *buf, size_t count);

    typedef uint64_t off_t;
    off_t lseek(int fildes, off_t offset, int whence);

    int close(int fd);

    char *strerror(int errnum);
]]

local function open(str)
    -- Default to empty buffer (e.g. writing only purposes)
    str = str or ""

    -- Create and get a file descriptor to a temporary file
    local tmpfile_path = string.format("/tmp/%08x", math.random(0, 0xffffffff))
    local file = ffi.C.fopen(tmpfile_path, "w+")
    assert(fd ~= -1, "fopen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    -- Get file descriptor from file
    local fd = ffi.C.fileno(file)

    -- Unlink the temporary file
    assert(ffi.C.unlink(tmpfile_path) == 0, "unlink(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    -- Write the buffer
    assert(ffi.C.write(fd, str, #str) == #str, "write(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    -- Reset the file offset
    assert(ffi.C.lseek(fd, 0, ffi.C.SEEK_SET) == 0, "lseek(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    return fd
end

local function read(fd, count)
    -- Read up to to count bytes from the fd
    local buf = ffi.new("char[?]", count)
    local num_read = ffi.C.read(fd, buf, ffi.sizeof(buf))
    assert(num_read >= 0, "read(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    return ffi.string(buf, num_read)
end

local function write(fd, str)
    -- Write the string to the fd
    assert(ffi.C.write(fd, str, #str) == #str, "write(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

local function rewind(fd)
    assert(ffi.C.lseek(fd, 0, ffi.C.SEEK_SET) == 0, "lseek(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

local function close(fd)
    assert(ffi.C.close(fd) == 0, "close(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
end

return {open = open, read = read, write = write, rewind = rewind, close = close}
