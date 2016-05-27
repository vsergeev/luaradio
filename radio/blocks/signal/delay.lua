local ffi = require('ffi')

local block = require('radio.core.block')
local types = require('radio.types')

local DelayBlock = block.factory("DelayBlock")

function DelayBlock:instantiate(num_samples)
    self.num_samples = assert(num_samples, "Missing argument #1 (num_samples)")
    assert(num_samples > 0, "Number of samples must be greater than 0")

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.Float32)})
    self:add_type_signature({block.Input("in", types.Bit)}, {block.Output("out", types.Bit)})
    self:add_type_signature({block.Input("in", types.Byte)}, {block.Output("out", types.Byte)})
end

function DelayBlock:initialize()
    self.data_type = self:get_input_type()
    self.state = self.data_type.vector(self.num_samples)
end

ffi.cdef[[
void *memcpy(void *dest, const void *src, size_t n);
void *memmove(void *dest, const void *src, size_t n);
]]

function DelayBlock:process(x)
    local out = self.data_type.vector(x.length)

    if x.length < self.state.length then
        -- Input is shorter than our state

        -- Shift out current state
        ffi.C.memcpy(out.data, self.state.data, out.length*ffi.sizeof(self.state.data[0]))
        -- Shift down state samples
        ffi.C.memmove(self.state.data, self.state.data[out.length], (self.state.length - out.length)*ffi.sizeof(self.state.data[0]))
        -- Shift input into state
        ffi.C.memcpy(self.state.data[self.state.length - out.length], x.data, x.length*ffi.sizeof(self.state.data[0]))
    else
        -- Input is longer than our state

        -- Shift out all of current state
        ffi.C.memcpy(out.data, self.state.data, self.state.length*ffi.sizeof(self.state.data[0]))
        -- Shift out part of the input
        ffi.C.memcpy(out.data[self.state.length], x.data, (out.length - self.state.length)*ffi.sizeof(self.state.data[0]))
        -- Shift remainder of the input into the state
        self.state:resize(x.length - (out.length - self.state.length))
        ffi.C.memcpy(self.state.data, x.data[out.length - self.state.length], (x.length - (out.length - self.state.length))*ffi.sizeof(self.state.data[0]))
    end

    return out
end

return DelayBlock
