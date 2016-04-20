local ffi = require('ffi')

local block = require('radio.core.block')
local object = require('radio.core.object')
local types = require('radio.types')
local vector = require('radio.core.vector')

local IIRFilterBlock = block.factory("IIRFilterBlock")

function IIRFilterBlock:instantiate(b_taps, a_taps)
    if object.isinstanceof(b_taps, vector.Vector) and b_taps.type == types.Float32Type then
        self.b_taps = b_taps
    else
        self.b_taps = types.Float32Type.vector_from_array(b_taps)
    end

    if object.isinstanceof(a_taps, vector.Vector) and a_taps.type == types.Float32Type then
        assert(a_taps.length >= 1, "Feedback taps must be at least length 1.")
        self.a_taps = a_taps
    else
        assert(#a_taps >= 1, "Feedback taps must be at least length 1.")
        self.a_taps = types.Float32Type.vector_from_array(a_taps)
    end

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)}, IIRFilterBlock.process_complex)
    self:add_type_signature({block.Input("in", types.Float32Type)}, {block.Output("out", types.Float32Type)}, IIRFilterBlock.process_scalar)
end

ffi.cdef[[
void *memmove(void *dest, const void *src, size_t n);
]]

function IIRFilterBlock:initialize()
    self.data_type = self:get_input_types()[1]
    self.input_state = self.data_type.vector(self.b_taps.length)
    self.output_state = self.data_type.vector(self.a_taps.length-1)
end

function IIRFilterBlock:process_complex(x)
    local out = types.ComplexFloat32Type.vector(x.length)

    for i = 0, x.length-1 do
        -- Shift the input state samples down
        ffi.C.memmove(self.input_state.data[1], self.input_state.data[0], (self.input_state.length-1)*ffi.sizeof(self.input_state.data[0]))
        -- Insert input sample into input state
        self.input_state.data[0] = x.data[i]

        -- Inner product of input state and b taps
        for j = 0, self.input_state.length-1 do
            out.data[i] = out.data[i] + self.input_state.data[j]:scalar_mul(self.b_taps.data[j].value)
        end
        -- Inner product of output state and a taps (skipping a[0])
        for j = 0, self.output_state.length-1 do
            out.data[i] = out.data[i] - self.output_state.data[j]:scalar_mul(self.a_taps.data[j+1].value)
        end
        -- Apply a[0] tap
        out.data[i] = out.data[i]:scalar_div(self.a_taps.data[0].value)

        -- Shift the output state samples down
        ffi.C.memmove(self.output_state.data[1], self.output_state.data[0], (self.output_state.length-1)*ffi.sizeof(self.output_state.data[0]))
        -- Insert output sample into output state
        self.output_state.data[0] = out.data[i]
    end

    return out
end

function IIRFilterBlock:process_scalar(x)
    local out = types.Float32Type.vector(x.length)

    for i = 0, x.length-1 do
        -- Shift the input state samples down
        ffi.C.memmove(self.input_state.data[1], self.input_state.data[0], (self.input_state.length-1)*ffi.sizeof(self.input_state.data[0]))
        -- Insert input sample into input state
        self.input_state.data[0] = x.data[i]

        -- Inner product of input state and b taps
        for j = 0, self.input_state.length-1 do
            out.data[i] = out.data[i] + self.input_state.data[j] * self.b_taps.data[j]
        end
        -- Inner product of output state and a taps (skipping a[0])
        for j = 0, self.output_state.length-1 do
            out.data[i] = out.data[i] - self.output_state.data[j] * self.a_taps.data[j+1]
        end
        -- Apply a[0] tap
        out.data[i] = out.data[i] / self.a_taps.data[0]

        -- Shift the output state samples down
        ffi.C.memmove(self.output_state.data[1], self.output_state.data[0], (self.output_state.length-1)*ffi.sizeof(self.output_state.data[0]))
        -- Insert output sample into output state
        self.output_state.data[0] = out.data[i]
    end

    return out
end

return IIRFilterBlock
