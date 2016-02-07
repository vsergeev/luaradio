local ffi = require('ffi')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type

local IIRFilterBlock = block.factory("IIRFilterBlock")

function IIRFilterBlock:instantiate(b_taps, a_taps)
    assert(#a_taps >= 1, "Feedback taps must be at least length 1.")
    self.b_taps = Float32Type.vector_from_array(b_taps)
    self.a_taps = Float32Type.vector_from_array(a_taps)

    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {block.Output("out", ComplexFloat32Type)}, IIRFilterBlock.process_complex)
    self:add_type_signature({block.Input("in", Float32Type)}, {block.Output("out", Float32Type)}, IIRFilterBlock.process_scalar)
end

ffi.cdef[[
void *memmove(void *dest, const void *src, size_t n);
]]

function IIRFilterBlock:initialize()
    if self.signature.inputs[1].data_type == ComplexFloat32Type then
        self.data_type = ComplexFloat32Type
    else
        self.data_type = Float32Type
    end

    self.input_state = self.data_type.vector(self.b_taps.length)
    self.output_state = self.data_type.vector(self.a_taps.length-1)
end

function IIRFilterBlock:process_complex(x)
    local out = ComplexFloat32Type.vector(x.length)

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
    local out = Float32Type.vector(x.length)

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

return {IIRFilterBlock = IIRFilterBlock}
