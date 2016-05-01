local math = require('math')
local ffi = require('ffi')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local types = require('radio.types')

local FrequencyTranslatorBlock = block.factory("FrequencyTranslatorBlock")

function FrequencyTranslatorBlock:instantiate(offset)
    self.offset = offset

    self:add_type_signature({block.Input("in", types.ComplexFloat32)}, {block.Output("out", types.ComplexFloat32)})
end

if platform.features.volk then

    function FrequencyTranslatorBlock:initialize()
        self.omega = 2*math.pi*(self.offset/self:get_rate())

        self.rotation = types.ComplexFloat32(math.cos(self.omega), math.sin(self.omega))
        self.phi = types.ComplexFloat32(1, 0)
    end

    ffi.cdef[[
    void (*volk_32fc_s32fc_x2_rotator_32fc)(complex_float32_t* outVector, const complex_float32_t* inVector, const complex_float32_t phase_inc, complex_float32_t* phase, unsigned int num_points);
    ]]
    local libvolk = platform.libs.volk

    function FrequencyTranslatorBlock:process(x)
        local out = types.ComplexFloat32.vector(x.length)
        libvolk.volk_32fc_s32fc_x2_rotator_32fc(out.data, x.data, self.rotation, self.phi, x.length)

        return out
    end

elseif platform.features.liquid then

    ffi.cdef[[
    typedef enum { LIQUID_NCO=0, LIQUID_VCO } liquid_ncotype;

    typedef struct nco_crcf_s * nco_crcf;
    nco_crcf nco_crcf_create(liquid_ncotype _type);
    void nco_crcf_destroy(nco_crcf _q);

    void nco_crcf_set_frequency(nco_crcf _q, float _f);
    void nco_crcf_set_phase(nco_crcf _q, float _phi);

    void nco_crcf_mix_block_up(nco_crcf _q, const complex_float32_t *_x, complex_float32_t *_y, unsigned int _N);
    ]]
    local libliquid = platform.libs.liquid

    function FrequencyTranslatorBlock:initialize()
        self.nco = ffi.gc(libliquid.nco_crcf_create(ffi.C.LIQUID_VCO), libliquid.nco_crcf_destroy)
        if self.nco == nil then
            error("Creating liquid nco object.")
        end

        libliquid.nco_crcf_set_frequency(self.nco, 2*math.pi*(self.offset/self:get_rate()))
        libliquid.nco_crcf_set_phase(self.nco, 0.0)
    end

    function FrequencyTranslatorBlock:process(x)
        local out = types.ComplexFloat32.vector(x.length)

        libliquid.nco_crcf_mix_block_up(self.nco, x.data, out.data, x.length)

        return out
    end

else

    function FrequencyTranslatorBlock:initialize()
        self.omega = 2*math.pi*(self.offset/self:get_rate())
        self.phase = 0
    end

    function FrequencyTranslatorBlock:process(x)
        local out = types.ComplexFloat32.vector(x.length)

        for i = 0, x.length-1 do
            out.data[i] = x.data[i] * types.ComplexFloat32(math.cos(self.phase), math.sin(self.phase))
            self.phase = self.phase + self.omega
            self.phase = (self.phase > 2*math.pi) and (self.phase - 2*math.pi) or self.phase
        end

        return out
    end

end

return FrequencyTranslatorBlock
