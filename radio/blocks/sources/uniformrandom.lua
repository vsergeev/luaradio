local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local UniformRandomSource = block.factory("UniformRandomSource")

local random_generator_table = {
    [types.ComplexFloat32Type] =
        function (a, b)
            a, b = a or -1.0, b or 1.0
            return function ()
                return types.ComplexFloat32Type((b-a)*math.random()-b, (b-a)*math.random()-b)
            end
        end,
    [types.Float32Type] =
        function (a, b)
            a, b = a or -1.0, b or 1.0
            return function ()
                return types.Float32Type((b-a)*math.random()-b)
            end
        end,
    [types.Integer32Type] =
        function (a, b)
            a, b = a or -2147483648, b or 2147483647
            return function ()
                return types.Integer32Type(math.random(a, b))
            end
        end,
    [types.ByteType] =
        function (a, b)
            a = a or 0, b or 255
            return function ()
                return types.ByteType(math.random(a, b))
            end
        end,
    [types.BitType] =
        function (a, b)
            return function ()
                return types.BitType(math.random(0, 1))
            end
        end,
}

function UniformRandomSource:instantiate(data_type, rate, range, options)
    if not random_generator_table[data_type] then
        error("Unsupported data type.")
    end

    options = options or {}

    self.rate = rate or 1
    self.chunk_size = 8192
    self.data_type = data_type
    self.generator = random_generator_table[data_type](unpack(range or {}))
    self.seed = options.seed or nil

    self:add_type_signature({}, {block.Output("out", data_type)})
end

function UniformRandomSource:get_rate()
    return self.rate
end

function UniformRandomSource:initialize()
    if self.seed then
        math.randomseed(self.seed)
    end
end

function UniformRandomSource:process()
    local samples = self.data_type.vector(self.chunk_size)

    for i=0, samples.length-1 do
        samples.data[i] = self.generator()
    end

    return samples
end

return UniformRandomSource
