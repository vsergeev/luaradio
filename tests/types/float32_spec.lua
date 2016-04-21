local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local Float32 = radio.types.Float32

describe("Float32 type", function ()
    it("size", function ()
        -- Check underlying struct size
        assert.is.equal(4, ffi.sizeof(Float32))
    end)

    it("operations", function ()
        -- Comparison
        assert.is_true(Float32(-1.0) < Float32(1.0))
        assert.is_true(Float32(0.0) <= Float32(0.0))
        assert.is_true(Float32(2.5) == Float32(2.5))
        assert.is_true(Float32(2.5) ~= Float32(2.6))

        -- Addition
        assert.is.equal(Float32(42.0), Float32(20.5) + Float32(21.5))
        assert.is.equal(Float32(-100.0), Float32(-150.0) + Float32(50.0))

        -- Subtraction
        assert.is.equal(Float32(30.0), Float32(31.0) - Float32(1.0))

        -- Multiplication
        assert.is.equal(Float32(400.0), Float32(20.0) * Float32(20.0))

        -- Division
        assert.is.equal(Float32(20.0), Float32(400.0) / Float32(20.0))

        -- Approximately equal
        assert.is_true(Float32(1.000005):approx_equal(Float32(1.000003), 1e-5))
        assert.is.not_true(Float32(1.000005):approx_equal(Float32(1.000003), 1e-6))
    end)
end)
