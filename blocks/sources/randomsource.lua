local math = require('math')

local block = require('block')
local ComplexFloat32Type = require('types.complexfloat32').ComplexFloat32Type

local RandomSourceBlock = block.BlockFactory("RandomSourceBlock")

function RandomSourceBlock:instantiate()
    self._chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", ComplexFloat32Type)})
end

function RandomSourceBlock:process()
    local samples = ComplexFloat32Type.vector(self._chunk_size)
    for i=0, samples.length-1 do
        samples[i].real = math.random()
        samples[i].imag = math.random()
    end
    return samples
end

return {RandomSourceBlock = RandomSourceBlock}
