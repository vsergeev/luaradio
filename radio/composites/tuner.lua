local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local TunerBlock = block.factory("TunerBlock", blocks.CompositeBlock)

function TunerBlock:instantiate(offset, bandwidth, decimation, options)
    blocks.CompositeBlock.instantiate(self)

    assert(offset, "Missing argument #1 (offset)")
    assert(bandwidth, "Missing argument #2 (bandwidth)")
    assert(decimation, "Missing argument #3 (decimation)")
    options = options or {}

    local translator = blocks.FrequencyTranslatorBlock(offset)
    local filter = blocks.LowpassFilterBlock(options.num_taps or 128, bandwidth/2, nil, options.window_type)
    local downsampler = blocks.DownsamplerBlock(decimation)
    self:connect(translator, filter, downsampler)

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:connect(self, "in", translator, "in")
    self:connect(self, "out", downsampler, "out")
end

return TunerBlock
