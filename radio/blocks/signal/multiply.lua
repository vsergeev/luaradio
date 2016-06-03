local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local types = require('radio.types')

local MultiplyBlock = block.factory("MultiplyBlock")

function MultiplyBlock:instantiate()
    self:add_type_signature({block.Input("in1", types.ComplexFloat32), block.Input("in2", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)}, MultiplyBlock.process_complex)
    self:add_type_signature({block.Input("in1", types.Float32), block.Input("in2", types.Float32)}, {block.Output("out", types.Float32)}, MultiplyBlock.process_real)
end

function MultiplyBlock:initialize()
    self.out = self:get_output_type().vector()
end

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_x2_multiply_32fc_a)(complex_float32_t* cVector, const complex_float32_t* aVector, const complex_float32_t* bVector, unsigned int num_points);
    void (*volk_32f_x2_multiply_32f_a)(float32_t* cVector, const float32_t* aVector, const float32_t* bVector, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function MultiplyBlock:process_complex(x, y)
        local out = self.out:resize(x.length)

        libvolk.volk_32fc_x2_multiply_32fc_a(out.data, x.data, y.data, x.length)

        return out
    end

    function MultiplyBlock:process_real(x, y)
        local out = self.out:resize(x.length)

        libvolk.volk_32f_x2_multiply_32f_a(out.data, x.data, y.data, x.length)

        return out
    end

else

    function MultiplyBlock:process_complex(x, y)
        local out = self.out:resize(x.length)

        for i = 0, x.length - 1 do
            out.data[i] = x.data[i] * y.data[i]
        end

        return out
    end

    function MultiplyBlock:process_real(x, y)
        local out = self.out:resize(x.length)

        for i = 0, x.length - 1 do
            out.data[i] = x.data[i] * y.data[i]
        end

        return out
    end

end

return MultiplyBlock
