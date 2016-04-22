---
-- Throttle a signal to limit CPU usage and pace plotting sinks.
--
-- $$ y[n] = x[n] $$
--
-- @category Miscellaneous
-- @block ThrottleBlock
--
-- @signature in:any > out:copy
--
-- @usage
-- local throttle = radio.ThrottleBlock()
-- top:connect(src, throttle, snk)

local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local ThrottleBlock = block.factory("ThrottleBlock")

function ThrottleBlock:instantiate()
    -- Add a dummy type signature
    self:add_type_signature({block.Input("in", nil)}, {block.Output("out", nil)})
end

function ThrottleBlock:differentiate(input_data_types)
    -- Absorb data type into dummy type signature
    self.signatures[1].inputs[1].data_type = input_data_types[1]
    self.signatures[1].outputs[1].data_type = input_data_types[1]

    block.Block.differentiate(self, input_data_types)
end

function ThrottleBlock:initialize()
    self.rate = self:get_rate()
end

ffi.cdef[[
    int usleep(unsigned int usec);
]]

function ThrottleBlock:process(x)
    -- Sleep for sample length / sample rate time
    ffi.C.usleep(math.floor((x.length / self.rate)*1e6))

    return x
end

return ThrottleBlock
