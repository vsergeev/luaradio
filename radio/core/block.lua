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
    -- Assert inputs are Inputs
    for i = 1, #inputs do
        assert(object.isinstanceof(inputs[i], Input), string.format("Invalid input %d.", i))
    end

    -- Create a PipeInput for each input
    if #self.inputs == 0 then
        for _, v in ipairs(inputs) do
            self.inputs[#self.inputs+1] = pipe.PipeInput(self, v.name)
        end
    end
    assert(#self.inputs == #inputs, "Invalid type signature: mismatch in input count.")

    -- Assert outputs are Outputs
    for i = 1, #outputs do
        assert(object.isinstanceof(outputs[i], Output), string.format("Invalid output %d.", i))
    end

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
            -- Compare input type with block's type signature input type
            local predicate
            if type(signature.inputs[i].data_type) == "function" then
                predicate = signature.inputs[i].data_type(input_data_types[i])
            else
                predicate = input_data_types[i] == signature.inputs[i].data_type
            end
            -- If they're incompatible, remove the signature candidate
            if not predicate then
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

function Block:cleanup()
    -- No operation
end

function Block:run_once()
    local data_out

    -- Process inputs into outputs
    if #self.inputs == 0 then
        -- No inputs (source)
        data_out = {self:process()}
        -- Check for EOF
        if #data_out == 0 then
            return false
        end
    elseif #self.inputs == 1 then
        -- One input
        local data_in = self.inputs[1].pipe:read_max()
        -- Check for EOF
        if data_in == nil then
            return false
        end

        data_out = {self:process(data_in)}
    else
        -- Multiple inputs
        -- Do a synchronous read across all pipes
        local pipes = {}
        for i=1, #self.inputs do
            pipes[i] = self.inputs[i].pipe
        end

        local data_in = pipe.read_synchronous(pipes)
        -- Check for EOF
        if data_in == nil then
            return false
        end

        data_out = {self:process(unpack(data_in))}
    end

    -- Write outputs to pipes
    for i=1, #self.outputs do
        for j=1, #self.outputs[i].pipes do
            self.outputs[i].pipes[j]:write(data_out[i])
        end
    end

    return true
end

function Block:run()
    -- Run forever
    while true do
        if not self:run_once() then
            break
        end
    end

    -- Clean up
    self:cleanup()
end

function Block:__tostring()
    local s = self.name .. "\n"

    local strs = {}

    for i=1, #self.inputs do
        local pipe = self.inputs[i].pipe or self.inputs[i].real_input.pipe
        if pipe then
            strs[#strs + 1] = string.format("    .%-5s <- {%s.%s}", self.inputs[i].name, pipe.pipe_output.owner.name, pipe.pipe_output.name)
        else
            strs[#strs + 1] = string.format("    .%-5s <- unconnected", self.inputs[i].name)
        end
    end

    for i=1, #self.outputs do
        local pipes = self.outputs[i].pipes or self.outputs[i].real_output.pipes
        if #pipes > 0 then
            local connections = {}
            for i=1, #pipes do
                connections[i] = string.format("%s.%s", pipes[i].pipe_input.owner.name, pipes[i].pipe_input.name)
            end
            strs[#strs + 1] = string.format("    .%-5s -> {%s}", self.outputs[i].name, table.concat(connections, ", "))
        else
            strs[#strs + 1] = string.format("    .%-5s -> unconnected", self.outputs[i].name)
        end
    end

    s = s .. table.concat(strs, "\n")

    return s
end

-- Block factory derived class generator
function factory(name, parent_class)
    local class = object.class_factory(parent_class or Block)

    class.name = name

    class.new = function (...)
        local self = setmetatable({}, class)

        -- Pipe inputs and outputs
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
return {Input = Input, Output = Output, Block = Block, factory = factory}
