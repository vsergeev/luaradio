return {
    -- Composite Block
    CompositeBlock = require('radio.core.composite').CompositeBlock,

    -- Source Blocks
    ZeroSource = require('radio.blocks.sources.zero'),
    NullSource = require('radio.blocks.sources.zero'),
    IQFileSource = require('radio.blocks.sources.iqfile'),
    RealFileSource = require('radio.blocks.sources.realfile'),
    WAVFileSource = require('radio.blocks.sources.wavfile'),
    RawFileSource = require('radio.blocks.sources.rawfile'),
    JSONSource = require('radio.blocks.sources.json'),
    UniformRandomSource = require('radio.blocks.sources.uniformrandom'),
    SignalSource = require('radio.blocks.sources.signal'),
    RtlSdrSource = require('radio.blocks.sources.rtlsdr'),
    AirspySource = require('radio.blocks.sources.airspy'),
    AirspyHFSource = require('radio.blocks.sources.airspyhf'),
    HackRFSource = require('radio.blocks.sources.hackrf'),
    SDRplaySource = require('radio.blocks.sources.sdrplay'),
    PulseAudioSource = require('radio.blocks.sources.pulseaudio'),
    PortAudioSource = require('radio.blocks.sources.portaudio'),
    SoapySDRSource = require('radio.blocks.sources.soapysdr'),
    UHDSource = require('radio.blocks.sources.uhd'),
    NetworkClientSource = require('radio.blocks.sources.networkclient'),
    NetworkServerSource = require('radio.blocks.sources.networkserver'),

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
    HackRFSink = require('radio.blocks.sinks.hackrf'),
    SoapySDRSink = require('radio.blocks.sinks.soapysdr'),
    NopSink = require('radio.blocks.sinks.nop'),
    UHDSink = require('radio.blocks.sinks.uhd'),
    NetworkClientSink = require('radio.blocks.sinks.networkclient'),
    NetworkServerSink = require('radio.blocks.sinks.networkserver'),

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
    SinglepoleLowpassFilterBlock = require('radio.blocks.signal.singlepolelowpassfilter'),
    SinglepoleHighpassFilterBlock = require('radio.blocks.signal.singlepolehighpassfilter'),
    FMDeemphasisFilterBlock = require('radio.blocks.signal.fmdeemphasisfilter'),
    FMPreemphasisFilterBlock = require('radio.blocks.signal.fmpreemphasisfilter'),
    ManchesterMatchedFilterBlock = require('radio.blocks.signal.manchestermatchedfilter'),
    --- Math Operations
    AddBlock = require('radio.blocks.signal.add'),
    AddConstantBlock = require('radio.blocks.signal.addconstant'),
    SubtractBlock = require('radio.blocks.signal.subtract'),
    MultiplyBlock = require('radio.blocks.signal.multiply'),
    MultiplyConstantBlock = require('radio.blocks.signal.multiplyconstant'),
    MultiplyConjugateBlock = require('radio.blocks.signal.multiplyconjugate'),
    AbsoluteValueBlock = require('radio.blocks.signal.absolutevalue'),
    ComplexConjugateBlock = require('radio.blocks.signal.complexconjugate'),
    ComplexMagnitudeBlock = require('radio.blocks.signal.complexmagnitude'),
    ComplexPhaseBlock = require('radio.blocks.signal.complexphase'),
    --- Level control
    PowerSquelchBlock = require('radio.blocks.signal.powersquelch'),
    AGCBlock = require('radio.blocks.signal.agc'),
    --- Sample Rate Manipulation
    DownsamplerBlock = require('radio.blocks.signal.downsampler'),
    UpsamplerBlock = require('radio.blocks.signal.upsampler'),
    --- Spectrum Manipulation
    FrequencyTranslatorBlock = require('radio.blocks.signal.frequencytranslator'),
    HilbertTransformBlock = require('radio.blocks.signal.hilberttransform'),
    --- Carrier and Clock Recovery
    PLLBlock = require('radio.blocks.signal.pll'),
    ZeroCrossingClockRecoveryBlock = require('radio.blocks.signal.zerocrossingclockrecovery'),
    --- Digital
    BinaryPhaseCorrectorBlock = require('radio.blocks.signal.binaryphasecorrector'),
    SamplerBlock = require('radio.blocks.signal.sampler'),
    PreambleSamplerBlock = require('radio.blocks.signal.preamblesampler'),
    SlicerBlock = require('radio.blocks.signal.slicer'),
    DifferentialDecoderBlock = require('radio.blocks.signal.differentialdecoder'),
    ManchesterDecoderBlock = require('radio.blocks.signal.manchesterdecoder'),
    --- Type Conversion
    ComplexToRealBlock = require('radio.blocks.signal.complextoreal'),
    ComplexToImagBlock = require('radio.blocks.signal.complextoimag'),
    ComplexToFloatBlock = require('radio.blocks.signal.complextofloat'),
    RealToComplexBlock = require('radio.blocks.signal.realtocomplex'),
    FloatToComplexBlock = require('radio.blocks.signal.floattocomplex'),
    --- Modulation
    FrequencyModulatorBlock = require('radio.blocks.signal.frequencymodulator'),
    --- Demodulation
    FrequencyDiscriminatorBlock = require('radio.blocks.signal.frequencydiscriminator'),
    --- Miscellaneous
    DelayBlock = require('radio.blocks.signal.delay'),
    ThrottleBlock = require('radio.blocks.signal.throttle'),
    NopBlock = require('radio.blocks.signal.nop'),
    DeinterleaveBlock = require('radio.blocks.signal.deinterleave'),
    InterleaveBlock = require('radio.blocks.signal.interleave'),

    -- Protocol Blocks
    --- RDS
    RDSFramerBlock = require('radio.blocks.protocol.rdsframer'),
    RDSDecoderBlock = require('radio.blocks.protocol.rdsdecoder'),
    --- AX25
    AX25FramerBlock = require('radio.blocks.protocol.ax25framer'),
    --- POCSAG
    POCSAGFramerBlock = require('radio.blocks.protocol.pocsagframer'),
    POCSAGDecoderBlock = require('radio.blocks.protocol.pocsagdecoder'),
    --- Varicode
    VaricodeDecoderBlock = require('radio.blocks.protocol.varicodedecoder'),
}
