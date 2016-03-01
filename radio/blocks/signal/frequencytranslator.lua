local math = require('math')
local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local types = require('radio.types')

local FrequencyTranslatorBlock = block.factory("FrequencyTranslatorBlock")

function FrequencyTranslatorBlock:instantiate(offset)
    self.offset = offset

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", types.ComplexFloat32Type)})
end

function FrequencyTranslatorBlock:initialize()
    self.omega = 2*math.pi*(self.offset/self:get_rate())

    self.rotation = types.ComplexFloat32Type(math.cos(self.omega), math.sin(self.omega))
    self.phi = types.ComplexFloat32Type(1, 0)
end

if platform.features.volk then

    ffi.cdef[[
    void (*volk_32fc_s32fc_x2_rotator_32fc)(complex_float32_t* outVector, const complex_float32_t* inVector, const complex_float32_t phase_inc, complex_float32_t* phase, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function FrequencyTranslatorBlock:process(x)
        local out = types.ComplexFloat32Type.vector(x.length)
        libvolk.volk_32fc_s32fc_x2_rotator_32fc(out.data, x.data, self.rotation, self.phi, x.length)

        return out
    end

else

    function FrequencyTranslatorBlock:process(x)
        local out = types.ComplexFloat32Type.vector(x.length)

        for i = 0, x.length-1 do
            out.data[i] = x.data[i] * self.phi
            self.phi = self.phi * self.rotation
        end

        return out
    end

end

return {FrequencyTranslatorBlock = FrequencyTranslatorBlock}
