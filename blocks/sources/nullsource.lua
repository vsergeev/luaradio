local ComplexFloat32Type = require('types.complexfloat32').ComplexFloat32Type
local pipe = require('pipe')
local block = require('block')

local NullSourceBlock = block.BlockFactory("NullSourceBlock")

function NullSourceBlock:instantiate(chunksize)
    self._chunksize = chunksize or 4096

    self.inputs = {}
    self.outputs = {pipe.PipeOutput("out", ComplexFloat32Type, rate)}
end

function NullSourceBlock:process()
    return ComplexFloat32Type.vector(self._chunksize)
end

return {NullSourceBlock = NullSourceBlock}
