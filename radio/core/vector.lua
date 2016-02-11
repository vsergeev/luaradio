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

function Vector:resize(num)
    -- If we're within capacity, adjust length and size
    if num <= self.capacity then
        self.length = num
        self.size = num*ffi.sizeof(self.type)
        return
    end

    -- Calculate new capacity
    local capacity = math.max(1, 2*self.capacity)
    -- Calculate new buffer size
    local size = capacity*ffi.sizeof(self.type)
    -- Allocate buffer
    local buf = ffi.gc(ffi.C.aligned_alloc(PAGE_SIZE, size), ffi.C.free)
    -- Zero buffer
    ffi.C.memset(buf, 0, size)
    -- Cast to specified pointer type
    local ptr = ffi.cast(ffi.typeof("$ *", self.type), buf)
    -- Copy old data
    ffi.C.memcpy(buf, self._buffer, math.min(self.size, num*ffi.sizeof(self.type)))

    -- Adjust state
    self.data = ptr
    self.length = num
    self.capacity = capacity
    self.size = num*ffi.sizeof(self.type)
    self._buffer = buf
end

function Vector:append(elem)
    self:resize(self.length + 1)
    self.data[self.length - 1] = elem
end

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
    return setmetatable({data = ptr, length = num, capacity = num, size = size, type = ctype, _buffer = buf}, Vector)
end

function Vector.cast(ctype, buf, size)
    -- Calculate number of elements
    local num = size/ffi.sizeof(ctype)
    -- Cast to specified pointer type
    local ptr = ffi.cast(ffi.typeof("const $ *", ctype), buf)

    -- Return vector container
    return setmetatable({data = ptr, length = num, capacity = num, size = size, type = ctype, _buffer = buf}, Vector)
end

return {Vector = Vector, PAGE_SIZE = PAGE_SIZE}
