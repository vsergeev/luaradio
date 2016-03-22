local block = require('radio.core.block')
local types = require('radio.types')

local CompositeBlock = require('radio.core.composite').CompositeBlock
local FrequencyTranslatorBlock = require('radio.blocks.signal.frequencytranslator').FrequencyTranslatorBlock
local LowpassFilterBlock = require('radio.blocks.signal.lowpassfilter').LowpassFilterBlock
local DownsamplerBlock = require('radio.blocks.signal.downsampler').DownsamplerBlock

local TunerBlock = block.factory("TunerBlock", CompositeBlock)

function TunerBlock:instantiate(offset, bandwidth, decimation, options)
    CompositeBlock.instantiate(self)

    options = options or {}

    local translator = FrequencyTranslatorBlock(offset)
    local filter = LowpassFilterBlock(options.num_taps or 128, bandwidth/2, options.window)
    local downsampler = DownsamplerBlock(decimation)
    self:connect(translator, filter, downsampler)

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)})
    self:connect(self, "in", translator, "in")
    self:connect(self, "out", downsampler, "out")
end

return {TunerBlock = TunerBlock}
