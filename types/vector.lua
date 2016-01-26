local ffi = require('ffi')

ffi.cdef[[
    void *aligned_alloc(size_t alignment, size_t size);
    void *memset(void *s, int c, size_t n);
    void free(void *ptr);
]]

function vector_alloc(ffi_type, n)
    -- FIXME use OS page size
    local buf = ffi.gc(ffi.C.aligned_alloc(4096, n*ffi.sizeof(ffi_type)), ffi.C.free)
    ffi.C.memset(buf, 0, n*ffi.sizeof(ffi_type))
    local ptr = ffi.cast(ffi.typeof("$ *", ffi_type), buf)
    return {data = ptr, _buf = buf, length = n, raw_length = n*ffi.sizeof(ffi_type)}
end

function vector_alloc_factory(ffi_type)
    local ctype = ffi.typeof("$ *", ffi_type)
    local sz = ffi.sizeof(ffi_type)
    return function (n)
        local data = ffi.cast(ctype, ffi.gc(ffi.C.calloc(n, sz), ffi.C.free))
        return {data = data, length = n, raw_length = n*sz}
    end
end
