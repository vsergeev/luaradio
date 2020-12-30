---
-- Platform constants.
--
-- @module radio.platform
-- @tfield string luajit_version LuaJIT version (e.g. "LuaJIT 2.0.4").
-- @tfield string os Operating System (e.g. "Linux", "OSX", "BSD").
-- @tfield string arch Architecture (e.g. "x64", "x86", "arm").
-- @tfield int page_size Page size (e.g. 4096).
-- @tfield int cpu_count CPU count (e.g. 4).
-- @tfield int cpu_model CPU model (e.g. "Intel(R) Core(TM) i5-4570T CPU @ 2.90GHz").
-- @tfield function alloc Platform page-aligned allocator function.
-- @tfield function load Platform FFI load library helper function.
-- @tfield function time_us Platform timestamp function.
-- @tfield bool features.liquid Liquid-dsp library found and enabled.
-- @tfield bool features.volk VOLK library found and enabled.
-- @tfield bool features.fftw3f FFTW3F library found and enabled.
-- @tfield string versions.liquid Liquid-dsp library version.
-- @tfield string versions.volk VOLK library version.
-- @tfield string versions.fftw3f FFTW3F library version.

local os = require('os')
local ffi = require('ffi')

-- Platform specific constants
if ffi.os == "Linux" then
    ffi.cdef[[
        /* Signal definitions */
        enum { SIGINT = 2, SIGPIPE = 13, SIGALRM = 14, SIGTERM = 15, SIGCHLD = 17 };
        /* sigprocmask() definitions */
        enum { SIG_BLOCK = 0, SIG_UNBLOCK = 1, SIG_SETMASK = 2 };
        /* socket() address families */
        enum { AF_UNSPEC = 0, AF_UNIX = 1, AF_INET = 2, AF_INET6 = 10 };
        /* socket() types */
        enum { SOCK_STREAM = 1, SOCK_DGRAM = 2 };
        /* getsockopt()/setsockopt() levels */
        enum { SOL_SOCKET = 1 };
        /* getsockopt()/setsockopt() option names */
        enum { SO_REUSEADDR = 2, SO_ERROR = 4 };
        /* send() flags */
        enum { MSG_NOSIGNAL = 0x4000 };
        /* open() and fcntl() file access mode flags */
        enum { O_NONBLOCK = 0x800 };
        /* errno values */
        enum { ENOENT = 2, EAGAIN = 11, EPIPE = 32, ECONNRESET = 104, ECONNREFUSED = 111, EINPROGRESS = 115 };
    ]]
elseif ffi.os == "BSD" or ffi.os == "OSX" then
    ffi.cdef[[
        /* Signal definitions */
        enum { SIGINT = 2, SIGPIPE = 13, SIGALRM = 14, SIGTERM = 15, SIGCHLD = 20 };
        /* sigprocmask() definitions */
        enum { SIG_BLOCK = 1, SIG_UNBLOCK = 2, SIG_SETMASK = 3 };
        /* socket() address families */
        enum { AF_UNSPEC = 0, AF_UNIX = 1, AF_INET = 2, AF_INET6 = 28 };
        /* socket() types */
        enum { SOCK_STREAM = 1, SOCK_DGRAM = 2 };
        /* getsockopt()/setsockopt() levels */
        enum { SOL_SOCKET = 0xffff };
        /* getsockopt()/setsockopt() option names */
        enum { SO_REUSEADDR = 0x0004, SO_ERROR = 0x1007 };
        /* send() flags */
        enum { MSG_NOSIGNAL = 0x20000 };
        /* open() and fcntl() file access mode flags */
        enum { O_NONBLOCK = 0x0004 };
        /* errno values */
        enum { ENOENT = 2, EAGAIN = 35, EPIPE = 32, ECONNRESET = 54, ECONNREFUSED = 61, EINPROGRESS = 36 };
    ]]
end

-- POSIX Error Formatting
ffi.cdef[[
    char *strerror(int errnum);
]]

-- POSIX Aligned Memory Allocator
ffi.cdef[[
    int posix_memalign(void **memptr, size_t alignment, size_t size);
    void free(void *ptr);
]]

-- POSIX String Functions
ffi.cdef[[
    void *memmove(void *dest, const void *src, size_t n);
    int memcmp(const void *s1, const void *s2, size_t n);
    void *memchr(const void *s, int c, size_t n);
]]

-- POSIX File Descriptor I/O
if ffi.os == "Linux" then
    ffi.cdef("typedef unsigned long int nfds_t;")
elseif ffi.os == "BSD" or ffi.os == "OSX" then
    ffi.cdef("typedef unsigned int nfds_t;")
end

ffi.cdef[[
    /* fcntl() commands */
    enum { F_GETFL = 3, F_SETFL = 4 };

    /* flock() operations */
    enum { LOCK_SH = 0x01, LOCK_EX = 0x02, LOCK_NB = 0x04, LOCK_UN = 0x08 };

    /* poll() events */
    enum { POLLIN = 0x1, POLLOUT = 0x4, POLLHUP = 0x10 };

    typedef intptr_t ssize_t;
    typedef long int off_t;

    struct pollfd {
        int fd;
        short events;
        short revents;
    };

    int fcntl(int fildes, int cmd, ...);

    int flock(int fd, int operation);

    int poll(struct pollfd fds[], nfds_t nfds, int timeout);

    ssize_t read(int fd, void *buf, size_t count);
    ssize_t write(int fd, const void *buf, size_t count);
    off_t lseek(int fildes, off_t offset, int whence);

    int close(int fildes);
    int unlink(const char *pathname);
]]

-- POSIX File Stream I/O
ffi.cdef[[
    /* fseek() whence values */
    enum {SEEK_SET = 0, SEEK_CUR = 1, SEEK_END = 2};

    typedef struct FILE FILE;

    FILE *fopen(const char *path, const char *mode);
    FILE *fdopen(int fd, const char *mode);
    int fileno(FILE *stream);
    int feof(FILE *stream);
    int ferror(FILE *stream);
    int fclose(FILE *stream);

    void rewind(FILE *stream);
    int fseek(FILE *stream, long offset, int whence);

    size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
    int fflush(FILE *stream);
]]

-- POSIX Process Handling
ffi.cdef[[
    /* waitpid() options */
    enum { WNOHANG = 1 };

    typedef int pid_t;

    pid_t fork(void);
    pid_t getpid(void);
    pid_t waitpid(pid_t pid, int *status, int options);
    int kill(pid_t pid, int sig);
]]

-- POSIX Signal Handling
ffi.cdef[[
    /* signal() special handlers */
    enum { SIG_DFL = 0, SIG_IGN = 1 };

    typedef void (*sighandler_t)(int);

    typedef struct {
        uint8_t set[128];
    } sigset_t;

    sighandler_t signal(int signum, sighandler_t handler);
    int sigwait(const sigset_t *set, int *sig);
    int sigprocmask(int how, const sigset_t *restrict set, sigset_t *restrict oset);
    int sigpending(sigset_t *set);

    int sigemptyset(sigset_t *set);
    int sigfillset(sigset_t *set);
    int sigaddset(sigset_t *set, int signum);
    int sigdelset(sigset_t *set, int signum);
    int sigismember(const sigset_t *set, int signum);
]]

-- POSIX sysconf()
ffi.cdef[[
    long sysconf(int name);
]]

-- POSIX Time
ffi.cdef[[
    /* clock_gettime() clock ids */
    enum { CLOCK_REALTIME = 0 };

    typedef long int time_t;
    typedef int clockid_t;

    struct timespec {
        time_t tv_sec;
        long tv_nsec;
    };
    int clock_gettime(clockid_t clk_id, struct timespec *tp);

    int usleep(unsigned int usec);
]]

local function getenv_flag(name)
    local value = string.lower(os.getenv(name) or "")
    return (value == "1" or value == "y" or value == "true" or value == "yes")
end

local platform = {
    luajit_version = jit.version,
    os = ffi.os,
    arch = ffi.arch,
    page_size = 4096,
    cpu_count = -1,
    cpu_model = "unknown",
    features = {
        liquid = false,
        volk = false,
        fftw3f = false,
    },
    versions = {},
    libs = {},
}

-- Platform specific lookups
if platform.os == "Linux" then
    -- Look up page size (_SC_PAGESIZE)
    platform.page_size = tonumber(ffi.C.sysconf(30))
    -- Look up CPU count (_SC_NPROCESSORS_ONLN)
    platform.cpu_count = tonumber(ffi.C.sysconf(84))
    -- Look up CPU model
    local f = io.open("/proc/cpuinfo", "r")
    if f then
        platform.cpu_model = f:read("*all"):match("model name%s*:%s*([^\n]*)")
        f:close()
    end
elseif platform.os == "BSD" then
    -- Look up page size (_SC_PAGESIZE)
    platform.page_size = tonumber(ffi.C.sysconf(47))
    -- Look up CPU count (_SC_NPROCESSORS_ONLN)
    platform.cpu_count = tonumber(ffi.C.sysconf(58))
    -- Look up CPU model
    ffi.cdef("int sysctlbyname(const char *name, void *oldp, size_t *oldlenp, const void *newp, size_t newlen);")
    local buf, sz = ffi.new("char[32]"), ffi.new("size_t[1]", {32})
    if ffi.C.sysctlbyname("hw.model", buf, sz, nil, 0) == 0 then
        platform.cpu_model = ffi.string(buf, sz[0])
    end
elseif platform.os == "OSX" then
    -- Look up page size (_SC_PAGESIZE)
    platform.page_size = tonumber(ffi.C.sysconf(29))
    -- Look up CPU count (_SC_NPROCESSORS_ONLN)
    platform.cpu_count = tonumber(ffi.C.sysconf(58))
    -- Look up CPU model
    ffi.cdef("int sysctlbyname(const char *name, void *oldp, size_t *oldlenp, const void *newp, size_t newlen);")
    local buf, sz = ffi.new("char[32]"), ffi.new("size_t[1]", {32})
    if ffi.C.sysctlbyname("hw.model", buf, sz, nil, 0) == 0 then
        platform.cpu_model = ffi.string(buf, sz[0])
    end
end

-- Platform aligned allocator
platform.alloc = function (size)
    local ptr = ffi.new("void *[1]")
    if ffi.C.posix_memalign(ptr, platform.page_size, size) ~= 0 then
        error("posix_memalign(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
    return ffi.gc(ptr[0], ffi.C.free)
end

-- Platform FFI load library helper
platform.load = function (names)
    for _, name in ipairs(names) do
        local lib_available, lib = pcall(ffi.load, name)
        if lib_available then
            return true, lib
        end
    end
    return false, nil
end

-- Platform timestamp
platform.time_us = function ()
    local tp = ffi.new("struct timespec")
    if ffi.C.clock_gettime(ffi.C.CLOCK_REALTIME, tp) ~= 0 then
        error("clock_gettime(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end
    return tonumber(tp.tv_sec) + (tonumber(tp.tv_nsec) / 1e9)
end

-- Load acceleration libraries
platform.features["liquid"], platform.libs["liquid"] = platform.load({"liquid", "libliquid.so.2d", "libliquid.so.1d"})
platform.features["volk"], platform.libs["volk"] = platform.load({"volk", "libvolk.so.2.3", "libvolk.so.1.4", "libvolk.so.1.3"})
platform.features["fftw3f"], platform.libs["fftw3f"] = platform.load({"fftw3f", "libfftw3f.so.3"})

-- Look up library versions
if platform.features.liquid then
    ffi.cdef[[
        const char *liquid_libversion(void);
    ]]
    platform.versions.liquid = ffi.string(platform.libs.liquid.liquid_libversion())
end
if platform.features.volk then
    ffi.cdef[[
        const char *volk_version(void);
        const char *volk_get_machine(void);
    ]]
    platform.versions.volk = string.format("%s (%s)", ffi.string(platform.libs.volk.volk_version()), ffi.string(platform.libs.volk.volk_get_machine()))
end
if platform.features.fftw3f then
    ffi.cdef[[
        const char fftwf_version[];
    ]]
    platform.versions.fftw3f = ffi.string(platform.libs.fftw3f.fftwf_version)
end

-- Warn if running without acceleration
if not platform.features.liquid and not platform.features.volk then
    io.stderr:write("Warning: neither libliquid nor libvolk found. LuaRadio will run without acceleration.\n")
end

-- Disable features with env vars
platform.features.liquid = platform.features.liquid and not getenv_flag("LUARADIO_DISABLE_LIQUID")
platform.features.volk = platform.features.volk and not getenv_flag("LUARADIO_DISABLE_VOLK")
platform.features.fftw3f = platform.features.fftw3f and not getenv_flag("LUARADIO_DISABLE_FFTW3F")

return platform
