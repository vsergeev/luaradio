---
-- Object data type base class.
--
-- @datatype ObjectType

local ffi = require('ffi')
local msgpack = require('radio.thirdparty.MessagePack')
local json = require('radio.thirdparty.json')

local class= require('radio.core.class')

local ObjectVector = require('radio.core.vector').ObjectVector

local ObjectType = class.factory()

---
-- Construct a new data type based on a Lua object. The data type will be
-- serializable between blocks in a flow graph.
--
-- The `new()` constructor must be provided by the implementation.
--
-- @function ObjectType.factory
-- @tparam[opt={}] table methods Table of methods and metamethods
-- @treturn class Data type
function ObjectType.factory(methods)
    local CustomType = class.factory(ObjectType)

    -- Constructors

    ---
    -- Construct a vector of this type.
    --
    -- @function ObjectType.vector
    -- @tparam int num Number of elements in the vector
    -- @treturn ObjectVector Vector
    function CustomType.vector(num)
        return ObjectVector(CustomType, num)
    end

    ---
    -- Construct a vector of this type initialized from an array.
    --
    -- @function ObjectType.vector_from_array
    -- @tparam array arr Array with element initializers
    -- @treturn ObjectVector Vector
    function CustomType.vector_from_array(arr)
        local vec = ObjectVector(CustomType)
        for i = 1, #arr do
            vec:append(CustomType(unpack(arr[i])))
        end
        return vec
    end

    -- Serialization/Deserialization

    ---
    -- Serialize this object with MessagePack.
    --
    -- @function ObjectType:to_msgpack
    -- @treturn string MessagePack serialized object
    function CustomType:to_msgpack()
        return msgpack.pack(self)
    end

    ---
    -- Serialize this object with JSON.
    --
    -- @function ObjectType:to_json
    -- @treturn string JSON serialized object
    function CustomType:to_json()
        return json.encode(self)
    end

    ---
    -- Deserialize an instance of this type with MessagePack.
    --
    -- @function ObjectType:from_msgpack
    -- @tparam string str MessagePack serialized object
    -- @treturn ObjectType Deserialized object
    function CustomType.from_msgpack(str)
        local obj = msgpack.unpack(str)
        return setmetatable(obj, CustomType)
    end

    ---
    -- Deserialize an instance of this type with JSON.
    --
    -- @function ObjectType:from_json
    -- @tparam string str JSON serialized object
    -- @treturn ObjectType Deserialized object
    function CustomType.from_json(str)
        local obj = json.decode(str)
        return setmetatable(obj, CustomType)
    end

    -- Buffer serialization interface

    ---
    -- Serialize a ObjectType vector into a buffer.
    --
    -- @internal
    -- @function ObjectType.serialize
    -- @tparam Vector vec Vector
    -- @treturn cdata Buffer
    -- @treturn int Size
    function CustomType.serialize(vec)
        local buf = ""

        for i = 0, vec.length-1 do
            local obj_ser = msgpack.pack(vec.data[i])
            local obj_size = #obj_ser

            -- Pack the big endian 32-bit size header
            buf = buf .. string.char(
                            bit.band(bit.rshift(obj_size, 24), 0xff),
                            bit.band(bit.rshift(obj_size, 16), 0xff),
                            bit.band(bit.rshift(obj_size, 8), 0xff),
                            bit.band(obj_size, 0xff)
                         )

            -- Pack the object
            buf = buf .. obj_ser
        end

        return buf, #buf
    end

    ---
    -- Deserialize a buffer into a ObjectType read-only vector.
    --
    -- @internal
    -- @function ObjectType.deserialize
    -- @tparam cdata buf Buffer
    -- @tparam int size Size
    -- @treturn Vector Vector
    function CustomType.deserialize(buf, size)
        local num_elems = CustomType.deserialize_count(buf, size)
        local vec = CustomType.deserialize_partial(buf, num_elems)
        return vec
    end

    ---
    -- Partially deserialize a buffer into a ObjectType read-only vector.
    --
    -- @internal
    -- @function ObjectType.deserialize
    -- @tparam cdata buf Buffer
    -- @tparam int count Count of elements
    -- @treturn Vector Vector
    function CustomType.deserialize_partial(buf, count)
        local vec = ObjectVector(CustomType)

        buf = ffi.cast("const uint8_t *", buf)

        local p = buf

        for i=1, count do
            -- Read the big endian 32-bit size header
            local obj_size = bit.bor(bit.lshift(p[0], 24), bit.lshift(p[1], 16), bit.lshift(p[2], 8), p[3])
            -- Extract the packed bytes as a string
            local obj_ser = ffi.string(p + 4, obj_size)
            -- Unpack the object
            local obj = setmetatable(msgpack.unpack(obj_ser), CustomType)
            -- Add it to the vector
            vec:append(obj)

            -- Advance p
            p = p + 4 + obj_size
        end

        return vec, (p-buf)
    end

    ---
    -- Deserialize count of ObjectType elements in a buffer.
    --
    -- @internal
    -- @function ObjectType.deserialize
    -- @tparam cdata buf Buffer
    -- @tparam int size Size
    -- @treturn int Count
    function CustomType.deserialize_count(buf, size)
        local num_elems = 0

        local p = ffi.cast("const uint8_t *", buf)
        local endp = p + size

        while (endp - p) >= 4 do
            -- Read the big endian 32-bit size header
            local obj_size = bit.bor(bit.lshift(p[0], 24), bit.lshift(p[1], 16), bit.lshift(p[2], 8), p[3])
            -- Adjust p with the size header
            p = p + 4 + obj_size

            -- If we're still in the buffer, increment the element count
            if p <= endp then
                num_elems = num_elems + 1
            end
        end

        return num_elems
    end

    ---
    -- Type name of this ObjectType.
    --
    -- @property ObjectType.type_name
    -- @treturn string Type name
    CustomType.type_name = "ObjectType"

    -- Absorb the user-defined metatable
    if methods then
        for k,v in pairs(methods) do
            CustomType[k] = v
        end
    end

    return CustomType
end

return ObjectType
