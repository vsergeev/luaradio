---
-- Demodulate and decode RDS frames from a baseband, wideband FM broadcast
-- modulated complex-valued signal.
--
-- @category Receivers
-- @block RDSReceiver
--
-- @signature in:ComplexFloat32 > out:RDSFrameType
--
-- @usage
-- local receiver = radio.RDSReceiver()
-- local decoder = radio.RDSDecoderBlock()
-- local snk = radio.JSONSink()
-- top:connect(src, receiver, decoder, snk)

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local RDSReceiver = block.factory("RDSReceiver", blocks.CompositeBlock)

function RDSReceiver:instantiate()
    blocks.CompositeBlock.instantiate(self)

    local fm_demod = blocks.FrequencyDiscriminatorBlock(1.25)
    local hilbert = blocks.HilbertTransformBlock(129)
    local mixer_delay = blocks.DelayBlock(129)
    local pilot_filter = blocks.ComplexBandpassFilterBlock(129, {18e3, 20e3})
    local pll_baseband = blocks.PLLBlock(1500.0, 19e3-100, 19e3+100, 3.0)
    local mixer = blocks.MultiplyConjugateBlock()
    local baseband_filter = blocks.LowpassFilterBlock(128, 4e3)
    local baseband_rrc = blocks.RootRaisedCosineFilterBlock(101, 1, 1187.5)
    local phase_corrector = blocks.BinaryPhaseCorrectorBlock(8000)
    local clock_demod = blocks.ComplexToRealBlock()
    local clock_recoverer = blocks.ZeroCrossingClockRecoveryBlock(1187.5*2)
    local sampler = blocks.SamplerBlock()
    local bit_demod = blocks.ComplexToRealBlock()
    local bit_slicer = blocks.SlicerBlock()
    local bit_decoder = blocks.ManchesterDecoderBlock()
    local bit_diff_decoder = blocks.DifferentialDecoderBlock()
    local framer = blocks.RDSFramerBlock()

    self:connect(fm_demod, hilbert, mixer_delay)
    self:connect(hilbert, pilot_filter, pll_baseband)
    self:connect(mixer_delay, 'out', mixer, 'in1')
    self:connect(pll_baseband, 'out', mixer, 'in2')
    self:connect(mixer, baseband_filter, baseband_rrc, phase_corrector)
    self:connect(phase_corrector, clock_demod, clock_recoverer)
    self:connect(phase_corrector, 'out', sampler, 'data')
    self:connect(clock_recoverer, 'out', sampler, 'clock')
    self:connect(sampler, bit_demod, bit_slicer, bit_decoder, bit_diff_decoder, framer)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", blocks.RDSFramerBlock.RDSFrameType)})
    self:connect(self, "in", fm_demod, "in")
    self:connect(self, "out", framer, "out")
end

return RDSReceiver
