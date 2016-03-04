return {
    -- Core public modules
    platform = require('radio.core.platform'),
    block = require('radio.core.block'),
    object = require('radio.core.object'),
    util = require('radio.core.util'),
    types = require('radio.types'),

    -- Types
    ComplexFloat32Type = require('radio.types').ComplexFloat32Type,
    Float32Type = require('radio.types').Float32Type,
    Integer32Type = require('radio.types').Integer32Type,
    ByteType = require('radio.types').ByteType,
    BitType = require('radio.types').BitType,
    CStructType = require('radio.types').CStructType,
    ObjectType = require('radio.types').ObjectType,

    -- Composite block
    CompositeBlock = require('radio.core.composite').CompositeBlock,

    -- Source Blocks
    IQFileSource = require('radio.blocks.sources.iqfile').IQFileSource,
    RealFileSource = require('radio.blocks.sources.realfile').RealFileSource,
    WAVFileSource = require('radio.blocks.sources.wavfile').WAVFileSource,
    RawFileSource = require('radio.blocks.sources.rawfile').RawFileSource,
    NullSource = require('radio.blocks.sources.null').NullSource,
    RandomSource = require('radio.blocks.sources.random').RandomSource,
    SignalSource = require('radio.blocks.sources.signal').SignalSource,
    RtlSdrSource = require('radio.blocks.sources.rtlsdr').RtlSdrSource,

    -- Sink Blocks
    IQFileSink = require('radio.blocks.sinks.iqfile').IQFileSink,
    RealFileSink = require('radio.blocks.sinks.realfile').RealFileSink,
    WAVFileSink = require('radio.blocks.sinks.wavfile').WAVFileSink,
    RawFileSink = require('radio.blocks.sinks.rawfile').RawFileSink,
    PrintSink = require('radio.blocks.sinks.print').PrintSink,
    JSONSink = require('radio.blocks.sinks.json').JSONSink,
    PulseAudioSink = require('radio.blocks.sinks.pulseaudio').PulseAudioSink,

    -- Signal Blocks
    FIRFilterBlock = require('radio.blocks.signal.firfilter').FIRFilterBlock,
    IIRFilterBlock = require('radio.blocks.signal.iirfilter').IIRFilterBlock,
    LowpassFilterBlock = require('radio.blocks.signal.lowpassfilter').LowpassFilterBlock,
    HighpassFilterBlock = require('radio.blocks.signal.highpassfilter').HighpassFilterBlock,
    BandpassFilterBlock = require('radio.blocks.signal.bandpassfilter').BandpassFilterBlock,
    BandstopFilterBlock = require('radio.blocks.signal.bandstopfilter').BandstopFilterBlock,
    RootRaisedCosineFilterBlock = require('radio.blocks.signal.rootraisedcosinefilter').RootRaisedCosineFilterBlock,
    FMDeemphasisFilterBlock = require('radio.blocks.signal.fmdeemphasisfilter').FMDeemphasisFilterBlock,
    SumBlock = require('radio.blocks.signal.sum').SumBlock,
    SubtractBlock = require('radio.blocks.signal.subtract').SubtractBlock,
    MultiplyBlock = require('radio.blocks.signal.multiply').MultiplyBlock,
    FrequencyTranslatorBlock = require('radio.blocks.signal.frequencytranslator').FrequencyTranslatorBlock,
    HilbertTransformBlock = require('radio.blocks.signal.hilberttransform').HilbertTransformBlock,
    MultiplyConjugateBlock = require('radio.blocks.signal.multiplyconjugate').MultiplyConjugateBlock,
    DownsamplerBlock = require('radio.blocks.signal.downsampler').DownsamplerBlock,
    SamplerBlock = require('radio.blocks.signal.sampler').SamplerBlock,
    SlicerBlock = require('radio.blocks.signal.slicer').SlicerBlock,
    DifferentialDecoderBlock = require('radio.blocks.signal.differentialdecoder').DifferentialDecoderBlock,
    AbsoluteValueBlock = require('radio.blocks.signal.absolutevalue').AbsoluteValueBlock,
    ComplexMagnitudeBlock = require('radio.blocks.signal.complexmagnitude').ComplexMagnitudeBlock,
    ComplexPhaseBlock = require('radio.blocks.signal.complexphase').ComplexPhaseBlock,
    ComplexToRealBlock = require('radio.blocks.signal.complextoreal').ComplexToRealBlock,
    ComplexToImagBlock = require('radio.blocks.signal.complextoimag').ComplexToImagBlock,
    DelayBlock = require('radio.blocks.signal.delay').DelayBlock,
    BinaryPhaseCorrectorBlock = require('radio.blocks.signal.binaryphasecorrector').BinaryPhaseCorrectorBlock,
    FrequencyDiscriminatorBlock = require('radio.blocks.signal.frequencydiscriminator').FrequencyDiscriminatorBlock,
    PLLBlock = require('radio.blocks.signal.pllblock').PLLBlock,

    -- Protocol Blocks
    RDSFrameBlock = require('radio.blocks.protocol.rdsframe').RDSFrameBlock,
    RDSDecodeBlock = require('radio.blocks.protocol.rdsdecode').RDSDecodeBlock,

    -- Composite Blocks
    TunerBlock = require('radio.composites.tuner').TunerBlock,
    DecimatorBlock = require('radio.composites.decimator').DecimatorBlock,
}
