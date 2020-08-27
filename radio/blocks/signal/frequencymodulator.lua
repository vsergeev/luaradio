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

local block = require('radio.core.block')
local types = require('radio.types')

local FrequencyModulatorBlock = block.factory("FrequencyModulatorBlock")

function FrequencyModulatorBlock:instantiate(modulation_index)
    self.modulation_index = assert(modulation_index, "Missing argument #1 (modulation_index)")

    self:add_type_signature({block.Input("in", types.Float32)}, {block.Output("out", types.ComplexFloat32)})
end

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

return FrequencyModulatorBlock
