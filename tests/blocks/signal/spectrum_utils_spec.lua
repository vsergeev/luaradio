local radio = require('radio')
local jigs = require('tests.jigs')

local spectrum_utils = require('radio.blocks.signal.spectrum_utils')
local test_vectors = require('tests.blocks.signal.spectrum_utils_vectors')

describe("spectrum_utils", function ()
    it("test complex dft", function ()
        local dft = spectrum_utils.DFT(128, radio.ComplexFloat32Type, 'rectangular')
        jigs.assert_vector_equal(dft:dft(test_vectors.complex_test_vector), test_vectors.dft_complex_rectangular, 1e-4)

        local dft = spectrum_utils.DFT(128, radio.ComplexFloat32Type, 'hamming')
        jigs.assert_vector_equal(dft:dft(test_vectors.complex_test_vector), test_vectors.dft_complex_hamming, 1e-4)
    end)

    it("test real dft", function ()
        local dft = spectrum_utils.DFT(128, radio.Float32Type, 'rectangular')
        jigs.assert_vector_equal(dft:dft(test_vectors.real_test_vector), test_vectors.dft_real_rectangular, 1e-4)

        local dft = spectrum_utils.DFT(128, radio.Float32Type, 'hamming')
        jigs.assert_vector_equal(dft:dft(test_vectors.real_test_vector), test_vectors.dft_real_hamming, 1e-4)
    end)

    it("test complex psd", function ()
        local dft = spectrum_utils.DFT(128, radio.ComplexFloat32Type, 'rectangular', 44100)
        jigs.assert_vector_equal(dft:psd(test_vectors.complex_test_vector, false), test_vectors.psd_complex_rectangular, 1e-5)
        jigs.assert_vector_equal(dft:psd(test_vectors.complex_test_vector, true), test_vectors.psd_complex_rectangular_log, 3)

        local dft = spectrum_utils.DFT(128, radio.ComplexFloat32Type, 'hamming', 44100)
        jigs.assert_vector_equal(dft:psd(test_vectors.complex_test_vector, false), test_vectors.psd_complex_hamming, 1e-5)
        jigs.assert_vector_equal(dft:psd(test_vectors.complex_test_vector, true), test_vectors.psd_complex_hamming_log, 3)
    end)

    it("test real psd", function ()
        local dft = spectrum_utils.DFT(128, radio.Float32Type, 'rectangular', 44100)
        jigs.assert_vector_equal(dft:psd(test_vectors.real_test_vector, false), test_vectors.psd_real_rectangular, 1e-5)
        jigs.assert_vector_equal(dft:psd(test_vectors.real_test_vector, true), test_vectors.psd_real_rectangular_log, 3)

        local dft = spectrum_utils.DFT(128, radio.Float32Type, 'hamming', 44100)
        jigs.assert_vector_equal(dft:psd(test_vectors.real_test_vector, false), test_vectors.psd_real_hamming, 1e-5)
        jigs.assert_vector_equal(dft:psd(test_vectors.real_test_vector, true), test_vectors.psd_real_hamming_log, 3)
    end)
end)
