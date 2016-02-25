local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local Integer32Type = radio.Integer32Type

describe("Integer32Type", function ()
    it("size", function ()
        -- Check underlying struct size
        assert.is_equal(4, ffi.sizeof(Integer32Type))
    end)

    it("operations", function ()
        -- Comparison
        assert.is_true(Integer32Type(0) < Integer32Type(1234))
        assert.is_true(Integer32Type(0xaaaaaaaa) <= Integer32Type(0xaaaaaaaa))
        assert.is_true(Integer32Type(0x55555555) == Integer32Type(0x55555555))
        assert.is_true(Integer32Type(0x55555555) ~= Integer32Type(0x55555556))

        -- Addition
        assert.is.equal(Integer32Type(0x19d9c), Integer32Type(0xdead) + Integer32Type(0xbeef))
        assert.is.equal(Integer32Type(0x1fbe), Integer32Type(0xdead) + Integer32Type(-0xbeef))
        assert.is.equal(Integer32Type(-0x1fbe), Integer32Type(-0xdead) + Integer32Type(0xbeef))
        -- Check overflow
        assert.is.equal(Integer32Type(-2147483647), Integer32Type(2147483648) + Integer32Type(1))

        -- Subtraction
        assert.is_equal(Integer32Type(0x1fbe), Integer32Type(0xdead) - Integer32Type(0xbeef))
        -- Check underflow
        assert.is.equal(Integer32Type(2147483647), Integer32Type(-2147483648) - Integer32Type(0x01))

        -- Multiplication
        assert.is_equal(Integer32Type(0x24b18a18), Integer32Type(0x1e0f3) * Integer32Type(0x1388))
        -- Check overflow
        assert.is_equal(Integer32Type(-1938485248), Integer32Type(0x1e240) * Integer32Type(0x1e240))

        -- Division
        assert.is_equal(Integer32Type(0x4d3929), Integer32Type(0x73d5bdc) / Integer32Type(0x18))
    end)
end)
