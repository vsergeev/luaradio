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

    function mt.const_vector_from_buf(buf, size)
        return Vector.cast(CustomType, buf, size)
    end

    -- Absorb the user-defined metatable
    for k,v in pairs(custom_mt) do
        mt[k] = v
    end

    -- FFI type binding
    CustomType = ffi.metatype(ct, mt)

    return CustomType
end

return {CStructType = CStructType}

