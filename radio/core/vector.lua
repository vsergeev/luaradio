---
-- Vector classes.
--
-- @module radio.vector

local ffi = require('ffi')

local class = require('radio.core.class')
local platform = require('radio.core.platform')

---
-- A dynamic array of a C structure type.
--
-- @class Vector
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
    ffi.fill(self._buffer, self.size)
    -- Cast buffer to data type pointer
    self.data = ffi.cast(ffi.typeof("$ *", ctype), self._buffer)

    return self
end

---
-- Read-only vector constructor for an existing buffer.
--
-- @internal
-- @function Vector.cast
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
-- @function Vector:__eq
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
-- @function Vector:__tostring
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
-- @function Vector:resize
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
    ffi.fill(buf, bufsize)
    -- Cast buffer to data type pointer
    local ptr = ffi.cast(ffi.typeof("$ *", self.data_type), buf)
    -- Copy old data
    ffi.copy(buf, self._buffer, math.min(self.size, num*ffi.sizeof(self.data_type)))

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
-- @function Vector:append
-- @param elem Element
-- @treturn Vector self
function Vector:append(elem)
    self:resize(self.length + 1)
    self.data[self.length - 1] = elem

    return self
end


---
-- Fill a vector with an element.
--
-- @function Vector:fill
-- @param elem Element
-- @treturn Vector self
function Vector:fill(elem)
    for i=0, self.length - 1 do
        self.data[i] = elem
    end

    return self
end

---
-- A dynamic array of a Lua object type.
--
-- @class ObjectVector
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
    for i = 0, self.length-1 do
        self.data[i] = type()
    end

    return self
end

---
-- Get a string representation.
--
-- @function ObjectVector:__tostring
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
-- @function ObjectVector:resize
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
-- @function ObjectVector:append
-- @param elem Element
-- @treturn Vector self
function ObjectVector:append(elem)
    self.data[self.length] = elem
    self.length = self.length + 1

    return self
end

return {Vector = Vector, ObjectVector = ObjectVector}
