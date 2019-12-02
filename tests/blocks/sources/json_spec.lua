local radio = require('radio')
local jigs = require('tests.jigs')
local buffer = require('tests.buffer')

describe("JSONSource", function ()
    -- Create new object type
    local MyObjectType = radio.types.ObjectType.factory()
    function MyObjectType.new(foo, bar)
        local self = setmetatable({}, MyObjectType)
        self.foo = foo
        self.bar = bar
        return self
    end

    -- Create test vector
    local test_vector = {}
    test_vector[1] = MyObjectType(123, true)
    test_vector[2] = MyObjectType("abc", "def")
    test_vector[3] = MyObjectType("foobar", {1, 2, 3})

    -- Serialize test vector into newline delimited JSON string
    local test_vector_json = ""
    for i = 1, #test_vector do
        test_vector_json = test_vector_json .. test_vector[i]:to_json() .. "\n"
    end

    it("test vector", function ()
        -- Open test vector as virtual file
        local src_fd = buffer.open(test_vector_json)

        -- Prepare source block
        local src = radio.JSONSource(src_fd, MyObjectType, 1)
        src:differentiate({})
        src:initialize()

        -- Run source block
        local vec = src:process()

        -- Check vector
        assert.is.equal(3, vec.length)
        assert.is.equal(0, vec.size)
        assert.is_true(radio.class.isinstanceof(vec.data[0], MyObjectType))
        assert.is_true(radio.class.isinstanceof(vec.data[1], MyObjectType))
        assert.is_true(radio.class.isinstanceof(vec.data[2], MyObjectType))
        assert.is.same(test_vector[1], vec.data[0])
        assert.is.same(test_vector[2], vec.data[1])
        assert.is.same(test_vector[3], vec.data[2])

        -- Check source block is at EOF
        assert.is.equal(nil, src:process())
    end)
end)
