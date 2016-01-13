require('types')
local pipe = require('pipe')
local block = require('block')

local SummerBlock = block.BlockFactory("SummerBlock")

function SummerBlock:instantiate()
    self.inputs = {pipe.PipeInput("x", types.AnyType),
                   pipe.PipeInput("y", types.AnyType)}
    self.outputs = {pipe.PipeOutput("out", types.AnyType,
                    function () return self.inputs[1].pipe.rate end)}
end

function SummerBlock:process(x, y)
    local out = ComplexIntegerType.alloc(x.length)
    for i = 0, x.length-1 do
        out[i] = x[i] + y[i]
    end
    return out
end

return {SummerBlock = SummerBlock}
