local ffi = require('ffi')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type

local MultiplierBlock = block.factory("MultiplierBlock")

function MultiplierBlock:instantiate()
    self:add_type_signature({block.Input("in1", ComplexFloat32Type), block.Input("in2", ComplexFloat32Type)}, {block.Output("out", ComplexFloat32Type)}, MultiplierBlock.process_complex)
    self:add_type_signature({block.Input("in1", Float32Type), block.Input("in2", Float32Type)}, {block.Output("out", Float32Type)}, MultiplierBlock.process_real)
end

ffi.cdef[[
void (*volk_32fc_x2_multiply_32fc_a)(complex_float32_t* cVector, const complex_float32_t* aVector, const complex_float32_t* bVector, unsigned int num_points);
void (*volk_32f_x2_multiply_32f_a)(float32_t* cVector, const float32_t* aVector, const float32_t* bVector, unsigned int num_points);
]]
local libvolk = ffi.load("libvolk.so")

function MultiplierBlock:process_complex(x, y)
    local out = ComplexFloat32Type.vector(x.length)
    libvolk.volk_32fc_x2_multiply_32fc_a(out.data, x.data, y.data, x.length)
    return out
end

function MultiplierBlock:process_real(x, y)
    local out = Float32Type.vector(x.length)
    libvolk.volk_32f_x2_multiply_32f_a(out.data, x.data, y.data, x.length)
    return out
end

return {MultiplierBlock = MultiplierBlock}
