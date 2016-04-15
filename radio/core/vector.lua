local ffi = require('ffi')

local object = require('radio.core.object')
local platform = require('radio.core.platform')

ffi.cdef[[
    void *memset(void *s, int c, size_t n);
    void *memcpy(void *dest, const void *src, size_t n);
]]

-- Vector object

local Vector = object.class_factory()

function Vector:__eq(other)
    if self.length ~= other.length then
        return false
    end

    for i = 0, self.length-1 do
        if self.data[i] ~= other.data[i] then
            return false
        end
    end

    return true
end

function Vector:resize(num)
    -- If we're within capacity, adjust length and size
    if num <= self._capacity then
        self.length = num
        self.size = num*ffi.sizeof(self.type)
        return
    end

    -- Calculate new capacity (grow exponentially)
    local capacity = math.max(num, 2*self._capacity)
    -- Calculate new buffer size
    local bufsize = capacity*ffi.sizeof(self.type)
    -- Allocate and zero buffer
    local buf = platform.alloc(bufsize)
    ffi.C.memset(buf, 0, bufsize)
    -- Cast to specified pointer type
    local ptr = ffi.cast(ffi.typeof("$ *", self.type), buf)
    -- Copy old data
    ffi.C.memcpy(buf, self._buffer, math.min(self.size, num*ffi.sizeof(self.type)))

    -- Update state
    self.data = ptr
    self.length = num
    self.size = num*ffi.sizeof(self.type)
    self._capacity = capacity
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
    local buf = platform.alloc(size)
    -- Zero buffer
    ffi.C.memset(buf, 0, size)
    -- Cast to specified pointer type
    local ptr = ffi.cast(ffi.typeof("$ *", ctype), buf)

    -- Return vector container
    return setmetatable({data = ptr, length = num, _capacity = num, size = size, type = ctype, _buffer = buf}, Vector)
end

function Vector.cast(ctype, buf, size)
    -- Calculate number of elements
    local num = size/ffi.sizeof(ctype)
    -- Cast to specified pointer type
    local ptr = ffi.cast(ffi.typeof("const $ *", ctype), buf)

    -- Return vector container
    return setmetatable({data = ptr, length = num, _capacity = num, size = size, type = ctype, _buffer = buf}, Vector)
end

return {Vector = Vector}
