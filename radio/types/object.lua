local ffi = require('ffi')
local msgpack = require('radio.thirdparty.MessagePack')
local json = require('radio.thirdparty.json')

local object = require('radio.core.object')

local ObjectVector
local ObjectType = object.class_factory()

function ObjectType.factory(custom_mt)
    local CustomType = object.class_factory(ObjectType)

    -- Constructors
    function CustomType.vector(num)
        return ObjectVector(num)
    end

    -- Serializers
    function CustomType:to_msgpack()
        return msgpack.pack(self)
    end

    function CustomType:to_json()
        return json.encode(self)
    end

    -- Deserializers
    function CustomType.from_msgpack(str)
        local obj = msgpack.unpack(str)
        return setmetatable(obj, CustomType)
    end

    function CustomType.from_json(str)
        local obj = json.decode(str)
        return setmetatable(obj, CustomType)
    end

    -- Buffer serialization interface
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

    function CustomType.deserialize(buf, count)
        local vec = ObjectVector()

        local p = ffi.cast("const uint8_t *", buf)

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

    -- Absorb the user-defined metatable
    if custom_mt then
        for k,v in pairs(custom_mt) do
            mt[k] = v
        end
    end

    return CustomType
end

-- ObjectVector

-- This is a simple wrapper to a Lua array that implements a Vector compatible
-- interface.

ObjectVector = object.class_factory()

function ObjectVector.new(num)
    return setmetatable({data = {}, length = 0, size = 0}, ObjectVector)
end

function ObjectVector:resize(num)
    if num < self.length then
        for i = num, self.length do
            self.data[i] = nil
        end
    end
    self.length = num
end

function ObjectVector:append(elem)
    self.data[self.length] = elem
    self.length = self.length + 1
end

return {ObjectType = ObjectType, ObjectVector = ObjectVector}
