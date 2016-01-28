return {
    -- Core public modules
    block = require('radio.core.block'),
    util = require('radio.core.util'),

    -- Blocks
    CompositeBlock = require('radio.core.composite').CompositeBlock,
    FIRFilterBlock = require('radio.blocks.signal.firfilter').FIRFilterBlock,
    SummerBlock = require('radio.blocks.signal.summer').SummerBlock,
    FileDescriptorSinkBlock = require('radio.blocks.sinks.filedescriptorsink').FileDescriptorSinkBlock,
    PrintSinkBlock = require('radio.blocks.sinks.printsink').PrintSinkBlock,
    FileIQSourceBlock = require('radio.blocks.sources.fileiqsource').FileIQSourceBlock,
    NullSourceBlock = require('radio.blocks.sources.nullsource').NullSourceBlock,
    RandomSourceBlock = require('radio.blocks.sources.randomsource').RandomSourceBlock,

    -- Types
    ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type,
    Float32Type = require('radio.types.float32').Float32Type,
    Integer32Type = require('radio.types.integer32').Integer32Type,
    ByteType = require('radio.types.byte').ByteType,
    BitType = require('radio.types.bit').BitType,
}
