local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local CStructType = radio.types.CStructType

describe("CStructType factory", function ()
    -- Test struct
    ffi.cdef[[
        typedef struct {
            uint32_t a;
            struct {
                uint8_t c[4];
            } b;
        } test_t;
    ]]

    -- Test metatable
    local mt = {
        foo = function (self) return self.a + self.b.c[0] + self.b.c[1] + self.b.c[2] + self.b.c[3] end
    }

    -- Manufacture the type
    local TestType = CStructType.factory("test_t", mt)

    it("size", function ()
        -- Check underlying struct size
        assert.is.equal(8, ffi.sizeof(TestType))
    end)

    it("constructors", function ()
        local x = TestType({0xdeadbeef, {{0xaa, 0xbb, 0xcc, 0xdd}}})

        -- Check initialization
        assert.is.equal(0xdeadbeef, x.a)
        assert.is.equal(0xaa, x.b.c[0])
        assert.is.equal(0xbb, x.b.c[1])
        assert.is.equal(0xcc, x.b.c[2])
        assert.is.equal(0xdd, x.b.c[3])

        local y = TestType{a = 0xdeadbeef, b = {{0xaa, 0xbb, 0xcc, 0xdd}}}

        -- Check initialization
        assert.is.equal(0xdeadbeef, y.a)
        assert.is.equal(0xaa, y.b.c[0])
        assert.is.equal(0xbb, y.b.c[1])
        assert.is.equal(0xcc, y.b.c[2])
        assert.is.equal(0xdd, y.b.c[3])

        local v1 = TestType.vector(3)

        -- Check vector properties
        assert.is.equal(TestType, v1.data_type)
        assert.is.equal(3, v1.length)
        assert.is.equal(3*ffi.sizeof(TestType), v1.size)
        assert.is_true(ffi.istype(TestType, v1.data[0]))

        -- Check initialization
        for i = 0, v1.length-1 do
            assert.is.equal(0x0, v1.data[i].a)
            assert.is.equal(0x0, v1.data[i].b.c[0])
            assert.is.equal(0x0, v1.data[i].b.c[1])
            assert.is.equal(0x0, v1.data[i].b.c[2])
            assert.is.equal(0x0, v1.data[i].b.c[3])
        end

        local v2 = TestType.vector_from_array({{0xcafecafe, {{0x01, 0x02, 0x03, 0x04}}},
                                               {0xbeefbeef, {{0x05, 0x06, 0x07, 0x08}}}})

        -- Check vector properties
        assert.is.equal(TestType, v2.data_type)
        assert.is.equal(2, v2.length)
        assert.is.equal(2*ffi.sizeof(TestType), v2.size)
        assert.is_true(ffi.istype(TestType, v2.data[0]))

        -- Check initialization
        assert.is.equal(0xcafecafe, v2.data[0].a)
        assert.is.equal(0x01, v2.data[0].b.c[0])
        assert.is.equal(0x02, v2.data[0].b.c[1])
        assert.is.equal(0x03, v2.data[0].b.c[2])
        assert.is.equal(0x04, v2.data[0].b.c[3])
        assert.is.equal(0xbeefbeef, v2.data[1].a)
        assert.is.equal(0x05, v2.data[1].b.c[0])
        assert.is.equal(0x06, v2.data[1].b.c[1])
        assert.is.equal(0x07, v2.data[1].b.c[2])
        assert.is.equal(0x08, v2.data[1].b.c[3])
    end)

    it("comparison", function ()
        local x = TestType({0xdeadbeef, {{0xaa, 0xbb, 0xcc, 0xdd}}})
        local y = TestType{a = 0xdeadbeef, b = {{0xaa, 0xbb, 0xcc, 0xdd}}}

        assert.is_true(x == y)

        y.b.c[1] = 0xee
        assert.is_true(x ~= y)
    end)

    it("metatable", function ()
        local x = TestType({0xdeadbeef, {{0xaa, 0xbb, 0xcc, 0xdd}}})

        assert.is.equal(0xdeadc1fd, x:foo())
    end)

    it("vector serialization and deserialization", function ()
        local v = TestType.vector_from_array({{0xcafecafe, {{0x01, 0x02, 0x03, 0x04}}},
                                              {0xdeadbeef, {{0xaa, 0xbb, 0xcc, 0xdd}}},
                                              {0xbeefbeef, {{0x05, 0x06, 0x07, 0x08}}}})

        -- Serialize the vector
        local s = ffi.string(TestType.serialize(v))
        assert.is.equal(3*ffi.sizeof(TestType), #s)

        -- Deserialize the vector
        local vv = TestType.deserialize(s, #s)

        -- Check vector properties
        assert.is.equal(TestType, vv.data_type)
        assert.is.equal(3, vv.length)
        assert.is.equal(3*ffi.sizeof(TestType), vv.size)
        assert.is_true(ffi.istype(TestType, vv.data[0]))

        -- Check vector equality with memcmp()
        assert.is_true(ffi.C.memcmp(v.data, vv.data, vv.size) == 0)

        -- Check vector equality with elements
        assert.is.equal(v.data[0], vv.data[0])
        assert.is.equal(v.data[1], vv.data[1])
        assert.is.equal(v.data[2], vv.data[2])

        -- Deserialization the count
        assert.is.equal(3, TestType.deserialize_count(s, #s))

        -- Deserialize the vector with deserialize_partial()
        local vv, size = TestType.deserialize_partial(s, 2)
        assert.is.equal(2*ffi.sizeof(TestType), size)

        -- Check vector properties
        assert.is.equal(TestType, vv.data_type)
        assert.is.equal(2, vv.length)
        assert.is.equal(2*ffi.sizeof(TestType), vv.size)
        assert.is_true(ffi.istype(TestType, vv.data[0]))

        -- Check vector equality with memcmp()
        assert.is_true(ffi.C.memcmp(v.data, vv.data, vv.size) == 0)

        -- Check vector equality with elements
        assert.is.equal(v.data[0], vv.data[0])
        assert.is.equal(v.data[1], vv.data[1])
    end)
end)
