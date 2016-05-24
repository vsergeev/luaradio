local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local POCSAGReceiver = block.factory("POCSAGReceiver", blocks.CompositeBlock)

function POCSAGReceiver:instantiate(baudrate)
    blocks.CompositeBlock.instantiate(self)

    local baudrate = baudrate or 1200

    assert(baudrate == 512 or baudrate == 1200, "Only 512 and 1200 baudrates supported.")

    local space_filter = blocks.ComplexBandpassFilterBlock(129, {3500, 5500})
    local space_magnitude = blocks.ComplexMagnitudeBlock()
    local mark_filter = blocks.ComplexBandpassFilterBlock(129, {-5500, -3500})
    local mark_magnitude = blocks.ComplexMagnitudeBlock()
    local subtractor = blocks.SubtractBlock()
    local data_filter = blocks.LowpassFilterBlock(128, baudrate)
    local clock_recovery = blocks.ZeroCrossingClockRecoveryBlock(baudrate)
    local sampler = blocks.SamplerBlock()
    local bit_slicer = blocks.SlicerBlock()
    local framer = blocks.POCSAGFramerBlock()
    local decoder = blocks.POCSAGDecodeBlock()

    self:connect(space_filter, space_magnitude)
    self:connect(mark_filter, mark_magnitude)
    self:connect(mark_magnitude, 'out', subtractor, 'in1')
    self:connect(space_magnitude, 'out', subtractor, 'in2')
    self:connect(subtractor, data_filter, clock_recovery)
    self:connect(data_filter, 'out', sampler, 'data')
    self:connect(clock_recovery, 'out', sampler, 'clock')
    self:connect(sampler, bit_slicer, framer, decoder)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", blocks.POCSAGDecodeBlock.POCSAGMessageType)})
    self:connect(self, "in", space_filter, "in")
    self:connect(self, "in", mark_filter, "in")
    self:connect(self, "out", decoder, "out")
end

return POCSAGReceiver
