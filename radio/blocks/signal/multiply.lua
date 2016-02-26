local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type

local MultiplyBlock = block.factory("MultiplyBlock")

function MultiplyBlock:instantiate()
    self:add_type_signature({block.Input("in1", ComplexFloat32Type), block.Input("in2", ComplexFloat32Type)}, {block.Output("out", ComplexFloat32Type)}, MultiplyBlock.process_complex)
    self:add_type_signature({block.Input("in1", Float32Type), block.Input("in2", Float32Type)}, {block.Output("out", Float32Type)}, MultiplyBlock.process_real)
end

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_x2_multiply_32fc_a)(complex_float32_t* cVector, const complex_float32_t* aVector, const complex_float32_t* bVector, unsigned int num_points);
    void (*volk_32f_x2_multiply_32f_a)(float32_t* cVector, const float32_t* aVector, const float32_t* bVector, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function MultiplyBlock:process_complex(x, y)
        local out = ComplexFloat32Type.vector(x.length)
        libvolk.volk_32fc_x2_multiply_32fc_a(out.data, x.data, y.data, x.length)
        return out
    end

    function MultiplyBlock:process_real(x, y)
        local out = Float32Type.vector(x.length)
        libvolk.volk_32f_x2_multiply_32f_a(out.data, x.data, y.data, x.length)
        return out
    end

else

    function MultiplyBlock:process_complex(x, y)
        local out = ComplexFloat32Type.vector(x.length)

        for i = 0, x.length - 1 do
            out.data[i] = x.data[i] * y.data[i]
        end

        return out
    end

    function MultiplyBlock:process_real(x, y)
        local out = Float32Type.vector(x.length)

        for i = 0, x.length - 1 do
            out.data[i] = x.data[i] * y.data[i]
        end

        return out
    end

end

return {MultiplyBlock = MultiplyBlock}
