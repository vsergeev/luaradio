local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local object = require('radio.core.object')
local ObjectVector = require('radio.core.vector').ObjectVector
local ObjectType = radio.types.ObjectType

describe("ObjectVector", function ()
    it("basics", function ()
        local v = ObjectVector()
        assert.is.equal(0, v.length)
        assert.is.equal(0, v.size)

        -- Append some elements
        v:append("test")
        v:append(123)
        v:append("foo")
        v:append("bar")

        -- Check vector properties
        assert.is.equal(4, v.length)
        assert.is.equal(0, v.size)

        -- Check vector elements
        assert.is.equal("test", v.data[0])
        assert.is.equal(123, v.data[1])
        assert.is.equal("foo", v.data[2])
        assert.is.equal("bar", v.data[3])

        -- Resize
        v:resize(2)
        assert.is.equal(2, v.length)
        assert.is.equal(0, v.size)

        -- Check vector elements
        assert.is.equal("test", v.data[0])
        assert.is.equal(123, v.data[1])
        assert.is.equal(nil, v.data[2])
        assert.is.equal(nil, v.data[3])

        -- Resize
        v:resize(100)
        assert.is.equal(100, v.length)
        assert.is.equal(0, v.size)
        assert.is.equal("test", v.data[0])
        assert.is.equal(123, v.data[1])
        assert.is.equal(nil, v.data[2])
        assert.is.equal(nil, v.data[3])
    end)
end)

describe("ObjectType factory", function ()
    -- Test type
    local TestType = ObjectType.factory()

    function TestType.new(a, b)
        local self = setmetatable({}, TestType)
        self.a = a
        self.b = b
        return self
    end

    function TestType:foo()
        return self.a + self.b[1] + self.b[2] + self.b[3] + self.b[4]
    end

    it("constructors", function ()
        local x = TestType(0xdeadbeef, {0xaa, 0xbb, 0xcc, 0xdd})
        assert.is_true(object.isinstanceof(x, TestType))
        assert.is_true(object.isinstanceof(x, ObjectType))

        local v = TestType.vector()
        -- Check vector properties
        assert.is_true(object.isinstanceof(v, ObjectVector))
        assert.is.equal(0, v.length)
        assert.is.equal(0, v.size)

        v:append(x)

        -- Check vector properties
        assert.is_true(object.isinstanceof(v.data[0], TestType))
        assert.is.equal(1, v.length)
        assert.is.equal(0, v.size)
    end)

    it("metatable", function ()
        local x = TestType(0xdeadbeef, {0xaa, 0xbb, 0xcc, 0xdd})

        assert.is.equal(0xdeadc1fd, x:foo())
    end)

    it("object serialization and deserialization", function ()
        local x = TestType(0xdeadbeef, {0xaa, 0xbb, 0xcc, 0xdd})

        -- Serialize to msgpack
        local s = x:to_msgpack()
        assert.is_true(type(s) == "string")
        assert.is_true(#s > 0)

        -- Deserialize from msgpack
        local y = TestType.from_msgpack(s)
        assert.is_true(object.isinstanceof(x, TestType))
        assert.are.same(x, y)

        -- Serialize to json
        local s = x:to_json()
        assert.is_true(type(s) == "string")
        assert.is_true(#s > 0)

        -- Deserialize from json
        local y = TestType.from_json(s)
        assert.is_true(object.isinstanceof(x, TestType))
        assert.are.same(x, y)
    end)

    it("vector serialization and deserialization", function ()
        local v = TestType.vector()
        v:append(TestType(0xcafecafe, {0x01, 0x02, 0x03, 0x04}))
        v:append(TestType(0xdeadbeef, {0xaa, 0xbb, 0xcc, 0xdd}))
        v:append(TestType(0xbeefbeef, {0x05, 0x06, 0x07, 0x08}))

        -- Serialize the vector
        local s = ffi.string(TestType.serialize(v))
        assert.is_true(#s > 0)

        -- Deserialize the vector
        local vv = TestType.deserialize(s, #s)

        -- Check vector properties
        assert.is_true(object.isinstanceof(vv, ObjectVector))
        assert.is.equal(3, vv.length)
        assert.is.equal(0, vv.size)
        assert.is_true(object.isinstanceof(vv.data[0], TestType))

        -- Check vector equality with elements
        assert.are.same(v.data[0], vv.data[0])
        assert.are.same(v.data[1], vv.data[1])
        assert.are.same(v.data[2], vv.data[2])

        -- Deserialization the count
        assert.is.equal(3, TestType.deserialize_count(s, #s))

        -- Deserialize the vector with deserialize_partial()
        local vv, size = TestType.deserialize_partial(s, 2)
        assert.is.equal(42, size)

        -- Check vector properties
        assert.is_true(object.isinstanceof(vv, ObjectVector))
        assert.is.equal(2, vv.length)
        assert.is.equal(0, vv.size)
        assert.is_true(object.isinstanceof(vv.data[0], TestType))

        -- Check vector equality with elements
        assert.are.same(v.data[0], vv.data[0])
        assert.are.same(v.data[1], vv.data[1])
    end)
end)
