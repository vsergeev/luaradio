local math = require('math')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type

local RandomSource = block.factory("RandomSource")

function RandomSource:instantiate(rate)
    self.rate = rate or 1
    self.chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", ComplexFloat32Type)})
end

function RandomSource:get_rate()
    return self.rate
end

function RandomSource:process()
    local samples = ComplexFloat32Type.vector(self.chunk_size)
    for i=0, samples.length-1 do
        samples.data[i].real = math.random()
        samples.data[i].imag = math.random()
    end
    return samples
end

return {RandomSource = RandomSource}
