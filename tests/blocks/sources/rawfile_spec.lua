local radio = require('radio')
local jigs = require('tests.jigs')
local buffer = require('tests.buffer')

SRC_TEST_VECTOR = "\x00\x00\x00\x0a\x93\xa3\x66\x6f\x6f\xa3\x62\x61\x72\x7b\x00\x00\x00\x04\x93\xc3\xc2\xc3\x00\x00\x00\x09\x92\x93\x01\x02\x03\xa3\x62\x61\x7a"

describe("RawFileSource", function ()
    it("test vector", function ()
        -- Create new object type
        local FooType = radio.types.ObjectType.factory()

        -- Prepare source block
        local src = radio.RawFileSource(buffer.open(SRC_TEST_VECTOR), FooType, 1)
        src:differentiate({})
        src:initialize()

        -- Run source block
        local vec = src:process()

        -- Check vector
        assert.is.equal(3, vec.length)
        assert.is.equal(0, vec.size)
        assert.is_true(radio.object.isinstanceof(vec.data[0], FooType))
        assert.is_true(radio.object.isinstanceof(vec.data[1], FooType))
        assert.is_true(radio.object.isinstanceof(vec.data[2], FooType))
        assert.is.same({"foo", "bar", 123}, vec.data[0])
        assert.is.same({true, false, true}, vec.data[1])
        assert.is.same({{1, 2, 3}, "baz"}, vec.data[2])

        -- Check source block is at EOF
        assert.is.equal(nil, src:process())
    end)
end)
