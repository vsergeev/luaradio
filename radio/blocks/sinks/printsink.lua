local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type
local Integer32Type = require('radio.types.integer32').Integer32Type
local BitType = require('radio.types.bit').BitType

local PrintSinkBlock = block.BlockFactory("PrintSinkBlock")

function PrintSinkBlock:instantiate()
    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {})
    self:add_type_signature({block.Input("in", Float32Type)}, {})
    self:add_type_signature({block.Input("in", Integer32Type)}, {})
    self:add_type_signature({block.Input("in", BitType)}, {})
end

function PrintSinkBlock:process(x)
    for i = 0, x.length-1 do
        print(x.data[i])
    end
end

return {PrintSinkBlock = PrintSinkBlock}
