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
    -- Add a dummy type signature
    self:add_type_signature({block.Input("in", nil)}, {block.Output("out", nil)})
end

function NopBlock:differentiate(input_data_types)
    -- Absorb data type into dummy type signature
    self.signatures[1].inputs[1].data_type = input_data_types[1]
    self.signatures[1].outputs[1].data_type = input_data_types[1]

    block.Block.differentiate(self, input_data_types)
end

function NopBlock:process(x)
    return x
end

return NopBlock
