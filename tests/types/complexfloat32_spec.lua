local ffi = require('ffi')
local radio = require('radio')
local jigs = require('tests.jigs')

local ComplexFloat32 = radio.types.ComplexFloat32

describe("ComplexFloat32 type", function ()
    it("type name", function ()
        assert.is.equal(ComplexFloat32.type_name, "ComplexFloat32")
    end)

    it("size", function ()
        -- Check underlying struct size
        assert.is.equal(8, ffi.sizeof(ComplexFloat32))
    end)

    it("operations", function ()
        -- Comparison
        assert.is_true(ComplexFloat32(-1.0, -1.0) < ComplexFloat32(1.0, 1.0))
        assert.is_true(ComplexFloat32(0.0, 0.0) <= ComplexFloat32(0.0, 0.0))
        assert.is_true(ComplexFloat32(2.5, 2.5) == ComplexFloat32(2.5, 2.5))
        assert.is_true(ComplexFloat32(2.5, 2.5) ~= ComplexFloat32(2.5, 2.6))

        -- Addition
        assert.is.equal(ComplexFloat32(1.5, -1.5), ComplexFloat32(0.75, -0.75) + ComplexFloat32(0.75, -0.75))

        -- Subtraction
        assert.is.equal(ComplexFloat32(1.5, -1.5), ComplexFloat32(3.0, 0.0) - ComplexFloat32(1.5, 1.5))

        -- Complex Multiplication
        assert.is.equal(ComplexFloat32(10, 5), ComplexFloat32(1, 2) * ComplexFloat32(4, -3))

        -- Complex Division
        assert.is.equal(ComplexFloat32(1, 2), ComplexFloat32(10, 5) / ComplexFloat32(4, -3))

        -- Scalar Multiplication
        assert.is.equal(ComplexFloat32(5, 3), ComplexFloat32(2.5, 1.5):scalar_mul(2))

        -- Scalar Division
        assert.is.equal(ComplexFloat32(2, 4), ComplexFloat32(3, 6):scalar_div(1.5))

        -- Complex Argument
        jigs.assert_approx_equal(math.pi/4, ComplexFloat32(1, 1):arg(), 1e-6)
        jigs.assert_approx_equal(-math.pi/4, ComplexFloat32(1, -1):arg(), 1e-6)
        jigs.assert_approx_equal(3*math.pi/4, ComplexFloat32(-1, 1):arg(), 1e-6)
        jigs.assert_approx_equal(-3*math.pi/4, ComplexFloat32(-1, -1):arg(), 1e-6)

        -- Complex Magnitude
        jigs.assert_approx_equal(math.sqrt(2), ComplexFloat32(1, 1):abs(), 1e-6)
        jigs.assert_approx_equal(math.sqrt(2), ComplexFloat32(1, -1):abs(), 1e-6)
        jigs.assert_approx_equal(math.sqrt(101), ComplexFloat32(-10, 1):abs(), 1e-6)
        jigs.assert_approx_equal(2, ComplexFloat32(1, 1):abs_squared(), 1e-6)
        jigs.assert_approx_equal(2, ComplexFloat32(1, -1):abs_squared(), 1e-6)
        jigs.assert_approx_equal(101, ComplexFloat32(-10, 1):abs_squared(), 1e-6)

        -- Complex Conjugate
        assert.is.equal(ComplexFloat32(1, -2), ComplexFloat32(1, 2):conj())
        assert.is.equal(ComplexFloat32(-5, 10), ComplexFloat32(-5, -10):conj())

        -- Approximately equal
        assert.is_true(ComplexFloat32(1.000004, 1.000005):approx_equal(ComplexFloat32(1.000006, 1.000003), 1e-5))
        assert.is.not_true(ComplexFloat32(1.000004, 1.000005):approx_equal(ComplexFloat32(1.000006, 1.000003), 1e-6))
    end)
end)
