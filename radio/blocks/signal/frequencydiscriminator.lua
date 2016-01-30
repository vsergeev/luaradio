local ffi = require('ffi')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type

local FrequencyDiscriminatorBlock = block.BlockFactory("FrequencyDiscriminatorBlock")

function FrequencyDiscriminatorBlock:instantiate(gain)
    self.prev_sample = ComplexFloat32Type()
    self.gain = gain or 1.0

    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {block.Output("out", Float32Type)})
end

ffi.cdef[[
void *memcpy(void *dest, const void *src, size_t n);
void (*volk_32fc_x2_multiply_conjugate_32fc_a)(complex_float32_t* cVector, const complex_float32_t* aVector, const complex_float32_t* bVector, unsigned int num_points);
void (*volk_32fc_s32f_atan2_32f_a)(float32_t* outputVector, const complex_float32_t* complexVector, const float normalizeFactor, unsigned int num_points);
]]
local libvolk = ffi.load("libvolk.so")

function FrequencyDiscriminatorBlock:process(x)
    -- Create shifted sequence from x, e.g.
    --      [a b c d e f g h] -> [p a b c d e f g]
    local x_shifted = ComplexFloat32Type.vector(x.length)
    ffi.C.memcpy(x_shifted.data[1], x.data[0], (x.length-1)*ffi.sizeof(x.data[0]))
    x_shifted.data[0] = self.prev_sample

    -- Multiply element-wise of samples by conjugate of previous samples
    --      [a b c d e f g h] * ~[p a b c d e f g]
    local tmp = ComplexFloat32Type.vector(x.length)
    libvolk.volk_32fc_x2_multiply_conjugate_32fc_a(tmp.data, x.data, x_shifted.data, x.length)

    -- Compute element-wise atan2 of multiplied samples
    local out = Float32Type.vector(x.length)
    libvolk.volk_32fc_s32f_atan2_32f_a(out.data, tmp.data, self.gain, tmp.length)

    -- Save last sample of x to be the next previous sample
    self.prev_sample = ComplexFloat32Type(x.data[x.length-1].real, x.data[x.length-1].imag)

    return out
end

return {FrequencyDiscriminatorBlock = FrequencyDiscriminatorBlock}
