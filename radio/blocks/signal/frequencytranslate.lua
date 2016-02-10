local math = require('math')
local ffi = require('ffi')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type

local FrequencyTranslateBlock = block.factory("FrequencyTranslateBlock")

function FrequencyTranslateBlock:instantiate(offset)
    self.offset = offset

    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {block.Output("out", ComplexFloat32Type)})
end

function FrequencyTranslateBlock:initialize()
    self.omega = 2*math.pi*(self.offset/self:get_rate())

    self.rotation = ComplexFloat32Type(math.cos(self.omega), math.sin(self.omega))
    self.phi = ComplexFloat32Type(1, 0)
end

ffi.cdef[[
void (*volk_32fc_s32fc_x2_rotator_32fc)(complex_float32_t* outVector, const complex_float32_t* inVector, const complex_float32_t phase_inc, complex_float32_t* phase, unsigned int num_points);
]]
local libvolk = ffi.load("libvolk.so")

function FrequencyTranslateBlock:process(x)
    local out = ComplexFloat32Type.vector(x.length)

    libvolk.volk_32fc_s32fc_x2_rotator_32fc(out.data, x.data, self.rotation, self.phi, x.length)

    -- Slow Lua version
    --for i = 0, x.length-1 do
    --    out.data[i] = x.data[i] * self.phi
    --    self.phi = self.phi * self.rotation
    --end

    return out
end

return {FrequencyTranslateBlock = FrequencyTranslateBlock}
