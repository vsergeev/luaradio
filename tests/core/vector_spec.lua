local ffi = require('ffi')

local Vector = require('radio.core.vector').Vector

describe("vector", function ()
    ffi.cdef[[
    typedef struct {
        uint32_t x;
        uint32_t y;
    } elem_t;
    ]]

    it("constructor", function ()
        -- Vector of 0
        local v = Vector(ffi.typeof("elem_t"), 0)
        assert.is_true(v.data ~= nil)
        assert.is.equal(0, v.length)
        assert.is.equal(0, v.size)
        assert.is.equal(ffi.typeof("elem_t"), v.data_type)

        -- Vector of 5
        local v = Vector(ffi.typeof("elem_t"), 5)
        assert.is_true(v.data ~= nil)
        assert.is.equal(5, v.length)
        assert.is.equal(5*ffi.sizeof("elem_t"), v.size)
        assert.is.equal(ffi.typeof("elem_t"), v.data_type)
        assert.is_true(ffi.C.memcmp(v.data, string.rep("\x00", 5*ffi.sizeof("elem_t")), 5*ffi.sizeof("elem_t")) == 0)

        -- Modify third element
        v.data[2].x = 5
        v.data[2].y = 5
        assert.is_true(ffi.C.memcmp(v.data, string.rep("\x00", 5*ffi.sizeof("elem_t")), 5*ffi.sizeof("elem_t")) ~= 0)
    end)

    it("cast", function ()
        -- Cast vector of 5
        local buf = string.rep("\xff", ffi.sizeof("elem_t")) .. string.rep("\xaa", ffi.sizeof("elem_t")) .. string.rep("\x55", ffi.sizeof("elem_t"))
        local v = Vector.cast(ffi.typeof("elem_t"), buf, #buf)
        assert.is_true(v.data ~= nil)
        assert.is.equal(3, v.length)
        assert.is.equal(3*ffi.sizeof("elem_t"), v.size)
        assert.is.equal(ffi.typeof("elem_t"), v.data_type)

        -- Check elements
        assert.is.equal(0xffffffff, v.data[0].x)
        assert.is.equal(0xffffffff, v.data[0].y)
        assert.is.equal(0xaaaaaaaa, v.data[1].x)
        assert.is.equal(0xaaaaaaaa, v.data[1].y)
        assert.is.equal(0x55555555, v.data[2].x)
        assert.is.equal(0x55555555, v.data[2].y)
    end)

    it("append", function ()
        -- Empty vector
        local v = Vector(ffi.typeof("elem_t"))

        -- Append elements
        v:append(ffi.new("elem_t", 0xdeadbeef, 0xcafecafe))
        assert.is.equal(1, v.length)
        assert.is.equal(ffi.sizeof("elem_t"), v.size)

        v:append(ffi.new("elem_t", 0xaaaaaaaa, 0xbbbbbbbb))
        assert.is.equal(2, v.length)
        assert.is.equal(2*ffi.sizeof("elem_t"), v.size)

        v:append(ffi.new("elem_t", 0xcccccccc, 0xdddddddd))
        assert.is.equal(3, v.length)
        assert.is.equal(3*ffi.sizeof("elem_t"), v.size)

        v:append(ffi.new("elem_t", 0xeeeeeeee, 0xffffffff))
        assert.is.equal(4, v.length)
        assert.is.equal(4*ffi.sizeof("elem_t"), v.size)

        -- Check elements
        assert.is.equal(0xdeadbeef, v.data[0].x)
        assert.is.equal(0xcafecafe, v.data[0].y)
        assert.is.equal(0xaaaaaaaa, v.data[1].x)
        assert.is.equal(0xbbbbbbbb, v.data[1].y)
        assert.is.equal(0xcccccccc, v.data[2].x)
        assert.is.equal(0xdddddddd, v.data[2].y)
        assert.is.equal(0xeeeeeeee, v.data[3].x)
        assert.is.equal(0xffffffff, v.data[3].y)
    end)

    it("fill", function ()
        -- Vector of 4 zero-initialized
        local v = Vector(ffi.typeof("elem_t"), 4)

        -- Fill with element
        v:fill(ffi.new("elem_t", 0xdeadbeef, 0xcafecafe))
        assert.is.equal(4, v.length)
        assert.is.equal(0xdeadbeef, v.data[0].x)
        assert.is.equal(0xcafecafe, v.data[0].y)
        assert.is.equal(0xdeadbeef, v.data[1].x)
        assert.is.equal(0xcafecafe, v.data[1].y)
        assert.is.equal(0xdeadbeef, v.data[2].x)
        assert.is.equal(0xcafecafe, v.data[2].y)
        assert.is.equal(0xdeadbeef, v.data[3].x)
        assert.is.equal(0xcafecafe, v.data[3].y)
    end)

    it("resize", function ()
        -- Empty vector
        local v = Vector(ffi.typeof("elem_t"))

        -- Append elements
        v:append(ffi.new("elem_t", 0xdeadbeef, 0xcafecafe))
        v:append(ffi.new("elem_t", 0xaaaaaaaa, 0xbbbbbbbb))
        v:append(ffi.new("elem_t", 0xcccccccc, 0xdddddddd))
        v:append(ffi.new("elem_t", 0xeeeeeeee, 0xffffffff))
        assert.is.equal(4, v.length)
        assert.is.equal(4*ffi.sizeof("elem_t"), v.size)

        -- Resize to existing capacity
        v:resize(4)
        assert.is.equal(4, v.length)
        assert.is.equal(4*ffi.sizeof("elem_t"), v.size)

        -- Check elements
        assert.is.equal(0xdeadbeef, v.data[0].x)
        assert.is.equal(0xcafecafe, v.data[0].y)
        assert.is.equal(0xaaaaaaaa, v.data[1].x)
        assert.is.equal(0xbbbbbbbb, v.data[1].y)
        assert.is.equal(0xcccccccc, v.data[2].x)
        assert.is.equal(0xdddddddd, v.data[2].y)
        assert.is.equal(0xeeeeeeee, v.data[3].x)
        assert.is.equal(0xffffffff, v.data[3].y)

        -- Resize to one less
        v:resize(3)
        assert.is.equal(3, v.length)
        assert.is.equal(3*ffi.sizeof("elem_t"), v.size)

        -- Check elements
        assert.is.equal(0xdeadbeef, v.data[0].x)
        assert.is.equal(0xcafecafe, v.data[0].y)
        assert.is.equal(0xaaaaaaaa, v.data[1].x)
        assert.is.equal(0xbbbbbbbb, v.data[1].y)
        assert.is.equal(0xcccccccc, v.data[2].x)
        assert.is.equal(0xdddddddd, v.data[2].y)

        -- Resize to 5
        v:resize(5)
        assert.is.equal(5, v.length)
        assert.is.equal(5*ffi.sizeof("elem_t"), v.size)

        -- Check elements
        assert.is.equal(0xdeadbeef, v.data[0].x)
        assert.is.equal(0xcafecafe, v.data[0].y)
        assert.is.equal(0xaaaaaaaa, v.data[1].x)
        assert.is.equal(0xbbbbbbbb, v.data[1].y)
        assert.is.equal(0xcccccccc, v.data[2].x)
        assert.is.equal(0xdddddddd, v.data[2].y)
        assert.is.equal(0x00000000, v.data[3].x)
        assert.is.equal(0x00000000, v.data[3].y)
        assert.is.equal(0x00000000, v.data[4].x)
        assert.is.equal(0x00000000, v.data[4].y)

        -- Resize to 0
        v:resize(0)
        assert.is.equal(0, v.length)
        assert.is.equal(0, v.size)

        -- Resize to 10
        v:resize(10)
        assert.is.equal(10, v.length)
        assert.is.equal(10*ffi.sizeof("elem_t"), v.size)

        -- Check memory
        assert.is_true(ffi.C.memcmp(v.data, string.rep("\x00", 10*ffi.sizeof("elem_t")), 10*ffi.sizeof("elem_t")) == 0)
    end)
end)
