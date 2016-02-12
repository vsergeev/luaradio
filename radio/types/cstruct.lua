local ffi = require('ffi')

local object = require('radio.core.object')
local Vector = require('radio.core.vector').Vector

local CStructType = object.class_factory()

function CStructType.factory(ct, custom_mt)
    local CustomType
    local mt = object.class_factory(CStructType)

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
            vec.data[i] = CustomType(unpack(arr[i+1]))
        end
        return vec
    end

    -- Buffer serialization interface
    function mt.serialize(vec)
        return vec.data, vec.size
    end

    function mt.deserialize(buf, count)
        local size = count*ffi.sizeof(CustomType)
        return Vector.cast(CustomType, buf, size), size
    end

    function mt.deserialize_count(buf, size)
        return math.floor(size/ffi.sizeof(CustomType))
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

return {CStructType = CStructType}

