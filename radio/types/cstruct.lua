local ffi = require('ffi')

local class = require('radio.core.class')
local Vector = require('radio.core.vector').Vector

local CStructType = class.factory()

ffi.cdef[[
    int memcmp(const void *s1, const void *s2, size_t n);
]]

function CStructType.factory(ct, custom_mt)
    local CustomType

    local mt = class.factory(CStructType)

    -- Constructors
    function mt.new(...)
        return CustomType(...)
    end

    function mt.vector(num)
        return Vector(CustomType, num)
    end

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

    -- Buffer serialization interface
    function mt.serialize(vec)
        return vec.data, vec.size
    end

    function mt.deserialize(buf, size)
        return Vector.cast(CustomType, buf, size)
    end

    function mt.deserialize_partial(buf, count)
        local size = count*ffi.sizeof(CustomType)
        return Vector.cast(CustomType, buf, size), size
    end

    function mt.deserialize_count(buf, size)
        return math.floor(size/ffi.sizeof(CustomType))
    end

    -- Comparison
    function mt:__eq(other)
        return ffi.C.memcmp(self, other, ffi.sizeof(CustomType)) == 0
    end

    -- Absorb the user-defined metatable
    if custom_mt then
        for k,v in pairs(custom_mt) do
            mt[k] = v
        end
    end

    -- FFI type binding
    CustomType = ffi.metatype(ct, mt)

    return CustomType
end

return CStructType
