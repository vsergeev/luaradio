local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local types = require('radio.types')

local FrequencyDiscriminatorBlock = block.factory("FrequencyDiscriminatorBlock")

function FrequencyDiscriminatorBlock:instantiate(gain)
    self.prev_sample = types.ComplexFloat32()
    self.gain = gain or 1.0

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.Float32)})
end

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_x2_multiply_conjugate_32fc)(complex_float32_t* cVector, const complex_float32_t* aVector, const complex_float32_t* bVector, unsigned int num_points);
    void (*volk_32fc_s32f_atan2_32f_a)(float32_t* outputVector, const complex_float32_t* complexVector, const float normalizeFactor, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function FrequencyDiscriminatorBlock:process(x)
        local tmp = types.ComplexFloat32.vector(x.length)
        local out = types.Float32.vector(x.length)

        -- Multiply element-wise of samples by conjugate of previous samples
        --      [a b c d e f g h] * ~[p a b c d e f g]
        tmp.data[0] = x.data[0]*self.prev_sample:conj()
        libvolk.volk_32fc_x2_multiply_conjugate_32fc(tmp.data[1], x.data[1], x.data, x.length-1)

        -- Compute element-wise atan2 of multiplied samples
        libvolk.volk_32fc_s32f_atan2_32f_a(out.data, tmp.data, self.gain, x.length)

        -- Save last sample of x to be the next previous sample
        self.prev_sample = types.ComplexFloat32(x.data[x.length-1].real, x.data[x.length-1].imag)

        return out
    end

else

    function FrequencyDiscriminatorBlock:process(x)
        local tmp = types.ComplexFloat32.vector(x.length)
        local out = types.Float32.vector(x.length)

        -- Multiply element-wise of samples by conjugate of previous samples
        --      [a b c d e f g h] * ~[p a b c d e f g]
        tmp.data[0] = x.data[0]*self.prev_sample:conj()
        for i = 1, x.length-1 do
            tmp.data[i] = x.data[i] * x.data[i-1]:conj()
        end

        -- Compute element-wise atan2 of multiplied samples
        for i = 0, tmp.length-1 do
            out.data[i].value = tmp.data[i]:arg()/self.gain
        end

        -- Save last sample of x to be the next previous sample
        self.prev_sample = types.ComplexFloat32(x.data[x.length-1].real, x.data[x.length-1].imag)

        return out
    end

end

return FrequencyDiscriminatorBlock
