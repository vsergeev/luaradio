local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local Byte = radio.types.Byte

describe("Byte type", function ()
    it("size", function ()
        -- Check underlying struct size
        assert.is.equal(1, ffi.sizeof(Byte))
    end)

    it("operations", function ()
        -- Comparison
        assert.is_true(Byte(0x00) < Byte(0xff))
        assert.is_true(Byte(0xaa) <= Byte(0xaa))
        assert.is_true(Byte(0x55) == Byte(0x55))
        assert.is_true(Byte(0x55) ~= Byte(0x56))

        -- Addition
        assert.is.equal(Byte(0x10), Byte(0x0f) + Byte(0x01))
        -- Check overflow
        assert.is.equal(Byte(0x00), Byte(0xff) + Byte(0x01))

        -- Subtraction
        assert.is.equal(Byte(0x32), Byte(0x33) - Byte(0x01))
        -- Check underflow
        assert.is.equal(Byte(0xff), Byte(0x00) - Byte(0x01))

        -- Multiplication
        assert.is.equal(Byte(0xd2), Byte(0x0e) * Byte(0x0f))
        -- Check overflow
        assert.is.equal(Byte(0x90), Byte(0x14) * Byte(0x14))

        -- Division
        assert.is.equal(Byte(0x02), Byte(0x32) / Byte(0x19))
    end)
end)
