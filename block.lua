require('oo')

-- Block base class
local Block = class_factory()

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
        local self  = setmetatable({}, class)
        self.name = name
        self.inputs = {}
        self.outputs = {}

        self:instantiate(...)

        -- Associate input and outputs with block
        for _, input in pairs(self.inputs) do
            input.owner = self
        end
        for _, output in pairs(self.outputs) do
            output.owner = self
        end

        return self
    end

    return class
end

-- Exported module
return {Block = Block, BlockFactory = BlockFactory}
