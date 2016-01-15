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

function Block:run_once()
    -- Read inputs from pipes
    local data_in = {}
    for i=1, #self.inputs do
        data_in[#data_in+1] = self.inputs[i].pipe:read()
    end

    -- Process the inputs
    local data_out = {self:process(unpack(data_in))}

    -- Write outputs to pipes
    for i=1, #self.outputs do
        for j=1, #self.outputs[i].pipes do
            self.outputs[i].pipes[j]:write(data_out[i])
        end
    end
end

function Block:run()
    error("run() not implemented")
end

-- BlockFactory derived class generator
function BlockFactory(name)
    local class = class_factory(Block)

    class.new = function (...)
        block = setmetatable(Block.new(name), class)

        block:instantiate(...)

        -- Associate input and outputs with block
        for _, input in pairs(block.inputs) do
            input.owner = block
        end
        for _, output in pairs(block.outputs) do
            output.owner = block
        end

        return block
    end

    return class
end

-- Exported module
return {Block = Block, BlockFactory = BlockFactory}
