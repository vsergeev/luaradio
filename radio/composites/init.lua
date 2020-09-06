return {
    --- Spectrum Manipulation
    TunerBlock = require('radio.composites.tuner'),

    --- Sample Rate Conversion
    DecimatorBlock = require('radio.composites.decimator'),
    InterpolatorBlock = require('radio.composites.interpolator'),
    RationalResamplerBlock = require('radio.composites.rationalresampler'),

    -- Demodulators
    NBFMDemodulator = require('radio.composites.nbfmdemodulator'),
    WBFMMonoDemodulator = require('radio.composites.wbfmmonodemodulator'),
    WBFMStereoDemodulator = require('radio.composites.wbfmstereodemodulator'),
    AMEnvelopeDemodulator = require('radio.composites.amenvelopedemodulator'),
    AMSynchronousDemodulator = require('radio.composites.amsynchronousdemodulator'),
    SSBDemodulator = require('radio.composites.ssbdemodulator'),

    -- Modulators
    SSBModulator = require('radio.composites.ssbmodulator'),

    -- Receivers
    RDSReceiver = require('radio.composites.rdsreceiver'),
    AX25Receiver = require('radio.composites.ax25receiver'),
    POCSAGReceiver = require('radio.composites.pocsagreceiver'),
    BPSK31Receiver = require('radio.composites.bpsk31receiver'),
    ERTReceiver = require('radio.composites.ertreceiver'),
}
