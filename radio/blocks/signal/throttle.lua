local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local ThrottleBlock = block.factory("ThrottleBlock")

function ThrottleBlock:instantiate()
    -- Accept all input types
    self:add_type_signature({block.Input("in", function (type) return true end)}, {block.Output("out", nil)})
end

function ThrottleBlock:differentiate(input_data_types)
    block.Block.differentiate(self, input_data_types)

    -- Copy input data type to output data type
    self.signature.outputs[1].data_type = input_data_types[1]
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

return {ThrottleBlock = ThrottleBlock}
