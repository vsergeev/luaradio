local class = require('radio.core.class')
local pipe = require('radio.core.pipe')
local util = require('radio.core.util')

-- Input class
local Input = class.factory()

function Input.new(name, data_type)
    self = setmetatable({}, Input)
    self.name = name
    self.data_type = data_type
    return self
end

-- Output class
local Output = class.factory()

function Output.new(name, data_type)
    self = setmetatable({}, Output)
    self.name = name
    self.data_type = data_type
    return self
end

-- Block base class
local Block = class.factory()

function Block:add_type_signature(inputs, outputs, process_func, initialize_func)
    -- Assert inputs are Inputs
    for i = 1, #inputs do
        assert(class.isinstanceof(inputs[i], Input), string.format("Invalid input port descriptor (index %d).", i))
    end

    if not self.inputs then
        -- Create inputs with a PipeInput for each input
        self.inputs = {}
        for i = 1, #inputs do
            self.inputs[i] = pipe.PipeInput(self, inputs[i].name)
        end
    else
        -- Check input count
        assert(#self.inputs == #inputs, string.format("Invalid type signature, input count mismatch (got %d, expected %d).", #inputs, #self.inputs))

        -- Check input names match
        for i = 1, #inputs do
            assert(self.inputs[i].name == inputs[i].name, string.format("Invalid type signature, input name mismatch (index %d).", i))
        end
    end

    -- Assert outputs are Outputs
    for i = 1, #outputs do
        assert(class.isinstanceof(outputs[i], Output), string.format("Invalid output port descriptor (index %d).", i))
    end

    if not self.outputs then
        -- Create outputs with a PipeOutput for each output
        self.outputs = {}
        for i = 1, #outputs do
            self.outputs[i] = pipe.PipeOutput(self, outputs[i].name)
        end
    else
        -- Check output count
        assert(#self.outputs == #outputs, string.format("Invalid type signature, output count mismatch (got %d, expected %d).", #outputs, #self.outputs))

        -- Check output names match
        for i = 1, #outputs do
            assert(self.outputs[i].name == outputs[i].name, string.format("Invalid type signature, output name mismatch (index %d).", i))
        end
    end

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
    for i = 1, #input_data_types do
        self.inputs[i].data_type = input_data_types[i]
    end
    for i = 1, #self.signature.outputs do
        self.outputs[i].data_type = self.signature.outputs[i].data_type
    end
end

function Block:get_input_types()
    assert(self.signature, "Block not yet differentiated.")

    local types = {}
    for i = 1, #self.inputs do
        types[i] = self.inputs[i].data_type
    end

    return types
end

function Block:get_output_types()
    assert(self.signature, "Block not yet differentiated.")

    local types = {}
    for i = 1, #self.outputs do
        types[i] = self.outputs[i].data_type
    end

    return types
end

function Block:get_rate()
    assert(self.signature, "Block not yet differentiated.")

    assert(#self.inputs > 0, "get_rate() not implemented for source " .. self.name .. ".")

    -- Default to copying rate from first input
    return self.inputs[1].pipe:get_rate()
end

function Block:__tostring()
    local s = self.name .. "\n"

    -- tostring() on class
    if self.inputs == nil or self.outputs == nil then
        return s
    end

    -- tostring() on class instance
    local strs = {}

    for i=1, #self.inputs do
        if self.inputs[i].pipe then
            local pipe = self.inputs[i].pipe or self.inputs[i].real_input.pipe
            if pipe then
                strs[#strs + 1] = string.format("    .%-5s <- {%s.%s}", self.inputs[i].name, pipe.pipe_output.owner.name, pipe.pipe_output.name)
            else
                strs[#strs + 1] = string.format("    .%-5s <- unconnected", self.inputs[i].name)
            end
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

function Block:instantiate()
    -- No operation
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

        -- Process
        data_out = {self:process()}

        -- Check for EOF
        if #data_out == 0 then
            return nil
        end
    elseif #self.inputs == 1 then
        -- One input

        -- Read input
        local data_in = self.inputs[1].pipe:read()

        -- Check for EOF
        if data_in == nil then
            return nil
        end

        -- Process
        data_out = {self:process(data_in)}
    else
        -- Multiple inputs

        -- Gather input pipes
        local pipes = {}
        for i=1, #self.inputs do
            pipes[i] = self.inputs[i].pipe
        end

        -- Synchronous read across all inputs
        local data_in = pipe.read_synchronous(pipes)
        -- Check for EOF
        if data_in == nil then
            return nil
        end

        -- Process
        data_out = {self:process(unpack(data_in))}
    end

    -- Write outputs to pipes
    local new_samples = false
    for i=1, #self.outputs do
        new_samples = new_samples or data_out[i].length > 0
        for j=1, #self.outputs[i].pipes do
            self.outputs[i].pipes[j]:write(data_out[i])
        end
    end

    -- Return true or false if new samples were produced
    return new_samples
end

function Block:run()
    if #self.inputs == 0 then
        -- No inputs (source)

        while true do
            -- Process
            data_out = {self:process()}

            -- Check for EOF
            if #data_out == 0 then
                break
            end

            -- Write outputs to pipes
            for i=1, #self.outputs do
                for j=1, #self.outputs[i].pipes do
                    self.outputs[i].pipes[j]:write(data_out[i])
                end
            end
        end
    elseif #self.inputs == 1 then
        -- One input

        while true do
            -- Read input
            local data_in = self.inputs[1].pipe:read()

            -- Check for EOF
            if data_in == nil then
                break
            end

            -- Process
            data_out = {self:process(data_in)}

            -- Write outputs to pipes
            for i=1, #self.outputs do
                for j=1, #self.outputs[i].pipes do
                    self.outputs[i].pipes[j]:write(data_out[i])
                end
            end
        end
    else
        -- Multiple inputs

        -- Gather input pipes
        local input_pipes = {}
        for i=1, #self.inputs do
            input_pipes[i] = self.inputs[i].pipe
        end

        while true do
            -- Synchronous read across all inputs
            local data_in = pipe.read_synchronous(input_pipes)

            -- Check for EOF
            if data_in == nil then
                break
            end

            -- Process
            data_out = {self:process(unpack(data_in))}

            -- Write outputs to pipes
            for i=1, #self.outputs do
                for j=1, #self.outputs[i].pipes do
                    self.outputs[i].pipes[j]:write(data_out[i])
                end
            end
        end
    end

    -- Clean up
    self:cleanup()
end

-- Block factory derived class generator
local function factory(name, parent_class)
    local class = class.factory(parent_class or Block)

    class.name = name

    class.new = function (...)
        local self = setmetatable({}, class)

        -- Pipe inputs and outputs
        self.inputs = nil
        self.outputs = nil

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
