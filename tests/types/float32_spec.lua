local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local Float32Type = radio.Float32Type

describe("Float32Type", function ()
    it("size", function ()
        -- Check underlying struct size
        assert.is_equal(4, ffi.sizeof(Float32Type))
    end)

    it("operations", function ()
        -- Comparison
        assert.is_true(Float32Type(-1.0) < Float32Type(1.0))
        assert.is_true(Float32Type(0.0) <= Float32Type(0.0))
        assert.is_true(Float32Type(2.5) == Float32Type(2.5))
        assert.is_true(Float32Type(2.5) ~= Float32Type(2.6))

        -- Addition
        assert.is.equal(Float32Type(42.0), Float32Type(20.5) + Float32Type(21.5))
        assert.is.equal(Float32Type(-100.0), Float32Type(-150.0) + Float32Type(50.0))

        -- Subtraction
        assert.is_equal(Float32Type(30.0), Float32Type(31.0) - Float32Type(1.0))

        -- Multiplication
        assert.is_equal(Float32Type(400.0), Float32Type(20.0) * Float32Type(20.0))

        -- Division
        assert.is_equal(Float32Type(20.0), Float32Type(400.0) / Float32Type(20.0))

        -- Approximately equal
        assert.is_true(Float32Type(1.000005):approx_equal(Float32Type(1.000003), 1e-5))
        assert.is.not_true(Float32Type(1.000005):approx_equal(Float32Type(1.000003), 1e-6))
    end)
end)
