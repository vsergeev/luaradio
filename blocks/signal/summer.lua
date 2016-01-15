require('types')
local pipe = require('pipe')
local block = require('block')

local SummerBlock = block.BlockFactory("SummerBlock")

function SummerBlock:instantiate()
    self.inputs = {pipe.PipeInput("x", AnyType),
                   pipe.PipeInput("y", AnyType)}
    self.outputs = {pipe.PipeOutput("out", AnyType,
                    function () return self.inputs[1].pipe.rate end)}
end

function SummerBlock:process(x, y)
    -- FIXME infer output type
    local out = ComplexFloatType.alloc(x.length)
    for i = 0, x.length-1 do
        out.data[i] = x.data[i] + y.data[i]
    end
    return out
end

return {SummerBlock = SummerBlock}
