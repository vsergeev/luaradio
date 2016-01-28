local block = require('radio.core.block')
local ComplexFloat32Type = require('radio.types.complexfloat32').ComplexFloat32Type

local NullSourceBlock = block.BlockFactory("NullSourceBlock")

function NullSourceBlock:instantiate(rate)
    self._rate = rate or 1
    self._chunk_size = 8192

    self:add_type_signature({}, {block.Output("out", ComplexFloat32Type)})
end

function NullSourceBlock:get_rate()
    return self._rate
end

function NullSourceBlock:process()
    return ComplexFloat32Type.vector(self._chunk_size)
end

return {NullSourceBlock = NullSourceBlock}
