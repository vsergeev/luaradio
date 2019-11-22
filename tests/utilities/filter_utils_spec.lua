local radio = require('radio')
local jigs = require('tests.jigs')

local filter_utils = require('radio.utilities.filter_utils')
local test_vectors = require('tests.utilities.filter_utils_vectors')

describe("filter_utils", function ()
    it("test firwin functions", function ()
        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(filter_utils.firwin_lowpass(128, 0.5)),
            test_vectors.firwin_lowpass, 1e-6)

        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(filter_utils.firwin_highpass(129, 0.5)),
            test_vectors.firwin_highpass, 1e-6)

        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(filter_utils.firwin_bandpass(129, {0.4, 0.6})),
            test_vectors.firwin_bandpass, 1e-6)

        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(filter_utils.firwin_bandstop(129, {0.4, 0.6})),
            test_vectors.firwin_bandstop, 1e-6)
    end)

    it("test complex firwin functions", function ()
        jigs.assert_vector_equal(
            radio.types.ComplexFloat32.vector_from_array(filter_utils.firwin_complex_bandpass(129, {0.1, 0.3})),
            test_vectors.firwin_complex_bandpass_positive, 1e-6)
        jigs.assert_vector_equal(
            radio.types.ComplexFloat32.vector_from_array(filter_utils.firwin_complex_bandpass(129, {-0.1, -0.3})),
            test_vectors.firwin_complex_bandpass_negative, 1e-6)
        jigs.assert_vector_equal(
            radio.types.ComplexFloat32.vector_from_array(filter_utils.firwin_complex_bandpass(129, {-0.2, 0.2})),
            test_vectors.firwin_complex_bandpass_zero, 1e-6)

        jigs.assert_vector_equal(
            radio.types.ComplexFloat32.vector_from_array(filter_utils.firwin_complex_bandstop(129, {0.1, 0.3})),
            test_vectors.firwin_complex_bandstop_positive, 1e-6)
        jigs.assert_vector_equal(
            radio.types.ComplexFloat32.vector_from_array(filter_utils.firwin_complex_bandstop(129, {-0.1, -0.3})),
            test_vectors.firwin_complex_bandstop_negative, 1e-6)
        jigs.assert_vector_equal(
            radio.types.ComplexFloat32.vector_from_array(filter_utils.firwin_complex_bandstop(129, {-0.2, 0.2})),
            test_vectors.firwin_complex_bandstop_zero, 1e-6)
    end)

    it("test fir root raised cosine function", function ()
        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(filter_utils.fir_root_raised_cosine(101, 1e6, 0.5, 1e3)),
            test_vectors.fir_root_raised_cosine, 1e-6)
    end)

    it("test fir hilbert transform function", function ()
        jigs.assert_vector_equal(
            radio.types.Float32.vector_from_array(filter_utils.fir_hilbert_transform(129)),
            test_vectors.fir_hilbert_transform, 1e-6)
    end)
end)
