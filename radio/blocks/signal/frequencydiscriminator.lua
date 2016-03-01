local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local types = require('radio.types')

local FrequencyDiscriminatorBlock = block.factory("FrequencyDiscriminatorBlock")

function FrequencyDiscriminatorBlock:instantiate(gain)
    self.prev_sample = types.ComplexFloat32Type()
    self.gain = gain or 1.0

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.Float32Type)})
end

ffi.cdef[[
void *memcpy(void *dest, const void *src, size_t n);
]]

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_x2_multiply_conjugate_32fc_a)(complex_float32_t* cVector, const complex_float32_t* aVector, const complex_float32_t* bVector, unsigned int num_points);
    void (*volk_32fc_s32f_atan2_32f_a)(float32_t* outputVector, const complex_float32_t* complexVector, const float normalizeFactor, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function FrequencyDiscriminatorBlock:process(x)
        -- Create shifted sequence from x, e.g.
        --      [a b c d e f g h] -> [p a b c d e f g]
        local x_shifted = types.ComplexFloat32Type.vector(x.length)
        ffi.C.memcpy(x_shifted.data[1], x.data[0], (x.length-1)*ffi.sizeof(x.data[0]))
        x_shifted.data[0] = self.prev_sample

        -- Multiply element-wise of samples by conjugate of previous samples
        --      [a b c d e f g h] * ~[p a b c d e f g]
        local tmp = types.ComplexFloat32Type.vector(x.length)
        libvolk.volk_32fc_x2_multiply_conjugate_32fc_a(tmp.data, x.data, x_shifted.data, x.length)

        -- Compute element-wise atan2 of multiplied samples
        local out = types.Float32Type.vector(x.length)
        libvolk.volk_32fc_s32f_atan2_32f_a(out.data, tmp.data, self.gain, tmp.length)

        -- Save last sample of x to be the next previous sample
        self.prev_sample = types.ComplexFloat32Type(x.data[x.length-1].real, x.data[x.length-1].imag)

        return out
    end

else

    function FrequencyDiscriminatorBlock:process(x)
        -- Create shifted sequence from x, e.g.
        --      [a b c d e f g h] -> [p a b c d e f g]
        local x_shifted = types.ComplexFloat32Type.vector(x.length)
        ffi.C.memcpy(x_shifted.data[1], x.data[0], (x.length-1)*ffi.sizeof(x.data[0]))
        x_shifted.data[0] = self.prev_sample

        -- Multiply element-wise of samples by conjugate of previous samples
        --      [a b c d e f g h] * ~[p a b c d e f g]
        local tmp = types.ComplexFloat32Type.vector(x.length)
        for i = 0, x.length-1 do
            tmp.data[i] = x.data[i] * x_shifted.data[i]:conj()
        end

        -- Compute element-wise atan2 of multiplied samples
        local out = types.Float32Type.vector(x.length)
        for i = 0, tmp.length-1 do
            out.data[i].value = tmp.data[i]:arg()/self.gain
        end

        -- Save last sample of x to be the next previous sample
        self.prev_sample = types.ComplexFloat32Type(x.data[x.length-1].real, x.data[x.length-1].imag)

        return out
    end

end

return {FrequencyDiscriminatorBlock = FrequencyDiscriminatorBlock}
