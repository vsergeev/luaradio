local radio = require('radio')
local jigs = require('tests.jigs')

local window_utils = require('radio.utilities.window_utils')
local test_vectors = dofile('tests/utilities/window_utils_vectors.gen.lua')

describe("window_utils", function ()
    it("test rectangular window", function ()
        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(window_utils.window(128, 'rectangular')),
            test_vectors.window_rectangular, 1e-6)
        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(window_utils.window(128, 'rectangular', true)),
            test_vectors.window_rectangular_periodic, 1e-6)
    end)

    it("test hamming window", function()
        jigs.assert_vector_equal(
           radio.types.Float32.vector_from_array(window_utils.window(128, 'hamming')),
           test_vectors.window_hamming, 1e-6)
        jigs.assert_vector_equal(
           radio.types.Float32.vector_from_array(window_utils.window(128, 'hamming', true)),
           test_vectors.window_hamming_periodic, 1e-6)
    end)

    it("test hanning window", function()
        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(window_utils.window(128, 'hanning')),
            test_vectors.window_hanning, 1e-6)
        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(window_utils.window(128, 'hanning', true)),
            test_vectors.window_hanning_periodic, 1e-6)
    end)

    it("test bartlett window", function()
        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(window_utils.window(128, 'bartlett')),
            test_vectors.window_bartlett, 1e-6)
        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(window_utils.window(128, 'bartlett', true)),
            test_vectors.window_bartlett_periodic, 1e-6)
    end)

    it("test blackman window", function()
        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(window_utils.window(128, 'blackman')),
            test_vectors.window_blackman, 1e-6)
        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(window_utils.window(128, 'blackman', true)),
            test_vectors.window_blackman_periodic, 1e-6)
    end)
end)
