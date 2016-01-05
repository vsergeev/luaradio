local types = require('types')
local pipe = require('pipe')
local block = require('block')

local PrintSinkBlock = block.BlockFactory("PrintSinkBlock")

function PrintSinkBlock:instantiate()
    self.inputs = {pipe.PipeInput("x", types.AnyType)}
    self.outputs = {}
end

function PrintSinkBlock:process(x)
    for i = 0, x.length-1 do
        print(x[i])
    end
end

return {PrintSinkBlock = PrintSinkBlock}
