---
-- Sink a signal and do nothing. This sink accepts any data type.
--
-- @category Sinks
-- @block NopSink
--
-- @signature in:any >
--
-- @usage
-- local snk = radio.NopSink()
-- top:connect(src, snk)

local block = require('radio.core.block')

local NopSink = block.factory("NopSink")

function NopSink:instantiate()
    -- Accept all input types
    self:add_type_signature({block.Input("in", function (t) return true end)}, {})
end

function NopSink:process(x)
    -- Do nothing
end

return NopSink
