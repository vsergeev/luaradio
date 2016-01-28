local ffi = require('ffi')

local block = require('block')
local ComplexFloat32Type = require('types.complexfloat32').ComplexFloat32Type
local Float32Type = require('types.float32').Float32Type

local FIRFilterBlock = block.BlockFactory("FIRFilterBlock")

function FIRFilterBlock:instantiate(taps)
    self.taps = Float32Type.vector(#taps)
    for i = 1, #taps do
        self.taps.data[i-1].value = taps[i]
    end

    self.state = ComplexFloat32Type.vector(#taps)

    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {block.Output("out", ComplexFloat32Type)})
end

ffi.cdef[[
void *memmove(void *dest, const void *src, size_t n);
void (*volk_32fc_32f_dot_prod_32fc_a)(complex_float32_t* result, const complex_float32_t* input, const float32_t* taps, unsigned int num_points);
]]
local volk = ffi.load("libvolk.so")

function FIRFilterBlock:process(x)
    local out = ComplexFloat32Type.vector(x.length)

    for i = 0, x.length-1 do
        -- Shift the state samples down
        ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
        -- Insert sample into state
        self.state.data[0] = x.data[i]

        -- Inner product of state and taps
        volk.volk_32fc_32f_dot_prod_32fc_a(out.data[i], self.state.data, self.taps.data, self.taps.length)

        -- Inner product of state and taps (slow Lua version)
        --for j = 0, self.state.length-1 do
        --    out.data[i] = out.data[i] + self.state.data[j]:scalar_mul(self.taps.data[j+1].value)
        --end
    end

    return out
end

return {FIRFilterBlock = FIRFilterBlock}
