local ffi = require('ffi')

local object = require('radio.core.object')

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

-- Vector object

local Vector = object.class_factory()

-- Constructors

function Vector.new(ctype, num)
    num = num or 0

    -- Calculate size
    local size = num*ffi.sizeof(ctype)
    -- Allocate buffer
    local buf = ffi.gc(ffi.C.aligned_alloc(PAGE_SIZE, size), ffi.C.free)
    -- Zero buffer
    ffi.C.memset(buf, 0, size)
    -- Cast to specified pointer type
    local ptr = ffi.cast(ffi.typeof("$ *", ctype), buf)

    -- Return vector container
    return setmetatable({data = ptr, length = num, size = size, type = ctype, _buffer = buf}, Vector)
end

function Vector.cast(ctype, buf, size)
    -- Calculate number of elements
    local num = size/ffi.sizeof(ctype)
    -- Cast to specified pointer type
    local ptr = ffi.cast(ffi.typeof("const $ *", ctype), buf)

    -- Return vector container
    return setmetatable({data = ptr, length = num, size = size, type = ctype, _buffer = buf}, Vector)
end

return {Vector = Vector, PAGE_SIZE = PAGE_SIZE}
