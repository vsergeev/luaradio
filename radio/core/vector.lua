---
-- Vector classes.
--
-- @module radio.core.vector

local ffi = require('ffi')

local class = require('radio.core.class')
local platform = require('radio.core.platform')

ffi.cdef[[
    void *memset(void *s, int c, size_t n);
    void *memcpy(void *dest, const void *src, size_t n);
]]

---
-- A dynamic array of a C structure type.
--
-- @type Vector
-- @tparam ctype ctype C type
-- @tparam[opt=0] int num Length
local Vector = class.factory()

function Vector.new(ctype, num)
    local self = setmetatable({}, Vector)

    -- Data type
    self.data_type = ctype
    -- Length
    self.length = num or 0
    -- Capacity
    self._capacity = self.length
    -- Size in bytes
    self.size = self.length*ffi.sizeof(ctype)
    -- Allocate and zero buffer
    self._buffer = platform.alloc(self.size)
    ffi.C.memset(self._buffer, 0, self.size)
    -- Cast buffer to data type pointer
    self.data = ffi.cast(ffi.typeof("$ *", ctype), self._buffer)

    return self
end

---
-- Read-only vector constructor for an existing buffer.
--
-- @constructor
-- @local
-- @tparam ctype ctype C data type
-- @tparam cdata buf Buffer
-- @tparam int size Buffer size
-- @treturn Vector Read-only vector
function Vector.cast(ctype, buf, size)
    local self = setmetatable({}, Vector)

    -- Data type
    self.data_type = ctype
    -- Length
    self.length = size/ffi.sizeof(ctype)
    -- Capacity
    self._capacity = self.length
    -- Size in bytes
    self.size = size
    -- Buffer
    self._buffer = buf
    -- Cast buffer to data type pointer
    self.data = ffi.cast(ffi.typeof("const $ *", ctype), buf)

    return self
end

---
-- Compare two vectors for equality.
--
-- @tparam vector other Other vector
-- @treturn bool Result
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

---
-- Get a string representation.
--
-- @treturn string String representation
function Vector:__tostring()
    local strs = {}

    for i = 0, self.length-1 do
        strs[i+1] = tostring(self.data[i])
    end

    return "[" .. table.concat(strs, ", ") .. "]"
end

---
-- Resize the vector.
--
-- @tparam int num New length
-- @treturn Vector self
function Vector:resize(num)
    -- If we're within capacity, adjust length and size
    if num <= self._capacity then
        self.length = num
        self.size = num*ffi.sizeof(self.data_type)
        return self
    end

    -- Calculate new capacity (grow exponentially)
    local capacity = math.max(num, 2*self._capacity)
    -- Calculate new buffer size
    local bufsize = capacity*ffi.sizeof(self.data_type)
    -- Allocate and zero buffer
    local buf = platform.alloc(bufsize)
    ffi.C.memset(buf, 0, bufsize)
    -- Cast buffer to data type pointer
    local ptr = ffi.cast(ffi.typeof("$ *", self.data_type), buf)
    -- Copy old data
    ffi.C.memcpy(buf, self._buffer, math.min(self.size, num*ffi.sizeof(self.data_type)))

    -- Update state
    self.data = ptr
    self.length = num
    self.size = num*ffi.sizeof(self.data_type)
    self._capacity = capacity
    self._buffer = buf

    return self
end

---
-- Append an element to the vector.
--
-- @param elem Element
-- @treturn Vector self
function Vector:append(elem)
    self:resize(self.length + 1)
    self.data[self.length - 1] = elem

    return self
end

---
-- A dynamic array of Lua objects.
--
-- @type ObjectVector
-- @tparam type type Lua class
-- @tparam[opt=0] int num Length
local ObjectVector = class.factory()

function ObjectVector.new(type, num)
    local self = setmetatable({}, ObjectVector)

    -- Class type
    self.data_type = type
    -- Length
    self.length = num or 0
    -- Size in bytes
    self.size = 0
    -- Data array
    self.data = {}

    return self
end

---
-- Get a string representation.
--
-- @treturn string String representation
function ObjectVector:__tostring()
    local strs = {}

    for i = 0, self.length-1 do
        strs[i+1] = tostring(self.data[i])
    end

    return "[" .. table.concat(strs, ", ") .. "]"
end

---
-- Resize the vector.
--
-- @tparam int num New length
-- @treturn Vector self
function ObjectVector:resize(num)
    if num < self.length then
        for i = num, self.length do
            self.data[i] = nil
        end
    end
    self.length = num

    return self
end

---
-- Append an element to the vector.
--
-- @param elem Element
-- @treturn Vector self
function ObjectVector:append(elem)
    self.data[self.length] = elem
    self.length = self.length + 1

    return self
end

return {Vector = Vector, ObjectVector = ObjectVector}
