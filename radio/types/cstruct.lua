local ffi = require('ffi')

local object = require('radio.core.object')
local vector = require('radio.core.vector')

local CStructType = object.class_factory()

function CStructType.factory(ct, custom_mt)
    local CustomType
    local mt = object.class_factory(CStructType)

    -- Constructors
    function mt.new(...)
        return CustomType(...)
    end

    function mt.vector(n)
        return vector.vector_calloc(ct .. " *", n, ffi.sizeof(CustomType))
    end

    function mt.vector_from_array(arr)
        local vec = mt.vector(#arr)
        for i = 0, vec.length-1 do
            vec.data[i] = CustomType(unpack(arr[i+1]))
        end
        return vec
    end

    function mt.vector_from_buf(buf, size)
        return vector.vector_cast(ct .. " *", buf, size, ffi.sizeof(CustomType))
    end

    function mt.const_vector_from_buf(buf, size)
        return vector.vector_cast("const " .. ct .. " *", buf, size, ffi.sizeof(CustomType))
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

