local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local filter_utils = require('radio.blocks.signal.filter_utils')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type

local HilbertTransformBlock = block.factory("HilbertTransformBlock")

function HilbertTransformBlock:instantiate(num_taps, window_type)
    assert((num_taps % 2) == 1, "Hilbert taps must be odd.")

    -- Default to hamming window
    window_type = (window_type == nil) and "hamming" or window_type

    -- Generate Hilbert transform taps
    local h = filter_utils.fir_hilbert_transform(num_taps, window_type)
    self.hilbert_taps = Float32Type.vector(num_taps)
    for i = 0, num_taps-1 do
        self.hilbert_taps.data[i].value = h[i+1]
    end

    self.state = Float32Type.vector(num_taps)

    self:add_type_signature({block.Input("in", Float32Type)}, {block.Output("out", ComplexFloat32Type)})
end

ffi.cdef[[
void *memmove(void *dest, const void *src, size_t n);
]]

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32f_x2_dot_prod_32f_a)(float32_t* result, const float32_t* input, const float32_t* taps, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function HilbertTransformBlock:process(x)
        local out = ComplexFloat32Type.vector(x.length)
        local filter_out = Float32Type()

        for i = 0, x.length-1 do
            -- Shift the state samples down
            ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
            -- Insert sample into state
            self.state.data[0] = x.data[i]
            -- Inner product of state and taps for imaginary component
            libvolk.volk_32f_x2_dot_prod_32f_a(filter_out, self.state.data, self.hilbert_taps.data, self.hilbert_taps.length)

            -- Create complex output with delayed real and filter output imaginary
            out.data[i] = ComplexFloat32Type(self.state.data[(self.hilbert_taps.length-1)/2].value, filter_out.value)
        end

        return out
    end

else

  function HilbertTransformBlock:process(x)
        local out = ComplexFloat32Type.vector(x.length)

        for i = 0, x.length-1 do
            -- Shift the state samples down
            ffi.C.memmove(self.state.data[1], self.state.data[0], (self.state.length-1)*ffi.sizeof(self.state.data[0]))
            -- Insert sample into state
            self.state.data[0] = x.data[i]
            -- Inner product of state and taps for imaginary component
            local filter_out = Float32Type()
            for j = 0, self.state.length-1 do
                filter_out = filter_out + self.state.data[j] * self.hilbert_taps.data[j]
            end

            -- Create complex output with delayed real and filter output imaginary
            out.data[i] = ComplexFloat32Type(self.state.data[(self.hilbert_taps.length-1)/2].value, filter_out.value)
        end

        return out
    end

end

return {HilbertTransformBlock = HilbertTransformBlock}
