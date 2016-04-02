local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local BitType = radio.BitType

describe("BitType", function ()
    it("size", function ()
        -- Check underlying struct size
        assert.is.equal(1, ffi.sizeof(BitType))
    end)

    it("operations", function ()
        local one = BitType(1)
        local zero = BitType(0)


        -- Comparison
        assert.is.equal(one, BitType(1))
        assert.is.equal(zero, BitType(0))
        assert.is.not_equal(one, zero)

        -- bnot()
        assert.is.equal(zero, one:bnot())
        assert.is.equal(one, zero:bnot())

        -- band()
        assert.is.equal(one, one:band(one))
        assert.is.equal(zero, one:band(zero))
        assert.is.equal(zero, zero:band(one))
        assert.is.equal(zero, zero:band(zero))

        -- bor()
        assert.is.equal(one, one:bor(one))
        assert.is.equal(one, one:bor(zero))
        assert.is.equal(one, zero:bor(one))
        assert.is.equal(zero, zero:bor(zero))

        -- bxor()
        assert.is.equal(zero, one:bxor(one))
        assert.is.equal(one, one:bxor(zero))
        assert.is.equal(one, zero:bxor(one))
        assert.is.equal(zero, zero:bxor(zero))
    end)

    it("tonumber()", function ()
        local bits = BitType.vector_from_array({1, 0, 1, 0, 0, 1, 0, 1, 0})

        -- Default usage: zero offset, full length, MSB first
        assert.is.equal(330, BitType.tonumber(bits))

        -- Offset
        assert.is.equal(74, BitType.tonumber(bits, 1))

        -- Offset and length
        assert.is.equal(10, BitType.tonumber(bits, 0, 4))

        -- LSB first
        assert.is.equal(165, BitType.tonumber(bits, 0, bits.length, "lsb"))

        -- Offset, length, LSB first
        assert.is.equal(2, BitType.tonumber(bits, 1, 4, "lsb"))
    end)
end)
