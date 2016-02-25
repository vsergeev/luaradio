local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local BitType = radio.BitType
local bits_to_number = require('radio.types.bit').bits_to_number

describe("BitType", function ()
    it("size", function ()
        -- Check underlying struct size
        assert.is_equal(1, ffi.sizeof(BitType))
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

    it("bits_to_number()", function ()
        local bits = BitType.vector_from_array({1, 0, 1, 0, 0, 1, 0, 1, 0})

        -- Normal usage
        assert.is.equal(330, bits_to_number(bits))

        -- Offset
        assert.is.equal(74, bits_to_number(bits, 1))

        -- Offset and length
        assert.is.equal(10, bits_to_number(bits, 0, 4))

        -- LSB first
        assert.is.equal(165, bits_to_number(bits, 0, bits.length, false))

        -- LSB first, offset, and length
        assert.is.equal(2, bits_to_number(bits, 1, 4, false))
    end)
end)
