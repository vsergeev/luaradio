local ffi = require('ffi')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type

local MultiplyConjugateBlock = block.factory("MultiplyConjugateBlock")

function MultiplyConjugateBlock:instantiate()
    self:add_type_signature({block.Input("in1", ComplexFloat32Type), block.Input("in2", ComplexFloat32Type)}, {block.Output("out", ComplexFloat32Type)})
end

ffi.cdef[[
void (*volk_32fc_x2_multiply_conjugate_32fc_a)(complex_float32_t* cVector, const complex_float32_t* aVector, const complex_float32_t* bVector, unsigned int num_points);
]]
local libvolk = ffi.load("libvolk.so")

function MultiplyConjugateBlock:process(x, y)
    local out = ComplexFloat32Type.vector(x.length)
    libvolk.volk_32fc_x2_multiply_conjugate_32fc_a(out.data, x.data, y.data, x.length)
    return out
end

return {MultiplyConjugateBlock = MultiplyConjugateBlock}
