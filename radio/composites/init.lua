return {
    --- Spectrum Manipulation
    TunerBlock = require('radio.composites.tuner').TunerBlock,

    --- Sample Rate Conversion
    DecimatorBlock = require('radio.composites.decimator').DecimatorBlock,
    InterpolatorBlock = require('radio.composites.interpolator').InterpolatorBlock,
    RationalResamplerBlock = require('radio.composites.rationalresampler').RationalResamplerBlock,

    -- Demodulators
    NBFMDemodulator = require('radio.composites.nbfmdemodulator').NBFMDemodulator,
    AMEnvelopeDemodulator = require('radio.composites.amenvelopedemodulator').AMEnvelopeDemodulator,
    AMSynchronousDemodulator = require('radio.composites.amsynchronousdemodulator').AMSynchronousDemodulator,
    SSBDemodulator = require('radio.composites.ssbdemodulator').SSBDemodulator,

    -- Modulators
    SSBModulator = require('radio.composites.ssbmodulator').SSBModulator,
}
