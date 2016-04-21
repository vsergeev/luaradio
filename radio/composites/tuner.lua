local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local TunerBlock = block.factory("TunerBlock", blocks.CompositeBlock)

function TunerBlock:instantiate(offset, bandwidth, decimation, options)
    blocks.CompositeBlock.instantiate(self)

    options = options or {}

    local translator = blocks.FrequencyTranslatorBlock(offset)
    local filter = blocks.LowpassFilterBlock(options.num_taps or 128, bandwidth/2, options.window)
    local downsampler = blocks.DownsamplerBlock(decimation)
    self:connect(translator, filter, downsampler)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:connect(self, "in", translator, "in")
    self:connect(self, "out", downsampler, "out")
end

return TunerBlock
