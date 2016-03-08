local radio = require('radio')
local jigs = require('tests.jigs')

local window_utils = require('radio.blocks.signal.window_utils')
local test_vectors = require('tests.blocks.signal.window_utils_vectors')

describe("window_utils", function ()
    it("test window functions", function ()
        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(window_utils.window(128, 'rectangular')),
            test_vectors.window_rectangular, 1e-6)

        jigs.assert_vector_equal(
           radio.Float32Type.vector_from_array(window_utils.window(128, 'hamming')),
           test_vectors.window_hamming, 1e-6)

        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(window_utils.window(128, 'hanning')),
            test_vectors.window_hanning, 1e-6)

        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(window_utils.window(128, 'bartlett')),
            test_vectors.window_bartlett, 1e-6)

        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(window_utils.window(128, 'blackman')),
            test_vectors.window_blackman, 1e-6)
    end)
end)
