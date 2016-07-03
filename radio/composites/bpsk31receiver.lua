---
-- Demodulate and decode bytes from a baseband BPSK31 modulated complex-valued
-- signal.
--
-- @category Receivers
-- @block BPSK31Receiver
--
-- @signature in:ComplexFloat32 > out:Byte
--
-- @usage
-- local receiver = radio.BPSK31Receiver()
-- local snk = radio.RawFileSink(io.stdout)
-- top:connect(src, receiver, snk)

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local BPSK31Receiver = block.factory("BPSK31Receiver", blocks.CompositeBlock)

function BPSK31Receiver:instantiate()
    blocks.CompositeBlock.instantiate(self)

    local bandwidth = 100
    local baudrate = 31.25

    local filter = blocks.LowpassFilterBlock(128, bandwidth)
    local rrc_filter = blocks.RootRaisedCosineFilterBlock(101, 1, baudrate)
    local phase_corrector = blocks.BinaryPhaseCorrectorBlock(50)
    local clock_demod = blocks.ComplexToRealBlock()
    local clock_recoverer = blocks.ZeroCrossingClockRecoveryBlock(baudrate)
    local sampler = blocks.SamplerBlock()
    local bit_demod = blocks.ComplexToRealBlock()
    local slicer = blocks.SlicerBlock()
    local bit_decoder = blocks.DifferentialDecoderBlock(true)
    local decoder = blocks.VaricodeDecoderBlock()

    self:connect(filter, rrc_filter, phase_corrector)
    self:connect(phase_corrector, clock_demod, clock_recoverer)
    self:connect(phase_corrector, 'out', sampler, 'data')
    self:connect(clock_recoverer, 'out', sampler, 'clock')
    self:connect(sampler, bit_demod, slicer, bit_decoder, decoder)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Byte)})
    self:connect(self, "in", filter, "in")
    self:connect(self, "out", decoder, "out")
end

return BPSK31Receiver
