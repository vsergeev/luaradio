local types = require('types')
local pipe = require('pipe')
local block = require('block')

local NullSourceBlock = block.BlockFactory("NullSourceBlock")

function NullSourceBlock:instantiate(chunksize)
    self._chunksize = chunksize or 4096

    self.inputs = {}
    self.outputs = {pipe.PipeOutput("out", types.ComplexFloat32Type, rate)}
end

function NullSourceBlock:process()
    local samples = types.ComplexFloat32Type.alloc(self._chunksize)
    return samples
end

return {NullSourceBlock = NullSourceBlock}
