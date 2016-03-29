local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')
local nbfmdemodulator = require('radio.composites.nbfmdemodulator')

local AX25Receiver = block.factory("AX25Receiver", blocks.CompositeBlock)

function AX25Receiver:instantiate()
    blocks.CompositeBlock.instantiate(self)

    local fm_deviation = 3e3
    local fm_bandwidth = 3e3
    local baudrate = 1200

    local nbfm_demod = nbfmdemodulator.NBFMDemodulator(fm_deviation, fm_bandwidth)
    local hilbert = blocks.HilbertTransformBlock(129)
    local translator = blocks.FrequencyTranslatorBlock(-1700)
    local afsk_filter = blocks.LowpassFilterBlock(128, 750)
    local afsk_demod = blocks.FrequencyDiscriminatorBlock(5.0)
    local data_filter = blocks.LowpassFilterBlock(128, baudrate)
    local clock_recoverer = blocks.ZeroCrossingClockRecoveryBlock(baudrate)
    local sampler = blocks.SamplerBlock()
    local bit_slicer = blocks.SlicerBlock()
    local bit_decoder = blocks.DifferentialDecoderBlock(true)
    local framer = blocks.AX25FrameBlock()

    self:connect(nbfm_demod, hilbert, translator, afsk_filter, afsk_demod, data_filter, clock_recoverer)
    self:connect(data_filter, 'out', sampler, 'data')
    self:connect(clock_recoverer, 'out', sampler, 'clock')
    self:connect(sampler, bit_slicer, bit_decoder, framer)

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", blocks.AX25FrameBlock.AX25FrameType)})
    self:connect(self, "in", nbfm_demod, "in")
    self:connect(self, "out", framer, "out")
end

return {AX25Receiver = AX25Receiver}
