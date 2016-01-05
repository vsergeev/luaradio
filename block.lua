-- Block base class
local Block = {}
Block.__call = function (self, ...) return self.new(...) end
Block.__index = Block

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
    local class = setmetatable({}, Block)
    class.__index = class

    class.new = function (...)
        block = setmetatable(Block.new(name), class)
        block:instantiate(...)
        return block
    end

    return class
end

-- Exported module
return {Block = Block, BlockFactory = BlockFactory}
