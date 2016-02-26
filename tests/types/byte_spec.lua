local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local ByteType = radio.ByteType

describe("ByteType", function ()
    it("size", function ()
        -- Check underlying struct size
        assert.is.equal(1, ffi.sizeof(ByteType))
    end)

    it("operations", function ()
        -- Comparison
        assert.is_true(ByteType(0x00) < ByteType(0xff))
        assert.is_true(ByteType(0xaa) <= ByteType(0xaa))
        assert.is_true(ByteType(0x55) == ByteType(0x55))
        assert.is_true(ByteType(0x55) ~= ByteType(0x56))

        -- Addition
        assert.is.equal(ByteType(0x10), ByteType(0x0f) + ByteType(0x01))
        -- Check overflow
        assert.is.equal(ByteType(0x00), ByteType(0xff) + ByteType(0x01))

        -- Subtraction
        assert.is.equal(ByteType(0x32), ByteType(0x33) - ByteType(0x01))
        -- Check underflow
        assert.is.equal(ByteType(0xff), ByteType(0x00) - ByteType(0x01))

        -- Multiplication
        assert.is.equal(ByteType(0xd2), ByteType(0x0e) * ByteType(0x0f))
        -- Check overflow
        assert.is.equal(ByteType(0x90), ByteType(0x14) * ByteType(0x14))

        -- Division
        assert.is.equal(ByteType(0x02), ByteType(0x32) / ByteType(0x19))
    end)
end)
