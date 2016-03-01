local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local DelayBlock = block.factory("DelayBlock")

function DelayBlock:instantiate(num_samples)
    assert(num_samples > 0, "Number of samples must be greater than 0.")
    self.num_samples = num_samples

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)})
    self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)})
    self:add_type_signature({block.Input("in", types.Integer32Type)}, {block.Output("out", types.Integer32Type)})
end

function DelayBlock:initialize()
    self.data_type = self.signature.inputs[1].data_type

    self.state = self.data_type.vector(self.num_samples+1)
end

ffi.cdef[[
void *memmove(void *dest, const void *src, size_t n);
]]

function DelayBlock:process(x)
    local out = self.data_type.vector(x.length)

    for i = 0, out.length-1 do
        -- Shift the state samples down
        ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
        -- Insert sample into state
        self.state.data[0] = x.data[i]

        out.data[i] = self.state.data[self.state.length-1]
    end

    return out
end

return {DelayBlock = DelayBlock}
