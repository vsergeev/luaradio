local block = require('block')
local ComplexFloat32Type = require('types.complexfloat32').ComplexFloat32Type
local Float32Type = require('types.float32').Float32Type
local Integer32Type = require('types.integer32').Integer32Type

local PrintSinkBlock = block.BlockFactory("PrintSinkBlock")

function PrintSinkBlock:instantiate()
    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {})
    self:add_type_signature({block.Input("in", Float32Type)}, {})
    self:add_type_signature({block.Input("in", Integer32Type)}, {})
end

function PrintSinkBlock:process(x)
    for i = 0, x.length-1 do
        print(x.data[i])
    end
end

return {PrintSinkBlock = PrintSinkBlock}
