local ComplexFloat32Type = require('types.complexfloat32').ComplexFloat32Type
local pipe = require('pipe')
local block = require('block')

local SummerBlock = block.BlockFactory("SummerBlock")

function SummerBlock:instantiate()
    self.inputs = {pipe.PipeInput("x", ComplexFloat32Type),
                   pipe.PipeInput("y", ComplexFloat32Type)}
    self.outputs = {pipe.PipeOutput("out", ComplexFloat32Type,
                    function () return self.inputs[1].pipe.rate end)}
end

function SummerBlock:process(x, y)
    -- FIXME infer output type
    local out = ComplexFloat32Type.alloc(x.length)
    for i = 0, x.length-1 do
        out.data[i] = x.data[i] + y.data[i]
    end
    return out
end

return {SummerBlock = SummerBlock}
