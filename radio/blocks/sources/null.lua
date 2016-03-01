local block = require('radio.core.block')
local types = require('radio.types')

local NullSource = block.factory("NullSource")

function NullSource:instantiate(rate)
    self.rate = rate or 1
    self.chunk_size = 8192
    self.out = types.ComplexFloat32Type.vector(self.chunk_size)

    self:add_type_signature({}, {block.Output("out", types.ComplexFloat32Type)})
end

function NullSource:get_rate()
    return self.rate
end

function NullSource:process()
    return self.out
end

return {NullSource = NullSource}
