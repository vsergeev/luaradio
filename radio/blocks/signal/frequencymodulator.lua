---
-- Frequency modulate a real-valued signal into a baseband complex-valued
-- signal.
--
-- $$ y[n] = e^{j 2 \pi k \sum x[n]} $$
--
-- @category Modulation
-- @block FrequencyModulatorBlock
-- @tparam number modulation_index Modulation index (Carrier Deviation / Maximum Modulation Frequency)
-- @signature in:Float32 > out:ComplexFloat32
--
-- @usage
-- -- Frequency modulator with modulation index 0.2
-- local fm_mod = radio.FrequencyModulatorBlock(0.2)

local ffi = require('ffi')
local math = require('math')

local platform = require('radio.core.platform')
local block = require('radio.core.block')
local types = require('radio.types')

local FrequencyModulatorBlock = block.factory("FrequencyModulatorBlock")

function FrequencyModulatorBlock:instantiate(modulation_index)
    self.modulation_index = assert(modulation_index, "Missing argument #1 (modulation_index)")

    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.ComplexFloat32)})
end

if platform.features.liquid then

    ffi.cdef[[
    typedef struct freqmod_s * freqmod;
    freqmod freqmod_create(float _kf);
    void freqmod_destroy(freqmod _q);

    void freqmod_modulate_block(freqmod _q, const float32_t * _m, unsigned int _n, complex_float32_t * _s);
    ]]
    local libliquid = platform.libs.liquid

    function FrequencyModulatorBlock:initialize()
        self.freqmod = ffi.gc(libliquid.freqmod_create(self.modulation_index), libliquid.freqmod_destroy)
        if self.freqmod == nil then
            error("Creating liquid freqmod object.")
        end

        self.out = types.ComplexFloat32.vector()
    end

    function FrequencyModulatorBlock:process(x)
        local out = self.out:resize(x.length)

        libliquid.freqmod_modulate_block(self.freqmod, x.data, x.length, out.data)

        return out
    end

else

    ffi.cdef[[
        float cosf(float x);
        float sinf(float x);
    ]]

    function FrequencyModulatorBlock:initialize()
        self.phase = 0
        self.delta = 2*math.pi*self.modulation_index

        self.out = types.ComplexFloat32.vector()
    end

    function FrequencyModulatorBlock:process(x)
        local out = self.out:resize(x.length)

        for i = 0, x.length-1 do
            self.phase = (self.phase + self.delta*x.data[i].value) % (2 * math.pi)
            out.data[i].real = ffi.C.cosf(self.phase)
            out.data[i].imag = ffi.C.sinf(self.phase)
        end

        return out
    end

end

return FrequencyModulatorBlock
