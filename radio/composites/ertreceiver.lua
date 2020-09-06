---
-- Demodulate and decode ERT frames from an OOK modulated complex-valued
-- signal. IDM, SCM, SCM+ protocols are supported.
--
-- This receiver is based on rtlamr's excellent description:
-- <https://github.com/bemasher/rtlamr/wiki/Signal-Processing>
--
-- @category Receivers
-- @block ERTReceiver
-- @tparam[opt={'idm','scm','scm+'}] array protocols Protocols to decode,
--                                                   choice of 'idm', 'scm',
--                                                   'scm+'. Default is all
--                                                   three.
-- @tparam[opt={}] table options Additional options, specifying:
--                               * `decimation` Downsampling factor (int, default 6)
--
-- @signature in:ComplexFloat32 > out1:IDMFrameType, out2:SCMFrameType, ...
--
-- @usage
-- local receiver = radio.ERTReceiver({'scm', 'scm+'})
-- local scm_sink = radio.PrintSink()
-- local scm_plus_sink = radio.PrintSink()
-- top:connect(src, receiver)
-- top:connect(receiver, 'out1', scm_sink, 'in')
-- top:connect(receiver, 'out2', scm_plus_sink, 'in')

local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local ERTReceiver = block.factory("ERTReceiver", blocks.CompositeBlock)

function ERTReceiver:instantiate(protocols, options)
    blocks.CompositeBlock.instantiate(self)

    options = options or {}

    local symbol_rate = 32768
    local decimation = options.decimation or 6

    local magnitude = blocks.ComplexMagnitudeBlock()
    local data_filter = blocks.LowpassFilterBlock(128, symbol_rate * 4)
    local downsampler = blocks.DownsamplerBlock(decimation)
    local matched_filter = blocks.ManchesterMatchedFilterBlock(symbol_rate)

    self:connect(magnitude, data_filter, downsampler, matched_filter)

    local framer_blocks = {}
    local outputs = {}

    for i, protocol in ipairs(protocols) do
        local sampler, slicer, framer, frame_type

        if protocol == 'idm' then
            sampler = blocks.PreambleSamplerBlock(symbol_rate / 2, blocks.IDMFramerBlock.IDM_PREAMBLE, blocks.IDMFramerBlock.IDM_FRAME_LEN)
            slicer = blocks.SlicerBlock()
            framer = blocks.IDMFramerBlock()
            frame_type = blocks.IDMFramerBlock.IDMFrameType
        elseif protocol == 'scm' then
            sampler = blocks.PreambleSamplerBlock(symbol_rate / 2, blocks.SCMFramerBlock.SCM_PREAMBLE, blocks.SCMFramerBlock.SCM_FRAME_LEN)
            slicer = blocks.SlicerBlock()
            framer = blocks.SCMFramerBlock()
            frame_type = blocks.SCMFramerBlock.SCMFrameType
        elseif protocol == 'scm+' then
            sampler = blocks.PreambleSamplerBlock(symbol_rate / 2, blocks.SCMPlusFramerBlock.SCM_PLUS_PREAMBLE, blocks.SCMPlusFramerBlock.SCM_PLUS_FRAME_LEN)
            slicer = blocks.SlicerBlock()
            framer = blocks.SCMPlusFramerBlock()
            frame_type = blocks.SCMPlusFramerBlock.SCMPlusFrameType
        else
            error("Unsupported protocol \"" .. protocol .. "\"")
        end

        self:connect(matched_filter, sampler, slicer, framer)
        framer_blocks[#framer_blocks + 1] = framer
        outputs[#outputs + 1] = block.Output("out" .. i, frame_type)
    end

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, outputs)

    self:connect(self, "in", magnitude, "in")

    -- Connect last block of each protocol decoding chain to an aliased output
    for i, _ in ipairs(outputs) do
        self:connect(self, "out" .. i, framer_blocks[i], "out")
    end
end

return ERTReceiver
