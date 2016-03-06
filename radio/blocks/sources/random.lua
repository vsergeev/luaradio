local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local RandomSource = block.factory("RandomSource")

local random_generator_table = {
    [types.ComplexFloat32Type] =
        function () return types.ComplexFloat32Type(2*math.random()-1, 2*math.random()-1) end,
    [types.Float32Type] =
        function () return types.Float32Type(2*math.random()-1) end,
    [types.Integer32Type] =
        function () return types.Integer32Type(math.random(-2147483648, 2147483647)) end,
    [types.ByteType] =
        function () return types.ByteType(math.random(0, 255)) end,
    [types.BitType] =
        function () return types.BitType(math.random(0, 1)) end,
}

function RandomSource:instantiate(data_type, rate)
    if not random_generator_table[data_type] then
        error("Unsupported data type.")
    end

    self.rate = rate or 1
    self.chunk_size = 8192
    self.data_type = data_type

    self:add_type_signature({}, {block.Output("out", data_type)})
end

function RandomSource:get_rate()
    return self.rate
end

function RandomSource:process()
    local samples = self.data_type.vector(self.chunk_size)

    for i=0, samples.length-1 do
        samples.data[i] = random_generator_table[self.data_type]()
    end

    return samples
end

return {RandomSource = RandomSource}
