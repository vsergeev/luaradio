local block = require('block')
local ComplexFloat32Type = require('types.complexfloat32').ComplexFloat32Type

local NullSourceBlock = block.BlockFactory("NullSourceBlock")

function NullSourceBlock:instantiate()
    self._chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", ComplexFloat32Type)})
end

function NullSourceBlock:process()
    return ComplexFloat32Type.vector(self._chunk_size)
end

return {NullSourceBlock = NullSourceBlock}
