local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local types = require('radio.types')

local MultiplyConjugateBlock = block.factory("MultiplyConjugateBlock")

function MultiplyConjugateBlock:instantiate()
    self:add_type_signature({block.Input("in1", types.ComplexFloat32), block.Input("in2", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
end

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_x2_multiply_conjugate_32fc_a)(complex_float32_t* cVector, const complex_float32_t* aVector, const complex_float32_t* bVector, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function MultiplyConjugateBlock:process(x, y)
        local out = types.ComplexFloat32.vector(x.length)
        libvolk.volk_32fc_x2_multiply_conjugate_32fc_a(out.data, x.data, y.data, x.length)
        return out
    end

else

    function MultiplyConjugateBlock:process(x, y)
        local out = types.ComplexFloat32.vector(x.length)

        for i = 0, x.length - 1 do
            out.data[i] = x.data[i] * y.data[i]:conj()
        end

        return out
    end

end

return MultiplyConjugateBlock
