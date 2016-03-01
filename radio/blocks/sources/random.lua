local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local RandomSource = block.factory("RandomSource")

function RandomSource:instantiate(rate)
    self.rate = rate or 1
    self.chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", types.ComplexFloat32Type)})
end

function RandomSource:get_rate()
    return self.rate
end

function RandomSource:process()
    local samples = types.ComplexFloat32Type.vector(self.chunk_size)
    for i=0, samples.length-1 do
        samples.data[i].real = math.random()
        samples.data[i].imag = math.random()
    end
    return samples
end

return {RandomSource = RandomSource}
