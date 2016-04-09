local os = require('os')
local ffi = require('ffi')

ffi.cdef[[
    long sysconf(int name);
]]

local function getenv_flag(name)
    local value = string.lower(os.getenv(name) or "")
    return (value == "1" or value == "y" or value == "true" or value == "yes")
end

-- Default platform configuration
local platform = {
    os = ffi.os,
    arch = ffi.arch,
    page_size = 4096,
    features = {
        volk = false,
        fftw3f = false,
        vmsplice = false,
    },
    libs = {},
}

-- Load libvolk if it is available
local libvolk_available, libvolk = pcall(ffi.load, "volk")
if libvolk_available then
    platform.libs.volk = libvolk
    platform.features.volk = true
else
    io.stderr:write("Warning: libvolk not found. LuaRadio will run without volk acceleration.\n")
end

-- Load libfftw3f if it is available
local libfftw3f_available, libfftw3f = pcall(ffi.load, "fftw3f")
if libfftw3f_available then
    platform.libs.fftw3f = libfftw3f
    platform.features.fftw3f = true
end

-- Platform specific lookups
if platform.os == "Linux" then
    -- Look up page size
    platform.page_size = ffi.C.sysconf(0x1e)
    -- vmsplice() system call available
    platform.features.vmsplice = true
    -- Signal definitions
    ffi.cdef("enum { SIGINT = 2, SIGTERM = 15, SIGCHLD = 17 };")
    -- sigprocmask() definitions
    ffi.cdef("enum { SIG_BLOCK = 0, SIG_UNBLOCK = 1, SIG_SETMASK = 2 };")
elseif platform.os == "BSD" then
    -- Look up page size
    platform.page_size = ffi.C.sysconf(0x2f)
    -- Signal definitions
    ffi.cdef("enum { SIGINT = 2, SIGTERM = 15, SIGCHLD = 20 };")
    -- sigprocmask() definitions
    ffi.cdef("enum { SIG_BLOCK = 1, SIG_UNBLOCK = 2, SIG_SETMASK = 3 };")
elseif platform.os == "OSX" then
    -- Look up page size
    platform.page_size = ffi.C.sysconf(0x1d)
    -- Signal definitions
    ffi.cdef("enum { SIGINT = 2, SIGTERM = 15, SIGCHLD = 20 };")
    -- sigprocmask() definitions
    ffi.cdef("enum { SIG_BLOCK = 1, SIG_UNBLOCK = 2, SIG_SETMASK = 3 };")
end

-- POSIX Aligned memory allocator
ffi.cdef[[
    int posix_memalign(void **memptr, size_t alignment, size_t size);
    void free(void *ptr);
    char *strerror(int errnum);
]]

platform.alloc = function (size)
    local ptr = ffi.new("void *[1]")
    assert(ffi.C.posix_memalign(ptr, platform.page_size, size) == 0, "posix_memalign(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    return ffi.gc(ptr[0], ffi.C.free)
end

-- Disable features with env vars
platform.features.volk = platform.features.volk and not getenv_flag("LUARADIO_DISABLE_VOLK")
platform.features.fftw3f = platform.features.fftw3f and not getenv_flag("LUARADIO_DISABLE_FFTW3")
platform.features.vmsplice = platform.features.vmsplice and not getenv_flag("LUARADIO_DISABLE_VMSPLICE")

return platform
