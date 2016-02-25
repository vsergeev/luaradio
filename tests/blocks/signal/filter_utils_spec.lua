local radio = require('radio')
local jigs = require('tests.jigs')

local filter_utils = require('radio.blocks.signal.filter_utils')
local test_vectors = require('tests.blocks.signal.filter_utils_vectors')

describe("filter_utils", function ()
    it("test window functions", function ()
        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(filter_utils.window(128, 'rectangular')),
            test_vectors.window_rectangular, 1e-6)

        jigs.assert_vector_equal(
           radio.Float32Type.vector_from_array(filter_utils.window(128, 'hamming')),
           test_vectors.window_hamming, 1e-6)

        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(filter_utils.window(128, 'hanning')),
            test_vectors.window_hanning, 1e-6)

        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(filter_utils.window(128, 'bartlett')),
            test_vectors.window_bartlett, 1e-6)

        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(filter_utils.window(128, 'blackman')),
            test_vectors.window_blackman, 1e-6)
    end)

    it("test firwin functions", function ()
        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(filter_utils.firwin_lowpass(128, 0.5)),
            test_vectors.firwin_lowpass, 1e-6)

        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(filter_utils.firwin_highpass(129, 0.5)),
            test_vectors.firwin_highpass, 1e-6)

        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(filter_utils.firwin_bandpass(129, {0.4, 0.6})),
            test_vectors.firwin_bandpass, 1e-6)

        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(filter_utils.firwin_bandstop(129, {0.4, 0.6})),
            test_vectors.firwin_bandstop, 1e-6)
    end)

    it("test fir root raised cosine function", function ()
        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(filter_utils.fir_root_raised_cosine(101, 1e6, 0.5, 1e3)),
            test_vectors.fir_root_raised_cosine, 1e-6)
    end)

    it("test fir hilbert transform function", function ()
        jigs.assert_vector_equal(
            radio.Float32Type.vector_from_array(filter_utils.fir_hilbert_transform(129)),
            test_vectors.fir_hilbert_transform, 1e-6)
    end)
end)
