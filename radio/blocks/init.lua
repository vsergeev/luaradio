return {
    -- Composite Block
    CompositeBlock = require('radio.core.composite').CompositeBlock,

    -- Source Blocks
    NullSource = require('radio.blocks.sources.null'),
    IQFileSource = require('radio.blocks.sources.iqfile'),
    RealFileSource = require('radio.blocks.sources.realfile'),
    WAVFileSource = require('radio.blocks.sources.wavfile'),
    RawFileSource = require('radio.blocks.sources.rawfile'),
    UniformRandomSource = require('radio.blocks.sources.uniformrandom'),
    SignalSource = require('radio.blocks.sources.signal'),
    RtlSdrSource = require('radio.blocks.sources.rtlsdr'),

    -- Sink Blocks
    IQFileSink = require('radio.blocks.sinks.iqfile'),
    RealFileSink = require('radio.blocks.sinks.realfile'),
    WAVFileSink = require('radio.blocks.sinks.wavfile'),
    RawFileSink = require('radio.blocks.sinks.rawfile'),
    PrintSink = require('radio.blocks.sinks.print'),
    JSONSink = require('radio.blocks.sinks.json'),
    PulseAudioSink = require('radio.blocks.sinks.pulseaudio'),
    PortAudioSink = require('radio.blocks.sinks.portaudio'),
    GnuplotPlotSink = require('radio.blocks.sinks.gnuplotplot'),
    GnuplotXYPlotSink = require('radio.blocks.sinks.gnuplotxyplot'),
    GnuplotSpectrumSink = require('radio.blocks.sinks.gnuplotspectrum'),
    GnuplotWaterfallSink = require('radio.blocks.sinks.gnuplotwaterfall'),
    BenchmarkSink = require('radio.blocks.sinks.benchmark'),

    -- Signal Blocks
    --- Filtering
    FIRFilterBlock = require('radio.blocks.signal.firfilter'),
    IIRFilterBlock = require('radio.blocks.signal.iirfilter'),
    LowpassFilterBlock = require('radio.blocks.signal.lowpassfilter'),
    HighpassFilterBlock = require('radio.blocks.signal.highpassfilter'),
    BandpassFilterBlock = require('radio.blocks.signal.bandpassfilter'),
    BandstopFilterBlock = require('radio.blocks.signal.bandstopfilter'),
    ComplexBandpassFilterBlock = require('radio.blocks.signal.complexbandpassfilter'),
    ComplexBandstopFilterBlock = require('radio.blocks.signal.complexbandstopfilter'),
    RootRaisedCosineFilterBlock = require('radio.blocks.signal.rootraisedcosinefilter'),
    FMDeemphasisFilterBlock = require('radio.blocks.signal.fmdeemphasisfilter'),
    --- Sample Rate Conversion
    DownsamplerBlock = require('radio.blocks.signal.downsampler'),
    UpsamplerBlock = require('radio.blocks.signal.upsampler'),
    --- Spectrum Manipulation
    FrequencyTranslatorBlock = require('radio.blocks.signal.frequencytranslator'),
    HilbertTransformBlock = require('radio.blocks.signal.hilberttransform'),
    --- Frequency Discriminator
    FrequencyDiscriminatorBlock = require('radio.blocks.signal.frequencydiscriminator'),
    --- Carrier Recovery
    PLLBlock = require('radio.blocks.signal.pll'),
    --- Clock Recovery
    ZeroCrossingClockRecoveryBlock = require('radio.blocks.signal.zerocrossingclockrecovery'),
    --- Basic Operators
    SumBlock = require('radio.blocks.signal.sum'),
    SubtractBlock = require('radio.blocks.signal.subtract'),
    MultiplyBlock = require('radio.blocks.signal.multiply'),
    MultiplyConstantBlock = require('radio.blocks.signal.multiplyconstant'),
    MultiplyConjugateBlock = require('radio.blocks.signal.multiplyconjugate'),
    AbsoluteValueBlock = require('radio.blocks.signal.absolutevalue'),
    ComplexConjugateBlock = require('radio.blocks.signal.complexconjugate'),
    ComplexMagnitudeBlock = require('radio.blocks.signal.complexmagnitude'),
    ComplexPhaseBlock = require('radio.blocks.signal.complexphase'),
    --- Sampling and Bits
    BinaryPhaseCorrectorBlock = require('radio.blocks.signal.binaryphasecorrector'),
    DelayBlock = require('radio.blocks.signal.delay'),
    SamplerBlock = require('radio.blocks.signal.sampler'),
    SlicerBlock = require('radio.blocks.signal.slicer'),
    DifferentialDecoderBlock = require('radio.blocks.signal.differentialdecoder'),
    --- Complex/Float Conversion
    ComplexToRealBlock = require('radio.blocks.signal.complextoreal'),
    ComplexToImagBlock = require('radio.blocks.signal.complextoimag'),
    ComplexToFloatBlock = require('radio.blocks.signal.complextofloat'),
    FloatToComplexBlock = require('radio.blocks.signal.floattocomplex'),
    --- Miscellaneous
    ThrottleBlock = require('radio.blocks.signal.throttle'),

    -- Protocol Blocks
    --- RDS
    RDSFrameBlock = require('radio.blocks.protocol.rdsframe'),
    RDSDecodeBlock = require('radio.blocks.protocol.rdsdecode'),
    --- AX25
    AX25FrameBlock = require('radio.blocks.protocol.ax25frame'),
    --- POCSAG
    POCSAGFrameBlock = require('radio.blocks.protocol.pocsagframe'),
    POCSAGDecodeBlock = require('radio.blocks.protocol.pocsagdecode'),
}
