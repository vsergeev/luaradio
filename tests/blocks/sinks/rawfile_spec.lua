local radio = require('radio')
local jigs = require('tests.jigs')
local buffer = require('tests.buffer')

SNK_TEST_VECTOR = "\x00\x00\x00\x0a\x93\xa3\x66\x6f\x6f\xa3\x62\x61\x72\x7b\x00\x00\x00\x04\x93\xc3\xc2\xc3\x00\x00\x00\x09\x92\x93\x01\x02\x03\xa3\x62\x61\x7a"

describe("RawFileSource", function ()
    it("test vector", function ()
        -- Create new object type
        local FooType = radio.types.ObjectType.factory()

        function FooType.new(a, b, c)
            return setmetatable({a, b, c}, FooType)
        end

        -- Create a FooType vector
        local vec = FooType.vector()
        vec:append(FooType("foo", "bar", 123))
        vec:append(FooType(true, false, true))
        vec:append(FooType({1, 2, 3}, "baz", nil))

        -- Run sink block
        local snk_fd = buffer.open()
        local snk = radio.RawFileSink(snk_fd)
        snk:differentiate({})
        snk:initialize()
        snk:process(vec)
        snk:cleanup()

        -- Rewind the sink buffer
        buffer.rewind(snk_fd)

        -- Read the sink buffer
        local buf = buffer.read(snk_fd, #SNK_TEST_VECTOR*2)
        assert.is.equal(#SNK_TEST_VECTOR, #buf)
        assert.is.equal(SNK_TEST_VECTOR, buf)
    end)
end)
