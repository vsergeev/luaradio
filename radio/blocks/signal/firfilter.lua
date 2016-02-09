local ffi = require('ffi')

local block = require('radio.core.block')
local object = require('radio.core.object')
local Vector = require('radio.core.vector').Vector
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type

local FIRFilterBlock = block.factory("FIRFilterBlock")

function FIRFilterBlock:instantiate(taps)
    if object.isinstanceof(taps, Vector) and taps.type == Float32Type then
        self.taps = taps
    else
        self.taps = Float32Type.vector_from_array(taps)
    end

    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {block.Output("out", ComplexFloat32Type)}, FIRFilterBlock.process_complex)
    self:add_type_signature({block.Input("in", Float32Type)}, {block.Output("out", Float32Type)}, FIRFilterBlock.process_float)
end

ffi.cdef[[
void *memmove(void *dest, const void *src, size_t n);
void (*volk_32fc_32f_dot_prod_32fc_a)(complex_float32_t* result, const complex_float32_t* input, const float32_t* taps, unsigned int num_points);
void (*volk_32f_x2_dot_prod_32f_a)(float32_t* result, const float32_t* input, const float32_t* taps, unsigned int num_points);
]]
local libvolk = ffi.load("libvolk.so")

function FIRFilterBlock:initialize()
    if self.signature.inputs[1].data_type == ComplexFloat32Type then
        self.data_type = ComplexFloat32Type
    else
        self.data_type = Float32Type
    end

    self.state = self.data_type.vector(self.taps.length)
end

function FIRFilterBlock:process_complex(x)
    local out = ComplexFloat32Type.vector(x.length)

    for i = 0, x.length-1 do
        -- Shift the state samples down
        ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
        -- Insert sample into state
        self.state.data[0] = x.data[i]
        -- Inner product of state and taps
        libvolk.volk_32fc_32f_dot_prod_32fc_a(out.data[i], self.state.data, self.taps.data, self.taps.length)

        -- Inner product of state and taps (slow Lua version)
        --for j = 0, self.state.length-1 do
        --    out.data[i] = out.data[i] + self.state.data[j]:scalar_mul(self.taps.data[j+1].value)
        --end
    end

    return out
end

function FIRFilterBlock:process_float(x)
    local out = Float32Type.vector(x.length)

    for i = 0, x.length-1 do
        -- Shift the state samples down
        ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
        -- Insert sample into state
        self.state.data[0] = x.data[i]
        -- Inner product of state and taps
        libvolk.volk_32f_x2_dot_prod_32f_a(out.data[i], self.state.data, self.taps.data, self.taps.length)

        -- Inner product of state and taps (slow Lua version)
        --for j = 0, self.state.length-1 do
        --    out.data[i].value = out.data[i].value + self.state.data[j].value * self.taps.data[j+1].value
        --end
    end

    return out
end

return {FIRFilterBlock = FIRFilterBlock}
