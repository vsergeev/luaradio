local ffi = require('ffi')

local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type
local Float32Type = require('radio.types.float32').Float32Type

local ComplexToRealBlock = block.factory("ComplexToRealBlock")

function ComplexToRealBlock:instantiate()
    self:add_type_signature({block.Input("in", ComplexFloat32Type)}, {block.Output("out", Float32Type)})
end

function ComplexToRealBlock:process(x)
    local out = Float32Type.vector(x.length)

    for i = 0, x.length-1 do
        out.data[i].value = x.data[i].real
    end

    return out
end

return {ComplexToRealBlock = ComplexToRealBlock}
