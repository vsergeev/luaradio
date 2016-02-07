local math = require('math')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type

local RandomSourceBlock = block.factory("RandomSourceBlock")

function RandomSourceBlock:instantiate(rate)
    self._rate = rate or 1
    self._chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", ComplexFloat32Type)})
end

function RandomSourceBlock:get_rate()
    return self._rate
end

function RandomSourceBlock:process()
    local samples = ComplexFloat32Type.vector(self._chunk_size)
    for i=0, samples.length-1 do
        samples.data[i].real = math.random()
        samples.data[i].imag = math.random()
    end
    return samples
end

return {RandomSourceBlock = RandomSourceBlock}
