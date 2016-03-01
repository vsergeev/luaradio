return {
    -- Basic types
    CStructType = require('radio.types.cstruct').CStructType,
    ObjectType = require('radio.types.object').ObjectType,
    ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type,
    Float32Type = require('radio.types.float32').Float32Type,
    Integer32Type = require('radio.types.integer32').Integer32Type,
    ByteType = require('radio.types.byte').ByteType,
    BitType = require('radio.types.bit').BitType,

    -- Helper functions
    bits_to_number = require('radio.types.bit').bits_to_number,
}
