local ComplexFloat32Type = require('types.complexfloat32').ComplexFloat32Type
local pipe = require('pipe')
local block = require('block')

local PrintSinkBlock = block.BlockFactory("PrintSinkBlock")

function PrintSinkBlock:instantiate()
    self.inputs = {pipe.PipeInput("x", ComplexFloat32Type)}
    self.outputs = {}
end

function PrintSinkBlock:process(x)
    for i = 0, x.length-1 do
        print(x.data[i])
    end
end

return {PrintSinkBlock = PrintSinkBlock}
