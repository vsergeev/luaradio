---
-- CStruct data type base class.
-- @datatype CStructType
-- @classmod CStructType

local ffi = require('ffi')

local class = require('radio.core.class')
local Vector = require('radio.core.vector').Vector

local CStructType = class.factory()

ffi.cdef[[
    int memcmp(const void *s1, const void *s2, size_t n);
]]

---
-- Construct a new data type based on a C structure type. The data type will be
-- serializable between blocks in a flow graph.
--
-- @static
-- @function factory
-- @tparam string|ctype ctype C type
-- @tparam[opt={}] table methods Table of methods and metamethods
-- @treturn class Data type
function CStructType.factory(ctype, methods)
    local CustomType

    local mt = class.factory(CStructType)

    -- Constructors

    ---
    -- Construct a new instance of this type.
    --
    -- @function CStructType.new
    -- @param ... Arguments
    function mt.new(...)
        return CustomType(...)
    end

    ---
    -- Construct a zero-initialized vector of this type.
    --
    -- @function CStructType.vector
    -- @tparam int num Number of elements in the vector
    -- @treturn Vector Vector
    function mt.vector(num)
        return Vector(CustomType, num)
    end

    ---
    -- Construct a vector of this type initialized from an array.
    --
    -- @function CStructType.vector_from_array
    -- @tparam array arr Array with element initializers
    -- @treturn Vector Vector
    function mt.vector_from_array(arr)
        local vec = Vector(CustomType, #arr)
        for i = 0, vec.length-1 do
            if type(arr[i+1]) == "table" then
                vec.data[i] = CustomType(unpack(arr[i+1]))
            else
                vec.data[i] = CustomType(arr[i+1])
            end
        end
        return vec
    end

    -- Comparison

    ---
    -- Compare two instances of this type.
    --
    -- @function CStructType:__eq
    -- @tparam CStructType other Other instance
    -- @treturn bool Result
    function mt:__eq(other)
        return ffi.C.memcmp(self, other, ffi.sizeof(CustomType)) == 0
    end

    -- Buffer serialization interface

    ---
    -- Serialize a CStructType vector into a buffer.
    --
    -- @local
    -- @function CStructType.serialize
    -- @tparam Vector vec Vector
    -- @treturn cdata Buffer
    -- @treturn int Size
    function mt.serialize(vec)
        return vec.data, vec.size
    end

    ---
    -- Deserialize a buffer into a CStructType read-only vector.
    --
    -- @local
    -- @function CStructType.deserialize
    -- @tparam cdata buf Buffer
    -- @tparam int size Size
    -- @treturn Vector Vector
    function mt.deserialize(buf, size)
        return Vector.cast(CustomType, buf, size)
    end

    ---
    -- Partially deserialize a buffer into a CStructType read-only vector.
    --
    -- @local
    -- @function CStructType.deserialize
    -- @tparam cdata buf Buffer
    -- @tparam int count Count of elements
    -- @treturn Vector Vector
    function mt.deserialize_partial(buf, count)
        local size = count*ffi.sizeof(CustomType)
        return Vector.cast(CustomType, buf, size), size
    end

    ---
    -- Deserialize count of CStructType elements in a buffer.
    --
    -- @local
    -- @function CStructType.deserialize
    -- @tparam cdata buf Buffer
    -- @tparam int size Size
    -- @treturn int Count
    function mt.deserialize_count(buf, size)
        return math.floor(size/ffi.sizeof(CustomType))
    end

    -- Absorb the user-defined metatable
    if methods then
        for k,v in pairs(methods) do
            mt[k] = v
        end
    end

    -- FFI type binding
    CustomType = ffi.metatype(ctype, mt)

    return CustomType
end

return CStructType
