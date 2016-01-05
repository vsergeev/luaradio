local ffi = require('ffi')

local types = require('types')
local pipe = require('pipe')
local block = require('block')

local FIRFilterBlock = block.BlockFactory("FIRFilterBlock")

function FIRFilterBlock:instantiate(taps)
    self.taps = types.Float32Type.alloc(#taps)
    for i = 1, #taps do
        self.taps[i-1] = types.Float32Type(taps[i])
    end

    self.state = types.ComplexFloat32Type.alloc(#taps)

    self.inputs = {pipe.PipeInput("in", types.ComplexFloat32Type)}
    self.outputs = {pipe.PipeOutput("out", types.ComplexFloat32Type,
                    function () return self.inputs[1].pipe.rate end)}
end

ffi.cdef[[
void volk_32fc_32f_dot_prod_32fc_a_sse( complex_float32_t* result, const  complex_float32_t* input, const  float32_t* taps, unsigned int num_points);
]]
local minivolk = ffi.load("minivolk/minivolk.so")

function FIRFilterBlock:process(x)
    local out = types.ComplexFloat32Type.alloc(x.length)

    for i = 0, x.length-1 do
        -- Shift the state samples down
        ffi.copy(self.state.data[1], self.state.data[0], (self.state.length-1)*8)
        -- Insert sample into state
        self.state[0] = x.data[i]

        -- Inner product of state and taps
        minivolk.volk_32fc_32f_dot_prod_32fc_a_sse(out.data[i], self.state.data, self.taps.data, self.taps.length)

        -- Inner product of state and taps (slow Lua version)
        --for j = 0, self.state.length-1 do
        --    out.data[i] = out.data[i] + self.state[j]*self.taps[j+1]
        --end
    end

    return out
end

return {FIRFilterBlock = FIRFilterBlock}
