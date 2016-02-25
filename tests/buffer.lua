local ffi = require('ffi')

ffi.cdef[[
    typedef uint32_t mode_t;
    int shm_open(const char *name, int oflag, mode_t mode);
    int shm_unlink(const char *name);
    enum {O_CREAT = 0x40, O_RDWR = 0x02};

    int write(int fd, const void *buf, size_t count);
    int read(int fd, void *buf, size_t count);

    typedef uint64_t off_t;
    off_t lseek(int fildes, off_t offset, int whence);
    enum {SEEK_SET = 0, SEEK_CUR = 1, SEEK_END = 2};

    int close(int fd);

    char *strerror(int errnum);
]]
local librt = ffi.load("rt")

local function open(str)
    -- Default to empty buffer (e.g. writing only purposes)
    str = str or ""

    -- Create and get a file descriptor to a shared memory object
    local shmobj_name = string.format("/%08x", math.random(0, 0xffffffff))
    local fd = librt.shm_open(shmobj_name, bit.bor(ffi.C.O_CREAT, ffi.C.O_RDWR), tonumber("600", 8))
    assert(fd ~= -1, "shm_open(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    -- Unlink the shared memory object
    assert(librt.shm_unlink(shmobj_name) == 0, "shm_unlink(): " .. ffi.string(ffi.C.strerror(ffi.errno())))

    -- Write the buffer to the shared memory object
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
