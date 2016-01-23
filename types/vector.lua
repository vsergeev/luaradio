local ffi = require('ffi')

ffi.cdef[[
    void *calloc(size_t nmemb, size_t size);
    void free(void *ptr);
]]

function vector_alloc(ffi_type, n)
    local buf = ffi.gc(ffi.C.calloc(n, ffi.sizeof(ffi_type)), ffi.C.free)
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
