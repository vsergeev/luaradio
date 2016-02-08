local ffi = require('ffi')

-- Aligned allocator/deallocator
ffi.cdef[[
    void *aligned_alloc(size_t alignment, size_t size);
    void free(void *ptr);

    void *memset(void *s, int c, size_t n);
]]

-- OS page size query
ffi.cdef[[
    enum { _SC_PAGESIZE = 0x1e };
    long sysconf(int name);
]]
local PAGE_SIZE = ffi.C.sysconf(ffi.C._SC_PAGESIZE)

local function vector_calloc(cptrtype, n, elem_size)
    -- Allocate buffer
    local buf = ffi.gc(ffi.C.aligned_alloc(PAGE_SIZE, n*elem_size), ffi.C.free)
    -- Zero buffer
    ffi.C.memset(buf, 0, n*elem_size)
    -- Cast to specified pointer type
    local ptr = ffi.cast(cptrtype, buf)

    -- Return vector container
    return {data = ptr, length = n, size = n*elem_size, _buffer = buf}
end

local function vector_cast(cptrtype, buf, size, elem_size)
    -- Cast to specified pointer type
    local ptr = ffi.cast(cptrtype, buf)

    -- Return vector container
    return {data = ptr, length = size/elem_size, size = size, _buffer = buf}
end

return {vector_calloc = vector_calloc, vector_cast = vector_cast, PAGE_SIZE = PAGE_SIZE}
