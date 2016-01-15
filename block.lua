require('oo')

-- Block base class
local Block = class_factory()

function Block.new(name)
    local self = setmetatable({}, Block)
    self.name = name
    self.inputs = {}
    self.outputs = {}
    return self
end

function Block:initialize()
end

function Block:process(...)
    error("process() not implemented")
end

-- BlockFactory derived class generator
function BlockFactory(name)
    local class = class_factory(Block)

    class.new = function (...)
        block = setmetatable(Block.new(name), class)

        block:instantiate(...)
        return block
    end

    return class
end

-- Exported module
return {Block = Block, BlockFactory = BlockFactory}
