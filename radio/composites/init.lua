return {
    --- Spectrum Manipulation
    TunerBlock = require('radio.composites.tuner').TunerBlock,

    --- Sample Rate Conversion
    DecimatorBlock = require('radio.composites.decimator').DecimatorBlock,
    InterpolatorBlock = require('radio.composites.interpolator').InterpolatorBlock,
    RationalResamplerBlock = require('radio.composites.rationalresampler').RationalResamplerBlock,
}
