require('types')
local pipe = require('pipe')
local block = require('block')

local NullSourceBlock = block.BlockFactory("NullSourceBlock")

function NullSourceBlock:instantiate(chunksize)
    self._chunksize = chunksize or 4096

    self.inputs = {}
    self.outputs = {pipe.PipeOutput("out", ComplexFloatType, rate)}
end

function NullSourceBlock:process()
    return ComplexFloatType.alloc(self._chunksize)
end

return {NullSourceBlock = NullSourceBlock}
