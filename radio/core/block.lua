local object = require('radio.core.object')
local pipe = require('radio.core.pipe')
local util = require('radio.core.util')

-- Input class
local Input = object.class_factory()

function Input.new(name, data_type)
    self = setmetatable({}, Input)
    self.name = name
    self.data_type = data_type
    return self
end

-- Output class
local Output = object.class_factory()

function Output.new(name, data_type)
    self = setmetatable({}, Output)
    self.name = name
    self.data_type = data_type
    return self
end

-- Block base class
local Block = object.class_factory()

function Block:add_type_signature(inputs, outputs, process_func, initialize_func)
    -- Create a PipeInput for each input
    if #self.inputs == 0 then
        for _, v in ipairs(inputs) do
            self.inputs[#self.inputs+1] = pipe.PipeInput(self, v.name)
        end
    end
    assert(#self.inputs == #inputs, "Invalid type signature: mismatch in input count.")

    -- Create a PipeOutput for each output
    if #self.outputs == 0 then
        for _, v in ipairs(outputs) do
            self.outputs[#self.outputs+1] = pipe.PipeOutput(self, v.name)
        end
    end
    assert(#self.outputs == #outputs, "Invalid type signature: mismatch in output count.")

    -- Add the type signature to our signatures list
    self.signatures[#self.signatures+1] = {
        inputs = inputs,
        outputs = outputs,
        initialize_func = initialize_func or self.initialize,
        process_func = process_func or self.process,
    }
end

function Block:differentiate(input_data_types)
    -- Eliminate type signature candidates that don't allow the specified input
    -- names and data types
    local signature_candidates = {}
    for _, signature in ipairs(self.signatures) do
        signature_candidates[signature] = true

        -- Compare signature input types with specified input types
        for i = 1, #signature.inputs do
            if input_data_types[i] ~= signature.inputs[i].data_type then
                signature_candidates[signature] = nil
                break
            end
        end
    end

    assert(util.table_length(signature_candidates) == 1, "No compatible type signatures found for block \"" .. self.name .. "\".")

    -- Differentiate to the type signature
    self.signature, _ = next(signature_candidates)
    self.initialize = self.signature.initialize_func
    self.process = self.signature.process_func

    -- Set output pipe data types (FIXME over-reaching)
    for i = 1, #self.signature.outputs do
        for _, pipe in ipairs(self.outputs[i].pipes) do
            pipe.data_type = self.signature.outputs[i].data_type
        end
    end
end

function Block:get_rate()
    assert(#self.inputs > 0, "get_rate() not implemented for source " .. self.name .. ".")

    -- Default to copying rate from first input
    return self.inputs[1].pipe:get_rate()
end

function Block:initialize()
    -- No operation
end

function Block:process(...)
    error("process() not implemented")
end

function Block:run_once()
    local data_out

    -- Process inputs into outputs
    if #self.inputs == 0 then
        -- No inputs (source)
        data_out = {self:process()}
    elseif #self.inputs == 1 then
        -- One input
        data_out = {self:process(self.inputs[1].pipe:read())}
    else
        -- Multiple inputs
        -- Do a synchronous read across all pipes
        local pipes = {}
        for i=1, #self.inputs do
            pipes[i] = self.inputs[i].pipe
        end
        data_out = {self:process(pipe.read_synchronous(pipes))}
    end

    -- Write outputs to pipes
    for i=1, #self.outputs do
        for j=1, #self.outputs[i].pipes do
            self.outputs[i].pipes[j]:write(data_out[i])
        end
    end
end

function Block:run()
    -- Run forever
    while true do
        self:run_once()
    end
end

-- BlockFactory derived class generator
function BlockFactory(name)
    local class = object.class_factory(Block)

    class.new = function (...)
        local self  = setmetatable({}, class)

        self.name = name
        self.inputs = {}
        self.outputs = {}

        -- Type signatures and differentiated signature
        self.signatures = {}
        self.signature = nil

        self:instantiate(...)

        return self
    end

    return class
end

-- Exported module
return {Input = Input, Output = Output, Block = Block, BlockFactory = BlockFactory}
