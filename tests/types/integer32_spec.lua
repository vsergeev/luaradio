local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local Integer32 = radio.types.Integer32

describe("Integer32 type", function ()
    it("size", function ()
        -- Check underlying struct size
        assert.is.equal(4, ffi.sizeof(Integer32))
    end)

    it("operations", function ()
        -- Comparison
        assert.is_true(Integer32(0) < Integer32(1234))
        assert.is_true(Integer32(0xaaaaaaaa) <= Integer32(0xaaaaaaaa))
        assert.is_true(Integer32(0x55555555) == Integer32(0x55555555))
        assert.is_true(Integer32(0x55555555) ~= Integer32(0x55555556))

        -- Addition
        assert.is.equal(Integer32(0x19d9c), Integer32(0xdead) + Integer32(0xbeef))
        assert.is.equal(Integer32(0x1fbe), Integer32(0xdead) + Integer32(-0xbeef))
        assert.is.equal(Integer32(-0x1fbe), Integer32(-0xdead) + Integer32(0xbeef))
        -- Check overflow
        assert.is.equal(Integer32(-2147483647), Integer32(2147483648) + Integer32(1))

        -- Subtraction
        assert.is.equal(Integer32(0x1fbe), Integer32(0xdead) - Integer32(0xbeef))
        -- Check underflow
        assert.is.equal(Integer32(2147483647), Integer32(-2147483648) - Integer32(0x01))

        -- Multiplication
        assert.is.equal(Integer32(0x24b18a18), Integer32(0x1e0f3) * Integer32(0x1388))
        -- Check overflow
        assert.is.equal(Integer32(-1938485248), Integer32(0x1e240) * Integer32(0x1e240))

        -- Division
        assert.is.equal(Integer32(0x4d3929), Integer32(0x73d5bdc) / Integer32(0x18))
    end)
end)
