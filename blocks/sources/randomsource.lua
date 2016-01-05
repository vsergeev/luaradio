local math = require('math')

local types = require('types')
local pipe = require('pipe')
local block = require('block')

local RandomSourceBlock = block.BlockFactory("RandomSourceBlock")

function RandomSourceBlock:instantiate(chunksize)
    self._chunksize = chunksize or 4096

    self.inputs = {}
    self.outputs = {pipe.PipeOutput("out", types.ComplexFloat32Type, rate)}
end

function RandomSourceBlock:process()
    local samples = types.ComplexFloat32Type.alloc(self._chunksize)
    for i=0, samples.length-1 do
        samples[i].real = math.random()
        samples[i].imag = math.random()
    end
    return samples
end

return {RandomSourceBlock = RandomSourceBlock}
