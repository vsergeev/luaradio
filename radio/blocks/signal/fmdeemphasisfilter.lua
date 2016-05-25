local block = require('radio.core.block')

local block = require('radio.core.block')

local SinglepoleLowpassFilterBlock = require('radio.blocks.signal.singlepolelowpassfilter')

local FMDeemphasisFilterBlock = block.factory("FMDeemphasisFilterBlock", SinglepoleLowpassFilterBlock)

function FMDeemphasisFilterBlock:instantiate(tau)
    SinglepoleLowpassFilterBlock.instantiate(self, 1/(2*math.pi*tau))
end

return FMDeemphasisFilterBlock
