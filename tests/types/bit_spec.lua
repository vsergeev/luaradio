local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local Bit = radio.types.Bit

describe("Bit type", function ()
    it("type name", function ()
        assert.is.equal(Bit.type_name, "Bit")
    end)

    it("size", function ()
        -- Check underlying struct size
        assert.is.equal(1, ffi.sizeof(Bit))
    end)

    it("operations", function ()
        local one = Bit(1)
        local zero = Bit(0)

        -- Comparison
        assert.is.equal(one, Bit(1))
        assert.is.equal(zero, Bit(0))
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
        local bits = Bit.vector_from_array({1, 0, 1, 0, 0, 1, 0, 1, 0})

        -- Default usage: zero offset, full length, MSB first
        assert.is.equal(330, Bit.tonumber(bits))

        -- Offset
        assert.is.equal(74, Bit.tonumber(bits, 1))

        -- Offset and length
        assert.is.equal(10, Bit.tonumber(bits, 0, 4))

        -- LSB first
        assert.is.equal(165, Bit.tonumber(bits, 0, bits.length, "lsb"))

        -- Offset, length, LSB first
        assert.is.equal(2, Bit.tonumber(bits, 1, 4, "lsb"))
    end)
end)
