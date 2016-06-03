local math = require('math')

local block = require('radio.core.block')
local types = require('radio.types')

local UniformRandomSource = block.factory("UniformRandomSource")

local random_generator_table = {
    [types.ComplexFloat32] =
        function (a, b)
            a, b = a or -1.0, b or 1.0
            return function ()
                return types.ComplexFloat32((b-a)*math.random()-b, (b-a)*math.random()-b)
            end
        end,
    [types.Float32] =
        function (a, b)
            a, b = a or -1.0, b or 1.0
            return function ()
                return types.Float32((b-a)*math.random()-b)
            end
        end,
    [types.Byte] =
        function (a, b)
            a = a or 0, b or 255
            return function ()
                return types.Byte(math.random(a, b))
            end
        end,
    [types.Bit] =
        function (a, b)
            return function ()
                return types.Bit(math.random(0, 1))
            end
        end,
}

function UniformRandomSource:instantiate(data_type, rate, range, options)
    self.data_type = assert(data_type, "Missing argument #1 (data_type)")
    self.rate = assert(rate, "Missing argument #2 (rate)")

    assert(random_generator_table[data_type], "Unsupported data type")
    self.generator = random_generator_table[data_type](unpack(range or {}))

    options = options or {}
    self.chunk_size = 8192
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

    self.out = self.data_type.vector(self.chunk_size)
end

function UniformRandomSource:process()
    local out = self.out

    for i=0, out.length-1 do
        out.data[i] = self.generator()
    end

    return out
end

return UniformRandomSource
