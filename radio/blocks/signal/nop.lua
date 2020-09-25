---
-- Pass a signal through, performing no operation.
--
-- $$ y[n] = x[n] $$
--
-- @category Miscellaneous
-- @block NopBlock
--
-- @signature in:any > out:copy
--
-- @usage
-- local nop = radio.NopBlock()
-- top:connect(src, nop, snk)

local ffi = require('ffi')

local block = require('radio.core.block')

local NopBlock = block.factory("NopBlock")

function NopBlock:instantiate()
    self:add_type_signature({block.Input("in", function (type) return true end)}, {block.Output("out", "copy")})
end

function NopBlock:process(x)
    return x
end

return NopBlock
